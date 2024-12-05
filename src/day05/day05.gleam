import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import lib/function.{equals, not}
import simplifile

type Rule =
  #(Int, Int)

type Update =
  List(Int)

type Graph(a) =
  Dict(a, Set(a))

fn parse() -> #(List(Rule), List(Update)) {
  let assert Ok(contents) = simplifile.read("src/day05/input")
  let lines = contents |> string.trim() |> string.split("\n")

  let assert #(rules, [_, ..updates]) =
    lines |> list.split_while(not(string.is_empty))

  let rules = rules |> list.map(parse_rule)
  let updates = updates |> list.map(parse_update)

  #(rules, updates)
}

fn parse_rule(rule: String) -> Rule {
  let assert [x, y] = rule |> string.split("|") |> list.filter_map(int.parse)
  #(x, y)
}

fn parse_update(update: String) -> Update {
  update |> string.split(",") |> list.filter_map(int.parse)
}

fn valid_update(rules: Graph(Int), update: Update, seen: Set(Int)) -> Bool {
  case update {
    [] -> True
    [x, ..xs] -> {
      let comes_before = x |> dict.get(rules, _) |> result.unwrap(set.new())

      case set.intersection(comes_before, seen) |> set.is_empty {
        False -> False
        True -> valid_update(rules, xs, set.insert(seen, x))
      }
    }
  }
}

fn middle_element(l: List(a)) {
  let length = list.length(l)
  let assert [x, ..] = list.drop(l, length / 2)
  x
}

fn part1(graph: Graph(Int), updates: List(Update)) {
  updates
  |> list.filter(valid_update(graph, _, set.new()))
  |> list.map(middle_element)
  |> int.sum
}

fn fix_update(rules: Set(Rule), update: Update) -> Update {
  update
  |> list.sort(by: fn(a, b) {
    case set.contains(rules, #(a, b)) {
      True -> order.Lt
      False -> order.Gt
    }
  })
}

fn part2(graph: Graph(Int), rules: List(Rule), updates: List(Update)) {
  let rules = set.from_list(rules)

  updates
  |> list.filter(not(valid_update(graph, _, set.new())))
  |> list.map(fix_update(rules, _))
  |> list.map(middle_element)
  |> int.sum
}

fn make_graph(rules: List(Rule)) -> Graph(Int) {
  use graph, #(before, after) <- list.fold(rules, dict.new())
  let graph =
    graph
    |> dict.upsert(before, fn(entry) {
      case entry {
        None -> set.from_list([after])
        Some(nums) -> set.insert(nums, after)
      }
    })

  graph
}

pub fn main() {
  let #(rules, updates) = parse()

  let graph = make_graph(rules)

  io.println("Part 1: " <> int.to_string(part1(graph, updates)))
  io.println("Part 2: " <> int.to_string(part2(graph, rules, updates)))
}
