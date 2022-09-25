defmodule Mix.Tasks.PrepareBundle do
  use Mix.Task

  @moduledoc """
    Prepare actor, item, and conversation data. Each category is parsed and persisted in batches
    Supplied arguments:
    1. First argument is the path to the json file containing the conversation data
    2. Second argument is the number of actors parsed and persisted in the database in each batch.
    3. Third argument is the number of items parsed and persisted in the database in each batch.
    4. Fourth argument is the number of conversations parsed and persisted in the database in each batch.
  """

  @shortdoc "Prepare bundle data."

  @impl Mix.Task
  def run(args) do
    try do
      # use the first argument as the path to the folder containing the audio clips
      path = List.first(args)
      full_path = Path.expand(path)

      Mix.Task.run("app.start")

      # open a json stream of the file
      actors_per_batch = parse_number_from_argument(args, 1, 100)
      items_per_batch = parse_number_from_argument(args, 2, 100)
      conversations_per_batch = parse_number_from_argument(args, 3, 3)

      stream =
        full_path
        |> File.stream!()
        |> Jaxon.Stream.from_enumerable()

      Mix.Tasks.PrepareActors.parse_and_persist_actors(stream, actors_per_batch)
      Mix.Tasks.PrepareItems.parse_and_persist_items(stream, items_per_batch)

      Mix.Tasks.PrepareConversations.parse_and_persist_conversations(
        stream,
        conversations_per_batch
      )

      IO.puts("Done!")
    rescue
      e in RuntimeError ->
        IO.puts("An error happened while parsing data from the bundle: #{e.message}")
    end
  end

  defp parse_number_from_argument(args, position, default \\ 100) do
    with raw_per_batch <- Enum.at(args, position),
         {:per_batch_not_nil, true} <- {:per_batch_not_nil, not is_nil(raw_per_batch)},
         {parsed_per_batch, _remainder} <-
           Integer.parse(raw_per_batch) do
      parsed_per_batch
    else
      _ -> default
    end
  end
end
