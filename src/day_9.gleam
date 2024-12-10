import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/string
import gleam/string_tree

import helpers

type FileSystemItem {
  File(length: Int, id: Int)
  Space(length: Int)
}

pub fn task_1(filepath: String) {
  let assert [input, ..] = helpers.load_non_empty_lines(filepath)
  parse_file_system(input)
  // |> function.tap(fn(x) { io.debug(print(x)) })
  |> defrag()
  |> deque.to_list()
  |> checksum()
}

pub fn task_2(filepath: String) {
  let assert [input, ..] = helpers.load_non_empty_lines(filepath)
  parse_file_system(input)
  |> deque.to_list()
  |> build_map(0, _, dict.new())
  |> defrag_map()
  |> dict.to_list()
  |> list.sort(by_first)
  |> list.map(pair.second)
  // |> function.tap(fn(x) { deque.to_list(x) |> io.debug() })
  |> checksum()
}

fn parse_file_system(input: String) -> Deque(FileSystemItem) {
  string.to_graphemes(input)
  |> list.index_fold(deque.new(), fn(acc, c, index) {
    let assert Ok(length) = int.parse(c)
    use <- bool.guard(when: length == 0, return: acc)
    // let length = int.random(8) + 1
    let item = case int.is_even(index) {
      // parsing a file
      True -> File(length: length, id: index / 2)
      False -> Space(length)
    }
    deque.push_back(acc, item)
  })
}

fn defrag(fs: Deque(FileSystemItem)) -> Deque(FileSystemItem) {
  do_defrag(fs, [])
  |> deque.from_list()
}

fn do_defrag(
  fragged: Deque(FileSystemItem),
  defragged: List(FileSystemItem),
) -> List(FileSystemItem) {
  case deque.pop_front(fragged) {
    Error(_) -> list.reverse(defragged)
    Ok(#(File(_, _) as f, rest)) -> do_defrag(rest, [f, ..defragged])
    Ok(#(Space(space_length) as s, rest)) ->
      case deque.pop_back(rest) {
        Error(_) -> list.reverse([s, ..defragged])
        Ok(#(Space(_), rest)) -> do_defrag(deque.push_front(rest, s), defragged)
        Ok(#(File(file_length, id), rest)) ->
          case int.compare(space_length, file_length) {
            order.Lt ->
              do_defrag(
                deque.push_back(rest, File(file_length - space_length, id)),
                [File(space_length, id), ..defragged],
              )
            order.Eq -> do_defrag(rest, [File(space_length, id), ..defragged])
            order.Gt ->
              do_defrag(
                deque.push_front(rest, Space(space_length - file_length)),
                [File(file_length, id), ..defragged],
              )
          }
      }
  }
}

fn checksum(fs: List(FileSystemItem)) -> Int {
  do_checksum(fs, 0, 0)
}

fn do_checksum(files: List(FileSystemItem), block_index: Int, acc: Int) -> Int {
  case files {
    [] -> acc
    [Space(length), ..rest] -> do_checksum(rest, block_index + length, acc)
    [File(id: id, length: length), ..rest] ->
      do_checksum(
        rest,
        block_index + length,
        acc + file_checksum(block_index, id, length),
      )
  }
}

fn file_checksum(start: Int, id: Int, length: Int) {
  do_file_checksum(start, id, length, 0)
}

fn do_file_checksum(start: Int, id: Int, length: Int, acc: Int) {
  use <- bool.guard(when: length == 0, return: acc)
  do_file_checksum(start + 1, id, length - 1, acc + start * id)
}

fn print_map(m) -> String {
  m
  |> dict.to_list()
  |> list.sort(by_first)
  |> list.map(pair.second)
  |> deque.from_list()
  |> print()
}

fn print(d) -> String {
  do_print(d, string_tree.new())
}

fn do_print(d, tree) {
  case deque.pop_front(d) {
    Ok(#(Space(len), rest)) ->
      do_print(rest, string_tree.append(tree, string.repeat(".", len)))
    Ok(#(File(id: id, length: len), rest)) ->
      do_print(
        rest,
        string_tree.append(tree, string.repeat(int.to_string(id), len)),
      )
    _ -> string_tree.to_string(tree)
  }
}

fn build_map(
  current_block: Int,
  fs: List(FileSystemItem),
  acc: Dict(Int, FileSystemItem),
) -> Dict(Int, FileSystemItem) {
  case fs {
    [] -> acc
    [item, ..rest] ->
      build_map(
        current_block + item.length,
        rest,
        dict.insert(acc, current_block, item),
      )
  }
}

fn defrag_map(fs_map: Dict(Int, FileSystemItem)) {
  let file_blocks_ordered_by_descending_id =
    dict.filter(fs_map, fn(_, v) {
      case v {
        File(_, _) -> True
        _ -> False
      }
    })
    |> dict.to_list()
    // Largest file ID to lowest file ID
    |> list.sort(fn(l, r) {
      case l, r {
        #(_, File(_, id_l)), #(_, File(_, id_r)) ->
          order.negate(int.compare(id_l, id_r))
        _, _ -> order.Eq
      }
    })
    // Only keep keys (block indices)
    |> list.map(pair.first)
  do_defrag_map(file_blocks_ordered_by_descending_id, fs_map)
}

fn do_defrag_map(
  fragmented_file_starts: List(Int),
  fs_map: Dict(Int, FileSystemItem),
) -> Dict(Int, FileSystemItem) {
  io.debug(list.first(fragmented_file_starts))
  case fragmented_file_starts {
    [] -> fs_map
    [file_index, ..rest] -> do_defrag_map(rest, defrag_file(fs_map, file_index))
  }
}

fn defrag_file(fs_map, file_index) {
  let assert Ok(File(length: _, id: _) as file) = dict.get(fs_map, file_index)
  do_defrag_file(fs_map, file_index, file, 0)
}

fn do_defrag_file(
  fs_map,
  file_index: Int,
  file: FileSystemItem,
  hole_index: Int,
) {
  use <- bool.guard(when: hole_index >= file_index, return: fs_map)
  case dict.get(fs_map, hole_index) {
    Ok(File(length, _)) ->
      do_defrag_file(fs_map, file_index, file, hole_index + length)
    Ok(Space(length)) if length < file.length ->
      do_defrag_file(fs_map, file_index, file, hole_index + length)
    Ok(Space(space_length)) if space_length <= file.length ->
      case int.compare(space_length, file.length) {
        order.Lt -> fs_map
        order.Eq ->
          fs_map |> dict.delete(file_index) |> dict.insert(hole_index, file)
        order.Gt ->
          fs_map
          |> dict.delete(file_index)
          |> dict.insert(hole_index, file)
          |> dict.insert(
            hole_index + file.length,
            Space(space_length - file.length),
          )
      }
    _ -> fs_map
  }
}

fn by_first(l: #(Int, a), r: #(Int, b)) -> order.Order {
  int.compare(l.0, r.0)
}
