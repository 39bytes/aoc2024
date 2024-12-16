import lib/grid.{type Point}

pub type Direction {
  Up
  Down
  Right
  Left
}

pub fn dir_to_vec(direction: Direction) -> Point {
  case direction {
    Right -> #(0, 1)
    Left -> #(0, -1)
    Up -> #(-1, 0)
    Down -> #(1, 0)
  }
}
