import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/result
import lib/grid.{type Point}
import pocket_watch
import simplifile

type Vec2 =
  Point

type Machine {
  Machine(a: Vec2, b: Vec2, prize: Vec2)
}

fn parse_int_optional(x: Option(String)) {
  x |> option.to_result(Nil) |> result.then(int.parse)
}

fn parse() -> List(Machine) {
  let assert Ok(contents) = simplifile.read("src/day13/input")
  let assert Ok(a_pattern) =
    regexp.from_string("Button A: X\\+(\\d+), Y\\+(\\d+)")
  let assert Ok(b_pattern) =
    regexp.from_string("Button B: X\\+(\\d+), Y\\+(\\d+)")
  let assert Ok(prize_pattern) = regexp.from_string("Prize: X=(\\d+), Y=(\\d+)")

  regexp.scan(a_pattern, contents)
  |> list.zip(regexp.scan(b_pattern, contents))
  |> list.zip(regexp.scan(prize_pattern, contents))
  |> list.map(fn(tup) {
    let #(#(a_match, b_match), prize_match) = tup
    let assert [Ok(a_x), Ok(a_y)] =
      a_match.submatches |> list.map(parse_int_optional)
    let assert [Ok(b_x), Ok(b_y)] =
      b_match.submatches |> list.map(parse_int_optional)
    let assert [Ok(p_x), Ok(p_y)] =
      prize_match.submatches |> list.map(parse_int_optional)

    Machine(a: #(a_x, a_y), b: #(b_x, b_y), prize: #(p_x, p_y))
  })
}

fn linearly_dependent(a: Vec2, b: Vec2) {
  { a.0 % b.0 == 0 && a.1 % b.1 == 0 } || { b.0 % a.0 == 0 && b.1 % a.1 == 0 }
}

fn solve(m: Machine) -> Result(Vec2, Nil) {
  case linearly_dependent(m.a, m.b) {
    True -> panic
    False -> {
      let #(x1, y1) = m.a
      let #(x2, y2) = m.b
      let #(x, y) = m.prize

      let det = x1 * y2 - x2 * y1
      let inv = #(y2 * x - x2 * y, -y1 * x + x1 * y)
      use <- bool.guard(inv.0 % det != 0 || inv.1 % det != 0, Error(Nil))

      Ok(#(inv.0 / det, inv.1 / det))
    }
  }
}

fn part1(machines: List(Machine)) {
  machines
  |> list.filter_map(solve)
  |> list.map(fn(x) { x.0 * 3 + x.1 })
  |> int.sum
}

fn part2(machines: List(Machine)) {
  machines
  |> list.map(fn(m) {
    Machine(
      ..m,
      prize: #(m.prize.0 + 10_000_000_000_000, m.prize.1 + 10_000_000_000_000),
    )
  })
  |> list.filter_map(solve)
  |> list.map(fn(x) { x.0 * 3 + x.1 })
  |> int.sum
}

pub fn main() {
  let machines = parse()

  let p1 = fn() { part1(machines) }
  let p2 = fn() { part2(machines) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
