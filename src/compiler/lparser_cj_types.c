/*
** $Id: lparser_cj_types.c $
** Cangjie type definition parsing — struct, class, interface, extend, enum
** This file is #include'd from lparser.c and shares its static context.
**
** Contents:
**   skip_type_annotation  — Skip Cangjie type annotations (: Type)
**   skip_generic_params   — Skip generic type parameters (<T, U>)
**   check_type_redefine   — Detect duplicate type names in same scope
**   structstat            — Parse struct/class definitions
**   interfacestat         — Parse interface definitions
**   is_builtin_type       — Check for built-in type names
**   extendstat            — Parse extend declarations
**   enumstat              — Parse enum definitions
**
** See Copyright Notice in lua.h
*/


/*
** ============================================================
** Type annotation handling
** Parses and skips Cangjie type annotations after ':'.
** Handles: simple types, generic types, function types.
** Examples: Int64, Array<String>, (Int64, Int64) -> Bool
** ============================================================
*/
static void skip_type_annotation (LexState *ls) {
  /* skip optional type annotation after ':'
  ** Handles simple types (Int64), generic types (Array<Int64>),
  ** function types ((Int64, Int64) -> Int64), and ?Type (Option sugar) */
  if (testnext(ls, ':')) {
    int depth = 0;
    int has_type = 0;  /* validate at least one type token */
    /* Handle leading '?' for ?Type sugar (e.g., ?Int64 = Option<Int64>) */
    if (ls->t.token == '?') {
      luaX_next(ls);  /* skip '?' */
    }
    for (;;) {
      if (ls->t.token == TK_NAME) {
        if (depth == 0) {
          /* If this NAME is followed by '(' at top level, it's likely
          ** a new member definition (e.g. init(...)), not part of type.
          ** Stop consuming here. */
          if (luaX_lookahead(ls) == '(') break;
        }
        has_type = 1;
        luaX_next(ls);
      }
      else if (ls->t.token == '<' || ls->t.token == '(') {
        if (ls->t.token == '(') has_type = 1;  /* function type */
        depth++;
        luaX_next(ls);
      }
      else if ((ls->t.token == '>' || ls->t.token == ')') && depth > 0) {
        int was_paren = (ls->t.token == ')');
        depth--;
        luaX_next(ls);
        /* After closing ')', check for function return type '-> Type' */
        if (was_paren && ls->t.token == '-') {
          if (luaX_lookahead(ls) == '>') {
            luaX_next(ls);  /* skip '-' */
            luaX_next(ls);  /* skip '>' */
            /* continue to parse the return type */
          }
        }
      }
      else if (ls->t.token == TK_SHR && depth >= 2) {
        /* '>>' is lexed as TK_SHR; treat as two '>' in type context */
        depth -= 2;
        luaX_next(ls);
      }
      else if (ls->t.token == ',' && depth > 0) {
        luaX_next(ls);
      }
      else if (ls->t.token == TK_NOT && depth > 0) {
        /* '!' in parameter names for named params in function types */
        luaX_next(ls);
      }
      else if (ls->t.token == '?' && depth > 0) {
        /* '?' inside generic params for nested Option types */
        luaX_next(ls);
      }
      else {
        break;
      }
    }
    if (!has_type) {
      luaX_syntaxerror(ls, "type name expected after ':'");
    }
  }
}

static void skip_generic_params (LexState *ls) {
  /* skip <T, U, ...> if present */
  if (ls->t.token == '<') {
    int depth = 1;
    luaX_next(ls);
    while (depth > 0 && ls->t.token != TK_EOS) {
      if (ls->t.token == '<') depth++;
      else if (ls->t.token == '>') depth--;
      else if (ls->t.token == TK_SHR) {  /* >> counts as two > */
        depth -= 2;
        if (depth < 0) depth = 0;
      }
      if (depth > 0) luaX_next(ls);
    }
    luaX_next(ls);  /* skip final '>' or '>>' */
  }
}


/*
** Check for type redefinition in the same scope.
** Types (struct/class/enum/interface) may not reuse the same name.
*/
static void check_type_redefine (LexState *ls, TString *name) {
  int i;
  for (i = 0; i < ls->ndefined_types; i++) {
    if (ls->defined_types[i] == name) {
      luaX_syntaxerror(ls, luaO_pushfstring(ls->L,
          "type '%s' already defined in this scope", getstr(name)));
    }
  }
  if (ls->ndefined_types < 128) {
    ls->defined_types[ls->ndefined_types++] = name;
  }
  else {
    luaX_syntaxerror(ls, "too many type definitions in one scope (limit 128)");
  }
}


