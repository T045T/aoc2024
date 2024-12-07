import gleam/int
import gleam/list
import gleam/result
import gleam/string
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
      let new_current = {
        use operator <- list.flat_map(operators)
        list.filter_map(current, fn(c) {
          case operator(c, arg) {
            x if x > goal -> Error(Nil)
            x -> Ok(x)
          }
        })
        |> list.filter(fn(x) { x <= goal })
      }
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
