import day_4.{type Vec2, vec_add, vec_neg, vec_sub}
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/string_tree
import gleam/yielder
import helpers

pub fn task_1(filepath: String) {
  let map = day_4.load_map(filepath)
  let antinodes =
    group_nodes(map)
    |> dict.values()
    |> list.map(fn(nodes: List(Vec2)) {
      list.combination_pairs(nodes)
      |> list.map(find_antinodes_in_bounds(_, map))
      |> list.flatten()
    })
    |> list.flatten()
  // print_map(map)
  // let map_with_antinodes =
  //   list.fold(antinodes, map, fn(acc, antinode) {
  //     dict.insert(acc, antinode, "#")
  //   })
  // print_map(map_with_antinodes)
  antinodes
  |> list.unique()
  |> list.length()
}

pub fn task_2(filepath: String) {
  let map = day_4.load_map(filepath)
  let antinodes =
    group_nodes(map)
    |> dict.values()
    |> list.map(fn(nodes: List(Vec2)) -> Set(Vec2) {
      list.combination_pairs(nodes)
      |> list.map(find_antinodes_in_bounds_2(_, map))
      |> list.fold(set.new(), set.union)
    })
    |> list.fold(set.new(), set.union)
    |> set.to_list()
  // print_map(map)
  // let map_with_antinodes =
  //   list.fold(antinodes, map, fn(acc, antinode) {
  //     dict.insert(acc, antinode, "#")
  //   })
  // print_map(map_with_antinodes)
  antinodes
  |> list.unique()
  |> list.length()
}

fn group_nodes(map: Dict(Vec2, String)) -> Dict(String, List(Vec2)) {
  use acc, key, value <- dict.fold(map, dict.new())
  case value {
    "." -> acc
    _ ->
      dict.upsert(acc, value, fn(maybe) { [key, ..option.unwrap(maybe, [])] })
  }
}

fn find_antinodes_in_bounds(
  pair: #(Vec2, Vec2),
  map: Dict(Vec2, String),
) -> List(Vec2) {
  let #(a, b) = pair
  let dist = day_4.vec_sub(b, a)
  [vec_add(b, dist), vec_sub(a, dist)]
  |> list.filter(dict.has_key(map, _))
}

fn find_antinodes_in_bounds_2(
  pair: #(Vec2, Vec2),
  map: Dict(Vec2, String),
) -> Set(Vec2) {
  let #(a, b) = pair
  let dist =
    day_4.vec_sub(b, a)
    |> simplify()
  // cast rays from a towards b, and from b towards a.
  // This ensures that we find antinodes at a or b, and in between the two.
  set.union(cast(map, a, dist), cast(map, b, vec_neg(dist)))
}

fn simplify(v: Vec2) {
  let gcd = find_gcd(int.absolute_value(v.0), int.absolute_value(v.1))
  #(v.0 / gcd, v.1 / gcd)
}

fn find_gcd(a: Int, b: Int) {
  case int.compare(a, b) {
    order.Eq -> a
    order.Lt -> find_gcd(a, b - a)
    order.Gt -> find_gcd(a - b, b)
  }
}

fn cast(map: Dict(Vec2, String), start: Vec2, direction: Vec2) {
  yielder.iterate(start, vec_add(direction, _))
  |> yielder.take_while(dict.has_key(map, _))
  |> yielder.to_list
  |> set.from_list
}

fn print_map(map: Dict(Vec2, String)) {
  let keys_sorted =
    dict.keys(map)
    |> list.sort(fn(lhs: Vec2, rhs: Vec2) {
      int.compare(lhs.0, rhs.0)
      |> order.lazy_break_tie(fn() { int.compare(lhs.1, rhs.1) })
    })
  let assert Ok(min) = list.first(keys_sorted)
  let assert Ok(max) = list.last(keys_sorted)
  list.range(min.1, max.1)
  |> list.fold(string_tree.new(), fn(tree, row) {
    list.range(min.0, max.0)
    |> list.fold(tree, fn(tree, col) {
      string_tree.append(tree, dict.get(map, #(col, row)) |> result.unwrap(""))
    })
    |> string_tree.append("\n")
  })
  |> fn(tree) { io.println(string_tree.to_string(tree)) }
}
