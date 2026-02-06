println("testing cangjie compatibility")

let name: String = "Cangjie"
let value: Float64 = 1.5f
let flag: Bool = false

func make_profile(n: String, v: Float64, f: Bool) {
  let profile = [n, "$(v)", "$(f)"]
  return profile
}

func format_profile(profile: Array<String>) {
  return "mix $(profile[1]) $(profile[2]) $(profile[3])"
}

let profile = make_profile(name, value, flag)

assert("Hello Cangjie" == "Hello $(name)")
assert("value 2.5" == "value $(value + 1.0)")
assert(format_profile(profile) == "mix Cangjie 1.5 false")

let scores: Array<Int64> = [1, 2, 3, 4, 5]

func sum_scores(values: Array<Int64>) {
  var total: Int64 = 0
  for (value in values) {
    total = total + value
  }
  return total
}

assert(sum_scores(scores) == 15)

let roster: Array<Array<String>> = [
  ["Ada", "Engineer"],
  ["Linus", "Maintainer"],
]

func lookup_role(list: Array<Array<String>>, index: Int64) {
  assert(index >= 1)
  assert(index <= list.size)
  return list[index][2]
}

assert(lookup_role(roster, 2) == "Maintainer")

println("profile $(format_profile(profile))")
