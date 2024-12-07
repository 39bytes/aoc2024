import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Equation =
  #(Int, List(Int))

type Operator =
  fn(Int, Int) -> Int

fn parse() -> List(Equation) {
  let assert Ok(contents) = simplifile.read("src/day07/input")
  contents
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(l) {
    let assert Ok(#(target, nums)) = string.split_once(l, on: ": ")
    let assert Ok(target) = int.parse(target)
    let assert Ok(nums) =
      nums |> string.split(" ") |> list.map(int.parse) |> result.all

    #(target, nums)
  })
}

fn valid_equation(
  target: Int,
  nums: List(Int),
  cur: Int,
  ops: List(Operator),
) -> Bool {
  case nums {
    [] -> target == cur
    [x, ..xs] -> {
      ops |> list.any(fn(op) { valid_equation(target, xs, op(cur, x), ops) })
    }
  }
}

fn solve(equations: List(Equation), ops: List(Operator)) {
  equations
  |> list.filter_map(fn(eq) {
    let assert [x, ..xs] = eq.1
    case valid_equation(eq.0, xs, x, ops) {
      True -> Ok(eq.0)
      False -> Error(Nil)
    }
  })
  |> int.sum
}

fn part1(equations: List(Equation)) {
  solve(equations, [int.add, int.multiply])
}

fn int_concat(a: Int, b: Int) {
  let assert Ok(x) = int.parse(int.to_string(a) <> int.to_string(b))
  x
}

fn part2(equations: List(Equation)) {
  solve(equations, [int.add, int.multiply, int_concat])
}

pub fn main() {
  let equations = parse()

  io.println("Part 1: " <> int.to_string(part1(equations)))
  io.println("Part 2: " <> int.to_string(part2(equations)))
}
