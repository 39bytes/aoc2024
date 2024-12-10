import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import lib/grid.{type Grid, type Point, point_add}
import simplifile

fn parse() -> Grid(Int) {
  let assert Ok(contents) = simplifile.read("src/day10/input")
  contents |> grid.to_int_grid
}

fn point_is(grid: Grid(Int), pt: Point, val: Int) {
  case grid.get2(grid, pt) {
    Ok(x) if x == val -> Ok(pt)
    _ -> Error(Nil)
  }
}

fn dfs(grid: Grid(Int), cur: Point) -> List(Point) {
  case grid.get2(grid, cur) {
    Ok(x) -> {
      use <- bool.guard(x == 9, [cur])
      grid.cardinals
      |> list.filter_map(fn(dir) {
        point_add(dir, cur)
        |> point_is(grid, _, x + 1)
        |> result.map(dfs(grid, _))
      })
      |> list.flatten
    }
    Error(Nil) -> []
  }
}

fn trailheads(grid: Grid(Int)) {
  let #(width, height) = grid.dimensions(grid)
  grid.coords(width, height)
  |> list.filter_map(point_is(grid, _, 0))
}

fn part1(grid: Grid(Int)) {
  trailheads(grid)
  |> list.map(dfs(grid, _))
  |> list.map(list.unique)
  |> list.map(list.length)
  |> int.sum
}

fn part2(grid: Grid(Int)) {
  trailheads(grid)
  |> list.map(dfs(grid, _))
  |> list.map(list.length)
  |> int.sum
}

pub fn main() {
  let grid = parse()

  io.println("Part 1: " <> int.to_string(part1(grid)))
  io.println("Part 2: " <> int.to_string(part2(grid)))
}
