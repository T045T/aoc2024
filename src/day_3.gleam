import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import helpers

type ParseError {
  NotANumber
  NotFound
}

type Token {
  Keyword(String)
  OpenParen
  CloseParen
  Comma
  Literal(Int)
}

type LexState {
  LexState(tokens: List(Token), rest: String)
}

type Instruction {
  Mul(lhs: Int, rhs: Int)
}

fn match_prefix(
  state: LexState,
  prefix: String,
  on_success: Token,
) -> Result(LexState, ParseError) {
  case string.starts_with(state.rest, prefix) {
    True ->
      Ok(LexState(
        tokens: [on_success, ..state.tokens],
        rest: string.drop_start(state.rest, string.length(prefix)),
      ))
    _ -> Error(NotFound)
  }
}

fn match_number_impl(
  state: LexState,
  acc: Option(Int),
) -> Result(LexState, ParseError) {
  case state.rest {
    "0" as digit <> rest
    | "1" as digit <> rest
    | "2" as digit <> rest
    | "3" as digit <> rest
    | "4" as digit <> rest
    | "5" as digit <> rest
    | "6" as digit <> rest
    | "7" as digit <> rest
    | "8" as digit <> rest
    | "9" as digit <> rest ->
      match_number_impl(
        LexState(..state, rest: rest),
        Some(10 * option.unwrap(acc, 0) + result.unwrap(int.parse(digit), 0)),
      )
    _ ->
      acc
      |> option.to_result(NotANumber)
      |> result.try(fn(n) {
        Ok(LexState(..state, tokens: [Literal(n), ..state.tokens]))
      })
  }
}

fn match_number(state: LexState) {
  match_number_impl(state, None)
}

fn lex_mul(state: LexState) -> Result(LexState, ParseError) {
  match_prefix(state, "mul", Keyword("mul"))
  |> result.try(match_prefix(_, "(", OpenParen))
  |> result.try(match_number)
  |> result.try(match_prefix(_, ",", Comma))
  |> result.try(match_number)
  |> result.try(match_prefix(_, ")", CloseParen))
}

fn parse_tokens(
  tokens: List(Token),
  acc: List(Instruction),
) -> Result(List(Instruction), ParseError) {
  case tokens {
    [
      Keyword("mul"),
      OpenParen,
      Literal(lhs),
      Comma,
      Literal(rhs),
      CloseParen,
      ..rest
    ] -> parse_tokens(rest, [Mul(lhs, rhs), ..acc])
    [] -> Ok(acc)
    _ -> Error(NotFound)
  }
}

fn parse_all_muls(state: LexState) {
  case state.rest {
    "" -> parse_tokens(list.reverse(state.tokens), [])
    _ -> {
      case lex_mul(state) {
        Error(_) ->
          parse_all_muls(
            LexState(..state, rest: string.drop_start(state.rest, 1)),
          )
        Ok(new_state) -> parse_all_muls(new_state)
      }
    }
  }
}

pub fn task_1(path: String) {
  let file_string = helpers.load(path)
  parse_all_muls(LexState(tokens: [], rest: file_string))
  |> result.unwrap([])
  |> list.map(fn(instruction) {
    case instruction {
      Mul(lhs, rhs) -> lhs * rhs
    }
  })
  |> list.reduce(fn(a, b) { a + b })
}

fn lex_muls_with_enable(state: LexState) {
  case state.rest {
    "" -> list.reverse(state.tokens)
    "do()" <> rest ->
      lex_muls_with_enable(LexState(
        tokens: [CloseParen, OpenParen, Keyword("do"), ..state.tokens],
        rest: rest,
      ))
    "don't()" <> rest ->
      lex_muls_with_enable(LexState(
        tokens: [CloseParen, OpenParen, Keyword("don't"), ..state.tokens],
        rest: rest,
      ))
    _ ->
      case lex_mul(state) {
        Error(_) ->
          lex_muls_with_enable(
            LexState(..state, rest: string.drop_start(state.rest, 1)),
          )
        Ok(new_state) -> lex_muls_with_enable(new_state)
      }
  }
}

fn do_parse_with_enable(
  tokens: List(Token),
  enabled: Bool,
  acc: List(Instruction),
) -> List(Instruction) {
  case tokens {
    [Keyword("do"), OpenParen, CloseParen, ..rest] ->
      do_parse_with_enable(rest, True, acc)
    [Keyword("don't"), OpenParen, CloseParen, ..rest] ->
      do_parse_with_enable(rest, False, acc)
    [
      Keyword("mul"),
      OpenParen,
      Literal(lhs),
      Comma,
      Literal(rhs),
      CloseParen,
      ..rest
    ] ->
      case enabled {
        True -> do_parse_with_enable(rest, enabled, [Mul(lhs, rhs), ..acc])
        False -> do_parse_with_enable(rest, enabled, acc)
      }
    [] -> acc
    _ -> []
  }
}

fn lex_then_parse_with_enable(input: String) -> List(Instruction) {
  let tokens = lex_muls_with_enable(LexState(rest: input, tokens: []))
  do_parse_with_enable(tokens, True, [])
}

pub fn task_2(path: String) {
  helpers.load(path)
  |> lex_then_parse_with_enable()
  |> list.map(fn(instruction) {
    case instruction {
      Mul(lhs, rhs) -> lhs * rhs
    }
  })
  |> list.reduce(fn(a, b) { a + b })
}
