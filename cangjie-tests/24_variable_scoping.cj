// Variable shadowing in nested scopes
let x = 10
if (true) {
  let x = 20
  println(x)  // 20
}
println(x)  // 10

// Function scope shadowing
let y = 100
func test(): Int64 {
  let y = 200
  return y
}
println(test())  // 200
println(y)  // 100

// Nested block shadowing
var z = 1
if (true) {
  var z = 2
  if (true) {
    var z = 3
    println(z)  // 3
  }
  println(z)  // 2
}
println(z)  // 1

println("PASS: 24_variable_scoping")
