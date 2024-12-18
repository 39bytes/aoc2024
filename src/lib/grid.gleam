import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array, get}

pub type Point =
  #(Int, Int)

pub type Grid(a) =
  Array(Array(a))

/// The 4 cardinal directions.
pub const cardinals = [#(-1, 0), #(0, 1), #(1, 0), #(0, -1)]

/// The 4 ordinal directions.
pub const diagonals = [#(1, -1), #(-1, -1), #(1, 1), #(-1, 1)]

/// The 8 directions (cardinals + ordinals)
pub const dirs8 = [
  #(1, 0), #(-1, 0), #(0, 1), #(0, -1), #(1, -1), #(-1, -1), #(1, 1), #(-1, 1),
]

// Grid stuff
pub fn to_char_grid(s: String) -> Grid(String) {
  s
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.to_graphemes |> glearray.from_list })
  |> glearray.from_list
}

pub fn to_int_grid(s: String) -> Grid(Int) {
  s
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(s) {
    s |> string.to_graphemes |> list.filter_map(int.parse) |> glearray.from_list
  })
  |> glearray.from_list
}

pub fn get2(array: Grid(a), coord: Point) -> Result(a, Nil) {
  use row <- result.try(get(array, coord.0))
  get(row, coord.1)
}

/// Return a list of every point in a grid of size (width, height)
pub fn coords(width: Int, height: Int) -> List(Point) {
  use i <- list.flat_map(list.range(0, height - 1))
  use j <- list.map(list.range(0, width - 1))
  #(i, j)
}

pub fn dimensions(grid: Grid(a)) -> #(Int, Int) {
  let height = glearray.length(grid)
  let width =
    glearray.get(grid, 0) |> result.unwrap(glearray.new()) |> glearray.length

  #(width, height)
}

pub fn adj4(pt: Point) -> List(Point) {
  cardinals |> list.map(point_add(pt, _))
}

pub fn point_add(a: Point, b: Point) -> Point {
  #(a.0 + b.0, a.1 + b.1)
}

pub fn point_sub(a: Point, b: Point) -> Point {
  #(a.0 - b.0, a.1 - b.1)
}

pub fn point_mul(a: Point, c: Int) -> Point {
  #(a.0 * c, a.1 * c)
}