/*
** ============================================================
** Struct/Class definition
** Compiles Cangjie struct/class declarations to Lua table+metatable
** patterns. Supports: fields, methods, constructors, inheritance,
** interface implementation, generic type parameters, implicit this.
** ============================================================
*/
static void structstat (LexState *ls, int line) {
  /*
  ** struct NAME ['<' typeparams '>'] ['<:' PARENT ['&' IFACE]*] '{' members '}'
  ** Compiles to:
  **   NAME = {}; NAME.__index = NAME
  **   function NAME:method(...) ... end
  **   __cangjie_setup_class(NAME)
  **   [__cangjie_set_parent(NAME, PARENT)]
  */
  FuncState *fs = ls->fs;
  expdesc v, e;
  TString *sname;
  TString *parent_name = NULL;
  int reg;
  int saved_nfields = ls->nfields;
  int saved_in_struct = ls->in_struct_method;
  TString *saved_class_name = ls->current_class_name;
  int has_init = 0;
#define MAX_VAR_FIELDS 64
  TString *var_fields[MAX_VAR_FIELDS];
  int nvarfields = 0;
#define MAX_IFACES 16
  TString *iface_names[MAX_IFACES];
  int nifaces = 0;

  /* Reset field tracking for this struct */
  ls->nfields = 0;
  ls->in_struct_method = 0;

  luaX_next(ls);  /* skip 'struct' or 'class' */
  sname = str_checkname(ls);
  ls->current_class_name = sname;
  check_type_redefine(ls, sname);

  /* Determine if '<' is generic params or '<:' inheritance */
  if (ls->t.token == '<') {
    int la = luaX_lookahead(ls);
    if (la == ':') {
      /* '<:' for inheritance/interface */
      luaX_next(ls);  /* skip '<' (consumes lookahead ':') */
      luaX_next(ls);  /* skip ':' */
      /* First name is the parent class or interface */
      if (ls->t.token == TK_NAME) {
        parent_name = ls->t.seminfo.ts;
        if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
        luaX_next(ls);
      }
      /* Skip additional interfaces after '&' */
      while (ls->t.token == '&') {
        luaX_next(ls);  /* skip '&' */
        if (ls->t.token == TK_NAME) {
          if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
          luaX_next(ls);
        }
      }
    }
    else {
      /* Generic params '<T, U, ...>' */
      skip_generic_params(ls);
      /* After generics, check for '<:' again */
      if (ls->t.token == '<' && luaX_lookahead(ls) == ':') {
        luaX_next(ls);  /* skip '<' */
        luaX_next(ls);  /* skip ':' */
        if (ls->t.token == TK_NAME) {
          parent_name = ls->t.seminfo.ts;
          if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
          luaX_next(ls);
        }
        while (ls->t.token == '&') {
          luaX_next(ls);
          if (ls->t.token == TK_NAME) {
            if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
            luaX_next(ls);
          }
        }
      }
    }
  }
  /* optional super class ':' NAME (old-style) */
  else if (testnext(ls, ':')) {
    if (ls->t.token == TK_NAME) {
      parent_name = ls->t.seminfo.ts;
      luaX_next(ls);
    }
    while (ls->t.token == TK_NAME) luaX_next(ls);
  }
  /* handle '<=' for backward compatibility */
  else if (ls->t.token == TK_LE) {
    luaX_next(ls);  /* skip '<=' */
    if (ls->t.token == TK_NAME) {
      parent_name = ls->t.seminfo.ts;
      if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
      luaX_next(ls);
    }
    while (ls->t.token == '&') {
      luaX_next(ls);
      if (ls->t.token == TK_NAME) {
        if (nifaces < MAX_IFACES) iface_names[nifaces++] = ls->t.seminfo.ts;
        luaX_next(ls);
      }
    }
  }

  /* Create the class table: NAME = {} */
  buildvar(ls, sname, &v);
  /* Generate: {} */
  {
    int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
    luaK_code(fs, 0);  /* space for extra arg */
    init_exp(&e, VNONRELOC, fs->freereg);
    luaK_reserveregs(fs, 1);
    luaK_settablesize(fs, pc, e.u.info, 0, 0);
  }
  luaK_storevar(fs, &v, &e);

  /* Generate: NAME.__index = NAME */
  {
    expdesc tab, key, val;
    buildvar(ls, sname, &tab);
    luaK_exp2anyregup(fs, &tab);
    codestring(&key, luaX_newstring(ls, "__index", 7));
    luaK_indexed(fs, &tab, &key);
    buildvar(ls, sname, &val);
    luaK_storevar(fs, &tab, &val);
  }

  checknext(ls, '{' /*}*/);

  /* Inherit parent class fields for implicit 'this' resolution */
  if (parent_name != NULL) {
    int ri;
    for (ri = 0; ri < ls->nclass_registry; ri++) {
      if (eqstr(ls->class_registry[ri].name, parent_name)) {
        int fi;
        for (fi = 0; fi < ls->class_registry[ri].nfields; fi++) {
          if (ls->nfields < 64) {
            ls->struct_fields[ls->nfields++] = ls->class_registry[ri].fields[fi];
          }
        }
        break;
      }
    }
  }

  /* Parse members */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    /* Skip visibility/open modifiers: open, public, private */
    while (ls->t.token == TK_NAME &&
           (ls->t.seminfo.ts == luaS_new(ls->L, "open") ||
            ls->t.seminfo.ts == luaS_new(ls->L, "public") ||
            ls->t.seminfo.ts == luaS_new(ls->L, "private"))) {
      luaX_next(ls);  /* skip modifier */
    }
    if (ls->t.token == TK_FUNC) {
      /* Method definition: func name(...) { ... } */
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'func' */
      mname = str_checkname(ls);
      /* Track method name for implicit 'this' resolution */
      if (ls->nfields < 64) {
        ls->struct_fields[ls->nfields++] = mname;
      }
      /* skip generic type params on method */
      skip_generic_params(ls);
      /* Build NAME.methodname */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse method body (with 'self' parameter and implicit this) */
      ls->in_struct_method = 1;
      body(ls, &mb, 1, ls->linenumber);
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "static")) {
      /* Static function: static func name(...) { ... } */
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'static' */
      checknext(ls, TK_FUNC);  /* expect 'func' */
      mname = str_checkname(ls);
      skip_generic_params(ls);
      /* Build NAME.methodname (same storage, but no self) */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse as regular function (no self) but with implicit this for field access */
      ls->in_struct_method = 1;
      body(ls, &mb, 0, ls->linenumber);  /* ismethod=0: no self param */
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
      /* Mark as static: NAME["__static_funcname"] = true */
      {
        expdesc tab2, key2, val2;
        const char *prefix = "__static_";
        const char *namestr = getstr(mname);
        size_t plen = strlen(prefix);
        size_t nlen = strlen(namestr);
        char markerkey[128];
        if (plen + nlen + 1 < sizeof(markerkey)) {
          memcpy(markerkey, prefix, plen);
          memcpy(markerkey + plen, namestr, nlen);
          markerkey[plen + nlen] = '\0';
          buildvar(ls, sname, &tab2);
          luaK_exp2anyregup(fs, &tab2);
          codestring(&key2, luaX_newstring(ls, markerkey, plen + nlen));
          luaK_indexed(fs, &tab2, &key2);
          init_exp(&val2, VTRUE, 0);
          luaK_storevar(fs, &tab2, &val2);
        }
      }
      /* Track for implicit resolution within member methods */
      if (ls->nfields < 64) {
        ls->struct_fields[ls->nfields++] = mname;
      }
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "operator")) {
      /* Operator overload: operator func +(other: Type): Type { ... } */
      expdesc mv, mb;
      TString *metamethod_name;
      int op_token;
      luaX_next(ls);  /* skip 'operator' */
      checknext(ls, TK_FUNC);  /* expect 'func' */
      /* Read operator token */
      op_token = ls->t.token;
      /* Map operator to Lua metamethod name */
      switch (op_token) {
        case '+': metamethod_name = luaS_new(ls->L, "__add"); break;
        case '-': metamethod_name = luaS_new(ls->L, "__sub"); break;
        case '*': metamethod_name = luaS_new(ls->L, "__mul"); break;
        case '/': metamethod_name = luaS_new(ls->L, "__div"); break;
        case '%': metamethod_name = luaS_new(ls->L, "__mod"); break;
        case TK_POW: metamethod_name = luaS_new(ls->L, "__pow"); break;
        case TK_EQ: metamethod_name = luaS_new(ls->L, "__eq"); break;
        case '<': metamethod_name = luaS_new(ls->L, "__lt"); break;
        case TK_LE: metamethod_name = luaS_new(ls->L, "__le"); break;
        case TK_SHL: metamethod_name = luaS_new(ls->L, "__shl"); break;
        case TK_SHR: metamethod_name = luaS_new(ls->L, "__shr"); break;
        case '&': metamethod_name = luaS_new(ls->L, "__band"); break;
        case '|': metamethod_name = luaS_new(ls->L, "__bor"); break;
        case '^': metamethod_name = luaS_new(ls->L, "__bxor"); break;
        case '~': metamethod_name = luaS_new(ls->L, "__bnot"); break;
        case '#': metamethod_name = luaS_new(ls->L, "__len"); break;
        case TK_IDIV: {
          metamethod_name = luaS_new(ls->L, "__idiv"); break;
        }
        case '[': {
          /* operator func [](index: Int64) for __index/__newindex */
          luaX_next(ls);  /* skip '[' */
          checknext(ls, ']');
          /* Check if it's assignment (has '=') - simplified, treat as __index */
          metamethod_name = luaS_new(ls->L, "__index");
          goto parse_operator_body;
        }
        default: {
          /* Try to handle func name like "toString" */
          if (ls->t.token == TK_NAME) {
            const char *opname = getstr(ls->t.seminfo.ts);
            if (strcmp(opname, "toString") == 0) {
              metamethod_name = luaS_new(ls->L, "__tostring");
            }
            else {
              char mm[64];
              snprintf(mm, sizeof(mm), "__%s", opname);
              metamethod_name = luaS_new(ls->L, mm);
            }
          }
          else {
            luaX_syntaxerror(ls, "unsupported operator for overloading");
            metamethod_name = NULL;  /* unreachable */
          }
          break;
        }
      }
      luaX_next(ls);  /* skip operator token */
parse_operator_body:
      skip_generic_params(ls);
      /* Build NAME.metamethod_name */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, metamethod_name);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse operator method body (with 'self' parameter) */
      ls->in_struct_method = 1;
      body(ls, &mb, 1, ls->linenumber);
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "init")) {
      /* Constructor: init(...) { ... } -- no 'func' keyword needed */
      has_init = 1;
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'init' */
      mname = luaS_new(ls->L, "init");
      /* Build NAME.init */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse constructor body (auto-returns self, with implicit this) */
      ls->in_struct_method = 1;
      body_init(ls, &mb, ls->linenumber);
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_LET || ls->t.token == TK_VAR) {
      /* Field declaration - record field name for implicit this */
      TString *fname;
      int is_var = (ls->t.token == TK_VAR);
      luaX_next(ls);  /* skip let/var */
      fname = str_checkname(ls);  /* field name */
      /* Track field name for implicit 'this' */
      if (ls->nfields < 64) {
        ls->struct_fields[ls->nfields++] = fname;
      }
      /* Track var fields for auto-constructor */
      if (is_var && nvarfields < MAX_VAR_FIELDS) {
        var_fields[nvarfields++] = fname;
      }
      skip_type_annotation(ls);
      /* optional default value - compile as ClassName.field = value */
      if (testnext(ls, '=')) {
        expdesc field_target, field_val;
        buildvar(ls, sname, &field_target);
        {
          expdesc fkey;
          luaK_exp2anyregup(fs, &field_target);
          codestring(&fkey, fname);
          luaK_indexed(fs, &field_target, &fkey);
        }
        expr(ls, &field_val);
        luaK_storevar(fs, &field_target, &field_val);
      }
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == sname &&
             luaX_lookahead(ls) == '(') {
      /* Primary constructor: ClassName(let field: Type, var field: Type) { ... }
      ** Equivalent to declaring fields + init constructor. */
      has_init = 1;
      {
        /* Parse primary constructor parameters to extract field declarations */
        TString *pcon_fields[MAX_VAR_FIELDS];
        int pcon_is_let[MAX_VAR_FIELDS];
        TString *pcon_params[MAX_VAR_FIELDS];
        int npcon = 0;
        int pi;
        luaX_next(ls);  /* skip class name */
        checknext(ls, '(');
        /* Parse parameter list: (let/var name: Type, ...) */
        while (ls->t.token != ')' && ls->t.token != TK_EOS) {
          int is_field = 0;
          int is_let_field = 0;
          if (ls->t.token == TK_LET || ls->t.token == TK_VAR) {
            is_field = 1;
            is_let_field = (ls->t.token == TK_LET);
            luaX_next(ls);  /* skip let/var */
          }
          if (npcon < MAX_VAR_FIELDS) {
            TString *pname = str_checkname(ls);
            pcon_params[npcon] = pname;
            if (is_field) {
              pcon_fields[npcon] = pname;
              pcon_is_let[npcon] = is_let_field;
              /* Register as struct field for implicit this */
              if (ls->nfields < 64) {
                ls->struct_fields[ls->nfields++] = pname;
              }
              /* Track var fields for auto-constructor */
              if (!is_let_field && nvarfields < MAX_VAR_FIELDS) {
                var_fields[nvarfields++] = pname;
              }
            }
            else {
              pcon_fields[npcon] = NULL;
              pcon_is_let[npcon] = 0;
            }
            npcon++;
          }
          skip_type_annotation(ls);
          if (!testnext(ls, ',')) break;
        }
        checknext(ls, ')');
        /* Now generate the init function with auto-assignments */
        {
          expdesc mv, mb;
          TString *mname = luaS_new(ls->L, "init");
          FuncState new_fs;
          BlockCnt bl;
          /* Build NAME.init */
          buildvar(ls, sname, &mv);
          {
            expdesc mkey;
            luaK_exp2anyregup(fs, &mv);
            codestring(&mkey, mname);
            luaK_indexed(fs, &mv, &mkey);
          }
          /* Create constructor function */
          new_fs.f = addprototype(ls);
          new_fs.f->linedefined = ls->linenumber;
          open_func(ls, &new_fs, &bl);
          /* 'self' parameter */
          new_localvarliteral(ls, "self");
          adjustlocalvars(ls, 1);
          /* Declare parameters */
          for (pi = 0; pi < npcon; pi++) {
            new_localvar(ls, pcon_params[pi]);
          }
          new_fs.f->numparams = cast_byte(npcon + 1);
          adjustlocalvars(ls, npcon);
          luaK_reserveregs(&new_fs, new_fs.f->numparams);
          /* Generate self.field = param for each let/var parameter */
          ls->in_struct_method = 1;
          for (pi = 0; pi < npcon; pi++) {
            if (pcon_fields[pi] != NULL) {
              expdesc self_e, field_key, param_e;
              TString *selfname = luaS_new(ls->L, "self");
              singlevaraux(ls->fs, selfname, &self_e, 1);
              luaK_exp2anyregup(ls->fs, &self_e);
              codestring(&field_key, pcon_fields[pi]);
              luaK_indexed(ls->fs, &self_e, &field_key);
              singlevaraux(ls->fs, pcon_params[pi], &param_e, 1);
              luaK_storevar(ls->fs, &self_e, &param_e);
            }
          }
          /* Parse optional body */
          checknext(ls, '{' /*}*/);
          statlist(ls);
          /* Auto-generate: return self */
          {
            expdesc selfvar;
            TString *selfname2 = luaS_new(ls->L, "self");
            singlevaraux(ls->fs, selfname2, &selfvar, 1);
            luaK_ret(ls->fs, luaK_exp2anyreg(ls->fs, &selfvar), 1);
          }
          new_fs.f->lastlinedefined = ls->linenumber;
          check_match(ls, /*{*/ '}', TK_FUNC, line);
          codeclosure(ls, &mb);
          close_func(ls);
          ls->in_struct_method = 0;
          luaK_storevar(fs, &mv, &mb);
          luaK_fixline(fs, line);
        }
      }
    }
    else {
      luaX_syntaxerror(ls, "expected 'func', 'init', 'let', 'var', 'static', or 'operator' in struct/class body");
    }
    testnext(ls, ';');  /* optional semicolons */
  }

  check_match(ls, /*{*/ '}', TK_STRUCT, line);

  /* If no init was defined, store field metadata for auto-constructor */
  if (!has_init && nvarfields > 0) {
    int fi;
    for (fi = 0; fi < nvarfields; fi++) {
      expdesc tab2, key2, val2;
      char fieldkey[32];
      snprintf(fieldkey, sizeof(fieldkey), "__field_%d", fi + 1);
      buildvar(ls, sname, &tab2);
      luaK_exp2anyregup(fs, &tab2);
      codestring(&key2, luaX_newstring(ls, fieldkey, strlen(fieldkey)));
      luaK_indexed(fs, &tab2, &key2);
      codestring(&val2, var_fields[fi]);
      luaK_storevar(fs, &tab2, &val2);
    }
    /* Store __nfields count */
    {
      expdesc tab2, key2, val2;
      buildvar(ls, sname, &tab2);
      luaK_exp2anyregup(fs, &tab2);
      codestring(&key2, luaX_newstring(ls, "__nfields", 9));
      luaK_indexed(fs, &tab2, &key2);
      init_exp(&val2, VKINT, 0);
      val2.u.ival = nvarfields;
      luaK_storevar(fs, &tab2, &val2);
    }
  }

  /* Generate: __cangjie_setup_class(NAME) to enable Point(x,y) constructor */
  {
    expdesc fn, arg;
    int base2;
    buildvar(ls, luaX_newstring(ls, "__cangjie_setup_class", 21), &fn);
    luaK_exp2nextreg(fs, &fn);
    base2 = fn.u.info;
    buildvar(ls, sname, &arg);
    luaK_exp2nextreg(fs, &arg);
    init_exp(&fn, VCALL,
             luaK_codeABC(fs, OP_CALL, base2, 2, 1));
    fs->freereg = cast_byte(base2);
  }

  /* If there's a parent class, generate: __cangjie_set_parent(NAME, PARENT) */
  if (parent_name != NULL) {
    expdesc fn, arg1, arg2;
    int base2;
    buildvar(ls, luaX_newstring(ls, "__cangjie_set_parent", 20), &fn);
    luaK_exp2nextreg(fs, &fn);
    base2 = fn.u.info;
    buildvar(ls, sname, &arg1);
    luaK_exp2nextreg(fs, &arg1);
    buildvar(ls, parent_name, &arg2);
    luaK_exp2nextreg(fs, &arg2);
    init_exp(&fn, VCALL,
             luaK_codeABC(fs, OP_CALL, base2, 3, 1));
    fs->freereg = cast_byte(base2);
  }

  /* Apply interface default implementations */
  {
    int ii;
    for (ii = 0; ii < nifaces; ii++) {
      expdesc fn, arg1, arg2;
      int base2;
      buildvar(ls, luaX_newstring(ls, "__cangjie_apply_interface", 25), &fn);
      luaK_exp2nextreg(fs, &fn);
      base2 = fn.u.info;
      buildvar(ls, sname, &arg1);
      luaK_exp2nextreg(fs, &arg1);
      buildvar(ls, iface_names[ii], &arg2);
      luaK_exp2nextreg(fs, &arg2);
      init_exp(&fn, VCALL,
               luaK_codeABC(fs, OP_CALL, base2, 3, 1));
      fs->freereg = cast_byte(base2);
    }
  }

  reg = fs->freereg;
  fs->freereg = cast_byte(reg);

  /* Save this class's fields to the registry for inheritance */
  if (ls->nclass_registry < MAX_CLASS_REGISTRY) {
    int ri = ls->nclass_registry;
    int fi;
    ls->class_registry[ri].name = sname;
    ls->class_registry[ri].nfields = (ls->nfields < MAX_CLASS_FIELDS) ?
                                       ls->nfields : MAX_CLASS_FIELDS;
    for (fi = 0; fi < ls->class_registry[ri].nfields; fi++) {
      ls->class_registry[ri].fields[fi] = ls->struct_fields[fi];
    }
    ls->nclass_registry++;
  }

  /* Restore previous struct field context */
  ls->nfields = saved_nfields;
  ls->in_struct_method = saved_in_struct;
  ls->current_class_name = saved_class_name;
}


