dofile("cangjie-tests/_testing.cj")

// Perf: ArrayList

let list = ArrayList()
let t0 = os.clock()
for (i in 0..5000) {
    list.add(i)
}
let add_time = os.clock() - t0
println("arraylist add: ${add_time}")
expectEq(list.size, 5000, "arraylist perf size")

let t1 = os.clock()
var sum = 0
for (i in 0..5000:2) {
    sum = sum + list[i]
}
let access_time = os.clock() - t1
println("arraylist access: ${access_time}")
expectTrue(sum > 0, "arraylist perf sum")

let t2 = os.clock()
list.remove(0..=4999:3)
let remove_time = os.clock() - t2
println("arraylist remove: ${remove_time}")
expectTrue(list.size < 5000, "arraylist perf remove")

let t3 = os.clock()
list.clear()
let clear_time = os.clock() - t3
println("arraylist clear: ${clear_time}")
expectTrue(list.isEmpty(), "arraylist perf clear")

if (!__test_failed) {
    println("PASS: arraylist_perf")
}
