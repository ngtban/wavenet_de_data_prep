defmodule Parsers.AssetName do
  import NimbleParsec

  name_part = utf8_string([?A..?Z], min: 1)

  name_rest =
    string("_")
    |> concat(name_part)
    |> repeat()

  name =
    empty()
    |> concat(name_part)
    |> concat(name_rest)
    |> reduce({Enum, :join, [""]})

  type =
    choice([
      string("description"),
      string("title")
    ])

  newspaper_endgame_asset_name_parts =
    string("NewspaperEndgame")
    |> ignore(string("_"))
    |> concat(name)
    |> ignore(string("_"))
    |> concat(type)

  defparsec(:newspaper_endgame_asset_name_parts, newspaper_endgame_asset_name_parts)
end
