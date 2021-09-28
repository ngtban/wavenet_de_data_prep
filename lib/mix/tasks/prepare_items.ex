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

      parse_and_persist_items(stream, per_batch)
    rescue
      RuntimeError -> IO.puts("Invalid path given")
    end
  end

  def parse_and_persist_items(json_stream, per_batch) do
    IO.puts("Parsing item (thought) data...")

    json_stream
    |> Jaxon.Stream.query([:root, "items", :all])
    |> Stream.chunk_every(per_batch)
    |> Stream.map(fn items ->
      list_item_data =
        Enum.map(items, fn item ->
          item_id = item["id"]

          item["fields"]
          |> Enum.reduce(%{"id" => item_id}, fn field, item_data ->
            new_item_data =
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

                  Map.put(item_data, undercored_title, processed_value)

                _ ->
                  item_data
              end

            new_item_data
          end)
        end)

      upserted_item_data =
        list_item_data
        |> Enum.map(fn item_data ->
          Elysium.Item.insert_changeset(item_data)
          |> Ecto.Changeset.apply_action(:insert)
          |> case do
            {:ok, item_data} -> Map.take(item_data, Elysium.Item.__schema__(:fields))
            {:error, _changeset} -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      Elysium.Repo.insert_all(
        Elysium.Item,
        upserted_item_data,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:id]
      )

      IO.puts("Parsed and persisted #{per_batch} items...")
    end)
    |> Stream.run()
  end

  IO.puts("Done!")
end
