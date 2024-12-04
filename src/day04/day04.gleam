import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array, get}
import simplifile

fn parse() -> Result(Array(Array(String)), _) {
  use contents <- result.try(simplifile.read("src/day04/input"))
  contents
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.to_graphemes |> glearray.from_list })
  |> glearray.from_list
  |> Ok
}

fn get2(array: Array(Array(a)), coord: #(Int, Int)) -> Result(a, Nil) {
  use row <- result.try(get(array, coord.0))
  get(row, coord.1)
}

fn get_string(coords: List(#(Int, Int)), array: Array(Array(String))) -> String {
  coords |> list.filter_map(get2(array, _)) |> string.join("")
}

fn read_in_dir(
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

const dirs = [
  #(1, 0), #(-1, 0), #(0, 1), #(0, -1), #(1, -1), #(-1, -1), #(1, 1), #(-1, 1),
]

fn dimensions(grid: Array(Array(a))) -> #(Int, Int) {
  let height = glearray.length(grid)
  let width = {
    let assert Ok(row) = glearray.get(grid, 0)
    glearray.length(row)
  }

  #(width, height)
}

fn grid_coords(width: Int, height: Int) {
  use i <- list.flat_map(list.range(0, height - 1))
  list.zip(list.repeat(i, width), list.range(0, width - 1))
}

fn part1(grid: Array(Array(String))) {
  let #(width, height) = dimensions(grid)

  let strs = {
    use #(i, j) <- list.flat_map(grid_coords(width, height))
    use dir <- list.map(dirs)
    read_in_dir(grid, i, j, dir)
  }

  strs |> list.filter(fn(s) { s == "XMAS" }) |> list.length
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
  grid_coords(width, height) |> list.filter(has_x(grid, _)) |> list.length
}

pub fn main() {
  let assert Ok(grid) = parse()

  io.println("Part 1: " <> int.to_string(part1(grid)))
  io.println("Part 2: " <> int.to_string(part2(grid)))
}
