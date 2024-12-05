import day_3
import day_4
import day_5
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import helpers

fn get_columns(lines: List(String)) {
  let get_tuples = fn(line: String) {
    let values =
      line
      |> string.split(on: " ")
      |> list.filter(helpers.not_empty)
      |> list.map(string.trim)
      |> list.map(int.base_parse(_, 10))
      |> list.map(result.unwrap(_, 0))

    case values {
      [left, right] -> #(left, right)
      _ -> #(0, 0)
    }
  }

  lines |> list.map(get_tuples) |> list.unzip
}

fn task_1(path: String) {
  let lines = helpers.load_non_empty_lines(path)

  // I thought I could be clever here, and re-order the additions, but the task wanted me
  // to calculate absolute distances, so the individual pairings actually matter...
  let #(left, right) = get_columns(lines)
  list.zip(list.sort(left, by: int.compare), list.sort(right, by: int.compare))
  |> list.map(fn(lr) { int.absolute_value(lr.1 - lr.0) })
  |> list.fold(0, fn(a, b) { a + b })
}

/// Similarity score:
/// 1. Break the file into two columns of integers
/// 2. Count how many times each number appears in the right column
/// 3. For each entry in the left column, multiply that number by
///    the times it appears in the right column
/// 4. Sum the numbers
fn task_2(path: String) {
  let lines = helpers.load_non_empty_lines(path)

  let #(left, right) = get_columns(lines)
  let increment = fn(v: Option(Int)) {
    case v {
      Some(x) -> x + 1
      None -> 1
    }
  }
  let counts =
    right
    |> list.fold(dict.new(), fn(acc, v) { dict.upsert(acc, v, increment) })
  left
  |> list.map(fn(x) {
    let count = counts |> dict.get(x) |> result.unwrap(0)
    x * count
  })
  |> list.fold(0, fn(a, b) { a + b })
}

// Day 2

// Returns true if `levels` are safe:
// * Values are strictly increasing or strictly decreasing
// * Values are at least 1 and at most 3 apart
//
// We can do this by differentiating `levels` and checking if
// * the numbers in levels' are all positive or all negative
// * none of the numbers in levels' has an absolute value outside the range (1,3)
fn levels_safe(levels: List(Int)) -> Bool {
  let diffs =
    list.window_by_2(levels)
    |> list.map(fn(lr) { lr.1 - lr.0 })
  { list.all(diffs, fn(x) { x > 0 }) || list.all(diffs, fn(x) { x < 0 }) }
  && list.all(diffs, fn(x) {
    let abs = int.absolute_value(x)
    abs >= 1 && abs <= 3
  })
}

// Returns true if `levels` are safe, or if any of the lists obtained by
// dropping one of the elements in `levels`are safe.
fn levels_safe_with_dampener(levels: List(Int)) -> Bool {
  case levels_safe(levels) {
    True -> True
    False -> {
      list.range(0, list.length(levels))
      |> list.map(drop_nth(levels, _))
      |> list.map(levels_safe)
      |> list.any(function.identity)
    }
  }
}

fn day_2_task_1(path: String) {
  let levels =
    helpers.load_non_empty_lines(path)
    |> list.map(string.split(_, on: " "))
    |> list.map(fn(levels_str) { list.map(levels_str, int.parse(_)) })
    |> list.map(result.values)

  levels
  |> list.map(levels_safe)
  |> list.filter(fn(x) { x })
  |> list.length
}

fn drop_nth(l: List(a), n: Int) {
  let #(front, back) = list.split(l, n)
  list.append(front, result.unwrap(list.rest(back), []))
}

fn day_2_task_2(path: String) {
  let levels =
    helpers.load_non_empty_lines(path)
    |> list.map(string.split(_, on: " "))
    |> list.map(fn(levels_str) { list.map(levels_str, int.parse(_)) })
    |> list.map(result.values)

  levels
  |> list.map(levels_safe_with_dampener)
  |> list.filter(fn(x) { x })
  |> list.length
}

pub fn main() {
  io.println("Example:")
  io.println("Task 1:")
  io.debug(task_1("data/example_1.txt"))
  io.println("Task 2:")
  io.debug(task_2("data/example_1.txt"))
  io.println("")
  io.println("Real Input:")
  io.println("Task 1:")
  io.debug(task_1("data/input_1.txt"))
  io.println("Task 2:")
  io.debug(task_2("data/input_1.txt"))

  io.println("\nDay 2")
  io.println("Task 1:")
  io.debug(day_2_task_1("data/example_2.txt"))
  io.debug(day_2_task_1("data/input_2.txt"))
  io.debug(day_2_task_2("data/example_2.txt"))
  io.debug(day_2_task_2("data/input_2.txt"))

  // Commented because it is sloooow :(
  // io.println("\nDay 3")
  // io.println("Task 1:")
  // io.debug(day_3.task_1("data/example_3.txt"))
  // io.debug(day_3.task_1("data/input_3.txt"))
  // io.debug(day_3.task_2("data/example_3b.txt"))
  // io.debug(day_3.task_2("data/input_3.txt"))

  io.println("\nDay 4")
  io.println("Task 1:")
  let _ = io.debug(day_4.task_1("data/example_4.txt"))
  let _ = io.debug(day_4.task_1("data/input_4.txt"))
  io.println("Task 2:")
  let _ = io.debug(day_4.task_2("data/example_4.txt"))
  let _ = io.debug(day_4.task_2("data/input_4.txt"))

  io.println("\nDay 5")
  io.println("Task 1:")
  let _ = io.debug(day_5.task_1("data/example_5.txt"))
  let _ = io.debug(day_5.task_1("data/input_5.txt"))
  io.println("Task 2:")
  let _ = io.debug(day_5.task_2("data/example_5.txt"))
  let _ = io.debug(day_5.task_2("data/input_5.txt"))
}
