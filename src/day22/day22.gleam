import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point}
import pocket_watch
import simplifile

fn parse() -> List(Int) {
  let assert Ok(contents) = simplifile.read("src/day22/input")
  let assert Ok(nums) =
    contents
    |> string.trim
    |> string.split("\n")
    |> list.map(int.parse)
    |> result.all
  nums
}

fn mix_and_prune(num, val) {
  int.bitwise_exclusive_or(num, val) |> prune
}

fn prune(num) {
  num |> int.bitwise_and(0xFFFFFF)
}

fn calc_next(num) {
  let x = mix_and_prune(num, num |> int.bitwise_shift_left(6))
  let x = mix_and_prune(x, x |> int.bitwise_shift_right(5))
  mix_and_prune(x, x |> int.bitwise_shift_left(11))
}

fn part1(nums: List(Int)) {
  nums
  |> list.map(fn(x) {
    let assert Ok(val) = yielder.iterate(x, calc_next) |> yielder.at(2000)
    val
  })
  |> int.sum
}

fn solve_num(num) {
  let seq =
    yielder.iterate(num, calc_next) |> yielder.take(2001) |> yielder.to_list

  let last_digits = seq |> list.map(fn(x) { x % 10 })
  let assert [_, ..tail] = last_digits
  let diffs = list.map2(tail, last_digits, int.subtract)
  let windows = list.window(diffs, 4)

  use sells, #(digit, window) <- list.fold(
    list.zip(last_digits |> list.drop(4), windows),
    dict.new(),
  )
  case dict.get(sells, window) {
    Error(Nil) -> sells |> dict.insert(window, digit)
    _ -> sells
  }
}

fn part2(nums: List(Int)) {
  nums
  |> list.map(solve_num)
  |> list.fold(dict.new(), fn(acc, x) { dict.combine(acc, x, int.add) })
  |> dict.values
  |> list.fold(0, int.max)
}

pub fn main() {
  let nums = parse()

  let p1 = fn() { part1(nums) }
  let p2 = fn() { part2(nums) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
