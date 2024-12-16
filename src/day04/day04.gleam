import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lib/func.{equals}
import lib/grid.{type Grid, type Point}
import simplifile

fn parse() -> Result(Grid(String), _) {
  use contents <- result.try(simplifile.read("src/day04/input"))
  contents
  |> grid.to_char_grid
  |> Ok
}

fn get_string(coords: List(Point), array: Grid(String)) -> String {
  coords |> list.filter_map(grid.get2(array, _)) |> string.join("")
}

fn string_along_dir(
  array: Grid(String),
  i: Int,
  j: Int,
  direction: Point,
) -> String {
  [
    #(i, j),
    #(i + direction.0, j + direction.1),
    #(i + direction.0 * 2, j + direction.1 * 2),
    #(i + direction.0 * 3, j + direction.1 * 3),
  ]
  |> get_string(array)
}

fn part1(grid: Grid(String)) {
  let #(width, height) = grid.dimensions(grid)

  let strs = {
    use #(i, j) <- list.flat_map(grid.coords(width, height))
    use dir <- list.map(grid.dirs8)
    string_along_dir(grid, i, j, dir)
  }

  strs |> list.count(equals("XMAS"))
}

fn has_x(grid: Grid(String), coord: Point) -> Bool {
  let bwd =
    [#(coord.0 - 1, coord.1 - 1), coord, #(coord.0 + 1, coord.1 + 1)]
    |> get_string(grid)
  let fwd =
    [#(coord.0 - 1, coord.1 + 1), coord, #(coord.0 + 1, coord.1 - 1)]
    |> get_string(grid)

  { fwd == "MAS" || fwd == "SAM" } && { bwd == "MAS" || bwd == "SAM" }
}

fn part2(grid: Grid(String)) {
  let #(width, height) = grid.dimensions(grid)
  grid.coords(width, height) |> list.count(has_x(grid, _))
}

pub fn main() {
  let assert Ok(grid) = parse()

  io.println("Part 1: " <> int.to_string(part1(grid)))
  io.println("Part 2: " <> int.to_string(part2(grid)))
}
