global <const> *

print("cangjie sample: stack/queue")

let stack: Table = {10, 20, 30}
let stack_top = stack[3]
assert(stack_top == 30)
let stack_middle = stack[2]
assert(stack_middle == 20)
let stack_bottom = stack[1]
assert(stack_bottom == 10)

let queue: Table = {"first", "second"}
let queue_first = queue[1]
assert(queue_first == "first")
let queue_second = queue[2]
assert(queue_second == "second")
