dofile("cangjie-tests/_testing.cj")

// Usage: State machine pattern using enum, match, Option, and closures
// Simulates a simple order processing workflow

enum OrderState {
    | Created
    | Validated(String)     // validated with customer name
    | Processing(Int64)     // processing step number
    | Shipped(String)       // shipped with tracking id
    | Delivered
    | Cancelled(String)     // cancelled with reason
}

open class Order {
    var state: OrderState = Created
    var history: Array<String> = []
    var historySize: Int64 = 0

    func init() {
        this.state = Created
        this.history = []
        this.historySize = 0
    }

    func addHistory(msg: String) {
        this.history[this.historySize] = msg
        this.historySize = this.historySize + 1
    }

    func validate(customer: String): Bool {
        return match (this.state) {
            case Created =>
                this.state = Validated(customer)
                this.addHistory("Validated for ${customer}")
                true
            case _ => false
        }
    }

    func startProcessing(): Bool {
        return match (this.state) {
            case Validated(_) =>
                this.state = Processing(1)
                this.addHistory("Processing started")
                true
            case _ => false
        }
    }

    func advanceProcessing(): ?Int64 {
        return match (this.state) {
            case Processing(step) =>
                if (step >= 3) {
                    return None
                }
                this.state = Processing(step + 1)
                this.addHistory("Processing step ${step + 1}")
                Some(step + 1)
            case _ => None
        }
    }

    func ship(trackingId: String): Bool {
        return match (this.state) {
            case Processing(step) =>
                if (step < 3) { return false }
                this.state = Shipped(trackingId)
                this.addHistory("Shipped: ${trackingId}")
                true
            case _ => false
        }
    }

    func deliver(): Bool {
        return match (this.state) {
            case Shipped(_) =>
                this.state = Delivered
                this.addHistory("Delivered")
                true
            case _ => false
        }
    }

    func cancel(reason: String): Bool {
        return match (this.state) {
            case Delivered => false
            case Cancelled(_) => false
            case _ =>
                this.state = Cancelled(reason)
                this.addHistory("Cancelled: ${reason}")
                true
        }
    }

    func getStatus(): String {
        return match (this.state) {
            case Created => "created"
            case Validated(name) => "validated(${name})"
            case Processing(step) => "processing(step ${step})"
            case Shipped(tid) => "shipped(${tid})"
            case Delivered => "delivered"
            case Cancelled(reason) => "cancelled(${reason})"
            case _ => "unknown"
        }
    }
}

// --- Happy path ---
let order = Order()
expectEq(order.getStatus(), "created", "initial status")

expectTrue(order.validate("Alice"), "validate succeeds")
expectEq(order.getStatus(), "validated(Alice)", "after validate")

expectTrue(order.startProcessing(), "start processing")
expectEq(order.getStatus(), "processing(step 1)", "processing step 1")

let step2 = order.advanceProcessing()
expectTrue(step2.isSome(), "advance to step 2")
expectEq(step2.getOrThrow(), 2, "step 2 value")

let step3 = order.advanceProcessing()
expectTrue(step3.isSome(), "advance to step 3")

let step4 = order.advanceProcessing()
expectTrue(step4.isNone(), "step 4 is None (max reached)")

expectTrue(order.ship("TRK-001"), "ship succeeds")
expectEq(order.getStatus(), "shipped(TRK-001)", "after ship")

expectTrue(order.deliver(), "deliver succeeds")
expectEq(order.getStatus(), "delivered", "after deliver")

expectFalse(order.cancel("too late"), "cannot cancel delivered order")

// --- Cancellation path ---
let order2 = Order()
order2.validate("Bob")
order2.startProcessing()
expectTrue(order2.cancel("out of stock"), "cancel during processing")
expectEq(order2.getStatus(), "cancelled(out of stock)", "after cancel")
expectFalse(order2.cancel("again"), "cannot cancel twice")

// --- Invalid transitions ---
let order3 = Order()
expectFalse(order3.startProcessing(), "cannot process before validate")
expectFalse(order3.ship("X"), "cannot ship before process")
expectFalse(order3.deliver(), "cannot deliver before ship")

// --- History tracking ---
expectEq(order.historySize, 6, "happy path history count")

if (!__test_failed) {
    println("PASS: state_machine_pattern")
}
