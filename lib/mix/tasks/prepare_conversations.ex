defmodule Mix.Tasks.PrepareConversations do
  use Mix.Task
  require IEx

  @moduledoc """
    Prepare conversation data. Conversations are parsed and persisted in batches
    Supplied arguments:
    1. First argument is the path to the json file containing the conversation data
    2. Second argument is the number of conversation parsed and persisted in the database in each batch.
  """

  @shortdoc "Prepare conversation data."

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
          _ -> 5
        end

      # Open a json stream of the file
      stream =
        full_path
        |> File.stream!()
        |> Jaxon.Stream.from_enumerable()

      parse_and_persist_conversations(stream, per_batch)
    rescue
      e in RuntimeError -> IO.puts("An error happened while parsing conversations: #{e.message}")
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

                  underscored_title =
                    title |> String.split(" ") |> Enum.join("") |> Macro.underscore()

                  Map.put(conversation_data, underscored_title, processed_value)

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
        Enum.flat_map(conversations, fn conversation ->
          Enum.map(conversation["dialogueEntries"], fn dialogue_entry ->
            {id_and_fields, rest} = Map.split(dialogue_entry, ~w(id fields))

            %{
              "id" => dialogue_entry_id,
              "fields" => fields
            } = id_and_fields

            dialogue_entry_data =
              fields
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

                      underscored_title =
                        title |> String.split(" ") |> Enum.join("") |> Macro.underscore()

                      Map.put(dialogue_entry_data, underscored_title, processed_value)

                    _ ->
                      dialogue_entry_data
                  end

                new_dialogue_entry_data
              end)

            # save other attributes apart from the ones defined in "fields"
            Enum.reduce(rest, dialogue_entry_data, fn {field_name, value}, data ->
              underscored_field_name =
                field_name |> String.split(" ") |> Enum.join("") |> Macro.underscore()

              processed_value =
                if field_name in ~w(isRoot isGroup) do
                  value > 0
                else
                  value
                end

              Map.put(data, underscored_field_name, processed_value)
            end)
          end)
        end)
        |> Enum.reject(&is_nil/1)

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
        on_conflict: {:replace_all_except, [:id, :conversation_id]},
        conflict_target: [:id, :conversation_id]
      )
      |> Elysium.Repo.transaction()

      IO.puts("Parsed and persisted #{per_batch} conversations...")
    end)
    |> Stream.run()
  end

  IO.puts("Done!")
end

# Mix.Tasks.PrepareConversations.run(["../MonoBehaviour/Disco Elysium.json", "5"])
