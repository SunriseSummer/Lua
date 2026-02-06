global <const> *

print("testing cangjie compatibility")

let name: String = "Cangjie"
let value: Float64 = 1.5f
let flag = false

println("Hello $(name)")
assert("Hello Cangjie" == "Hello $(name)")
assert("value 2.5" == "value $(value + 1.0)")
assert("mix Cangjie 1.5 false" == "mix $(name) $(value) $(flag)")
assert(type(println) == "function")

dofile("cangjie_samples/stack_queue.cj")
dofile("cangjie_samples/algorithms.cj")
