import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import lib/grid.{type Grid, type Point, point_add, point_mul}
import pocket_watch
import simplifile

fn parse() -> #(Grid(String), List(String)) {
  let assert Ok(contents) = simplifile.read("src/day15/input")
  let assert Ok(#(grid, moves)) = contents |> string.split_once("\n\n")
  let grid = grid |> grid.to_char_grid
  let moves =
    moves |> string.replace(each: "\n", with: "") |> string.to_graphemes
  #(grid, moves)
}

type Direction {
  Left
  Right
  Up
  Down
}

fn move_to_dir(move: String) -> Direction {
  case move {
    ">" -> Right
    "<" -> Left
    "^" -> Up
    "v" -> Down
    _ -> panic as "invalid move"
  }
}

fn dir_to_vec(direction: Direction) -> Point {
  case direction {
    Right -> #(0, 1)
    Left -> #(0, -1)
    Up -> #(-1, 0)
    Down -> #(1, 0)
  }
}

fn get_pushable(
  from: Point,
  dir: Point,
  walls: Set(Point),
  boxes: Set(Point),
) -> Result(List(Point), Nil) {
  use <- bool.guard(when: set.contains(walls, from), return: Error(Nil))
  case boxes |> set.contains(from) {
    False -> Ok([])
    True -> {
      use further <- result.try(get_pushable(
        point_add(from, dir),
        dir,
        walls,
        boxes,
      ))
      Ok([from, ..further])
    }
  }
}

fn move_guard(
  guard: Point,
  walls: Set(Point),
  boxes: Set(Point),
  dir: Direction,
) -> #(Point, Set(Point)) {
  let dir = dir_to_vec(dir)
  let next = point_add(guard, dir)
  case get_pushable(next, dir, walls, boxes) {
    Error(Nil) -> #(guard, boxes)
    Ok([]) -> #(next, boxes)
    Ok(pushable) -> {
      let assert Ok(first) = list.first(pushable)
      let assert Ok(last) = list.last(pushable)
      let boxes = boxes |> set.delete(first) |> set.insert(point_add(last, dir))
      #(next, boxes)
    }
  }
}

fn part1(grid: Grid(String), moves: List(String)) {
  let #(width, height) = grid.dimensions(grid)
  let #(walls, boxes, guard) = {
    use #(walls, boxes, guard), point <- list.fold(
      grid.coords(width, height),
      #(set.new(), set.new(), #(0, 0)),
    )

    case grid.get2(grid, point) {
      Ok("O") -> #(walls, set.insert(boxes, point), guard)
      Ok("#") -> #(set.insert(walls, point), boxes, guard)
      Ok("@") -> #(walls, boxes, point)
      Ok(_) | Error(Nil) -> #(walls, boxes, guard)
    }
  }
  let #(_, boxes) = {
    use #(guard, boxes), move <- list.fold(moves, #(guard, boxes))
    move_guard(guard, walls, boxes, move_to_dir(move))
  }

  boxes
  |> set.to_list
  |> list.map(fn(pt) { pt.0 * 100 + pt.1 })
  |> int.sum
}

type Box {
  LeftHalf
  RightHalf
}

fn other_half(box: Box, pos: Point) -> #(Box, Point) {
  case box {
    LeftHalf -> #(RightHalf, point_add(pos, #(0, 1)))
    RightHalf -> #(LeftHalf, point_add(pos, #(0, -1)))
  }
}

