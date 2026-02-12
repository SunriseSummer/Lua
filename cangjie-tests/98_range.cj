dofile("cangjie-tests/_testing.cj")

// Test: Range struct and range literals

let r1 = Range(0, 5)
expectEq(r1.start, 0, "range start")
expectEq(r1.end, 5, "range end")
expectEq(r1.step, 1, "range step")
expectEq(r1.hasEnd, 1, "range hasEnd")
expectEq(r1.isClosed, 0, "range isClosed")

let iter1 = r1.iterator()
var seq1 = ""
while (let Some(v) <- iter1()) {
    seq1 = seq1 + tostring(v) + ","
}
expectEq(seq1, "0,1,2,3,4,", "range iterator exclusive")

let r2 = Range(1, 5, 2, true)
expectEq(r2.step, 2, "range step custom")
expectEq(r2.isClosed, 1, "range closed")
expectEq(r2.toString(), "1..=5:2", "range tostring closed")

let iter2 = r2.iterator()
var seq2 = ""
while (let Some(v) <- iter2()) {
    seq2 = seq2 + tostring(v) + ","
}
expectEq(seq2, "1,3,5,", "range iterator step")

let r3 = 0..10:2
expectEq(r3.start, 0, "range literal start")
expectEq(r3.end, 10, "range literal end")
expectEq(r3.step, 2, "range literal step")
expectEq(r3.isClosed, 0, "range literal isClosed")
expectEq(r3.toString(), "0..10:2", "range literal tostring")

let r4 = Range(5, 0, -2, true)
let iter4 = r4.iterator()
var seq4 = ""
while (let Some(v) <- iter4()) {
    seq4 = seq4 + tostring(v) + ","
}
expectEq(seq4, "5,3,1,", "range iterator reverse")

if (!__test_failed) {
    println("PASS: range")
}
