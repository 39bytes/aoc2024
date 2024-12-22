import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point, point_sub}
import pocket_watch
import rememo/memo
import simplifile

fn parse() -> List(List(String)) {
  let assert Ok(codes) = simplifile.read("src/day21/input")
  codes |> string.trim |> string.split("\n") |> list.map(string.to_graphemes)
}

type Keys =
  Dict(String, Point)

type Robot {
  Robot(keypad: Keys, pos: Point)
}

fn num_keys() {
  dict.from_list([
    #("7", #(0, 0)),
    #("8", #(0, 1)),
    #("9", #(0, 2)),
    #("4", #(1, 0)),
    #("5", #(1, 1)),
    #("6", #(1, 2)),
    #("1", #(2, 0)),
    #("2", #(2, 1)),
    #("3", #(2, 2)),
    #(" ", #(3, 0)),
    #("0", #(3, 1)),
    #("A", #(3, 2)),
  ])
}

fn dir_keys() {
  dict.from_list([
    #(" ", #(0, 0)),
    #("^", #(0, 1)),
    #("A", #(0, 2)),
    #("<", #(1, 0)),
    #("v", #(1, 1)),
    #(">", #(1, 2)),
  ])
}

fn robots(n: Int) -> List(Robot) {
  let keypad = num_keys()
  let dir_keypad = dir_keys()

  [Robot(keypad, #(3, 2)), ..list.repeat(Robot(dir_keypad, #(0, 2)), n - 1)]
}

type Path {
  Single(List(String))
  Branch(List(String), List(String))
}

fn key_path(blank: Point, from: Point, to: Point) {
  let diff = point_sub(to, from)
  let horz_move = case diff.1 >= 0 {
    True -> list.repeat(">", diff.1)
    False -> list.repeat("<", -diff.1)
  }
  let vert_move = case diff.0 >= 0 {
    True -> list.repeat("v", diff.0)
    False -> list.repeat("^", -diff.0)
  }

  case diff.0 == 0 || #(from.0 + diff.0, from.1) == blank {
    True -> Single([horz_move, vert_move, ["A"]] |> list.flatten)
    False -> {
      case diff.1 == 0 || #(from.0, from.1 + diff.1) == blank {
        True -> Single([vert_move, horz_move, ["A"]] |> list.flatten)
        False -> {
          Branch(
            [horz_move, vert_move, ["A"]] |> list.flatten,
            [vert_move, horz_move, ["A"]] |> list.flatten,
          )
        }
      }
    }
  }
}

fn min_presses(code: List(String), robots: List(Robot), cache) {
  use <- memo.memoize(cache, #(code, robots))
  use #(count, robots), button <- list.fold(code, #(0, robots))
  case robots {
    [] -> #(count + 1, robots)
    [Robot(keypad, from), ..robots] -> {
      let assert Ok(to) = dict.get(keypad, button)
      let assert Ok(blank) = dict.get(keypad, " ")
      let paths = key_path(blank, from, to)

      let #(presses, robots) = case paths {
        Single(path) -> min_presses(path, robots, cache)
        Branch(path1, path2) -> {
          let #(count1, robots1) = min_presses(path1, robots, cache)
          let #(count2, robots2) = min_presses(path2, robots, cache)
          case count1 < count2 {
            True -> #(count1, robots1)
            False -> #(count2, robots2)
          }
        }
      }

      #(count + presses, [Robot(keypad:, pos: to), ..robots])
    }
  }
}

fn part1(codes: List(List(String))) {
  use cache <- memo.create()
  let robots = robots(3)

  codes
  |> list.map(fn(code) {
    let assert Ok(num) = code |> list.take(3) |> string.join("") |> int.parse
    let #(presses, _) = min_presses(code, robots, cache)
    num * presses
  })
  |> int.sum
}

fn part2(codes: List(List(String))) {
  use cache <- memo.create()
  let robots = robots(26)

  codes
  |> list.map(fn(code) {
    let assert Ok(num) = code |> list.take(3) |> string.join("") |> int.parse
    let #(presses, _) = min_presses(code, robots, cache)
    num * presses
  })
  |> int.sum
}

pub fn main() {
  let codes = parse()

  let p1 = fn() { part1(codes) }
  let p2 = fn() { part2(codes) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