fn map_keys(d: Dict(a, b), f: fn(a) -> c) -> Dict(c, b) {
  d
  |> dict.to_list
  |> list.map(fn(x) { #(f(x.0), x.1) })
  |> dict.from_list
}

fn display(
  width: Int,
  height: Int,
  guard: Point,
  walls: Set(Point),
  boxes: Dict(Point, Box),
) {
  let grid = {
    use i <- list.map(list.range(0, height - 1))
    use j <- list.map(list.range(0, width - 1))
    let pt = #(i, j)
    use <- bool.guard(when: pt == guard, return: "@")
    case set.contains(walls, pt) {
      True -> "#"
      False -> {
        case dict.get(boxes, pt) {
          Ok(LeftHalf) -> "["
          Ok(RightHalf) -> "]"
          Error(Nil) -> "."
        }
      }
    }
  }
  grid |> list.map(string.join(_, "")) |> string.join("\n")
}

fn get_pushable2(
  from: Point,
  dir: Direction,
  walls: Set(Point),
  boxes: Dict(Point, Box),
) -> Result(Dict(Point, Box), Nil) {
  use <- bool.guard(when: set.contains(walls, from), return: Error(Nil))
  let dir_vec = dir_to_vec(dir)
  case boxes |> dict.get(from) {
    Error(_) -> Ok(dict.new())
    Ok(box) -> {
      case dir {
        Up | Down -> {
          use further1 <- result.try(get_pushable2(
            point_add(from, dir_vec),
            dir,
            walls,
            boxes,
          ))
          let other = other_half(box, from)
          use further2 <- result.try(get_pushable2(
            point_add(other.1, dir_vec),
            dir,
            walls,
            boxes,
          ))
          Ok(
            dict.merge(further1, further2)
            |> dict.insert(from, box)
            |> dict.insert(other.1, other.0),
          )
        }
        Left | Right -> {
          let other = other_half(box, from)
          use further <- result.try(get_pushable2(
            point_add(other.1, dir_vec),
            dir,
            walls,
            boxes,
          ))
          Ok(further |> dict.insert(from, box) |> dict.insert(other.1, other.0))
        }
      }
    }
  }
}

fn move_guard2(
  guard: Point,
  walls: Set(Point),
  boxes: Dict(Point, Box),
  dir: Direction,
) -> #(Point, Dict(Point, Box)) {
  let dir_vec = dir_to_vec(dir)
  let next = point_add(guard, dir_vec)
  case get_pushable2(next, dir, walls, boxes) {
    Error(Nil) -> #(guard, boxes)
    Ok(pushable) -> {
      case dict.is_empty(pushable) {
        True -> #(next, boxes)
        False -> {
          let after_push = map_keys(pushable, point_add(_, dir_vec))

          let boxes =
            boxes
            |> dict.drop(dict.keys(pushable))
            |> dict.merge(after_push)

          #(next, boxes)
        }
      }
    }
  }
}

fn part2(grid: Grid(String), moves: List(String)) {
  let #(width, height) = grid.dimensions(grid)
  let #(walls, boxes, guard) = {
    use #(walls, boxes, guard), point <- list.fold(
      grid.coords(width, height),
      #(set.new(), dict.new(), #(0, 0)),
    )

    let actual_l = #(point.0, point.1 * 2)
    let actual_r = point_add(actual_l, #(0, 1))

    case grid.get2(grid, point) {
      Ok("O") -> #(
        walls,
        boxes
          |> dict.insert(actual_l, LeftHalf)
          |> dict.insert(actual_r, RightHalf),
        guard,
      )
      Ok("#") -> #(
        walls |> set.insert(actual_l) |> set.insert(actual_r),
        boxes,
        guard,
      )
      Ok("@") -> #(walls, boxes, actual_l)
      Ok(_) | Error(Nil) -> #(walls, boxes, guard)
    }
  }

  let #(_, boxes) = {
    use #(guard, boxes), move <- list.fold(moves, #(guard, boxes))
    // io.println(display(width * 2, height, guard, walls, boxes))
    move_guard2(guard, walls, boxes, move_to_dir(move))
  }

  boxes
  |> dict.to_list
  |> list.filter_map(fn(entry) {
    case entry.1 {
      LeftHalf -> Ok(entry.0.0 * 100 + entry.0.1)
      RightHalf -> Error(Nil)
    }
  })
  |> int.sum
}

pub fn main() {
  let #(grid, moves) = parse()

  let p1 = fn() { part1(grid, moves) }
  let p2 = fn() { part2(grid, moves) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
