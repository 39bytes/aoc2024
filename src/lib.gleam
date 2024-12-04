//// General purpose utility constants, functions and combinators shared across solutions.

import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array, get}

/// The 4 cardinal directions.
pub const cardinals = [#(1, 0), #(-1, 0), #(0, 1), #(0, -1)]

/// The 4 ordinal directions.
pub const diagonals = [#(1, -1), #(-1, -1), #(1, 1), #(-1, 1)]

/// The 8 directions (cardinals + ordinals)
pub const dirs8 = [
  #(1, 0), #(-1, 0), #(0, 1), #(0, -1), #(1, -1), #(-1, -1), #(1, 1), #(-1, 1),
]

/// Negate a predicate.
pub fn not(f: fn(a) -> Bool) {
  fn(x) { !f(x) }
}

/// Return a predicate that returns true if an input value equals the given value.
pub fn equals(val: a) -> fn(a) -> Bool {
  fn(x) { x == val }
}

// Grid stuff
pub fn to_char_grid(s: String) -> Array(Array(String)) {
  s
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.to_graphemes |> glearray.from_list })
  |> glearray.from_list
}

pub fn to_int_grid(s: String) -> Array(Array(Int)) {
  s
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(s) {
    s |> string.to_graphemes |> list.filter_map(int.parse) |> glearray.from_list
  })
  |> glearray.from_list
}

pub fn get2(array: Array(Array(a)), coord: #(Int, Int)) -> Result(a, Nil) {
  use row <- result.try(get(array, coord.0))
  get(row, coord.1)
}

/// Return a list of every point in a grid of size (width, height)
pub fn grid_coords(width: Int, height: Int) {
  use i <- list.flat_map(list.range(0, height - 1))
  use j <- list.map(list.range(0, width - 1))
  #(i, j)
}
