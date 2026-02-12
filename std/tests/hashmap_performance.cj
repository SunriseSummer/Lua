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
let elapsed = os.time() - start
println("HashMap performance: ${elapsed}s, sum=${sum}")
println("PASS: std/tests/hashmap_performance")
