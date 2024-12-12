import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pocket_watch
import rememo/memo
import simplifile

fn parse() -> List(Int) {
  let assert Ok(contents) = simplifile.read("src/day11/input")
  let assert Ok(nums) =
    contents
    |> string.trim
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
  nums
}

fn transform(x: Int, k: Int, cache) {
  use <- memo.memoize(cache, #(x, k))
  use <- bool.guard(k == 0, 1)

  case x {
    0 -> transform(1, k - 1, cache)
    x -> {
      let digits = x |> int.to_string |> string.to_graphemes
      let len = list.length(digits)
      case len % 2 == 0 {
        True -> {
          let #(left, right) = digits |> list.split(len / 2)
          let assert Ok(left) = left |> string.join("") |> int.parse
          let assert Ok(right) = right |> string.join("") |> int.parse

          transform(left, k - 1, cache) + transform(right, k - 1, cache)
        }
        False -> transform(x * 2024, k - 1, cache)
      }
    }
  }
}

fn part1(nums: List(Int), cache) {
  nums |> list.map(transform(_, 25, cache)) |> int.sum
}

fn part2(nums: List(Int), cache) {
  nums |> list.map(transform(_, 75, cache)) |> int.sum
}

pub fn main() {
  let nums = parse()

  use cache <- memo.create()

  let p1 = fn() { part1(nums, cache) }
  let p2 = fn() { part2(nums, cache) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
