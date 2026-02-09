dofile("cangjie-tests/_testing.cj")

// Usage: Comprehensive patterns combining enums, match, class hierarchy,
// Option, string interpolation, arrays, for-in, and lambdas

// --- Section: Enum for shapes with different constructors ---
enum Shape {
    | CircleShape(Float64)
    | RectShape(Float64, Float64)
    | TriShape(Float64, Float64)
}

// --- Section: Area calculation using match ---
func area(s): Float64 {
    return match (s) {
        case CircleShape(r) => 3.14159 * r * r
        case RectShape(w, h) => w * h
        case TriShape(b, h) => 0.5 * b * h
    }
}

expectTrue(area(CircleShape(1.0)) > 3.14 && area(CircleShape(1.0)) < 3.15, "circle area ~3.14")
expectEq(area(RectShape(3.0, 4.0)), 12.0, "rect area 3*4")
expectEq(area(TriShape(6.0, 4.0)), 12.0, "tri area 0.5*6*4")

// --- Section: Class hierarchy for rendering ---
open class Renderer {
    var name: String = "base"
    init(name: String) {
        this.name = name
    }
    open func render(s): String {
        return "${name}: unknown shape"
    }
}

class TextRenderer <: Renderer {
    init() {
        super("TextRenderer")
    }
    func render(s): String {
        let a = area(s)
        return match (s) {
            case CircleShape(r) => "[Text] Circle r=${r} area=${a}"
            case RectShape(w, h) => "[Text] Rect ${w}x${h} area=${a}"
            case TriShape(b, h) => "[Text] Tri base=${b} h=${h} area=${a}"
        }
    }
}

class JsonRenderer <: Renderer {
    init() {
        super("JsonRenderer")
    }
    func render(s): String {
        let a = area(s)
        return match (s) {
            case CircleShape(r) => "{type:circle,r:${r},area:${a}}"
            case RectShape(w, h) => "{type:rect,w:${w},h:${h},area:${a}}"
            case TriShape(b, h) => "{type:tri,b:${b},h:${h},area:${a}}"
        }
    }
}

let textR = TextRenderer()
let jsonR = JsonRenderer()

expectEq(textR.render(RectShape(3.0, 4.0)), "[Text] Rect 3.0x4.0 area=12.0", "text render rect")
expectTrue(string.find(jsonR.render(CircleShape(1.0)), "circle", 1, true) != nil, "json render circle")

// --- Section: Option for nullable results ---
func findShape(shapes, name: String): ?Shape {
    var i = 0
    while (i < shapes.size) {
        let entry = shapes[i]
        if (entry[0] == name) {
            return Some(entry[1])
        }
        i = i + 1
    }
    return None
}

let catalog = [
    ["circle", CircleShape(5.0)],
    ["rect", RectShape(2.0, 3.0)],
    ["tri", TriShape(4.0, 6.0)]
]

let found = findShape(catalog, "rect")
expectTrue(found.isSome(), "findShape rect found")
expectEq(area(found.getOrThrow()), 6.0, "findShape rect area")

let notFound = findShape(catalog, "hexagon")
expectTrue(notFound.isNone(), "findShape hexagon not found")
var fallbackArea = -1.0
if (let Some(s) <- notFound) {
    fallbackArea = area(s)
}
expectEq(fallbackArea, -1.0, "not found fallback area")

// --- Section: String interpolation for output ---
func shapeReport(s): String {
    let a = area(s)
    let kind = match (s) {
        case CircleShape(_) => "circle"
        case RectShape(_, _) => "rectangle"
        case TriShape(_, _) => "triangle"
    }
    return "Shape: ${kind}, Area: ${a}"
}

expectEq(shapeReport(RectShape(5.0, 2.0)), "Shape: rectangle, Area: 10.0", "shape report rect")

// --- Section: Array and for-in iteration ---
let shapes = [CircleShape(1.0), RectShape(2.0, 3.0), TriShape(4.0, 5.0)]
var totalArea = 0.0
for (s in shapes) {
    totalArea = totalArea + area(s)
}
// circle ~3.14 + rect 6.0 + tri 10.0 = ~19.14
expectTrue(totalArea > 19.1 && totalArea < 19.2, "total area sum ~19.14")

var count = 0
for (s in shapes) {
    count = count + 1
}
expectEq(count, 3, "shapes count via for-in")

// --- Section: Lambda for transformations ---
let transform = { s => area(s) * 2.0 }
expectEq(transform(RectShape(3.0, 4.0)), 24.0, "lambda transform rect double area")

var areaCount = 0
var areaSum = 0.0
for (s in shapes) {
    areaCount = areaCount + 1
    areaSum = areaSum + area(s)
}
expectEq(areaCount, 3, "areas count")
expectEq(area(shapes[1]), 6.0, "shapes[1] rect area")

// Lambda as callback
func applyToAll(arr, fn) {
    let results = []
    var idx = 0
    for (item in arr) {
        results[idx] = fn(item)
        idx = idx + 1
    }
    return results
}

let doubled = applyToAll([1, 2, 3], { x => x * 2 })
expectEq(doubled[0], 2, "applyToAll [0]")
expectEq(doubled[1], 4, "applyToAll [1]")
expectEq(doubled[2], 6, "applyToAll [2]")

if (__test_failed) {
    println("FAIL: comprehensive_patterns")
} else {
    println("PASS: comprehensive_patterns")
}
