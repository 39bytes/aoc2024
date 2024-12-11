import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lib/function.{equals, not}
import lib/grid.{type Grid, type Point}
import simplifile

fn parse() -> String {
  let assert Ok(contents) = simplifile.read("src/day<num>/input")
  todo
}

fn part1() {
  todo
}

fn part2() {
  todo
}

pub fn main() {
  let contents = parse()

  io.println("Part 1: " <> int.to_string(part1()))
  io.println("Part 2: " <> int.to_string(part2()))
}
