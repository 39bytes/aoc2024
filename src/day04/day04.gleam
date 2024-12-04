import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array}
import lib.{dirs8, equals, get2, grid_coords, to_char_grid}
import simplifile

fn parse() -> Result(Array(Array(String)), _) {
  use contents <- result.try(simplifile.read("src/day04/input"))
  contents
  |> to_char_grid
  |> Ok
}

fn get_string(coords: List(#(Int, Int)), array: Array(Array(String))) -> String {
  coords |> list.filter_map(get2(array, _)) |> string.join("")
}

fn string_along_dir(
  array: Array(Array(String)),
  i: Int,
  j: Int,
  direction: #(Int, Int),
) -> String {
  [
    #(i, j),
    #(i + direction.0, j + direction.1),
    #(i + direction.0 * 2, j + direction.1 * 2),
    #(i + direction.0 * 3, j + direction.1 * 3),
  ]
  |> get_string(array)
}

fn dimensions(grid: Array(Array(a))) -> #(Int, Int) {
  let height = glearray.length(grid)
  let width =
    glearray.get(grid, 0) |> result.unwrap(glearray.new()) |> glearray.length

  #(width, height)
}

fn part1(grid: Array(Array(String))) {
  let #(width, height) = dimensions(grid)

  let strs = {
    use #(i, j) <- list.flat_map(grid_coords(width, height))
    use dir <- list.map(dirs8)
    string_along_dir(grid, i, j, dir)
  }

  strs |> list.count(equals("XMAS"))
}

fn has_x(grid: Array(Array(String)), coord: #(Int, Int)) -> Bool {
  let bwd =
    [#(coord.0 - 1, coord.1 - 1), coord, #(coord.0 + 1, coord.1 + 1)]
    |> get_string(grid)
  let fwd =
    [#(coord.0 - 1, coord.1 + 1), coord, #(coord.0 + 1, coord.1 - 1)]
    |> get_string(grid)

  { fwd == "MAS" || fwd == "SAM" } && { bwd == "MAS" || bwd == "SAM" }
}

fn part2(grid: Array(Array(String))) {
  let #(width, height) = dimensions(grid)
  grid_coords(width, height) |> list.count(has_x(grid, _))
}

pub fn main() {
  let assert Ok(grid) = parse()

  io.println("Part 1: " <> int.to_string(part1(grid)))
  io.println("Part 2: " <> int.to_string(part2(grid)))
}
