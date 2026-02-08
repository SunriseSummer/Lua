dofile("cangjie-tests/_testing.cj")

// Test: Deep inheritance chains (4 levels), method override, super calls, field inheritance

// -- Level 1: Base class --
open class Being {
    var kind: String = "being"
    var id: Int64 = 0
    init(id: Int64) {
        this.id = id
    }
    open public func describe(): String {
        return "Being#${id}"
    }
    open public func greet(): String {
        return "I am a ${kind}"
    }
}

// -- Level 2: Creature --
open class Creature <: Being {
    var legs: Int64 = 0
    init(id: Int64, legs: Int64) {
        super(id)
        this.kind = "creature"
        this.legs = legs
    }
    public func describe(): String {
        return "Creature#${id} with ${legs} legs"
    }
}

// -- Level 3: Pet --
open class Pet <: Creature {
    var name: String = ""
    init(id: Int64, legs: Int64, name: String) {
        super(id, legs)
        this.kind = "pet"
        this.name = name
    }
    public func describe(): String {
        return "Pet ${name}#${id}"
    }
    public func greet(): String {
        return "Hi, I'm ${name} the ${kind}"
    }
}

// -- Level 4: SpecialPet --
class SpecialPet <: Pet {
    var talent: String = "none"
    init(id: Int64, name: String, talent: String) {
        super(id, 4, name)
        this.kind = "special pet"
        this.talent = talent
    }
    public func describe(): String {
        return "${name} can ${talent}"
    }
}

// -- Test instantiation at each level --
let b = Being(1)
expectEq(b.describe(), "Being#1", "Being describe")
expectEq(b.greet(), "I am a being", "Being greet")
expectEq(b.id, 1, "Being id field")

let c = Creature(2, 6)
expectEq(c.describe(), "Creature#2 with 6 legs", "Creature describe")
expectEq(c.greet(), "I am a creature", "Creature inherits greet with updated kind")
expectEq(c.legs, 6, "Creature legs field")
expectEq(c.id, 2, "Creature inherits id")

let p = Pet(3, 4, "Buddy")
expectEq(p.describe(), "Pet Buddy#3", "Pet describe")
expectEq(p.greet(), "Hi, I'm Buddy the pet", "Pet overrides greet")
expectEq(p.name, "Buddy", "Pet name field")
expectEq(p.legs, 4, "Pet inherits legs")
expectEq(p.id, 3, "Pet inherits id from Being")

let sp = SpecialPet(4, "Rex", "backflip")
expectEq(sp.describe(), "Rex can backflip", "SpecialPet describe")
expectEq(sp.talent, "backflip", "SpecialPet talent field")
expectEq(sp.name, "Rex", "SpecialPet inherits name")
expectEq(sp.legs, 4, "SpecialPet inherits legs")
expectEq(sp.id, 4, "SpecialPet inherits id from Being")

// -- Polymorphic dispatch --
func getDesc(obj) {
    return obj.describe()
}
expectEq(getDesc(b), "Being#1", "polymorphic Being")
expectEq(getDesc(c), "Creature#2 with 6 legs", "polymorphic Creature")
expectEq(getDesc(sp), "Rex can backflip", "polymorphic SpecialPet")

if (!__test_failed) {
    println("PASS: 68_deep_inheritance")
}
