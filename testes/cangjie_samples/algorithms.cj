println("cangjie sample: sorted values")

let sorted_numbers: Array<Int64> = [1, 2, 3, 4, 5]
let first = sorted_numbers[1]
let last = sorted_numbers[sorted_numbers.size]

assert(first == 1)
assert(last == 5)
println("sorted first $(first) last $(last)")

func sum_range(values: Array<Int64>) {
  var total: Int64 = 0
  for (value in values) {
    total = total + value
  }
  return total
}

assert(sum_range(sorted_numbers) == 15)

let fib_values: Array<Int64> = [0, 1, 1, 2, 3, 5]

func fib_lookup(values: Array<Int64>, index: Int64) {
  assert(index >= 1)
  assert(index <= values.size)
  return values[index]
}

assert(fib_lookup(fib_values, 6) == 5)
