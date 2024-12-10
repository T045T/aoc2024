import day_4.{type Vec2, load_map, vec_add, vec_neg, vec_sub}
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/string_tree
import gleam/yielder

import helpers

type FileSystemItem {
  File(length: Int, id: Int)
  Space(length: Int)
}

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
