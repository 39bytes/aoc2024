import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pocket_watch
import simplifile

type Operator {
  And
  Or
  Xor
}

fn operator(s: String) -> Result(Operator, Nil) {
  case s {
    "XOR" -> Ok(Xor)
    "AND" -> Ok(And)
    "OR" -> Ok(Or)
    _ -> Error(Nil)
  }
}

fn apply_op(l: Int, op: Operator, r: Int) {
  case op {
    And -> int.bitwise_and(l, r)
    Or -> int.bitwise_or(l, r)
    Xor -> int.bitwise_exclusive_or(l, r)
  }
}

type Gate {
  Gate(l: String, op: Operator, r: String, res: String)
}

fn parse() {
  let assert Ok(contents) = simplifile.read("src/day24/input")
  let assert Ok(#(initial, eqs)) =
    contents |> string.trim |> string.split_once("\n\n")

  let initial_values =
    initial
    |> string.split("\n")
    |> list.fold(dict.new(), fn(acc, cur) {
      let assert Ok(#(var, val)) = cur |> string.split_once(": ")
      let assert Ok(val) = int.parse(val)
      acc |> dict.insert(var, val)
    })

  let gates =
    eqs
    |> string.split("\n")
    |> list.fold([], fn(acc, cur) {
      let assert [l, op, r, _, res] = cur |> string.split(" ")
      let assert Ok(op) = operator(op)
      [Gate(l, op, r, res), ..acc]
    })

  #(initial_values, gates)
}

fn run_iter(values: Dict(String, Int), gates: List(Gate)) {
  use #(new_values, gates), eq <- list.fold(gates, #(dict.new(), []))
  let l = dict.get(values, eq.l)
  let r = dict.get(values, eq.r)
  case l, r {
    Ok(l), Ok(r) -> {
      let res = apply_op(l, eq.op, r)
      #(new_values |> dict.insert(eq.res, res), gates)
    }
    _, _ -> {
      #(new_values, [eq, ..gates])
    }
  }
}

fn solve(values: Dict(String, Int), gates: List(Gate)) {
  case gates {
    [] -> values
    eqs -> {
      let #(new_values, next_gates) = run_iter(values, eqs)
      solve(values |> dict.merge(new_values), next_gates)
    }
  }
}

fn value_bits(values: Dict(String, Int), char: String) {
  values
  |> dict.filter(fn(k, _) { k |> string.starts_with(char) })
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(b.0, a.0) })
  |> list.map(fn(x) { int.to_string(x.1) })
  |> string.join("")
  |> int.base_parse(2)
}

fn part1(input) {
  let #(values, gates) = input
  let values = solve(values, gates)

  let assert Ok(result) = value_bits(values, "z")
  result
}

fn find_gate(gates: List(Gate), input: String, op: Operator) {
  gates
  |> list.find(fn(gate) {
    { gate.l == input || gate.r == input } && gate.op == op
  })
}

fn valid_gate(gate: Gate, gates: List(Gate)) {
  case gate.res |> string.starts_with("z") {
    True -> {
      gate.op == Xor || gate.res == "z45"
    }
    False -> {
      let l_input =
        string.starts_with(gate.l, "x") || string.starts_with(gate.l, "y")
      let r_input =
        string.starts_with(gate.r, "x") || string.starts_with(gate.r, "y")
      case l_input, r_input {
        True, True -> {
          case gate.op {
            Or -> False
            And -> {
              find_gate(gates, gate.res, Or) |> result.is_ok
            }
            Xor -> {
              find_gate(gates, gate.res, Xor) |> result.is_ok
            }
          }
        }
        _, _ -> {
          gate.op != Xor
        }
      }
    }
  }
}

fn part2(input) {
  let #(_, gates) = input
  gates
  |> list.filter(fn(g) { !valid_gate(g, gates) })
  |> list.map(fn(g) { g.res })
  |> list.sort(string.compare)
  |> string.join(",")
}

pub fn main() {
  let input = parse()

  let p1 = fn() { part1(input) }
  let p2 = fn() { part2(input) }

  io.println(int.to_string(pocket_watch.simple("Part 1", p1)))
  io.debug(pocket_watch.simple("Part 2", p2))
}
