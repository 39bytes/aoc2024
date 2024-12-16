import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleamy/priority_queue as pq
import lib/direction.{type Direction, dir_to_vec}
import lib/grid.{type Grid, type Point, point_add}
import pocket_watch
import simplifile

fn parse() -> #(Grid(String), Point) {
  let assert Ok(contents) = simplifile.read("src/day16/input")
  let grid = contents |> grid.to_char_grid
  let #(width, height) = grid.dimensions(grid)

  let assert Ok(start) =
    grid.coords(width, height)
    |> list.find(fn(pt) {
      case grid.get2(grid, pt) {
        Ok("S") -> True
        _ -> False
      }
    })

  #(grid, start)
}

type PointDir =
  #(Point, Direction)

fn turn_dirs(dir: Direction) -> List(Direction) {
  case dir {
    direction.Up -> [direction.Left, direction.Right]
    direction.Down -> [direction.Left, direction.Right]
    direction.Right -> [direction.Up, direction.Down]
    direction.Left -> [direction.Up, direction.Down]
  }
}

fn turnable(maze: Grid(String), cur: Point, dir: Direction) {
  let turns = turn_dirs(dir)

  turns
  |> list.filter(fn(dir) {
    let pt = dir |> dir_to_vec |> point_add(cur)
    case grid.get2(maze, pt) {
      Ok(".") -> True
      _ -> False
    }
  })
}

const inf = 99_999_999_999_999_999_999

fn dijkstra(
  maze: Grid(String),
  queue: pq.Queue(#(Point, Direction, Int)),
  dists: Dict(PointDir, Int),
  visited: Set(PointDir),
  prev: Dict(PointDir, Set(PointDir)),
) {
  let assert Ok(#(#(cur, dir, score), queue)) = pq.pop(queue)
  let assert Ok(tile) = grid.get2(maze, cur)
  use <- bool.guard(when: tile == "E", return: #(score, #(cur, dir), prev))

  let visited = visited |> set.insert(#(cur, dir))

  let turns =
    turnable(maze, cur, dir) |> list.map(fn(d) { #(cur, d, score + 1000) })
  let adj = [#(point_add(cur, dir_to_vec(dir)), dir, score + 1), ..turns]
  let #(queue, dists, prev) = {
    use #(queue, dists, prev), #(new_pt, new_dir, new_score) as entry <- list.fold(
      adj,
      #(queue, dists, prev),
    )

    let assert Ok(tile) = grid.get2(maze, new_pt)

    use <- bool.guard(
      when: set.contains(visited, #(new_pt, new_dir)),
      return: #(queue, dists, prev),
    )
    use <- bool.guard(when: tile == "#", return: #(queue, dists, prev))

    let dist = dict.get(dists, #(new_pt, new_dir)) |> result.unwrap(inf)
    case int.compare(new_score, dist) {
      order.Gt -> #(queue, dists, prev)
      order.Eq -> {
        let assert Ok(s) = dict.get(prev, #(new_pt, new_dir))
        #(
          queue,
          dists,
          prev |> dict.insert(#(new_pt, new_dir), s |> set.insert(#(cur, dir))),
        )
      }
      order.Lt -> {
        #(
          queue |> pq.push(entry),
          dists |> dict.insert(#(new_pt, new_dir), new_score),
          prev |> dict.insert(#(new_pt, new_dir), set.from_list([#(cur, dir)])),
        )
      }
    }
  }

  dijkstra(maze, queue, dists, visited, prev)
}

fn part1(maze: Grid(String), start: Point) -> Int {
  let heap =
    pq.from_list([#(start, direction.Right, 0)], fn(a, b) {
      int.compare(a.2, b.2)
    })
  let dists = dict.from_list([#(#(start, direction.Right), 0)])
  let #(score, _, _) = dijkstra(maze, heap, dists, set.new(), dict.new())
  score
}

fn reconstruct(
  cur: PointDir,
  prev: Dict(PointDir, Set(PointDir)),
) -> Set(PointDir) {
  case dict.get(prev, cur) {
    Error(Nil) -> set.new()
    Ok(entry) ->
      set.fold(entry, entry, with: fn(path, cur) {
        set.union(path, reconstruct(cur, prev))
      })
  }
}

fn part2(maze: Grid(String), start: Point) {
  let heap =
    pq.from_list([#(start, direction.Right, 0)], fn(a, b) {
      int.compare(a.2, b.2)
    })
  let dists = dict.from_list([#(#(start, direction.Right), 0)])
  let #(_, end, prev) = dijkstra(maze, heap, dists, set.new(), dict.new())
  let best_tiles = reconstruct(end, prev)
  { best_tiles |> set.map(fn(x) { x.0 }) |> set.size } + 1
}

pub fn main() {
  let #(maze, start) = parse()

  let p1 = fn() { part1(maze, start) }
  let p2 = fn() { part2(maze, start) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
