import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse() -> Result(#(List(Int), List(Int)), _) {
  use contents <- result.try(simplifile.read("src/day01/input"))
  contents
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(fn(s) {
    let assert Ok([a, b]) =
      string.split(s, "   ") |> list.map(int.parse) |> result.all
    #(a, b)
  })
  |> list.unzip
  |> Ok
}

fn part1(xs: List(Int), ys: List(Int)) {
  let xs = list.sort(xs, by: int.compare)
  let ys = list.sort(ys, by: int.compare)
  list.zip(xs, ys)
  |> list.map(fn(pair) { int.absolute_value(pair.0 - pair.1) })
  |> int.sum
}

fn part2(xs: List(Int), ys: List(Int)) {
  xs
  |> list.map(fn(x) { x * list.count(ys, fn(y) { y == x }) })
  |> int.sum
}

pub fn main() {
  let assert Ok(#(xs, ys)) = parse()

  io.println("Part 1: " <> int.to_string(part1(xs, ys)))
  io.println("Part 2: " <> int.to_string(part2(xs, ys)))
}
