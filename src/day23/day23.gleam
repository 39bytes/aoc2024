import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import lib/func.{equals, not}
import lib/grid.{type Grid, type Point}
import pocket_watch
import simplifile

type Graph =
  Dict(String, List(String))

fn parse() -> Graph {
  let assert Ok(contents) = simplifile.read("src/day23/input")
  let lines =
    contents
    |> string.trim
    |> string.split("\n")

  use graph, line <- list.fold(lines, dict.new())
  let assert Ok(#(a, b)) = string.split_once(line, "-")
  graph
  |> dict.upsert(a, fn(entry) {
    case entry {
      None -> [b]
      Some(adj) -> [b, ..adj]
    }
  })
  |> dict.upsert(b, fn(entry) {
    case entry {
      None -> [a]
      Some(adj) -> [a, ..adj]
    }
  })
}

fn find_3_cycle(
  graph: Graph,
  cur: String,
  prev: String,
  visited: List(String),
) -> Result(List(List(String)), Nil) {
  use <- bool.guard(list.length(visited) > 3, Error(Nil))
  case visited |> list.contains(cur) {
    True -> Ok([visited])
    False -> {
      let assert Ok(adj) = dict.get(graph, cur)
      adj
      |> list.filter(not(equals(prev)))
      |> list.filter_map(find_3_cycle(graph, _, cur, [cur, ..visited]))
      |> list.flatten
      |> Ok
    }
  }
}

fn find_cliques(
  graph: Dict(String, Set(String)),
  r: Set(String),
  p: Set(String),
  x: Set(String),
) -> Set(Set(String)) {
  use <- bool.guard(set.size(p) == 0 && set.size(x) == 0, set.from_list([r]))
  let #(_, _, res) = {
    use #(p, x, res), v <- set.fold(p, #(p, x, set.new()))
    let assert Ok(adj) = dict.get(graph, v)
    let res =
      res
      |> set.union(find_cliques(
        graph,
        r |> set.insert(v),
        p |> set.intersection(adj),
        x |> set.intersection(adj),
      ))
    let p = set.delete(p, v)
    let x = set.insert(p, v)
    #(p, x, res)
  }
  res
}

fn part2(input: Graph) {
  let cliques =
    find_cliques(
      input |> dict.map_values(fn(_, v) { set.from_list(v) }),
      set.new(),
      set.from_list(dict.keys(input)),
      set.new(),
    )

  cliques
  |> set.fold(set.new(), fn(max, s) {
    case set.size(s) > set.size(max) {
      True -> s
      False -> max
    }
  })
  |> set.to_list
  |> list.sort(by: string.compare)
  |> string.join(",")
}

pub fn main() {
  let input = parse()

  let p1 = fn() { part1(input) }
  let p2 = fn() { part2(input) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(pocket_watch.simple("Part 2", p2))
}
