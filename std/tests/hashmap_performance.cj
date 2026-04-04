dofile("std/HashMap.cj")

let map = HashMap()
let start = os.time()
for (i in 0..5000) {
    map.add(i, i * 2)
}
var sum = 0
for (i in 0..5000) {
    sum = sum + (map.get(i) ?? 0)
}
map.removeIf({ k, _ => k % 2 == 0 })
for (i in 0..2500) {
    map.add(i, i * 3)
}
let iter = map.iterator()
var count = 0
while (let Some(_) <- iter()) {
    count = count + 1
}
let elapsed = os.time() - start
println("HashMap performance: ${elapsed}s, sum=${sum}, count=${count}")
println("PASS: std/tests/hashmap_performance")
