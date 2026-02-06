global <const> *

print("cangjie sample: stack/queue values")

let stack_values: Table = {10, 20, 30}
let stack_top = stack_values[3]
assert(stack_top == 30)
let stack_middle = stack_values[2]
assert(stack_middle == 20)
let stack_bottom = stack_values[1]
assert(stack_bottom == 10)

let queue_values: Table = {"first", "second"}
let queue_first = queue_values[1]
assert(queue_first == "first")
let queue_second = queue_values[2]
assert(queue_second == "second")
