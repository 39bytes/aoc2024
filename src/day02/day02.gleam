import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse() -> Result(List(List(Int)), _) {
  let assert Ok(contents) = simplifile.read("src/day02/input")
  contents
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) {
    string.split(line, " ") |> list.map(int.parse) |> result.all
  })
  |> result.all
}

fn increasing(pair: #(Int, Int)) -> Bool {
  pair.0 < pair.1 && pair.1 - pair.0 >= 1 && pair.1 - pair.0 <= 3
}

fn decreasing(pair: #(Int, Int)) -> Bool {
  pair.0 > pair.1 && pair.0 - pair.1 >= 1 && pair.0 - pair.1 <= 3
}

fn check(report: List(Int), cmp: fn(#(Int, Int)) -> Bool) -> Bool {
  report
  |> list.window_by_2
  |> list.all(cmp)
}

fn safe(report) {
  check(report, increasing) || check(report, decreasing)
}

fn filter_count(xs: List(a), pred: fn(a) -> Bool) -> Int {
  xs |> list.filter(pred) |> list.length
}

fn part1(reports: List(List(Int))) {
  reports
  |> filter_count(safe)
}

fn remove_at(xs: List(a), i: Int) -> List(a) {
  case xs {
    [] -> []
    [_, ..xs] if i == 0 -> xs
    [x, ..xs] -> [x, ..remove_at(xs, i - 1)]
  }
}

fn part2(reports: List(List(Int))) {
  reports
  |> filter_count(fn(report) {
    report
    |> list.length
    |> list.range(0, _)
    |> list.map(remove_at(report, _))
    |> list.any(safe)
  })
}

pub fn main() {
  let assert Ok(reports) = parse()

  io.println("Part 1: " <> int.to_string(part1(reports)))
  io.println("Part 2: " <> int.to_string(part2(reports)))
}
