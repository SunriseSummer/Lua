dofile("cangjie-tests/_testing.cj")

// Test: Visibility modifiers (open, public, private)
// Validates that open/public/private modifiers are accepted in class/struct bodies.

// -- Section: public/private on methods --
class Account {
    var balance: Float64 = 0.0
    public func deposit(amount: Float64) {
        this.balance = this.balance + amount
    }
    public func getBalance(): Float64 {
        balance
    }
    private func internalLog(): String {
        "log"
    }
}

let acc = Account()
acc.deposit(100.0)
expectEq(acc.getBalance(), 100.0, "Account.deposit + getBalance")
acc.deposit(50.5)
expectEq(acc.getBalance(), 150.5, "Account.getBalance after second deposit")

// -- Section: public/private on fields --
class Person {
    public var name: String
    private var age: Int64 = 0
    init(name: String, age: Int64) {
        this.name = name
        this.age = age
    }
    public func info(): String {
        "${name}, ${age}"
    }
}

let p = Person("Alice", 30)
expectEq(p.info(), "Alice, 30", "Person.info with public/private fields")

// -- Section: open class can be inherited --
open class Shape {
    var kind: String = "shape"
    open public func describe(): String {
        "Shape: ${kind}"
    }
}

class Square <: Shape {
    var side: Float64 = 1.0
    init(side: Float64) {
        this.kind = "square"
        this.side = side
    }
    public func describe(): String {
        "Square: side=${side}"
    }
}

let sh = Shape()
expectEq(sh.describe(), "Shape: shape", "Shape.describe")

let sq = Square(5.0)
expectEq(sq.describe(), "Square: side=5.0", "Square.describe override")

// -- Section: open + public on method allows override --
open class Vehicle {
    var speed: Float64 = 0.0
    open public func maxSpeed(): Float64 {
        100.0
    }
    public func info(): String {
        "Vehicle, max=${maxSpeed()}"
    }
}

class SportsCar <: Vehicle {
    public func maxSpeed(): Float64 {
        300.0
    }
}

let v = Vehicle()
expectEq(v.maxSpeed(), 100.0, "Vehicle.maxSpeed")

let sc = SportsCar()
expectEq(sc.maxSpeed(), 300.0, "SportsCar.maxSpeed override")

if (!__test_failed) {
    println("PASS: 37_visibility_modifiers")
}
