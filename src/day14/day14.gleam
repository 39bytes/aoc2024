import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import lib/grid.{type Point, point_add, point_mul}
import pocket_watch
import simplifile

type Vec2 =
  Point

type Robot {
  Robot(position: Vec2, velocity: Vec2)
}

fn parse_vec(s: String) -> Vec2 {
  let assert Ok(#(_, vec)) = string.split_once(s, "=")
  let assert Ok([x, y]) =
    vec |> string.split(",") |> list.map(int.parse) |> result.all
  #(x, y)
}

fn parse() -> List(Robot) {
  let assert Ok(contents) = simplifile.read("src/day14/input")
  contents
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(#(pos, vel)) = string.split_once(line, " ")
    Robot(parse_vec(pos), parse_vec(vel))
  })
}

const width = 101

const height = 103

fn mod(a: Int, b: Int) -> Int {
  { a % b + b } % b
}

fn move(robot: Robot, ticks: Int) -> Robot {
  let v = point_mul(robot.velocity, ticks) |> point_add(robot.position)
  let position = #(mod(v.0, width), mod(v.1, height))
  Robot(position, robot.velocity)
}

fn quadrant(pos: Vec2) {
  let #(x, y) = pos
  let mid_x = width / 2
  let mid_y = height / 2

  case pos.0, pos.1 {
    _, _ if x < mid_x && y < mid_y -> Ok(1)
    _, _ if x > mid_x && y < mid_y -> Ok(2)
    _, _ if x < mid_x && y > mid_y -> Ok(3)
    _, _ if x > mid_x && y > mid_y -> Ok(4)
    _, _ -> Error(Nil)
  }
}

fn part1(robots: List(Robot)) {
  robots
  |> list.map(move(_, 100))
  |> list.map(fn(r) { r.position })
  |> list.filter_map(quadrant)
  |> list.group(function.identity)
  |> dict.values
  |> list.map(list.length)
  |> int.product
}

fn display(robots: List(Robot)) {
  let robots = set.from_list(robots) |> set.map(fn(r) { r.position })
  let grid = {
    use y <- list.map(list.range(0, height - 1))
    use x <- list.map(list.range(0, width - 1))
    case set.contains(robots, #(x, y)) {
      True -> "#"
      False -> "."
    }
  }

  grid |> list.map(string.join(_, "")) |> string.join("\n")
}

fn part2(robots: List(Robot), acc: Int) {
  let robots = robots |> list.map(move(_, 1))
  io.println(display(robots))
  io.println(int.to_string(acc))
  part2(robots, acc + 1)
}

pub fn main() {
  let robots = parse()

  let p1 = fn() { part1(robots) }
  let p2 = fn() { part2(robots, 0) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
