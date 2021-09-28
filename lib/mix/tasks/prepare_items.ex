defmodule Mix.Tasks.PrepareItems do
  use Mix.Task
  require IEx

  @impl Mix.Task
  def run(args) do
    try do
      # use the first argument as the path to the folder containing the audio clips
      path = List.first(args)
      full_path = Path.expand(path)

      per_batch =
        with raw_per_batch <- Enum.at(args, 1),
             {parsed_per_batch, _remainder} <- Integer.parse(raw_per_batch) do
          parsed_per_batch
        else
          _ -> 100
        end

      # Open a json stream of the file
      stream =
        full_path
        |> File.stream!()
        |> Jaxon.Stream.from_enumerable()

      parse_and_persist_actors(stream, per_batch)
    rescue
      RuntimeError -> IO.puts("Invalid path given")
    end
  end

  def parse_and_persist_actors(json_stream, per_batch) do
    IO.puts("Parsing actor data...")

    json_stream
    |> Jaxon.Stream.query([:root, "actors", :all])
    |> Stream.chunk_every(per_batch)
    |> Stream.map(fn actors ->
      list_actor_data =
        Enum.map(actors, fn actor ->
          actor_id = actor["id"]

          actor["fields"]
          |> Enum.reduce(%{"id" => actor_id}, fn field, actor_data ->
            new_actor_data =
              case field do
                %{
                  "title" => title,
                  "value" => value,
                  "typeString" => type_string
                } ->
                  processed_value =
                    if type_string == "CustomFieldType_Boolean" do
                      value < 2
                    else
                      value
                    end

                  undercored_title =
                    title |> String.split(" ") |> Enum.join("") |> Macro.underscore()

                  Map.put(actor_data, undercored_title, processed_value)

                _ ->
                  actor_data
              end

            new_actor_data
          end)
        end)

      upserted_actor_data =
        list_actor_data
        |> Enum.map(fn actor_data ->
          Elysium.Actor.insert_changeset(actor_data)
          |> Ecto.Changeset.apply_action(:insert)
          |> case do
            {:ok, actor_data} -> Map.take(actor_data, Elysium.Actor.__schema__(:fields))
            {:error, _changeset} -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      Elysium.Repo.insert_all(
        Elysium.Actor,
        upserted_actor_data,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:id]
      )

      IO.puts("Parsed and persisted #{per_batch} actor...")
    end)
    |> Stream.run()
  end

  IO.puts("Done!")
end

# r Mix.Tasks.PrepareActors
# Mix.Tasks.PrepareActors.run(["../MonoBehaviour/Disco Elysium.json", "100"])
