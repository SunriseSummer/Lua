dofile("cangjie-tests/_testing.cj")

// Comprehensive usage: Mini task manager combining enum, class, match, option, and closures

// --- Task status enum ---
enum Status {
    | Todo
    | InProgress
    | Done
}

extend Status {
    func toString(): String {
        return match(this) {
            case Todo => "Todo"
            case InProgress => "InProgress"
            case Done => "Done"
        }
    }
    func isDone(): Bool {
        return match(this) {
            case Done => true
            case _ => false
        }
    }
}

// --- Task class ---
class Task {
    var name: String
    var status: Status
    var priority: Int64

    init(name: String, priority: Int64) {
        this.name = name
        this.status = Todo
        this.priority = priority
    }

    func start() {
        this.status = InProgress
    }

    func complete() {
        this.status = Done
    }

    func describe(): String {
        return "[${status.toString()}] ${name} (P${priority})"
    }
}

// --- Task list with higher-order functions ---
var tasks: Array<Task> = []
tasks[0] = Task("Design", 1)
tasks[1] = Task("Implement", 2)
tasks[2] = Task("Test", 3)

expectEq(tasks[0].describe(), "[Todo] Design (P1)", "task 0 describe")
expectEq(tasks[1].describe(), "[Todo] Implement (P2)", "task 1 describe")

// Start first task
tasks[0].start()
expectEq(tasks[0].describe(), "[InProgress] Design (P1)", "task 0 after start")

// Complete first, start second
tasks[0].complete()
tasks[1].start()
expectTrue(tasks[0].status.isDone(), "task 0 is done")
expectFalse(tasks[1].status.isDone(), "task 1 not done")

// --- Count done tasks using loop ---
var doneCount = 0
for (i in 0..3) {
    if (tasks[i].status.isDone()) {
        doneCount = doneCount + 1
    }
}
expectEq(doneCount, 1, "done count is 1")

// --- Find task by name using option ---
func findTask(name: String): ?Task {
    for (i in 0..3) {
        if (tasks[i].name == name) {
            return Some(tasks[i])
        }
    }
    return None
}

let found = findTask("Design")
expectTrue(found.isSome(), "found Design task")

let notFound = findTask("Deploy")
expectTrue(notFound.isNone(), "Deploy not found")

// --- Priority-based filtering with lambda ---
let isHighPriority = { task: Task =>
    return task.priority <= 2
}
expectTrue(isHighPriority(tasks[0]), "Design is high priority")
expectTrue(isHighPriority(tasks[1]), "Implement is high priority")
expectFalse(isHighPriority(tasks[2]), "Test is not high priority")

// --- String interpolation with complex expressions ---
let summary = "Tasks: ${doneCount}/3 done"
expectEq(summary, "Tasks: 1/3 done", "summary string interpolation")

// --- Complete all and verify ---
tasks[1].complete()
tasks[2].complete()
var allDone = true
for (i in 0..3) {
    if (!tasks[i].status.isDone()) {
        allDone = false
    }
}
expectTrue(allDone, "all tasks done")

if (!__test_failed) {
    println("PASS: task_manager_usage")
}
