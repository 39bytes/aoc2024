import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse() -> Result(String, _) {
  use contents <- result.try(simplifile.read("src/day<num>/input"))
  Ok(contents)
}

fn part1() {
  todo
}

fn part2() {
  todo
}

pub fn main() {
  let assert Ok(contents) = parse()

  io.println("Part 1: " <> int.to_string(part1()))
  io.println("Part 2: " <> int.to_string(part2()))
}
