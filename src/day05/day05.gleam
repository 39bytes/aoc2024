import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import lib/function.{not}
import simplifile

type Rule =
  #(Int, Int)

type Update =
  List(Int)

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

fn valid_update(
  update: Update,
  rules_map: Dict(Int, Set(Int)),
  seen: Set(Int),
) -> Bool {
  case update {
    [] -> True
    [x, ..xs] -> {
      let comes_before = x |> dict.get(rules_map, _) |> result.unwrap(set.new())

      case set.intersection(comes_before, seen) |> set.is_empty {
        False -> False
        True -> valid_update(xs, rules_map, set.insert(seen, x))
      }
    }
  }
}

fn middle_element(l: List(a)) {
  let length = list.length(l)
  let assert [x, ..] = list.drop(l, length / 2)
  x
}

fn part1(rules: List(Rule), updates: List(Update)) {
  let rules_map = {
    use d, #(before, after) <- list.fold(rules, dict.new())
    d
    |> dict.upsert(before, fn(entry) {
      case entry {
        None -> set.from_list([after])
        Some(nums) -> set.insert(nums, after)
      }
    })
  }

  updates
  |> list.filter(valid_update(_, rules_map, set.new()))
  |> list.map(middle_element)
  |> int.sum
}

fn part2() {
  todo
}

pub fn main() {
  let #(rules, updates) = parse()
  io.debug(rules)
  io.debug(updates)

  io.println("Part 1: " <> int.to_string(part1(rules, updates)))
  io.println("Part 2: " <> int.to_string(part2()))
}
