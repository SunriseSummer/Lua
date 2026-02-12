dofile("cangjie-tests/_testing.cj")

// Perf: HashSet

let set = HashSet()
let t0 = os.clock()
for (i in 0..5000) {
    set.add(i)
}
let add_time = os.clock() - t0
println("hashset add: ${add_time}")
expectEq(set.size, 5000, "hashset perf size")

let t1 = os.clock()
var sum = 0
for (i in 0..5000:4) {
    if (set.contains(i)) {
        sum = sum + i
    }
}
let access_time = os.clock() - t1
println("hashset access: ${access_time}")
expectTrue(sum > 0, "hashset perf sum")

let t2 = os.clock()
set.removeIf({ v => v % 3 == 0 })
let remove_time = os.clock() - t2
println("hashset removeIf: ${remove_time}")
expectTrue(set.size < 5000, "hashset perf removeIf")

let t3 = os.clock()
set.clear()
let clear_time = os.clock() - t3
println("hashset clear: ${clear_time}")
expectTrue(set.isEmpty(), "hashset perf clear")

if (!__test_failed) {
    println("PASS: hashset_perf")
}
