dofile("cangjie-tests/_testing.cj")

// Test: Multi-level inheritance (4 levels), method override at each level,
// super calls, field inheritance, interface implementation, polymorphic dispatch

// --- Section: Interface ---
interface Identifiable {
    func identify(): String
}

// --- Section: Level 1 — Base ---
open class Base {
    var tag: String = "base"
    var level: Int64 = 1
    init(tag: String) {
        this.tag = tag
    }
    open public func whoAmI(): String {
        return "Base(${tag})"
    }
    open public func depth(): Int64 {
        return 1
    }
}

// --- Section: Level 2 ---
open class Level1 <: Base {
    var extra1: String = ""
    init(tag: String, extra1: String) {
        super(tag)
        this.level = 2
        this.extra1 = extra1
    }
    public func whoAmI(): String {
        return "Level1(${tag}, ${extra1})"
    }
    public func depth(): Int64 {
        return 2
    }
}

// --- Section: Level 3 ---
open class Level2 <: Level1 {
    var extra2: Int64 = 0
    init(tag: String, extra1: String, extra2: Int64) {
        super(tag, extra1)
        this.level = 3
        this.extra2 = extra2
    }
    public func whoAmI(): String {
        return "Level2(${tag}, ${extra1}, ${extra2})"
    }
    public func depth(): Int64 {
        return 3
    }
}

// --- Section: Level 4, also implements interface ---
class Level3 <: Level2 & Identifiable {
    var extra3: Bool = false
    init(tag: String, extra1: String, extra2: Int64, extra3: Bool) {
        super(tag, extra1, extra2)
        this.level = 4
        this.extra3 = extra3
    }
    public func whoAmI(): String {
        return "Level3(${tag})"
    }
    public func depth(): Int64 {
        return 4
    }
    func identify(): String {
        return "id:${tag}-L4"
    }
}

// --- Section: Instantiation and method dispatch ---
let b = Base("root")
expectEq(b.whoAmI(), "Base(root)", "Base whoAmI")
expectEq(b.depth(), 1, "Base depth")
expectEq(b.tag, "root", "Base tag")
expectEq(b.level, 1, "Base level")

let l1 = Level1("node", "alpha")
expectEq(l1.whoAmI(), "Level1(node, alpha)", "Level1 whoAmI")
expectEq(l1.depth(), 2, "Level1 depth")
expectEq(l1.tag, "node", "Level1 inherits tag")
expectEq(l1.extra1, "alpha", "Level1 extra1")
expectEq(l1.level, 2, "Level1 level")

let l2 = Level2("mid", "beta", 99)
expectEq(l2.whoAmI(), "Level2(mid, beta, 99)", "Level2 whoAmI")
expectEq(l2.depth(), 3, "Level2 depth")
expectEq(l2.tag, "mid", "Level2 inherits tag")
expectEq(l2.extra1, "beta", "Level2 inherits extra1")
expectEq(l2.extra2, 99, "Level2 extra2")
expectEq(l2.level, 3, "Level2 level")

let l3 = Level3("leaf", "gamma", 42, true)
expectEq(l3.whoAmI(), "Level3(leaf)", "Level3 whoAmI")
expectEq(l3.depth(), 4, "Level3 depth")
expectEq(l3.tag, "leaf", "Level3 inherits tag from Base")
expectEq(l3.extra1, "gamma", "Level3 inherits extra1 from Level1")
expectEq(l3.extra2, 42, "Level3 inherits extra2 from Level2")
expectEq(l3.extra3, true, "Level3 extra3")
expectEq(l3.level, 4, "Level3 level")
expectEq(l3.identify(), "id:leaf-L4", "Level3 identify interface")

// --- Section: Polymorphic dispatch ---
func getWho(obj): String {
    return obj.whoAmI()
}
func getDepth(obj): Int64 {
    return obj.depth()
}

expectEq(getWho(b), "Base(root)", "polymorphic Base")
expectEq(getWho(l1), "Level1(node, alpha)", "polymorphic Level1")
expectEq(getWho(l2), "Level2(mid, beta, 99)", "polymorphic Level2")
expectEq(getWho(l3), "Level3(leaf)", "polymorphic Level3")

expectEq(getDepth(b), 1, "polymorphic depth Base")
expectEq(getDepth(l1), 2, "polymorphic depth Level1")
expectEq(getDepth(l2), 3, "polymorphic depth Level2")
expectEq(getDepth(l3), 4, "polymorphic depth Level3")

// --- Section: Type pattern matching across hierarchy ---
func classifyByType(obj): String {
    match (obj) {
        case x: Level3 => return "Level3"
        case x: Level2 => return "Level2"
        case x: Level1 => return "Level1"
        case x: Base => return "Base"
        case _ => return "unknown"
    }
    return "unknown"
}

expectEq(classifyByType(l3), "Level3", "type match Level3")
expectEq(classifyByType(l2), "Level2", "type match Level2")
expectEq(classifyByType(l1), "Level1", "type match Level1")
expectEq(classifyByType(b), "Base", "type match Base")
expectEq(classifyByType(42), "unknown", "type match non-class")

if (__test_failed) {
    println("FAIL: 85_deep_inheritance")
} else {
    println("PASS: 85_deep_inheritance")
}
