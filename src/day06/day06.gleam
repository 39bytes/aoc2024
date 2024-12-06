import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import lib/grid.{type Grid, type Point}
import simplifile

fn parse() -> Result(Grid(String), _) {
  use contents <- result.try(simplifile.read("src/day06/input"))
  contents
  |> grid.to_char_grid
  |> Ok
}

type Direction {
  Up
  Right
  Down
  Left
}

fn rotate90(dir: Direction) -> Direction {
  case dir {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

fn to_coord(dir: Direction) -> Point {
  case dir {
    Up -> #(-1, 0)
    Down -> #(1, 0)
    Right -> #(0, 1)
    Left -> #(0, -1)
  }
}

fn traverse(
  map: Grid(String),
  cur: Point,
  visited: Set(#(Point, Direction)),
  dir: Direction,
) {
  case set.contains(visited, #(cur, dir)) {
    True -> visited
    False -> {
      let visited = visited |> set.insert(#(cur, dir))
      let pt = to_coord(dir)
      let next = #(cur.0 + pt.0, cur.1 + pt.1)
      case grid.get2(map, next) {
        Error(_) -> visited
        Ok(".") | Ok("^") -> traverse(map, next, visited, dir)
        Ok("#") -> traverse(map, cur, visited, rotate90(dir))
        _ -> panic as "unknown character"
      }
    }
  }
}

fn part1(map: Grid(String), guard_pos: Point) {
  traverse(map, guard_pos, set.new(), Up)
  |> set.map(fn(x) { x.0 })
  |> set.size
}

fn traverse_extra(
  map: Grid(String),
  cur: Point,
  visited: Set(#(Point, Direction)),
  dir: Direction,
  extra: Point,
) {
  case set.contains(visited, #(cur, dir)) {
    True -> True
    False -> {
      let visited = visited |> set.insert(#(cur, dir))
      let pt = to_coord(dir)
      let next = #(cur.0 + pt.0, cur.1 + pt.1)
      case grid.get2(map, next) {
        Error(_) -> False
        _ if next == extra ->
          traverse_extra(map, cur, visited, rotate90(dir), extra)
        Ok("#") -> traverse_extra(map, cur, visited, rotate90(dir), extra)
        Ok(".") | Ok("^") -> traverse_extra(map, next, visited, dir, extra)
        _ -> panic as "unknown character"
      }
    }
  }
}

fn part2(map: Grid(String), guard_pos: Point) {
  let #(width, height) = grid.dimensions(map)
  grid.coords(width, height)
  |> list.filter(fn(coord) {
    case grid.get2(map, coord) {
      Ok(".") -> True
      _ -> False
    }
  })
  |> list.count(traverse_extra(map, guard_pos, set.new(), Up, _))
}

pub fn main() {
  let assert Ok(map) = parse()

  let #(width, height) = grid.dimensions(map)
  let assert Ok(guard_pos) =
    grid.coords(width, height)
    |> list.find_map(fn(coord) {
      use char <- result.try(grid.get2(map, coord))
      case char {
        "^" -> Ok(coord)
        _ -> Error(Nil)
      }
    })

  io.println("Part 1: " <> int.to_string(part1(map, guard_pos)))
  io.println("Part 2: " <> int.to_string(part2(map, guard_pos)))
}
