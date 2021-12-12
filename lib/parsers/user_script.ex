defmodule Parsers.UserScript do
  import NimbleParsec

  escaped_character =
    choice([
      string("\\\"") |> replace("\""),
      string("\\\n") |> replace("\n"),
      utf8_string([not: ?", not: ?\\], 1)
    ])

  string_argument =
    ignore(string("\""))
    |> repeat(escaped_character)
    |> ignore(string("\""))
    |> reduce({Enum, :join, [""]})

  next_string_argument =
    ignore(string(","))
    |> repeat(ignore(string(" ")))
    |> concat(string_argument)

  newspaper_endgame_arguments =
    ignore(string("NewspaperEndgame"))
    |> ignore(string("("))
    |> concat(string_argument)
    |> repeat(next_string_argument)
    |> ignore(string(")"))

  defparsec(:newspaper_endgame_arguments, newspaper_endgame_arguments)
end
