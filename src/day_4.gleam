import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree
import helpers

pub type Vec2 =
  #(Int, Int)

fn parse_line(line: String, row: Int, col: Int, map: Dict(Vec2, String)) {
  case string.pop_grapheme(line) {
    Ok(#(c, rest)) ->
      parse_line(rest, row, col + 1, dict.insert(map, #(col, row), c))
    _ -> map
  }
}

pub fn vec_add(lhs: Vec2, rhs: Vec2) -> Vec2 {
  #(lhs.0 + rhs.0, lhs.1 + rhs.1)
}

pub fn vec_sub(lhs: Vec2, rhs: Vec2) -> Vec2 {
  #(lhs.0 - rhs.0, lhs.1 - rhs.1)
}

pub fn vec_dot(lhs: Vec2, rhs: Vec2) -> Int {
  lhs.0 * rhs.0 + lhs.1 * rhs.1
}

pub fn vec_mag_sq(v: Vec2) -> Int {
  v.0 * v.0 + v.1 * v.1
}

pub fn vec_neg(v: Vec2) -> Vec2 {
  #(v.0 * -1, v.1 * -1)
}

fn get_word(
  map: Dict(Vec2, String),
  start: Vec2,
  direction: Vec2,
  length: Int,
  acc: string_tree.StringTree,
) -> Result(String, Nil) {
  case length {
    0 -> Ok(string_tree.to_string(acc))
    _ -> {
      use c <- result.try(dict.get(map, start))
      get_word(
        map,
        vec_add(start, direction),
        direction,
        length - 1,
        string_tree.append(acc, c),
      )
    }
  }
}

const directions = [
  #(0, -1), #(0, 1), #(-1, 0), #(1, 0), #(-1, -1), #(1, -1), #(-1, 1), #(1, 1),
]

const diagonals = [#(-1, -1), #(1, -1), #(-1, 1), #(1, 1)]

fn count_words(map: Dict(Vec2, String), start: Vec2, word: String) {
  directions
  |> list.map(get_word(map, start, _, string.length(word), string_tree.new()))
  |> result.values()
  |> list.filter(fn(s) { s == word })
  |> list.length()
}

fn count_words_offset(map: Dict(Vec2, String), start: Vec2) {
  let mases =
    diagonals
    |> list.map(fn(direction) {
      get_word(
        map,
        vec_add(start, vec_neg(direction)),
        direction,
        3,
        string_tree.new(),
      )
    })
    |> result.values()
    |> list.filter(fn(s) { s == "MAS" })
    |> list.length()
  case mases > 1 {
    True -> 1
    False -> 0
  }
}

fn count_xmas(map: Dict(Vec2, String)) {
  dict.keys(map)
  |> list.map(count_words(map, _, "XMAS"))
  |> list.reduce(fn(a, b) { a + b })
}

fn count_x_mas(map: Dict(Vec2, String)) {
  dict.keys(map)
  |> list.map(count_words_offset(map, _))
  |> list.reduce(fn(a, b) { a + b })
}

pub fn load_map(path: String) -> Dict(Vec2, String) {
  helpers.load_non_empty_lines(path)
  |> list.index_map(fn(line, index) { parse_line(line, index, 0, dict.new()) })
  |> list.reduce(dict.merge)
  |> result.unwrap(dict.new())
}

pub fn task_1(path: String) {
  load_map(path)
  |> count_xmas()
}

pub fn task_2(path: String) {
  helpers.load_non_empty_lines(path)
  |> list.index_map(fn(line, index) { parse_line(line, index, 0, dict.new()) })
  |> list.reduce(dict.merge)
  |> result.unwrap(dict.new())
  |> count_x_mas()
}
