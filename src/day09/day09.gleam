import gleam/bool
import gleam/deque.{type Deque}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn parse() -> List(Int) {
  let assert Ok(contents) = simplifile.read("src/day09/input")
  let assert Ok(nums) =
    contents
    |> string.trim
    |> string.to_graphemes
    |> list.map(int.parse)
    |> result.all
  nums
}

fn take_alternate(xs: List(a)) -> List(a) {
  take_alternate_rec(xs, [])
}

fn take_alternate_rec(xs: List(a), acc: List(a)) {
  case xs {
    [] -> list.reverse(acc)
    [x] -> take_alternate_rec([], [x, ..acc])
    [x, _, ..xs] -> take_alternate_rec(xs, [x, ..acc])
  }
}

fn compact(files: Deque(#(Int, Int)), empty: List(Int)) {
  compact_rec(files, empty, True, 0, 0, [])
}

fn add_block(file: Int, id: Int, disk: List(Int)) {
  list.repeat(id, file)
  |> list.append(disk)
}

fn compact_rec(
  files: Deque(#(Int, Int)),
  empty: List(Int),
  existing: Bool,
  cur_blocks: Int,
  id: Int,
  acc: List(Int),
) -> List(Int) {
  case existing {
    True -> {
      case deque.pop_front(files) {
        Error(_) -> add_block(cur_blocks, id, acc)
        Ok(#(#(file, existing_id), rest)) ->
          compact_rec(
            rest,
            empty,
            False,
            cur_blocks,
            id,
            add_block(file, existing_id, acc),
          )
      }
    }
    False -> {
      case cur_blocks, deque.pop_back(files), empty {
        0, Error(_), _ -> acc
        0, Ok(#(#(file, id), rest)), [space, ..slots] -> {
          let taken = int.min(space, file)
          let empty = case taken == space {
            True -> slots
            False -> [space - taken, ..slots]
          }
          compact_rec(
            rest,
            empty,
            taken == space,
            file - taken,
            id,
            add_block(taken, id, acc),
          )
        }
        x, _, [space, ..slots] -> {
          let taken = int.min(space, x)
          let empty = case taken == space {
            True -> slots
            False -> [space - taken, ..slots]
          }
          compact_rec(
            files,
            empty,
            taken == space,
            x - taken,
            id,
            add_block(taken, id, acc),
          )
        }
        _, _, _ -> panic
      }
    }
  }
}

fn part1(files: Deque(#(Int, Int)), empty: List(Int)) -> Int {
  compact(files, empty)
  |> list.reverse
  |> list.index_map(int.multiply)
  |> int.sum
}

type Block {
  File(size: Int, id: Int)
  Empty(size: Int)
}

fn move_file(
  disk: Deque(Block),
  file_size: Int,
  file_id: Int,
) -> Result(Deque(Block), Nil) {
  use #(block, rest) <- result.try(deque.pop_front(disk))
  case block {
    File(..) -> {
      use rest <- result.try(move_file(rest, file_size, file_id))
      Ok(deque.push_front(rest, block))
    }
    Empty(size) -> {
      use <- bool.guard(
        size > file_size,
        rest
          |> deque.push_front(Empty(size - file_size))
          |> deque.push_front(File(file_size, file_id))
          |> Ok,
      )
      use <- bool.guard(
        size == file_size,
        rest
          |> deque.push_front(File(file_size, file_id))
          |> Ok,
      )
      use rest <- result.try(move_file(rest, file_size, file_id))
      Ok(deque.push_front(rest, block))
    }
  }
}

fn go(disk: Deque(Block), acc: List(Block)) -> List(Block) {
  case deque.pop_back(disk) {
    Error(Nil) -> acc
    Ok(#(block, rest)) -> {
      case block {
        Empty(_) -> go(rest, [block, ..acc])
        File(size, id) -> {
          case move_file(rest, size, id) {
            Ok(moved) -> go(moved, [Empty(size), ..acc])
            Error(Nil) -> go(rest, [block, ..acc])
          }
        }
      }
    }
  }
}

fn expand(disk: List(Block), acc: List(Int)) {
  case disk {
    [] -> list.reverse(acc)
    [block, ..rest] -> {
      case block {
        File(size, id) -> expand(rest, add_block(size, id, acc))
        Empty(size) -> expand(rest, add_block(size, 0, acc))
      }
    }
  }
}

fn part2(disk: Deque(Block)) {
  go(disk, [])
  |> expand([])
  |> list.index_map(int.multiply)
  |> int.sum
}

pub fn main() {
  let disk_map = parse()

  let assert [_, ..tail] = disk_map
  let files =
    take_alternate(disk_map)
    |> list.index_map(fn(x, i) { #(x, i) })
    |> deque.from_list
  let empty = take_alternate(tail)

  io.println("Part 1: " <> int.to_string(part1(files, empty)))

  let disk =
    disk_map
    |> list.index_map(fn(x, i) {
      case i % 2 == 0 {
        True -> File(x, i / 2)
        False -> Empty(x)
      }
    })
    |> deque.from_list

  io.println("Part 2: " <> int.to_string(part2(disk)))
}
