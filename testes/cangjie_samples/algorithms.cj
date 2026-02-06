global <const> *

print("cangjie sample: algorithms")

let numbers: Table = {5, 1, 4, 2, 3}

let bubble_sort = function(list)
  let n = #list
  for i = 1, n do
    for j = 1, n - i do
      if list[j] > list[j + 1] then
        let tmp = list[j]
        list[j] = list[j + 1]
        list[j + 1] = tmp
      end
    end
  end
end

bubble_sort(numbers)
assert(numbers[1] == 1)
assert(numbers[5] == 5)
println("sorted first $(numbers[1]) last $(numbers[5])")

local function fibonacci(n)
  if n < 2 then
    return n
  end
  return fibonacci(n - 1) + fibonacci(n - 2)
end

let fib5 = fibonacci(5)
assert(fib5 == 5)
