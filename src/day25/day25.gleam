import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point}
import pocket_watch
import simplifile

fn parse() -> #(List(List(Int)), List(List(Int))) {
  let assert Ok(contents) = simplifile.read("src/day25/input")

  use #(keys, locks), cur <- list.fold(
    string.split(contents, "\n\n"),
    #([], []),
  )
  let lines =
    cur
    |> string.split("\n")

  let heights =
    lines
    |> list.map(string.to_graphemes)
    |> list.transpose
    |> list.map(fn(x) { list.count(x, equals("#")) - 1 })

  case lines {
    ["#####", ..] -> #(keys, [heights, ..locks])
    _ -> #([heights, ..keys], locks)
  }
}

fn product(xs: List(a), ys: List(a)) {
  use x <- list.flat_map(xs)
  use y <- list.map(ys)
  #(x, y)
}

fn part1(input: #(List(List(Int)), List(List(Int)))) {
  let #(keys, locks) = input
  product(keys, locks)
  |> list.count(fn(pair) {
    list.map2(pair.0, pair.1, int.add) |> list.all(fn(x) { x < 6 })
  })
}

pub fn main() {
  let input = parse()

  let p1 = fn() { part1(input) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
}
