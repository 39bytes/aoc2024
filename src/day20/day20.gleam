import gleam/bool
import gleam/deque
import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point, point_add, point_mul}
import pocket_watch
import simplifile

fn parse() -> Grid(String) {
  let assert Ok(contents) = simplifile.read("src/day20/input")
  contents |> grid.to_char_grid
}

fn dfs(
  track: Grid(String),
  cur: Point,
  prev: Point,
  t: Int,
  path: Dict(Point, Int),
) {
  let path = path |> dict.insert(cur, t)

  use <- bool.guard(grid.get2(track, cur) |> result.unwrap("#") == "E", path)

  let assert Ok(next) =
    grid.adj4(cur)
    |> list.find(fn(pt) {
      pt != prev && grid.get2(track, pt) |> result.unwrap("#") != "#"
    })

  dfs(track, next, cur, t + 1, path)
}

fn time_save(
  from: Point,
  to: Point,
  grid: Grid(String),
  path: Dict(Point, Int),
  time: Int,
) {
  case grid.get2(grid, from), grid.get2(grid, to) {
    Ok(a), Ok(b) -> {
      use <- bool.guard(a == "#" || b == "#", Error(Nil))
      use start_time <- result.try(dict.get(path, from))
      use end_time <- result.try(dict.get(path, to))
      case end_time > start_time {
        True -> Ok(end_time - start_time - time)
        False -> Error(Nil)
      }
    }
    _, _ -> Error(Nil)
  }
}

fn bfs(
  track: Grid(String),
  source: Point,
  max_cheat_time: Int,
  path: Dict(Point, Int),
  q: deque.Deque(#(Point, Int)),
  visited: Set(Point),
  cheats: List(Int),
) {
  case deque.pop_front(q) {
    Error(Nil) -> cheats
    Ok(#(#(pt, time), q)) -> {
      let #(q, visited, cheats) = {
        let cheats = case time_save(source, pt, track, path, time) {
          Ok(save) -> [save, ..cheats]
          Error(Nil) -> cheats
        }
        use <- bool.guard(time >= max_cheat_time, #(q, visited, cheats))

        let next =
          grid.adj4(pt)
          |> list.filter(fn(adj) {
            !set.contains(visited, adj) && grid.get2(track, adj) |> result.is_ok
          })

        let #(visited, q) =
          list.fold(next, #(visited, q), fn(acc, pt) {
            #(
              acc.0 |> set.insert(pt),
              acc.1 |> deque.push_back(#(pt, time + 1)),
            )
          })

        #(q, visited, cheats)
      }

      bfs(track, source, max_cheat_time, path, q, visited, cheats)
    }
  }
}

fn part1(track: Grid(String), start: Point) {
  let path = dfs(track, start, #(-1, -1), 0, dict.new())

  path
  |> dict.to_list
  |> list.flat_map(fn(entry) {
    bfs(
      track,
      entry.0,
      2,
      path,
      deque.from_list([#(entry.0, 0)]),
      set.new(),
      [],
    )
  })
  |> list.count(fn(x) { x >= 100 })
}

fn part2(track: Grid(String), start: Point) {
  let path = dfs(track, start, #(-1, -1), 0, dict.new())

  path
  |> dict.to_list
  |> list.flat_map(fn(entry) {
    bfs(
      track,
      entry.0,
      20,
      path,
      deque.from_list([#(entry.0, 0)]),
      set.new(),
      [],
    )
  })
  |> list.count(fn(x) { x >= 100 })
}

pub fn main() {
  let track = parse()

  let #(width, height) = grid.dimensions(track)
  let assert Ok(start) =
    grid.coords(width, height)
    |> list.find(fn(pt) { grid.get2(track, pt) |> result.unwrap("#") == "S" })

  let p1 = fn() { part1(track, start) }
  let p2 = fn() { part2(track, start) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
