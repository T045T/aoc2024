import gleam/list
import gleam/string

import simplifile

pub fn not_empty(s: String) {
  !string.is_empty(s)
}

pub fn load(path: String) {
  let assert Ok(file_string) = simplifile.read(path)
  file_string
}

pub fn load_non_empty_lines(path: String) {
  path
  |> load()
  |> string.split(on: "\n")
  |> list.filter(not_empty)
}

pub fn lines(input: String) {
  string.split(input, on: "\n")
}

pub fn words(line: String) {
  line
  |> string.split(on: " ")
  |> list.filter(not_empty)
}

pub fn sum(l: List(Int)) {
  list.fold(l, 0, fn(a, b) { a + b })
}
