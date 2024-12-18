import gleam/bool
import gleam/deque.{type Deque}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import glearray
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point}
import pocket_watch
import simplifile

fn parse() -> List(Point) {
  let assert Ok(contents) = simplifile.read("src/day18/input")
  contents
  |> string.trim
  |> string.split("\n")
  |> list.filter_map(string.split_once(_, ","))
  |> list.map(fn(pt) {
    let assert Ok(i) = int.parse(pt.1)
    let assert Ok(j) = int.parse(pt.0)
    #(i, j)
  })
}

type Tile {
  Empty
  Full
}

const width = 71

const height = 71

fn make_grid(walls: Set(Point)) -> Grid(Tile) {
  grid.coords(width, height)
  |> list.map(fn(pt) {
    case set.contains(walls, pt) {
      True -> Full
      False -> Empty
    }
  })
  |> list.sized_chunk(width)
  |> list.map(glearray.from_list)
  |> glearray.from_list
}

fn bfs(
  q: Deque(#(Point, Int)),
  visited: Set(Point),
  grid: Grid(Tile),
) -> Result(Int, Nil) {
  use #(#(pt, dist), q) <- result.try(deque.pop_front(q))
  use <- bool.guard(pt == #(width - 1, height - 1), Ok(dist))

  let #(q, visited) =
    list.fold(grid.adj4(pt), #(q, visited), fn(state, neighbor) {
      case grid.get2(grid, neighbor), set.contains(visited, neighbor) {
        Ok(Empty), False -> #(
          state.0 |> deque.push_back(#(neighbor, dist + 1)),
          state.1 |> set.insert(neighbor),
        )
        _, _ -> state
      }
    })

  bfs(q, visited, grid)
}

fn part1(walls: List(Point)) {
  let walls = list.take(walls, 1024) |> set.from_list
  let grid = make_grid(walls)

  let assert Ok(ans) =
    bfs(deque.from_list([#(#(0, 0), 0)]), set.from_list([#(0, 0)]), grid)
  ans
}

fn iter(rest: List(Point), cur_walls: Set(Point)) {
  case rest {
    [] -> Error(Nil)
    [x, ..xs] -> {
      let cur_walls = cur_walls |> set.insert(x)
      let grid = make_grid(cur_walls)
      case
        bfs(deque.from_list([#(#(0, 0), 0)]), set.from_list([#(0, 0)]), grid)
      {
        Ok(_) -> iter(xs, cur_walls)
        Error(Nil) -> Ok(x)
      }
    }
  }
}

fn part2(walls: List(Point)) {
  let assert Ok(pt) = iter(walls, set.new())
  pt
}

pub fn main() {
  let walls = parse()

  let p1 = fn() { part1(walls) }
  let p2 = fn() { part2(walls) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.debug(pocket_watch.simple("Part 2", p2))
}