static void interfacestat (LexState *ls, int line) {
  /*
  ** interface NAME ['<' typeparams '>'] '{' func_decls '}'
  ** Compiles to: NAME = {} (interface table)
  ** Default method implementations are compiled and stored in the table.
  */
  FuncState *fs = ls->fs;
  expdesc v, e;
  TString *iname;

  luaX_next(ls);  /* skip 'interface' */
  iname = str_checkname(ls);
  check_type_redefine(ls, iname);
  skip_generic_params(ls);

  /* Create the interface table: NAME = {} */
  buildvar(ls, iname, &v);
  {
    int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
    luaK_code(fs, 0);
    init_exp(&e, VNONRELOC, fs->freereg);
    luaK_reserveregs(fs, 1);
    luaK_settablesize(fs, pc, e.u.info, 0, 0);
  }
  luaK_storevar(fs, &v, &e);

  checknext(ls, '{' /*}*/);

  /* Parse interface members */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    if (ls->t.token == TK_FUNC) {
      TString *mname;
      luaX_next(ls);  /* skip 'func' */
      mname = str_checkname(ls);  /* method name */
      skip_generic_params(ls);
      /* Parse method - might be abstract (no body) or default (with body).
      ** body_or_abstract handles both: compiles body if '{' found,
      ** otherwise skips the abstract declaration. */
      {
        expdesc mv, mb;
        int has_body;
        buildvar(ls, iname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, mname);
          luaK_indexed(fs, &mv, &mkey);
        }
        ls->in_struct_method = 1;
        has_body = body_or_abstract(ls, &mb, 1, ls->linenumber);
        ls->in_struct_method = 0;
        if (has_body) {
          luaK_storevar(fs, &mv, &mb);
          luaK_fixline(fs, line);
        }
      }
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "operator")) {
      TString *metamethod_name;
      int op_token;
      luaX_next(ls);  /* skip 'operator' */
      checknext(ls, TK_FUNC);  /* expect 'func' */
      /* Read operator token and map to metamethod name */
      op_token = ls->t.token;
      if (op_token == '[') {
        luaX_next(ls);  /* skip '[' */
        checknext(ls, ']');
        metamethod_name = luaS_new(ls->L, "__index");
      }
      else {
        switch (op_token) {
          case '+': metamethod_name = luaS_new(ls->L, "__add"); break;
          case '-': metamethod_name = luaS_new(ls->L, "__sub"); break;
          case '*': metamethod_name = luaS_new(ls->L, "__mul"); break;
          case '/': metamethod_name = luaS_new(ls->L, "__div"); break;
          case '%': metamethod_name = luaS_new(ls->L, "__mod"); break;
          case TK_POW: metamethod_name = luaS_new(ls->L, "__pow"); break;
          case TK_EQ: metamethod_name = luaS_new(ls->L, "__eq"); break;
          case '<': metamethod_name = luaS_new(ls->L, "__lt"); break;
          case TK_LE: metamethod_name = luaS_new(ls->L, "__le"); break;
          case TK_SHL: metamethod_name = luaS_new(ls->L, "__shl"); break;
          case TK_SHR: metamethod_name = luaS_new(ls->L, "__shr"); break;
          case '&': metamethod_name = luaS_new(ls->L, "__band"); break;
          case '|': metamethod_name = luaS_new(ls->L, "__bor"); break;
          case '^': metamethod_name = luaS_new(ls->L, "__bxor"); break;
          case '~': metamethod_name = luaS_new(ls->L, "__bnot"); break;
          case '#': metamethod_name = luaS_new(ls->L, "__len"); break;
          case TK_IDIV: metamethod_name = luaS_new(ls->L, "__idiv"); break;
          default: {
            if (ls->t.token == TK_NAME) {
              const char *opname = getstr(ls->t.seminfo.ts);
              if (strcmp(opname, "toString") == 0) {
                metamethod_name = luaS_new(ls->L, "__tostring");
              } else {
                char mm[64];
                snprintf(mm, sizeof(mm), "__%s", opname);
                metamethod_name = luaS_new(ls->L, mm);
              }
            } else {
              luaX_syntaxerror(ls, "unsupported operator for overloading");
              metamethod_name = NULL;
            }
            break;
          }
        }
        luaX_next(ls);  /* skip operator token */
      }
      skip_generic_params(ls);
      /* Parse operator method - might be abstract or have default body.
      ** body_or_abstract handles (params): Type { body } or just
      ** (params): Type for abstract declarations. */
      {
        expdesc mv, mb;
        int has_body;
        buildvar(ls, iname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, metamethod_name);
          luaK_indexed(fs, &mv, &mkey);
        }
        ls->in_struct_method = 1;
        has_body = body_or_abstract(ls, &mb, 1, ls->linenumber);
        ls->in_struct_method = 0;
        if (has_body) {
          luaK_storevar(fs, &mv, &mb);
          luaK_fixline(fs, line);
        }
      }
    }
    else {
      luaX_syntaxerror(ls, "expected 'func' declaration in interface body");
    }
    testnext(ls, ';');
  }

  check_match(ls, /*{*/ '}', TK_INTERFACE, line);
}


