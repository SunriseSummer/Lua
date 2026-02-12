dofile("std/HashSet.cj")

let set = HashSet()
let start = os.time()
for (i in 0..5000) {
    set.add(i)
}
var found = 0
for (i in 0..5000) {
    if (set.contains(i)) {
        found = found + 1
    }
}
let elapsed = os.time() - start
println("HashSet performance: ${elapsed}s, found=${found}")
println("PASS: std/tests/hashset_performance")
