import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point}
import pocket_watch
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

  let p1 = fn() { part1() }
  let p2 = fn() { part2() }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
