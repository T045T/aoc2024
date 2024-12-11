import day_4.{type Vec2, load_map, vec_add}
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/yielder

pub fn task_1(filepath: String) {
  let m =
    load_map(filepath)
    |> dict.map_values(fn(_, v) {
      int.parse(v)
      |> result.unwrap(-1)
    })
  let trailheads =
    dict.filter(m, fn(_, v) { v == 0 })
    |> dict.keys()
    |> list.map(fn(x) { [x] })
  yielder.iterate(trailheads, fn(paths: List(List(Vec2))) {
    list.map(paths, fn(path: List(Vec2)) {
      list.map(path, find_plus_one_neighbors(m, _))
      |> list.flatten()
    })
  })
  |> yielder.take(10)
  |> yielder.last()
  |> result.unwrap([])
  |> list.map(list.unique)
  |> list.map(list.length)
  |> int.sum()
}

pub fn task_2(filepath: String) {
  let m =
    load_map(filepath)
    |> dict.map_values(fn(_, v) {
      int.parse(v)
      |> result.unwrap(-1)
    })
  let trailheads =
    dict.filter(m, fn(_, v) { v == 0 })
    |> dict.keys()
    |> list.map(fn(x) { [x] })
  yielder.iterate(trailheads, fn(paths: List(List(Vec2))) {
    list.map(paths, fn(path: List(Vec2)) {
      list.map(path, find_plus_one_neighbors(m, _))
      |> list.flatten()
    })
  })
  |> yielder.take(10)
  |> yielder.last()
  |> result.unwrap([])
  |> list.map(list.length)
  |> int.sum()
}

const cardinal_directions = [#(0, -1), #(0, 1), #(-1, 0), #(1, 0)]

fn find_plus_one_neighbors(m, location: Vec2) -> List(Vec2) {
  case dict.get(m, location) {
    Error(_) -> []
    Ok(start_height) -> {
      list.map(cardinal_directions, vec_add(location, _))
      |> list.filter(fn(neighbor) {
        case dict.get(m, neighbor) {
          Ok(neighbor_height) if neighbor_height == 1 + start_height -> True
          _ -> False
        }
      })
    }
  }
}
