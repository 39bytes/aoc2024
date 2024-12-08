import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/yielder
import lib/grid.{type Grid, type Point, point_add, point_sub}
import simplifile

fn parse() -> Grid(String) {
  let assert Ok(contents) = simplifile.read("src/day08/input")
  contents |> grid.to_char_grid
}

fn get_stations(grid: Grid(String)) -> Dict(String, List(Point)) {
  let #(width, height) = grid.dimensions(grid)
  grid.coords(width, height)
  |> list.group(fn(coord) { grid.get2(grid, coord) |> result.unwrap(".") })
  |> dict.delete(".")
}

fn in_bounds(p: Point, grid: Grid(String)) {
  let #(width, height) = grid.dimensions(grid)
  p.0 >= 0 && p.0 < height && p.1 >= 0 && p.1 < width
}

fn part1(grid: Grid(String)) {
  dict.values(get_stations(grid))
  |> list.flat_map(fn(stations) {
    use #(a, b) <- list.map(list.combination_pairs(stations))
    let diff = point_sub(b, a)
    set.from_list([point_sub(a, diff), point_add(b, diff)])
  })
  |> list.fold(set.new(), with: set.union)
  |> set.filter(in_bounds(_, grid))
  |> set.size
}

fn part2(grid: Grid(String)) {
  dict.values(get_stations(grid))
  |> list.flat_map(fn(stations) {
    use #(a, b) <- list.map(list.combination_pairs(stations))
    let diff = point_sub(b, a)
    let fwd =
      yielder.iterate(b, point_add(_, diff))
      |> yielder.take_while(in_bounds(_, grid))

    let bwd =
      yielder.iterate(b, point_sub(_, diff))
      |> yielder.take_while(in_bounds(_, grid))

    yielder.concat([fwd, bwd])
    |> yielder.to_list
    |> set.from_list
  })
  |> list.fold(set.new(), with: set.union)
  |> set.size
}

pub fn main() {
  let grid = parse()

  io.println("Part 1: " <> int.to_string(part1(grid)))
  io.println("Part 2: " <> int.to_string(part2(grid)))
}
