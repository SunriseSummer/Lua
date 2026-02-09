dofile("cangjie-tests/_testing.cj")

// Test: Multi-interface implementation with inheritance and method resolution

// --- Section: Multiple interfaces ---
interface Printable {
    func display(): String
}

interface Measurable {
    func size(): Int64
}

// --- Section: Base class ---
open class Container {
    var name: String = ""
    func init(n: String) {
        this.name = n
    }
    func getName(): String {
        return this.name
    }
}

// --- Section: Child implementing interfaces ---
open class Box <: Container & Printable & Measurable {
    var width: Int64 = 0
    var height: Int64 = 0

    func init(n: String, w: Int64, h: Int64) {
        super(n)
        this.width = w
        this.height = h
    }

    func display(): String {
        return "Box(${this.name}, ${this.width}x${this.height})"
    }

    func size(): Int64 {
        return this.width * this.height
    }
}

let b = Box("test", 3, 4)
expectEq(b.display(), "Box(test, 3x4)", "multi-interface display")
expectEq(b.size(), 12, "multi-interface size")
expectEq(b.getName(), "test", "inherited getName")

// --- Section: Grandchild with additional override ---
class ColorBox <: Box {
    var color: String = ""

    func init(n: String, w: Int64, h: Int64, c: String) {
        super(n, w, h)
        this.color = c
    }

    func display(): String {
        return "ColorBox(${this.name}, ${this.width}x${this.height}, ${this.color})"
    }
}

let cb = ColorBox("fancy", 5, 6, "red")
expectEq(cb.display(), "ColorBox(fancy, 5x6, red)", "grandchild override display")
expectEq(cb.size(), 30, "grandchild inherited size")
expectEq(cb.getName(), "fancy", "grandchild inherited getName")

// --- Section: Interface with default implementation ---
interface Describable {
    func describe(): String {
        return "an object"
    }
}

open class Widget <: Describable {
    var id: Int64 = 0
    func init(i: Int64) { this.id = i }
}

class SpecialWidget <: Widget & Describable {
    func init(i: Int64) { super(i) }
    func describe(): String {
        return "special widget #${this.id}"
    }
}

let w = Widget(1)
expectEq(w.describe(), "an object", "interface default implementation")

let sw = SpecialWidget(42)
expectEq(sw.describe(), "special widget #42", "override interface default")

// --- Section: Static methods in inheritance ---
open class MathBase {
    static func zero(): Int64 {
        return 0
    }
}

class MathChild <: MathBase {
    static func one(): Int64 {
        return 1
    }
}

expectEq(MathBase.zero(), 0, "static method on base")
expectEq(MathChild.one(), 1, "static method on child")

// --- Section: Instance check across inheritance ---
let boxInst = Box("b", 1, 1)
let colorInst = ColorBox("c", 2, 2, "blue")

expectTrue(__cangjie_is_instance(boxInst, Box), "box is Box")
expectTrue(__cangjie_is_instance(boxInst, Container), "box is Container")
expectTrue(__cangjie_is_instance(colorInst, ColorBox), "colorbox is ColorBox")
expectTrue(__cangjie_is_instance(colorInst, Box), "colorbox is Box")
expectTrue(__cangjie_is_instance(colorInst, Container), "colorbox is Container")
expectFalse(__cangjie_is_instance(boxInst, ColorBox), "box is not ColorBox")

if (!__test_failed) {
    println("PASS: 89_multi_interface_inheritance")
}
