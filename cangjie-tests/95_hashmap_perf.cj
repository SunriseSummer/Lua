dofile("cangjie-tests/_testing.cj")

// Perf: HashMap

let map = HashMap()
let t0 = os.clock()
for (i in 0..5000) {
    map.add(i, i * 2)
}
let add_time = os.clock() - t0
println("hashmap add: ${add_time}")
expectEq(map.size, 5000, "hashmap perf size")

let t1 = os.clock()
var sum = 0
for (i in 0..5000:5) {
    sum = sum + map.get(i).getOrDefault({=> 0})
}
let access_time = os.clock() - t1
println("hashmap access: ${access_time}")
expectTrue(sum > 0, "hashmap perf sum")

let t2 = os.clock()
map.removeIf({ k, v => k % 3 == 0 })
let remove_time = os.clock() - t2
println("hashmap removeIf: ${remove_time}")
expectTrue(map.size < 5000, "hashmap perf removeIf")

let t3 = os.clock()
map.clear()
let clear_time = os.clock() - t3
println("hashmap clear: ${clear_time}")
expectTrue(map.isEmpty(), "hashmap perf clear")

if (!__test_failed) {
    println("PASS: hashmap_perf")
}
