import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pocket_watch
import rememo/memo
import simplifile

fn parse() -> #(List(String), List(String)) {
  let assert Ok(contents) = simplifile.read("src/day19/input")
  let assert Ok(#(patterns, designs)) = contents |> string.split_once("\n\n")

  let patterns = patterns |> string.trim |> string.split(", ")
  let designs = designs |> string.trim |> string.split("\n")

  #(patterns, designs)
}

type Trie {
  Trie(children: Dict(String, Trie), end: Bool)
}

fn new_trie() {
  Trie(children: dict.new(), end: False)
}

fn trie_insert(trie: Trie, s: String) {
  trie_insert_rec(trie, string.to_graphemes(s))
}

fn trie_insert_rec(trie: Trie, chars: List(String)) {
  case chars {
    [] -> Trie(..trie, end: True)
    [c, ..cs] -> {
      let child =
        trie.children
        |> dict.get(c)
        |> result.unwrap(new_trie())
        |> trie_insert_rec(cs)
      Trie(..trie, children: trie.children |> dict.insert(c, child))
    }
  }
}

fn is_possible(root: Trie, s: String) {
  is_possible_rec(root, root, string.to_graphemes(s))
}

fn is_possible_rec(root: Trie, cur: Trie, chars: List(String)) {
  case chars {
    [] -> cur.end
    [c, ..cs] as chars -> {
      let restart = cur.end && is_possible_rec(root, root, chars)
      restart
      || case cur.children |> dict.get(c) {
        Ok(next) -> is_possible_rec(root, next, cs)
        Error(Nil) -> False
      }
    }
  }
}

fn count_ways(root: Trie, s: String, cache) {
  count_ways_rec(root, root, [], string.to_graphemes(s), cache)
}

fn count_ways_rec(
  root: Trie,
  cur: Trie,
  prev: List(String),
  chars: List(String),
  cache,
) {
  use <- memo.memoize(cache, #(prev, chars))

  case chars {
    [] -> {
      case cur.end {
        True -> 1
        False -> 0
      }
    }
    [c, ..cs] as chars -> {
      let restart = case cur.end {
        True -> count_ways_rec(root, root, [], chars, cache)
        False -> 0
      }
      restart
      + case cur.children |> dict.get(c) {
        Ok(next) -> count_ways_rec(root, next, [c, ..prev], cs, cache)
        Error(Nil) -> 0
      }
    }
  }
}

fn part1(patterns: List(String), designs: List(String)) {
  let trie = list.fold(patterns, new_trie(), trie_insert)
  designs |> list.count(is_possible(trie, _))
}

fn part2(patterns: List(String), designs: List(String)) {
  use cache <- memo.create()
  let trie = list.fold(patterns, new_trie(), trie_insert)
  designs |> list.map(count_ways(trie, _, cache)) |> int.sum
}

pub fn main() {
  let #(patterns, designs) = parse()

  let p1 = fn() { part1(patterns, designs) }
  let p2 = fn() { part2(patterns, designs) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
