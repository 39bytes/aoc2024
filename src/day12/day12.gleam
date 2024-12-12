import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import lib/function.{equals, not}
import lib/grid.{type Grid, type Point, point_add, point_sub}
import pocket_watch
import simplifile

fn parse() -> Grid(String) {
  let assert Ok(contents) = simplifile.read("src/day12/input")
  contents |> grid.to_char_grid
}

fn dfs(
  cur: Point,
  grid: Grid(String),
  visited: Set(Point),
) -> #(Set(Point), Int) {
  use <- bool.guard(set.contains(visited, cur), #(visited, 0))
  let assert Ok(plant) = grid.get2(grid, cur)
  let visited = visited |> set.insert(cur)

  let next_points =
    grid.adj4(cur)
    |> list.filter(fn(p) {
      case grid.get2(grid, p) {
        Ok(adj_plant) -> adj_plant == plant
        _ -> False
      }
    })

  let p = 4 - list.length(next_points)

  use #(visited, p), next <- list.fold(next_points, #(visited, p))
  let #(visited, perim) = dfs(next, grid, visited)
  #(visited, p + perim)
}

fn find_regions(grid: Grid(String)) -> #(List(Int), List(Set(Point))) {
  let #(_, perims, areas) = {
    let #(width, height) = grid.dimensions(grid)
    use #(visited, perims, areas), pt <- list.fold(
      grid.coords(width, height),
      #(set.new(), [], []),
    )
    use <- bool.guard(set.contains(visited, pt), #(visited, perims, areas))

    let #(region, perimeter) = dfs(pt, grid, set.new())
    let visited = visited |> set.union(region)
    let perims = [perimeter, ..perims]
    let areas = [region, ..areas]

    #(visited, perims, areas)
  }
  #(perims, areas)
}

fn part1(grid: Grid(String)) {
  let #(perims, regions) = find_regions(grid)

  regions
  |> list.map(set.size)
  |> list.map2(perims, _, int.multiply)
  |> int.sum
}

fn map_dirs(dirs: List(Point), pt: Point) {
  set.from_list(dirs) |> set.map(point_add(pt, _))
}

fn between(origin: Point, a: Point, b: Point) -> Point {
  point_add(point_sub(a, origin), point_sub(b, origin))
  |> point_add(origin)
}

fn vertex_count(pt: Point, region: Set(Point)) {
  let vertical = map_dirs([#(1, 0), #(-1, 0)], pt)
  let horizontal = map_dirs([#(0, -1), #(0, 1)], pt)

  let adj =
    set.union(vertical, horizontal)
    |> set.intersection(region)

  case set.size(adj) {
    0 -> 4
    1 -> 2
    2 -> {
      use <- bool.guard(
        set.is_subset(vertical, region) || set.is_subset(horizontal, region),
        0,
      )
      let assert [x, y] = set.to_list(adj)
      case set.contains(region, between(pt, x, y)) {
        True -> 1
        False -> 2
      }
    }
    3 -> {
      let assert [up, right, down, left] =
        grid.cardinals
        |> list.map(point_add(pt, _))
        |> list.map(set.contains(region, _))

      let #(diag1, diag2) = case up, right, down, left {
        True, True, True, False -> #(#(-1, 1), #(1, 1))
        False, True, True, True -> #(#(1, 1), #(1, -1))
        True, False, True, True -> #(#(1, -1), #(-1, -1))
        True, True, False, True -> #(#(-1, -1), #(-1, 1))
        _, _, _, _ -> panic as "unreachable"
      }

      [diag1, diag2]
      |> list.map(point_add(pt, _))
      |> list.count(not(set.contains(region, _)))
    }
    4 -> {
      map_dirs(grid.diagonals, pt) |> set.difference(region) |> set.size
    }
    _ -> panic as "unreachable"
  }
}

fn price(region: Set(Point)) {
  let sides =
    region
    |> set.to_list
    |> list.map(vertex_count(_, region))
    |> int.sum
  set.size(region) * sides
}

fn part2(grid: Grid(String)) {
  let #(_, regions) = find_regions(grid)
  regions |> list.map(price) |> int.sum
}

pub fn main() {
  let grid = parse()

  let p1 = fn() { part1(grid) }
  let p2 = fn() { part2(grid) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
