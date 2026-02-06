println("cangjie sample: stack/queue values")

let stack_values: Array<Int64> = [10, 20, 30]

func stack_top(values: Array<Int64>) {
  assert(values.size > 0)
  return values[values.size]
}

assert(stack_top(stack_values) == 30)

let queue_values: Array<String> = ["first", "second"]

func queue_front(values: Array<String>) {
  assert(values.size > 0)
  return values[1]
}

func queue_back(values: Array<String>) {
  assert(values.size > 0)
  return values[values.size]
}

assert(queue_front(queue_values) == "first")
assert(queue_back(queue_values) == "second")
