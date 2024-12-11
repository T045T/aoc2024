import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/yielder

import helpers

pub fn task_1(filepath: String) {
  let numbers =
    helpers.load(filepath)
    |> helpers.words()
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))

  yielder.iterate(numbers, apply_rules)
  |> yielder.take(26)
  |> yielder.last()
  |> result.unwrap([])
  |> list.length()
}

pub fn task_2(filepath: String) {
  let numbers =
    helpers.load(filepath)
    |> helpers.words()
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
    |> list.fold(dict.new(), fn(acc, n) { inc(acc, n, 1) })

  yielder.iterate(numbers, apply_rules_with_count)
  |> yielder.take(76)
  |> yielder.last()
  |> result.unwrap(dict.new())
  |> dict.values()
  |> int.sum()
}

fn apply_rules(numbers: List(Int)) -> List(Int) {
  // io.debug(numbers)
  let assert Error(Nil) = list.find(numbers, fn(x) { x == -1 })
  list.fold(numbers, [], fn(acc, number) {
    use <- bool.guard(when: number == 0, return: [1, ..acc])
    let digits =
      int.digits(number, 10)
      |> result.unwrap([])
    let len = list.length(digits)
    use <- bool.guard(when: int.is_odd(len), return: [number * 2024, ..acc])
    let #(left_digits, right_digits) = list.split(digits, len / 2)
    let left = int.undigits(left_digits, 10) |> result.unwrap(-1)
    let right = int.undigits(right_digits, 10) |> result.unwrap(-1)

    // "reversed" because we reverse the entire list at the end
    [right, left, ..acc]
  })
  |> list.reverse()
}

fn inc(dict, number, count) {
  dict.upsert(dict, number, fn(maybe) { option.unwrap(maybe, 0) + count })
}

fn apply_rules_with_count(numbers: Dict(Int, Int)) -> Dict(Int, Int) {
  // io.debug(numbers)
  use acc, number, count <- dict.fold(numbers, dict.new())

  use <- bool.guard(when: number == 0, return: inc(acc, 1, count))
  let digits =
    int.digits(number, 10)
    |> result.unwrap([])
  let len = list.length(digits)
  use <- bool.guard(
    when: int.is_odd(len),
    return: inc(acc, number * 2024, count),
  )
  let #(left_digits, right_digits) = list.split(digits, len / 2)
  let left = int.undigits(left_digits, 10) |> result.unwrap(-1)
  let right = int.undigits(right_digits, 10) |> result.unwrap(-1)

  inc(acc, left, count) |> inc(right, count)
}