static int is_builtin_type (LexState *ls, TString *name) {
  const char *s = getstr(name);
  UNUSED(ls);
  return (strcmp(s, "Int64") == 0 ||
          strcmp(s, "Float64") == 0 ||
          strcmp(s, "String") == 0 ||
          strcmp(s, "Bool") == 0);
}


static void extendstat (LexState *ls, int line) {
  /*
  ** extend NAME ['<' typeparams '>'] ['<:' INTERFACE ['&' INTERFACE]*] '{' methods '}'
  ** Adds methods to an existing type.
  ** For user-defined types (struct/class), methods are added directly to the type table.
  ** For built-in types (Int64, Float64, String, Bool), a proxy table is created
  ** and __cangjie_extend_type is called to set up type metatables.
  */
  FuncState *fs = ls->fs;
  TString *tname;
  int builtin;
#define MAX_EXT_IFACES 16
  TString *ext_iface_names[MAX_EXT_IFACES];
  int next_ifaces = 0;

  luaX_next(ls);  /* skip 'extend' */
  skip_generic_params(ls);  /* skip possible generic params before name */
  tname = str_checkname(ls);

  /* Distinguish between generic params '<T>' and interface impl '<:' */
  if (ls->t.token == '<') {
    /* Peek ahead to see if this is '<:' (interface impl) or '<...>' (generics) */
    int la = luaX_lookahead(ls);
    if (la == ':') {
      /* This is '<:' interface implementation */
      luaX_next(ls);  /* skip '<' (consumes lookahead ':') */
      luaX_next(ls);  /* skip ':' */
      while (ls->t.token == TK_NAME || ls->t.token == '&') {
        if (ls->t.token == TK_NAME && next_ifaces < MAX_EXT_IFACES) {
          ext_iface_names[next_ifaces++] = ls->t.seminfo.ts;
        }
        luaX_next(ls);
      }
    }
    else {
      /* This is generic params '<T, U, ...>' */
      /* lookahead was consumed by luaX_lookahead, need to handle it */
      skip_generic_params(ls);  /* skip generic params after name */
      /* After generics, check for '<:' again */
      if (ls->t.token == '<') {
        la = luaX_lookahead(ls);
        if (la == ':') {
          luaX_next(ls);  /* skip '<' */
          luaX_next(ls);  /* skip ':' */
          while (ls->t.token == TK_NAME || ls->t.token == '&') {
            if (ls->t.token == TK_NAME && next_ifaces < MAX_EXT_IFACES) {
              ext_iface_names[next_ifaces++] = ls->t.seminfo.ts;
            }
            luaX_next(ls);
          }
        }
      }
    }
  }
  /* also handle '<=' for backward compatibility */
  if (ls->t.token == TK_LE) {
    luaX_next(ls);
    while (ls->t.token == TK_NAME || ls->t.token == '&') {
      if (ls->t.token == TK_NAME && next_ifaces < MAX_EXT_IFACES) {
        ext_iface_names[next_ifaces++] = ls->t.seminfo.ts;
      }
      luaX_next(ls);
    }
  }

  builtin = is_builtin_type(ls, tname);

  if (builtin) {
    /* For built-in types: ensure type proxy table exists, add methods to it,
    ** then call __cangjie_extend_type to set up type metatables */

    /* First, create the type proxy table if it doesn't exist:
    ** TypeName = TypeName or {} (handled as: TypeName = {}) */
    {
      expdesc gv, ge;
      int pc;
      buildvar(ls, tname, &gv);
      pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
      luaK_code(fs, 0);
      init_exp(&ge, VNONRELOC, fs->freereg);
      luaK_reserveregs(fs, 1);
      luaK_settablesize(fs, pc, ge.u.info, 0, 0);
      luaK_storevar(fs, &gv, &ge);
    }

    /* Set TypeName.__index = TypeName */
    {
      expdesc tab, key, val;
      buildvar(ls, tname, &tab);
      luaK_exp2anyregup(fs, &tab);
      codestring(&key, luaX_newstring(ls, "__index", 7));
      luaK_indexed(fs, &tab, &key);
      buildvar(ls, tname, &val);
      luaK_storevar(fs, &tab, &val);
    }

    checknext(ls, '{' /*}*/);

    /* Parse extension methods - add them directly to type proxy table
    ** (same as user-defined type extend) */
    while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
      if (ls->t.token == TK_FUNC) {
        expdesc mv, mb;
        TString *mname;
        luaX_next(ls);  /* skip 'func' */
        mname = str_checkname(ls);
        skip_generic_params(ls);
        /* Build TypeName.methodname */
        buildvar(ls, tname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, mname);
          luaK_indexed(fs, &mv, &mkey);
        }
        body(ls, &mb, 1, ls->linenumber);
        luaK_storevar(fs, &mv, &mb);
        luaK_fixline(fs, line);
      }
      else if (ls->t.token == TK_NAME &&
               ls->t.seminfo.ts == luaS_new(ls->L, "operator")) {
        expdesc mv, mb;
        TString *metamethod_name;
        int op_token;
        luaX_next(ls);  /* skip 'operator' */
        checknext(ls, TK_FUNC);  /* expect 'func' */
        op_token = ls->t.token;
        switch (op_token) {
          case '+': metamethod_name = luaS_new(ls->L, "__add"); break;
          case '-': metamethod_name = luaS_new(ls->L, "__sub"); break;
          case '*': metamethod_name = luaS_new(ls->L, "__mul"); break;
          case '/': metamethod_name = luaS_new(ls->L, "__div"); break;
          case '%': metamethod_name = luaS_new(ls->L, "__mod"); break;
          case TK_POW: metamethod_name = luaS_new(ls->L, "__pow"); break;
          case TK_EQ: metamethod_name = luaS_new(ls->L, "__eq"); break;
          case '<': metamethod_name = luaS_new(ls->L, "__lt"); break;
          case TK_LE: metamethod_name = luaS_new(ls->L, "__le"); break;
          case TK_SHL: metamethod_name = luaS_new(ls->L, "__shl"); break;
          case TK_SHR: metamethod_name = luaS_new(ls->L, "__shr"); break;
          case '&': metamethod_name = luaS_new(ls->L, "__band"); break;
          case '|': metamethod_name = luaS_new(ls->L, "__bor"); break;
          case '^': metamethod_name = luaS_new(ls->L, "__bxor"); break;
          case '~': metamethod_name = luaS_new(ls->L, "__bnot"); break;
          case '#': metamethod_name = luaS_new(ls->L, "__len"); break;
          case TK_IDIV: metamethod_name = luaS_new(ls->L, "__idiv"); break;
          case '[': {
            luaX_next(ls);  /* skip '[' */
            checknext(ls, ']');
            metamethod_name = luaS_new(ls->L, "__index");
            goto parse_ext_b_opbody;
          }
          default: {
            if (ls->t.token == TK_NAME) {
              const char *opname = getstr(ls->t.seminfo.ts);
              if (strcmp(opname, "toString") == 0) {
                metamethod_name = luaS_new(ls->L, "__tostring");
              } else {
                char mm[64];
                snprintf(mm, sizeof(mm), "__%s", opname);
                metamethod_name = luaS_new(ls->L, mm);
              }
            } else {
              luaX_syntaxerror(ls, "unsupported operator for overloading");
              metamethod_name = NULL;
            }
            break;
          }
        }
        luaX_next(ls);  /* skip operator token */
parse_ext_b_opbody:
        skip_generic_params(ls);
        buildvar(ls, tname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, metamethod_name);
          luaK_indexed(fs, &mv, &mkey);
        }
        body(ls, &mb, 1, ls->linenumber);
        luaK_storevar(fs, &mv, &mb);
        luaK_fixline(fs, line);
      }
      else {
        luaX_next(ls);
      }
      testnext(ls, ';');
    }

    check_match(ls, /*{*/ '}', TK_EXTEND, line);

    /* Generate: __cangjie_extend_type("TypeName", TypeName_table) */
    {
      expdesc fn, arg1, arg2;
      int base2;
      buildvar(ls, luaX_newstring(ls, "__cangjie_extend_type", 21), &fn);
      luaK_exp2nextreg(fs, &fn);
      base2 = fn.u.info;
      /* push type name as string constant */
      codestring(&arg1, tname);
      luaK_exp2nextreg(fs, &arg1);
      /* push the type proxy table */
      buildvar(ls, tname, &arg2);
      luaK_exp2nextreg(fs, &arg2);
      init_exp(&fn, VCALL,
               luaK_codeABC(fs, OP_CALL, base2, 3, 1));
      fs->freereg = cast_byte(base2);
    }

    /* Apply interface defaults to the proxy table */
    {
      int ii;
      for (ii = 0; ii < next_ifaces; ii++) {
        expdesc fn, arg1, arg2;
        int base2;
        buildvar(ls, luaX_newstring(ls, "__cangjie_apply_interface", 25), &fn);
        luaK_exp2nextreg(fs, &fn);
        base2 = fn.u.info;
        buildvar(ls, tname, &arg1);
        luaK_exp2nextreg(fs, &arg1);
        buildvar(ls, ext_iface_names[ii], &arg2);
        luaK_exp2nextreg(fs, &arg2);
        init_exp(&fn, VCALL,
                 luaK_codeABC(fs, OP_CALL, base2, 3, 1));
        fs->freereg = cast_byte(base2);
      }
    }
  }
  else {
    /* For user-defined types: add methods directly to the type table */
    checknext(ls, '{' /*}*/);

    /* Parse extension methods */
    while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
      if (ls->t.token == TK_FUNC) {
        expdesc mv, mb;
        TString *mname;
        luaX_next(ls);  /* skip 'func' */
        mname = str_checkname(ls);
        skip_generic_params(ls);
        /* Build NAME.methodname */
        buildvar(ls, tname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, mname);
          luaK_indexed(fs, &mv, &mkey);
        }
        body(ls, &mb, 1, ls->linenumber);
        luaK_storevar(fs, &mv, &mb);
        luaK_fixline(fs, line);
      }
      else if (ls->t.token == TK_NAME &&
               ls->t.seminfo.ts == luaS_new(ls->L, "operator")) {
        expdesc mv, mb;
        TString *metamethod_name;
        int op_token;
        luaX_next(ls);  /* skip 'operator' */
        checknext(ls, TK_FUNC);  /* expect 'func' */
        op_token = ls->t.token;
        switch (op_token) {
          case '+': metamethod_name = luaS_new(ls->L, "__add"); break;
          case '-': metamethod_name = luaS_new(ls->L, "__sub"); break;
          case '*': metamethod_name = luaS_new(ls->L, "__mul"); break;
          case '/': metamethod_name = luaS_new(ls->L, "__div"); break;
          case '%': metamethod_name = luaS_new(ls->L, "__mod"); break;
          case TK_POW: metamethod_name = luaS_new(ls->L, "__pow"); break;
          case TK_EQ: metamethod_name = luaS_new(ls->L, "__eq"); break;
          case '<': metamethod_name = luaS_new(ls->L, "__lt"); break;
          case TK_LE: metamethod_name = luaS_new(ls->L, "__le"); break;
          case TK_SHL: metamethod_name = luaS_new(ls->L, "__shl"); break;
          case TK_SHR: metamethod_name = luaS_new(ls->L, "__shr"); break;
          case '&': metamethod_name = luaS_new(ls->L, "__band"); break;
          case '|': metamethod_name = luaS_new(ls->L, "__bor"); break;
          case '^': metamethod_name = luaS_new(ls->L, "__bxor"); break;
          case '~': metamethod_name = luaS_new(ls->L, "__bnot"); break;
          case '#': metamethod_name = luaS_new(ls->L, "__len"); break;
          case TK_IDIV: metamethod_name = luaS_new(ls->L, "__idiv"); break;
          case '[': {
            luaX_next(ls);  /* skip '[' */
            checknext(ls, ']');
            metamethod_name = luaS_new(ls->L, "__index");
            goto parse_ext_u_opbody;
          }
          default: {
            if (ls->t.token == TK_NAME) {
              const char *opname = getstr(ls->t.seminfo.ts);
              if (strcmp(opname, "toString") == 0) {
                metamethod_name = luaS_new(ls->L, "__tostring");
              } else {
                char mm[64];
                snprintf(mm, sizeof(mm), "__%s", opname);
                metamethod_name = luaS_new(ls->L, mm);
              }
            } else {
              luaX_syntaxerror(ls, "unsupported operator for overloading");
              metamethod_name = NULL;
            }
            break;
          }
        }
        luaX_next(ls);  /* skip operator token */
parse_ext_u_opbody:
        skip_generic_params(ls);
        buildvar(ls, tname, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, metamethod_name);
          luaK_indexed(fs, &mv, &mkey);
        }
        body(ls, &mb, 1, ls->linenumber);
        luaK_storevar(fs, &mv, &mb);
        luaK_fixline(fs, line);
      }
      else {
        luaX_next(ls);
      }
      testnext(ls, ';');
    }

    check_match(ls, /*{*/ '}', TK_EXTEND, line);

    /* Apply interface defaults to the user-defined type */
    {
      int ii;
      for (ii = 0; ii < next_ifaces; ii++) {
        expdesc fn, arg1, arg2;
        int base2;
        buildvar(ls, luaX_newstring(ls, "__cangjie_apply_interface", 25), &fn);
        luaK_exp2nextreg(fs, &fn);
        base2 = fn.u.info;
        buildvar(ls, tname, &arg1);
        luaK_exp2nextreg(fs, &arg1);
        buildvar(ls, ext_iface_names[ii], &arg2);
        luaK_exp2nextreg(fs, &arg2);
        init_exp(&fn, VCALL,
                 luaK_codeABC(fs, OP_CALL, base2, 3, 1));
        fs->freereg = cast_byte(base2);
      }
    }
  }
}


