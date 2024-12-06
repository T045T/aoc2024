import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import helpers

type Rule =
  fn(Int, Int) -> order.Order

pub fn task_1(path: String) {
  let assert Ok(#(rules_str, updates_str)) =
    helpers.load(path)
    |> string.split_once(on: "\n\n")

  let rules: List(Rule) = parse_rules(rules_str)
  let updates: List(List(Int)) = parse_updates(updates_str)

  updates
  |> list.map(already_sorted(_, omnirule(rules)))
  |> option.values()
  |> list.map(find_center)
  |> result.values
  |> list.fold(0, fn(a, b) { a + b })
}

pub fn task_2(path: String) {
  let assert Ok(#(rules_str, updates_str)) =
    helpers.load(path)
    |> string.split_once(on: "\n\n")

  let rules: List(Rule) = parse_rules(rules_str)
  let updates: List(List(Int)) = parse_updates(updates_str)

  updates
  |> list.map(not_sorted(_, omnirule(rules)))
  |> option.values()
  |> list.map(find_center)
  |> result.values
  |> list.fold(0, fn(a, b) { a + b })
}

fn parse_rules(input: String) -> List(Rule) {
  input
  |> helpers.lines()
  |> list.filter(helpers.not_empty)
  |> list.map(parse_rule)
}

fn parse_rule(input: String) -> Rule {
  let assert Ok(#(lhs_str, rhs_str)) = string.split_once(input, on: "|")
  let assert Ok(lhs) = int.parse(string.trim(lhs_str))
  let assert Ok(rhs) = int.parse(string.trim(rhs_str))

  fn(a: Int, b: Int) -> order.Order {
    case a, b {
      _, _ if a == lhs && b == rhs -> order.Lt
      _, _ if a == rhs && b == lhs -> order.Gt
      _, _ -> order.Eq
    }
  }
}

fn parse_updates(input: String) -> List(List(Int)) {
  input
  |> helpers.lines()
  |> list.filter(helpers.not_empty)
  |> list.map(parse_update)
}

fn parse_update(input: String) -> List(Int) {
  input
  |> string.split(on: ",")
  |> list.map(string.trim)
  |> list.map(int.parse)
  |> result.values
}

fn already_sorted(l: List(Int), rule: Rule) -> option.Option(List(Int)) {
  let sorted =
    list.zip(l, list.sort(l, rule))
    |> list.all(fn(a_b) { a_b.0 == a_b.1 })
  case sorted {
    True -> option.Some(l)
    False -> option.None
  }
}

fn omnirule(rules: List(Rule)) -> Rule {
  fn(a: Int, b: Int) -> order.Order {
    let applicable_rule_results =
      list.map(rules, fn(rule) { rule(a, b) })
      |> list.filter(fn(x: order.Order) {
        case x {
          order.Eq -> False
          _ -> True
        }
      })

    case list.first(applicable_rule_results) {
      Ok(o) -> o
      _ -> order.Eq
    }
  }
}

fn find_center(l: List(a)) -> Result(a, Nil) {
  let half_length = list.length(l) / 2
  l
  |> list.drop(half_length)
  |> list.first
}

fn not_sorted(l: List(Int), rule: Rule) -> option.Option(List(Int)) {
  let sorted = list.sort(l, rule)
  let same =
    list.zip(l, sorted)
    |> list.all(fn(a_b) { a_b.0 == a_b.1 })
  case same {
    True -> option.None
    False -> option.Some(sorted)
  }
}
