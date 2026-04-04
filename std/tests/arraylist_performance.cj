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
list.reverse()
list.removeIf({ v => v % 3 == 0 })
let cloned = list.clone()
let iter = cloned.iterator()
var count = 0
while (let Some(_) <- iter()) {
    count = count + 1
}
let elapsed = os.time() - start
println("ArrayList performance: ${elapsed}s, sum=${sum}, count=${count}")
println("PASS: std/tests/arraylist_performance")