/*
** ============================================================
** Enum type definition
** Compiles Cangjie enum declarations. Each enum variant becomes
** either a static table (no-arg) or a factory function (with args).
** Supports: parameterized constructors, member functions,
** recursive enums, generic enums.
** ============================================================
*/
static void enumstat (LexState *ls, int line) {
  /*
  ** enum NAME '{' '|' CTOR ['(' types ')'] ... '}'
  ** Compiles to:
  **   NAME = {}
  **   NAME.CTOR = function(...) return { __tag="CTOR", __enum=NAME, [1]=a1, ... } end
  **   (for no-arg constructors: NAME.CTOR = { __tag="CTOR", __enum=NAME, __nargs=0 })
  */
  FuncState *fs = ls->fs;
  expdesc v, e;
  TString *ename;

  luaX_next(ls);  /* skip 'enum' */
  ename = str_checkname(ls);
  check_type_redefine(ls, ename);

  /* skip generic type parameters */
  skip_generic_params(ls);

  /* optional '<:' interface */
  if (ls->t.token == '<' && luaX_lookahead(ls) == ':') {
    luaX_next(ls);  /* skip '<' */
    luaX_next(ls);  /* skip ':' */
    while (ls->t.token == TK_NAME || ls->t.token == '&') luaX_next(ls);
  }

  /* Create the enum table: NAME = {} */
  buildvar(ls, ename, &v);
  {
    int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
    luaK_code(fs, 0);
    init_exp(&e, VNONRELOC, fs->freereg);
    luaK_reserveregs(fs, 1);
    luaK_settablesize(fs, pc, e.u.info, 0, 0);
  }
  luaK_storevar(fs, &v, &e);

  checknext(ls, '{' /*}*/);

  /* Parse enum constructors */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    if (testnext(ls, '|') ||
        (ls->t.token == TK_NAME &&
         ls->t.seminfo.ts != luaS_new(ls->L, "operator"))) {
      /* '|' CTOR_NAME ['(' type_list ')'] */
      TString *ctorname;
      int has_params = 0;
      int nparams = 0;

      ctorname = str_checkname(ls);

      /* Check for parameters */
      if (ls->t.token == '(') {
        luaX_next(ls);  /* skip '(' */
        has_params = 1;
        /* Count and skip parameter types */
        if (ls->t.token != ')') {
          nparams = 1;
          /* skip type name (may be nested like Array<Int64>) */
          {
            int depth = 0;
            while (ls->t.token != ')' || depth > 0) {
              if (ls->t.token == '(' || ls->t.token == '<') depth++;
              else if (ls->t.token == ')' || ls->t.token == '>') {
                if (depth > 0) depth--;
                else break;
              }
              else if (ls->t.token == ',' && depth == 0) nparams++;
              if (ls->t.token == TK_EOS) break;
              luaX_next(ls);
            }
          }
        }
        checknext(ls, ')');
      }

      if (has_params && nparams > 0) {
        /* Constructor with parameters: create a function using cangjie_enum_ctor
        ** Generate: NAME.CTOR = function(...)
        **   local __val = {}
        **   __val.__tag = "CTOR"
        **   __val.__enum = NAME
        **   __val.__nargs = nparams
        **   for i=1,select('#',...) do __val[i] = select(i,...) end
        **   return __val
        ** end
        ** We use a simpler approach: emit a closure with upvalues.
        ** Actually, we'll generate Lua code that does this:
        **   NAME.CTOR = function(a1, a2, ...)
        **     return { __tag="CTOR", __enum=NAME, a1, a2, ..., __nargs=N }
        **   end
        **
        ** For simplicity, we'll create a closure that captures NAME and CTOR string:
        */
        expdesc mv;
        /* Build NAME.CTOR = __cangjie_enum_ctor_wrapper(NAME, "CTOR", nparams) */
        /* We do it differently: create a small function inline */

        /* NAME.CTOR */
        buildvar(ls, ename, &mv);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv);
          codestring(&mkey, ctorname);
          luaK_indexed(fs, &mv, &mkey);
        }

        /* Create a function that takes nparams args and returns enum value table */
        {
          expdesc fb;
          FuncState new_fs;
          BlockCnt bl;
          int param_i;
          char pname[16];

          new_fs.f = addprototype(ls);
          new_fs.f->linedefined = line;
          open_func(ls, &new_fs, &bl);

          /* Create parameter variables a1, a2, ..., aN */
          for (param_i = 0; param_i < nparams; param_i++) {
            TString *pn;
            snprintf(pname, sizeof(pname), "__p%d", param_i);
            pn = luaX_newstring(ls, pname, (size_t)strlen(pname));
            new_localvar(ls, pn);
          }
          new_fs.f->numparams = cast_byte(nparams);
          adjustlocalvars(ls, nparams);
          luaK_reserveregs(&new_fs, cast_int(new_fs.f->numparams));

          /* Generate: local __val = {} */
          {
            TString *valname = luaX_newstring(ls, "__val", 5);
            expdesc val_exp;
            int pc2;
            new_localvar(ls, valname);
            pc2 = luaK_codevABCk(&new_fs, OP_NEWTABLE, 0, 0, 0, 0);
            luaK_code(&new_fs, 0);
            init_exp(&val_exp, VNONRELOC, new_fs.freereg);
            luaK_reserveregs(&new_fs, 1);
            luaK_settablesize(&new_fs, pc2, val_exp.u.info, 0, 0);
            adjustlocalvars(ls, 1);

            /* __val.__tag = "CTOR" */
            {
              expdesc tab2, key2, str_v;
              init_exp(&tab2, VLOCAL, new_fs.freereg - 1);
              luaK_exp2anyregup(&new_fs, &tab2);
              codestring(&key2, luaX_newstring(ls, "__tag", 5));
              luaK_indexed(&new_fs, &tab2, &key2);
              codestring(&str_v, ctorname);
              luaK_storevar(&new_fs, &tab2, &str_v);
            }

            /* __val.__enum = NAME (upvalue) */
            {
              expdesc tab2, key2, enum_v;
              init_exp(&tab2, VLOCAL, new_fs.freereg - 1);
              luaK_exp2anyregup(&new_fs, &tab2);
              codestring(&key2, luaX_newstring(ls, "__enum", 6));
              luaK_indexed(&new_fs, &tab2, &key2);
              singlevaraux(&new_fs, ename, &enum_v, 1);
              if (enum_v.k == VGLOBAL)
                buildglobal(ls, ename, &enum_v);
              luaK_storevar(&new_fs, &tab2, &enum_v);
            }

            /* __val.__nargs = nparams */
            {
              expdesc tab2, key2, nval;
              init_exp(&tab2, VLOCAL, new_fs.freereg - 1);
              luaK_exp2anyregup(&new_fs, &tab2);
              codestring(&key2, luaX_newstring(ls, "__nargs", 7));
              luaK_indexed(&new_fs, &tab2, &key2);
              init_exp(&nval, VKINT, 0);
              nval.u.ival = nparams;
              luaK_storevar(&new_fs, &tab2, &nval);
            }

            /* __val[i] = param_i for each parameter */
            for (param_i = 0; param_i < nparams; param_i++) {
              expdesc tab2, key2, pval;
              init_exp(&tab2, VLOCAL, new_fs.freereg - 1);
              luaK_exp2anyregup(&new_fs, &tab2);
              init_exp(&key2, VKINT, 0);
              key2.u.ival = param_i + 1;
              luaK_indexed(&new_fs, &tab2, &key2);
              init_exp(&pval, VLOCAL, param_i);
              luaK_storevar(&new_fs, &tab2, &pval);
            }

            /* return __val */
            {
              expdesc ret;
              init_exp(&ret, VLOCAL, new_fs.freereg - 1);
              luaK_ret(&new_fs, luaK_exp2anyreg(&new_fs, &ret), 1);
            }
          }

          new_fs.f->lastlinedefined = ls->linenumber;
          codeclosure(ls, &fb);
          close_func(ls);

          luaK_storevar(fs, &mv, &fb);
        }
      }
      else {
        /* No-parameter constructor: create a static enum value table */
        /* NAME.CTOR = { __tag = "CTOR", __enum = NAME, __nargs = 0 } */
        expdesc mv_v;

        /* Build NAME.CTOR */
        buildvar(ls, ename, &mv_v);
        {
          expdesc mkey;
          luaK_exp2anyregup(fs, &mv_v);
          codestring(&mkey, ctorname);
          luaK_indexed(fs, &mv_v, &mkey);
        }

        /* Create the value table */
        {
          expdesc tbl_exp;
          int pc2 = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
          luaK_code(fs, 0);
          init_exp(&tbl_exp, VNONRELOC, fs->freereg);
          luaK_reserveregs(fs, 1);
          luaK_settablesize(fs, pc2, tbl_exp.u.info, 0, 0);
          luaK_storevar(fs, &mv_v, &tbl_exp);
        }

        /* Set __tag = "CTOR" */
        {
          expdesc tab2, key2, str_v;
          buildvar(ls, ename, &tab2);
          {
            expdesc ck;
            luaK_exp2anyregup(fs, &tab2);
            codestring(&ck, ctorname);
            luaK_indexed(fs, &tab2, &ck);
          }
          luaK_exp2anyregup(fs, &tab2);
          codestring(&key2, luaX_newstring(ls, "__tag", 5));
          luaK_indexed(fs, &tab2, &key2);
          codestring(&str_v, ctorname);
          luaK_storevar(fs, &tab2, &str_v);
        }

        /* Set __enum = NAME */
        {
          expdesc tab2, key2, enum_v;
          buildvar(ls, ename, &tab2);
          {
            expdesc ck;
            luaK_exp2anyregup(fs, &tab2);
            codestring(&ck, ctorname);
            luaK_indexed(fs, &tab2, &ck);
          }
          luaK_exp2anyregup(fs, &tab2);
          codestring(&key2, luaX_newstring(ls, "__enum", 6));
          luaK_indexed(fs, &tab2, &key2);
          buildvar(ls, ename, &enum_v);
          luaK_storevar(fs, &tab2, &enum_v);
        }

        /* Set __nargs = 0 */
        {
          expdesc tab2, key2, nval;
          buildvar(ls, ename, &tab2);
          {
            expdesc ck;
            luaK_exp2anyregup(fs, &tab2);
            codestring(&ck, ctorname);
            luaK_indexed(fs, &tab2, &ck);
          }
          luaK_exp2anyregup(fs, &tab2);
          codestring(&key2, luaX_newstring(ls, "__nargs", 7));
          luaK_indexed(fs, &tab2, &key2);
          init_exp(&nval, VKINT, 0);
          nval.u.ival = 0;
          luaK_storevar(fs, &tab2, &nval);
        }

        /* Also set as a global so constructors can be used without enum prefix */
        {
          expdesc gv, ctv;
          buildvar(ls, ctorname, &gv);
          buildvar(ls, ename, &ctv);
          {
            expdesc ck;
            luaK_exp2anyregup(fs, &ctv);
            codestring(&ck, ctorname);
            luaK_indexed(fs, &ctv, &ck);
          }
          luaK_storevar(fs, &gv, &ctv);
        }
      }

      /* Also register as global for direct access: CTOR = NAME.CTOR */
      if (has_params && nparams > 0) {
        expdesc gv, ctv;
        buildvar(ls, ctorname, &gv);
        buildvar(ls, ename, &ctv);
        {
          expdesc ck;
          luaK_exp2anyregup(fs, &ctv);
          codestring(&ck, ctorname);
          luaK_indexed(fs, &ctv, &ck);
        }
        luaK_storevar(fs, &gv, &ctv);
      }
    }
    else if (ls->t.token == TK_FUNC) {
      /* Method definition inside enum: func name(...) { ... }
      ** Stored as NAME.methodname = function(self, ...) ... end
      ** Enum values will access via metatable __index = NAME
      */
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'func' */
      mname = str_checkname(ls);
      /* skip generic type params on method */
      skip_generic_params(ls);
      /* Build NAME.methodname */
      buildvar(ls, ename, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse method body (with 'self' parameter for implicit this) */
      ls->in_struct_method = 1;
      body(ls, &mb, 1, ls->linenumber);
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "operator")) {
      /* Operator overload inside enum: operator func +(other: Type): Type { ... } */
      expdesc mv, mb;
      TString *metamethod_name;
      int op_token;
      luaX_next(ls);  /* skip 'operator' */
      checknext(ls, TK_FUNC);  /* expect 'func' */
      op_token = ls->t.token;
      switch (op_token) {
        case '+': metamethod_name = luaS_new(ls->L, "__add"); break;
        case '-': metamethod_name = luaS_new(ls->L, "__sub"); break;
        case '*': metamethod_name = luaS_new(ls->L, "__mul"); break;
        case '/': metamethod_name = luaS_new(ls->L, "__div"); break;
        case '%': metamethod_name = luaS_new(ls->L, "__mod"); break;
        case TK_POW: metamethod_name = luaS_new(ls->L, "__pow"); break;
        case TK_EQ: metamethod_name = luaS_new(ls->L, "__eq"); break;
        case '<': metamethod_name = luaS_new(ls->L, "__lt"); break;
        case TK_LE: metamethod_name = luaS_new(ls->L, "__le"); break;
        case TK_SHL: metamethod_name = luaS_new(ls->L, "__shl"); break;
        case TK_SHR: metamethod_name = luaS_new(ls->L, "__shr"); break;
        case '&': metamethod_name = luaS_new(ls->L, "__band"); break;
        case '|': metamethod_name = luaS_new(ls->L, "__bor"); break;
        case '^': metamethod_name = luaS_new(ls->L, "__bxor"); break;
        case '~': metamethod_name = luaS_new(ls->L, "__bnot"); break;
        case '#': metamethod_name = luaS_new(ls->L, "__len"); break;
        case TK_IDIV: metamethod_name = luaS_new(ls->L, "__idiv"); break;
        case '[': {
          luaX_next(ls);  /* skip '[' */
          checknext(ls, ']');
          metamethod_name = luaS_new(ls->L, "__index");
          goto enum_parse_operator_body;
        }
        default: {
          if (ls->t.token == TK_NAME) {
            const char *opname = getstr(ls->t.seminfo.ts);
            if (strcmp(opname, "toString") == 0) {
              metamethod_name = luaS_new(ls->L, "__tostring");
            }
            else {
              char mm[64];
              if (strlen(opname) > 58)
                luaX_syntaxerror(ls, "operator name too long");
              snprintf(mm, sizeof(mm), "__%s", opname);
              metamethod_name = luaS_new(ls->L, mm);
            }
          }
          else {
            luaX_syntaxerror(ls, "unsupported operator for overloading");
            metamethod_name = NULL;  /* unreachable */
          }
          break;
        }
      }
      luaX_next(ls);  /* skip operator token */
enum_parse_operator_body:
      skip_generic_params(ls);
      /* Build NAME.metamethod_name */
      buildvar(ls, ename, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, metamethod_name);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse operator method body (with 'self' parameter) */
      ls->in_struct_method = 1;
      body(ls, &mb, 1, ls->linenumber);
      ls->in_struct_method = 0;
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else {
      luaX_syntaxerror(ls,
          "expected '|', constructor name, 'func', or 'operator' in enum body");
    }
    testnext(ls, ';');
  }

  check_match(ls, /*{*/ '}', TK_ENUM, line);

  /* Generate: __cangjie_setup_enum(NAME) to set up metatable for enum values */
  {
    expdesc fn, arg;
    int base2;
    buildvar(ls, luaX_newstring(ls, "__cangjie_setup_enum", 20), &fn);
    luaK_exp2nextreg(fs, &fn);
    base2 = fn.u.info;
    buildvar(ls, ename, &arg);
    luaK_exp2nextreg(fs, &arg);
    init_exp(&fn, VCALL,
             luaK_codeABC(fs, OP_CALL, base2, 2, 1));
    fs->freereg = cast_byte(base2);
  }
}
