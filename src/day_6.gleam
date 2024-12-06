import day_4.{type Vec2, load_map, vec_add, vec_mag_sq, vec_sub}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}

type Position {
  Position(xy: Vec2, facing: Vec2)
}

pub fn task_1(filepath: String) {
  let map = load_map(filepath)
  let start_pos = find_guard(map)
  path(map, start_pos)
  |> list.map(fn(pos) { pos.xy })
  |> list.unique()
  |> list.length()
}

pub fn task_2(filepath: String) {
  let map = load_map(filepath)
  let start_pos = find_guard(map)

  find_possible_cycles_2(map, start_pos)
  |> list.unique
  |> list.length
}

fn find_guard(map: Dict(Vec2, String)) -> Position {
  let assert Some(pos) =
    dict.fold(
      map,
      option.None,
      fn(acc: Option(Position), where: Vec2, what: String) {
        use <- option.lazy_or(acc)
        case what {
          "^" -> Some(Position(xy: where, facing: #(0, -1)))
          _ -> None
        }
      },
    )
  pos
}

fn path(map: Dict(Vec2, String), start: Position) -> List(Position) {
  do_path(map, start, [])
}

fn do_path(
  map: Dict(Vec2, String),
  current: Position,
  acc: List(Position),
) -> List(Position) {
  case dict.get(map, vec_add(current.xy, current.facing)) {
    Error(_) -> list.reverse([current, ..acc])
    Ok("#") ->
      do_path(map, Position(..current, facing: turn_right(current.facing)), [
        current,
        ..acc
      ])
    _ ->
      do_path(
        map,
        Position(..current, xy: vec_add(current.xy, current.facing)),
        [current, ..acc],
      )
  }
}

fn turn_right(direction: Vec2) {
  #(-direction.1, direction.0)
}

fn find_possible_cycles_2(
  map: Dict(Vec2, String),
  start: Position,
) -> List(Vec2) {
  let obstacles =
    map
    |> dict.filter(fn(_, v) { v == "#" })
    |> dict.keys()
    |> set.from_list
  // Drop the last element from path_taken.
  // By definition, that is the last position before leaving the grid,
  // so we can't add an obstacle in front of it.
  //
  // On the flip side, we don't have to worry about that problem anywhere else.
  // If the space in front of our guard was off the grid, that would mean we're
  // at the last position already (because we stop when the guard leaves the grid)
  let path_taken =
    path(map, start)
    |> list.reverse()
    |> list.drop(1)
    |> list.reverse()

  do_find_possible_cycles_2(obstacles, path_taken, set.new(), [])
}

fn do_find_possible_cycles_2(
  obstacles: Set(Vec2),
  path_taken: List(Position),
  previous_steps: Set(Position),
  acc: List(Vec2),
) -> List(Vec2) {
  case path_taken {
    [] -> acc
    [current_pos, ..rest_path] -> {
      let new_previous_steps = set.insert(previous_steps, current_pos)
      let new_obstacle = vec_add(current_pos.xy, current_pos.facing)
      let can_put_obstacle =
        !{
          {
            // If previous_steps contains the space where we want to put an
            // obstacle, we can't do that. If there was an obstacle there, we
            // wouldn't be able to get *here*!
            previous_steps
            |> set.map(fn(pos) { pos.xy })
            |> set.contains(new_obstacle)
          }
          || set.contains(obstacles, new_obstacle)
        }
      use <- bool.guard(
        when: !can_put_obstacle,
        return: do_find_possible_cycles_2(
          obstacles,
          rest_path,
          new_previous_steps,
          acc,
        ),
      )
      let causes_cycle =
        detect_cycle(
          current_pos,
          set.insert(obstacles, new_obstacle),
          previous_steps,
        )
      use <- bool.guard(
        when: causes_cycle,
        return: do_find_possible_cycles_2(
          obstacles,
          rest_path,
          new_previous_steps,
          [new_obstacle, ..acc],
        ),
      )
      do_find_possible_cycles_2(obstacles, rest_path, new_previous_steps, acc)
    }
  }
}

fn detect_cycle(p: Position, obstacles: Set(Vec2), seen: Set(Position)) -> Bool {
  use <- bool.guard(when: set.contains(seen, p), return: True)
  case move(p, obstacles) {
    Ok(new_p) -> detect_cycle(new_p, obstacles, set.insert(seen, p))
    _ -> False
  }
}

fn move(p: Position, obstacles: Set(Vec2)) -> Result(Position, Nil) {
  use obstacle <- result.try(find_bonk(p, obstacles))
  Ok(Position(vec_sub(obstacle, p.facing), turn_right(p.facing)))
}

fn find_bonk(p: Position, obstacles: Set(Vec2)) -> Result(Vec2, Nil) {
  obstacles
  |> set.filter(fn(obstacle) { can_hit(p.xy, obstacle, p.facing) })
  |> set.to_list()
  |> list.sort(by_distance_to(p.xy))
  |> list.first
}

fn by_distance_to(reference: Vec2) -> fn(Vec2, Vec2) -> order.Order {
  fn(lhs: Vec2, rhs: Vec2) {
    int.compare(
      vec_mag_sq(vec_sub(lhs, reference)),
      vec_mag_sq(vec_sub(rhs, reference)),
    )
  }
}

fn can_hit(p: Vec2, target: Vec2, direction: Vec2) -> Bool {
  let dist = vec_sub(target, p)
  case direction, dist {
    #(0, y), #(0, y2) if y * y2 > 0 -> True
    #(x, 0), #(x2, 0) if x * x2 > 0 -> True
    _, _ -> False
  }
}
