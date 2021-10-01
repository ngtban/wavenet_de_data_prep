defmodule Mix.Tasks.LabelAudioClips do
  use Mix.Task
  import Ecto.Query, only: [from: 2]
  require IEx

  @moduledoc """
    Label audio clips
    Supplied arguments:
    1. First argument is the path to the folder containing the audio clips
  """

  @shortdoc "Label audio clips."

  @conversation_audio_clip_pattern ~r/^(alternative|([A-Z][^_]+))-[^_]+-[^_]+(\d)+$/m

  @human_actor_ids 1..145
  @group_1_object_actor_ids 146..153
  @book_actor_ids 154..204
  @group_2_object_actor_ids 205..386
  # 387 is "You", or Harry
  # 388 is the branch marker
  @skill_actor_ids 389..420

  @impl Mix.Task
  def run(args) do
    try do
      # use the first argument as the path to the folder containing the audio clips
      path = List.first(args)
      full_path = Path.expand(path)

      Mix.Task.run("app.start")

      {result, _exit_status} = System.cmd("ls", [full_path])

      # read the file names of that folder
      # ignore clips with names beginning in lowercase
      # ignore clips with underscore,
      # seems like that is legacy?
      asset_names_without_extensions =
        result
        |> String.split("\n")
        |> Enum.map(&Path.basename/1)
        |> Enum.map(&Path.basename(&1, ".wav"))

      # thoughts and joke endings have to be processed separately
      # thoughts are treated as items, and the transcription is in the description
      # I can't find any text for the newspaper endings
      conversation_asset_names =
        asset_names_without_extensions
        |> Stream.filter(&String.match?(&1, @conversation_audio_clip_pattern))
        |> Enum.to_list()

      list_conversation_asset_name_parts =
        conversation_asset_names
        |> Enum.map(&String.split(&1, ~r/-(?![ -])/))

      %{
        true => _list_alternative_asset_names,
        false => list_default_asset_names
      } =
        Enum.group_by(
          list_conversation_asset_name_parts,
          &(Enum.at(&1, 0) == "alternative")
        )

      grouped_list_conversatin_asset_name_parts =
        Enum.group_by(list_default_asset_names, &Enum.at(&1, -2))

      grouped_list_conversatin_asset_name_parts
      |> Enum.chunk_every(5)
      |> Enum.each(fn asset_name_groups ->
        list_audio_clip_data =
          asset_name_groups
          |> Enum.flat_map(&build_records_from_asset_name_group/1)
          |> Enum.reject(&is_nil/1)

        Elysium.Repo.insert_all(
          Elysium.AudioClip,
          list_audio_clip_data,
          on_conflict: {:replace_all_except, [:name]},
          conflict_target: [:name]
        )

        IO.puts("Proccessed audio clips belonging to 5 conversations.")
      end)

      # grouped_alternative_asset_name_parts =
      #   Enum.group_by(list_alternative_asset_names, &Enum.at(&1, -3))
    rescue
      RuntimeError -> "Invalid path given."
    end
  end

  def build_records_from_asset_name_group({conversation_name, asset_name_group}) do
    conversation_title =
      conversation_name
      |> String.split("  ")
      |> Enum.join(" / ")

    IO.puts(
      "Building records for audio clips belonging to the conversation titled \"#{
        conversation_title
      }\""
    )

    # I have to use ilike here because some conversation titles include special characters,
    # for example "?", and the asset exporter stripped those in the file names
    ilike_string = "%#{conversation_title}%"

    conversation =
      Elysium.Repo.one(
        from(c in Elysium.Conversation,
          where: ilike(c.title, ^ilike_string),
          order_by: {:asc, c.title},
          limit: 1
        )
      )

    indexed_dialogue_entries =
      Elysium.Repo.all(
        from(de in Elysium.DialogueEntry,
          where: de.conversation_id == ^conversation.id
        )
      )
      |> Map.new(fn dialogue_entry -> {dialogue_entry.id, dialogue_entry} end)

    dialogue_entry_index = -1

    asset_name_group
    |> Enum.map(fn asset_name_parts ->
      {dialogue_entry_id, _fractional_part} =
        asset_name_parts
        |> Enum.at(dialogue_entry_index)
        |> Integer.parse()

      dialogue_entry = indexed_dialogue_entries[dialogue_entry_id]

      # Some audio files do not correspond to any dialogue entry
      # One example is "Inland Empire-WHIRLING F2  DREAM 2 INTRO-40"
      if not is_nil(dialogue_entry) do
        actor_id = dialogue_entry.actor

        transcription =
          if(
            actor_id in @book_actor_ids or actor_id in @group_1_object_actor_ids or
              actor_id in @group_2_object_actor_ids or actor_id in @skill_actor_ids
          ) do
            dialogue_entry.dialogue_text
          else
            if(actor_id in @human_actor_ids) do
              "figuring this out"
            else
              dialogue_entry.dialogue_text
            end
          end

        %{
          "name" => asset_name_parts |> Enum.join("-"),
          "conversation_id" => conversation.id,
          "dialogue_entry_id" => dialogue_entry_id,
          "actor" => actor_id,
          "conversant" => dialogue_entry.conversant,
          "transcription" => transcription
        }
        |> Elysium.AudioClip.insert_changeset()
        |> Ecto.Changeset.apply_action(:insert)
        |> case do
          {:ok, audio_clip} -> audio_clip |> Map.take(Elysium.AudioClip.__schema__(:fields))
          {:error, _changeset} -> nil
        end
      end
    end)
  end
end

# r Mix.Tasks.LabelAudioClips
# Mix.Tasks.LabelAudioClips.run(["../AudioClip"])
# Some pathological/test asset names:
# "interface-skill-passiveINT-04-01"
# "Inland Empire-WHIRLING F2  DREAM 2 INTRO-40"
# "alternative-0-Acele-ICE  ACELE AND ASSOCIATES-116-0"
# "Communistreading-ambience-coffeeboiler"
# "Kim_Shoe_on_carpet.03-01-01"
