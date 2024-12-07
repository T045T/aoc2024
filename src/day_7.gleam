import day_4.{type Vec2, load_map, vec_add, vec_mag_sq, vec_sub}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import helpers

pub fn task_1(filepath: String) {
  helpers.load_non_empty_lines(filepath)
  |> list.map(parse_line)
  |> list.filter(plausible)
  |> list.map(fn(x) { x.0 })
  |> int.sum()
}

pub fn task_2(filepath: String) {
  helpers.load_non_empty_lines(filepath)
  |> list.map(parse_line)
  |> list.filter(plausible_2)
  |> list.map(fn(x) { x.0 })
  |> int.sum()
}

fn parse_line(line: String) {
  let assert [first, ..rest] = helpers.words(line)
  #(
    result.unwrap(int.parse(string.drop_end(first, 1)), 0),
    list.map(rest, int.parse)
      |> list.map(result.unwrap(_, 0)),
    // |> yielder.from_list,
  )
}

fn plausible(equation) {
  case equation {
    #(goal, [first_arg, ..args]) ->
      do_plausible(goal, args, [add, mul], [first_arg])
    _ -> False
  }
}

fn do_plausible(goal, args, operators, current) {
  case args {
    [] -> list.any(current, fn(x) { x == goal })
    [arg, ..rest] -> {
      let new_current =
        {
          use operator <- list.map(operators)
          use c <- list.map(current)
          operator(c, arg)
        }
        |> list.flatten()
        |> list.filter(fn(x) { x <= goal })
      do_plausible(goal, rest, operators, new_current)
    }
  }
}

fn plausible_2(equation) {
  case equation {
    #(goal, [first_arg, ..args]) ->
      do_plausible(goal, args, [add, mul, concat], [first_arg])
    _ -> False
  }
}

fn add(lhs, rhs) {
  lhs + rhs
}

fn mul(lhs, rhs) {
  lhs * rhs
}

fn concat(lhs, rhs) {
  string.append(int.to_string(lhs), int.to_string(rhs))
  |> int.parse()
  |> result.unwrap(0)
}
