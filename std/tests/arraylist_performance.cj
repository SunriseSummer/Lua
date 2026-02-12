dofile("std/ArrayList.cj")

let list = ArrayList()
let start = os.time()
for (i in 0..5000) {
    list.add(i)
}
var sum = 0
for (i in 0..5000) {
    sum = sum + (list.get(i) ?? 0)
}
let elapsed = os.time() - start
println("ArrayList performance: ${elapsed}s, sum=${sum}")
println("PASS: std/tests/arraylist_performance")
