global <const> *

print("cangjie sample: stack/queue")

let stack: Table = {}
let top = 0

let push = function(value)
  let idx = top + 1
  stack[idx] = value
  top = idx
end

let pop = function()
  let value = stack[top]
  stack[top] = nil
  top = top - 1
  return value
end

push(10)
push(20)
push(30)
assert(pop() == 30)
assert(pop() == 20)
assert(pop() == 10)

let queue: Table = {}
let head = 1
let tail = 0

let enqueue = function(value)
  tail = tail + 1
  queue[tail] = value
end

let dequeue = function()
  let value = queue[head]
  queue[head] = nil
  head = head + 1
  return value
end

enqueue("first")
enqueue("second")
assert(dequeue() == "first")
assert(dequeue() == "second")
