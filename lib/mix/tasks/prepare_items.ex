defmodule Mix.Tasks.PrepareItems do
  use Mix.Task

  @moduledoc """
    Prepare item data. Items are parsed and persisted in batches
    Supplied arguments:
    1. First argument is the path to the json file containing the conversation data
    2. Second argument is the number of items parsed and persisted in the database in each batch.
  """

  @shortdoc "Prepare item data."

  @impl Mix.Task
  def run(args) do
    try do
      # use the first argument as the path to the folder containing the audio clips
      path = List.first(args)
      full_path = Path.expand(path)

      Mix.Task.run("app.start")

      per_batch =
        with raw_per_batch <- Enum.at(args, 1),
             {:per_batch_not_nil, true} <- {:per_batch_not_nil, not is_nil(raw_per_batch)},
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
      e in RuntimeError -> IO.puts("An error happened while parsing items: #{e.message}")
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
                      value == "True"
                    else
                      value
                    end

                  underscored_title =
                    title |> String.split(" ") |> Enum.join("") |> Macro.underscore()

                  Map.put(item_data, underscored_title, processed_value)

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

    IO.puts("Done parsing items.")
  end
end
