import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array}
import pocket_watch
import simplifile

type Cpu {
  Cpu(a: Int, b: Int, c: Int, pc: Int, output: List(Int))
}

fn parse_register(line) {
  use #(_, num) <- result.try(string.split_once(line, ": "))
  int.parse(num)
}

fn parse() -> #(Cpu, Array(Int)) {
  let assert Ok(contents) = simplifile.read("src/day17/input")
  let assert [line1, line2, line3, _, line5] =
    contents |> string.trim |> string.split("\n")
  let assert Ok(a) = parse_register(line1)
  let assert Ok(b) = parse_register(line2)
  let assert Ok(c) = parse_register(line3)

  let assert Ok(#(_, program)) = line5 |> string.split_once(": ")
  let assert Ok(program) =
    program |> string.split(",") |> list.map(int.parse) |> result.all

  #(Cpu(a, b, c, 0, []), glearray.from_list(program))
}

type Combo {
  Lit(Int)
  A
  B
  C
}

fn combo(operand: Int) {
  case operand {
    0 | 1 | 2 | 3 -> Lit(operand)
    4 -> A
    5 -> B
    6 -> C
    _ -> panic as "invalid combo operand"
  }
}

fn resolve_combo(combo: Combo, cpu: Cpu) {
  case combo {
    Lit(val) -> val
    A -> cpu.a
    B -> cpu.b
    C -> cpu.c
  }
}

type Instruction {
  Adv(Combo)
  Bxl(Int)
  Bst(Combo)
  Jnz(Int)
  Bxc
  Out(Combo)
  Bdv(Combo)
  Cdv(Combo)
}

fn instruction(opcode: Int, operand: Int) -> Instruction {
  case opcode {
    0 -> Adv(combo(operand))
    1 -> Bxl(operand)
    2 -> Bst(combo(operand))
    3 -> Jnz(operand)
    4 -> Bxc
    5 -> Out(combo(operand))
    6 -> Bdv(combo(operand))
    7 -> Cdv(combo(operand))
    _ -> panic as "invalid opcode"
  }
}

fn read_instruction(cpu: Cpu, program: Array(Int)) -> Result(Instruction, Nil) {
  use opcode <- result.map(glearray.get(program, cpu.pc))
  let assert Ok(operand) = glearray.get(program, cpu.pc + 1)

  instruction(opcode, operand)
}

fn run(cpu: Cpu, program: Array(Int)) -> #(Cpu, Bool) {
  case read_instruction(cpu, program) {
    Error(Nil) -> #(cpu, True)
    Ok(instruction) -> {
      let cpu = case instruction {
        Adv(op) ->
          Cpu(
            ..cpu,
            a: int.bitwise_shift_right(cpu.a, resolve_combo(op, cpu)),
            pc: cpu.pc + 2,
          )
        Bxl(op) ->
          Cpu(..cpu, b: int.bitwise_exclusive_or(cpu.b, op), pc: cpu.pc + 2)
        Bst(op) -> Cpu(..cpu, b: resolve_combo(op, cpu) % 8, pc: cpu.pc + 2)
        Jnz(op) ->
          case cpu.a {
            0 -> Cpu(..cpu, pc: cpu.pc + 2)
            _ -> Cpu(..cpu, pc: op)
          }
        Bxc ->
          Cpu(..cpu, b: int.bitwise_exclusive_or(cpu.b, cpu.c), pc: cpu.pc + 2)
        Out(op) ->
          Cpu(
            ..cpu,
            output: [resolve_combo(op, cpu) % 8, ..cpu.output],
            pc: cpu.pc + 2,
          )
        Bdv(op) ->
          Cpu(
            ..cpu,
            b: int.bitwise_shift_right(cpu.a, resolve_combo(op, cpu)),
            pc: cpu.pc + 2,
          )
        Cdv(op) ->
          Cpu(
            ..cpu,
            c: int.bitwise_shift_right(cpu.a, resolve_combo(op, cpu)),
            pc: cpu.pc + 2,
          )
      }

      #(cpu, False)
    }
  }
}

fn part1(cpu: Cpu, program: Array(Int)) -> String {
  case run(cpu, program) {
    #(cpu, True) ->
      cpu.output |> list.reverse |> list.map(int.to_string) |> string.join(",")
    #(cpu, False) -> part1(cpu, program)
  }
}

// Bst(A),        B = A & 0b111
// Bxl(2),        B = B ^ 0b010
// Cdv(B),        C = A >> B   
// Bxl(3),        B = B ^ 0b011
// Bxc,           B = B ^ C    
// Out(B),        output B     
// Adv(Lit(3)),   A = A >> 3   
// Jnz(0)         loop

fn run_til_output(cpu: Cpu, program: Array(Int)) -> Int {
  case run(cpu, program) {
    #(Cpu(output: [x], ..), _) -> x
    #(cpu, False) -> run_til_output(cpu, program)
    #(_, True) -> panic
  }
}

fn dfs(cpu: Cpu, program: Array(Int), targets: List(Int)) -> Result(Int, Nil) {
  case targets {
    [] -> Ok(cpu.a)
    [target, ..targets] -> {
      case solve_iter(cpu, program, target) {
        [] -> Error(Nil)
        possible ->
          list.find_map(possible, fn(bits) {
            dfs(
              Cpu(
                ..cpu,
                a: cpu.a |> int.bitwise_shift_left(3) |> int.bitwise_or(bits),
              ),
              program,
              targets,
            )
          })
      }
    }
  }
}

fn solve_iter(cpu: Cpu, program: Array(Int), target: Int) -> List(Int) {
  list.range(0, 7)
  |> list.filter(fn(bits) {
    run_til_output(
      Cpu(..cpu, a: cpu.a |> int.bitwise_shift_left(3) |> int.bitwise_or(bits)),
      program,
    )
    == target
  })
}

fn part2(cpu: Cpu, program: Array(Int)) {
  let targets = program |> glearray.to_list |> list.reverse
  let assert Ok(ans) = dfs(Cpu(..cpu, a: 0), program, targets)
  ans
}

pub fn main() {
  let #(cpu, program) = parse()

  let p1 = fn() { part1(cpu, program) }
  let p2 = fn() { part2(cpu, program) }

  io.println(pocket_watch.simple("Part 1", p1))
  io.println(int.to_string(pocket_watch.simple("Part 2", p2)))
}
