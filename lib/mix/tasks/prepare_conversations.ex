defmodule Mix.Tasks.PrepareConversations do
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

      parse_and_persist_conversations(stream, per_batch)
    rescue
      RuntimeError -> IO.puts("Invalid path given")
    end
  end

  def parse_and_persist_conversations(json_stream, per_batch) do
    IO.puts("Parsing conversation data...")

    json_stream
    |> Jaxon.Stream.query([:root, "conversations", :all])
    |> Stream.chunk_every(per_batch)
    |> Stream.map(fn conversations ->
      list_conversation_data =
        Enum.map(conversations, fn conversation ->
          conversation_id = conversation["id"]

          conversation["fields"]
          |> Enum.reduce(%{"id" => conversation_id}, fn field, conversation_data ->
            new_conversation_data =
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

                  Map.put(conversation_data, undercored_title, processed_value)

                _ ->
                  conversation_data
              end

            new_conversation_data
          end)
        end)

      upserted_conversation_data =
        list_conversation_data
        |> Enum.map(fn conversation_data ->
          Elysium.Conversation.insert_changeset(conversation_data)
          |> Ecto.Changeset.apply_action(:insert)
          |> case do
            {:ok, conversation_data} ->
              Map.take(conversation_data, Elysium.Conversation.__schema__(:fields))

            {:error, _changeset} ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      list_dialogue_entry_data =
        Enum.map(conversations, fn conversation ->
          Enum.map(conversation["dialogueEntries"], fn dialogue_entry ->
            dialogue_entry_id = dialogue_entry["id"]

            dialogue_entry["fields"]
            |> Enum.reduce(%{"id" => dialogue_entry_id}, fn field, dialogue_entry_data ->
              new_dialogue_entry_data =
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

                    Map.put(dialogue_entry_data, undercored_title, processed_value)

                  _ ->
                    dialogue_entry_data
                end

              new_dialogue_entry_data
            end)
          end)
        end)

      upserted_dialogue_entry_data =
        list_dialogue_entry_data
        |> Enum.map(fn dialogue_entry_data ->
          Elysium.DialogueEntry.insert_changeset(dialogue_entry_data)
          |> Ecto.Changeset.apply_action(:insert)
          |> case do
            {:ok, dialogue_entry_data} ->
              Map.take(dialogue_entry_data, Elysium.DialogueEntry.__schema__(:fields))

            {:error, _changeset} ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(
        :insert_conversations,
        Elysium.Conversation,
        upserted_conversation_data,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:id]
      )
      |> Ecto.Multi.insert_all(
        :insert_dialogue_entries,
        Elysium.DialogueEntry,
        upserted_dialogue_entry_data,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:id]
      )
      |> Elysium.Repo.transaction()

      IO.puts("Parsed and persisted #{per_batch} conversations...")
    end)
    |> Stream.run()
  end

  IO.puts("Done!")
end
