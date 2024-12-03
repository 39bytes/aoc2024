import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/result
import simplifile

pub type Instruction {
  Do
  Dont
  Mul(Int, Int)
}

fn is_do(ins: Instruction) {
  case ins {
    Do -> True
    _ -> False
  }
}

fn is_dont(ins: Instruction) {
  case ins {
    Dont -> True
    _ -> False
  }
}

fn not(f: fn(a) -> Bool) {
  fn(x) { !f(x) }
}

fn parse(
  contents: String,
  pattern: regexp.Regexp,
  mul_pattern: regexp.Regexp,
) -> List(Instruction) {
  regexp.scan(pattern, contents)
  |> list.filter_map(fn(match) {
    case match.submatches {
      [Some(_)] -> Ok(Do)
      [None, Some(_)] -> Ok(Dont)
      [None, None, Some(s)] -> parse_mul(s, mul_pattern)
      _ -> Error(Nil)
    }
  })
}

fn parse_mul(s: String, pattern: regexp.Regexp) -> Result(Instruction, Nil) {
  use nums <- result.try(
    regexp.scan(pattern, s)
    |> list.map(fn(match) {
      match.submatches
      |> option.all
      |> option.to_result(Nil)
      |> result.map(fn(submatches) { submatches |> list.filter_map(int.parse) })
    })
    |> result.all,
  )

  case nums {
    [[x, y]] -> Ok(Mul(x, y))
    _ -> Error(Nil)
  }
}

fn eval_muls(instructions: List(Instruction)) {
  instructions
  |> list.filter_map(fn(ins) {
    case ins {
      Mul(x, y) -> Ok(x * y)
      _ -> Error(Nil)
    }
  })
  |> int.sum
}

fn part1(instructions: List(Instruction)) {
  eval_muls(instructions)
}

fn eval(instructions: List(Instruction)) {
  case instructions {
    [] -> 0
    [Do, ..instructions] -> {
      let #(muls, rest) = instructions |> list.split_while(not(is_dont))
      eval_muls(muls) + eval(rest)
    }
    [Dont, ..instructions] -> {
      instructions |> list.drop_while(not(is_do)) |> eval
    }
    _ -> panic
  }
}

fn part2(instructions: List(Instruction)) {
  eval(instructions)
}

pub fn main() {
  let assert Ok(contents) = simplifile.read("src/day03/input")
  let assert Ok(pattern) =
    regexp.from_string("(do\\(\\))|(don't\\(\\))|(mul\\(\\d+,\\d+\\))")
  let assert Ok(mul_pattern) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")

  let instructions = [Do, ..parse(contents, pattern, mul_pattern)]

  io.println("Part 1: " <> int.to_string(part1(instructions)))
  io.println("Part 2: " <> int.to_string(part2(instructions)))
}
