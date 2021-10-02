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

  # Taken from https://stackoverflow.com/questions/39638172/using-regex-extract-quoted-strings-that-may-contain-nested-quotes
  # , just in case that some dialogue texts contain nested quotes
  # I really hope it works.
  @capture_quotes_pattern ~r/(?=(?:(?<!\w)'(\w.*?)'(?!\w)|\"(\w.*?)\"(?!\w)))/

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

      {ls_result, _exit_status} = System.cmd("ls", [full_path])

      asset_names_without_extensions =
        ls_result
        |> String.split("\n")
        |> Enum.map(&Path.basename/1)
        |> Enum.map(&Path.basename(&1, ".wav"))

      # thoughts and joke endings have to be processed separately
      # thoughts are treated as items, and the transcription is in the description
      # I can't find any text for the newspaper endings
      conversation_asset_names =
        asset_names_without_extensions
        |> Enum.filter(&String.match?(&1, @conversation_audio_clip_pattern))

      thought_asset_name_groups =
        asset_names_without_extensions
        |> Stream.filter(&String.match?(&1, ~r/^.+_(DESCRIPTION|TITLE)/m))
        |> Stream.map(&String.split(&1, "_"))
        |> Enum.to_list()
        |> Enum.group_by(&Enum.at(&1, -2))

      thought_asset_name_groups
      |> process_thought_asset_name_groups

      list_conversation_asset_name_parts =
        conversation_asset_names
        |> Enum.map(&String.split(&1, ~r/-(?![ -])/))

      # %{
      #   true => list_alternative_asset_names,
      #   false => list_default_conversation_asset_names
      # } =
      #   Enum.group_by(
      #     list_conversation_asset_name_parts,
      #     &(Enum.at(&1, 0) == "alternative")
      #   )

      # grouped_list_conversation_asset_name_parts =
      #   Enum.group_by(list_default_conversation_asset_names, &Enum.at(&1, -2))

      # grouped_list_conversation_asset_name_parts
      # |> process_conversation_asset_name_groups()

      # grouped_alternative_asset_name_parts =
      #   Enum.group_by(list_alternative_asset_names, &Enum.at(&1, -3))

      # grouped_alternative_asset_name_parts
      # |> process_conversation_asset_name_groups(true)

      IO.puts("Done.")
    rescue
      RuntimeError -> "Invalid path given."
    end
  end

  @thought_type_actor_id_map %{
    # Pysche
    3 => 417,
    # Motorics
    5 => 418,
    # Intellect
    2 => 419,
    # Fysique
    4 => 420
  }

  def process_thought_asset_name_groups(asset_name_groups) do
    indexed_items =
      Elysium.Repo.all(
        from(i in Elysium.Item,
          where: i.is_thought == true
        )
      )
      |> Map.new(fn item -> {item.name, item} end)

    list_thought_audio_clip_data =
      asset_name_groups
      |> Enum.flat_map(&build_records_from_thought_asset_name_group(&1, indexed_items))
      |> Enum.reject(&is_nil/1)

    Elysium.Repo.insert_all(
      Elysium.AudioClip,
      list_thought_audio_clip_data,
      on_conflict: {:replace_all_except, [:name]},
      conflict_target: [:name]
    )
  end

  def build_records_from_thought_asset_name_group({thought_name, asset_name_group}, indexed_items) do
    key =
      thought_name
      |> String.split()
      |> Stream.filter(&String.match?(&1, ~r/^[^()]+$/m))
      |> Stream.map(&String.downcase/1)
      |> Enum.join("_")

    item = indexed_items[key]

    if is_nil(item) do
      IEx.pry()
    end

    actor_id = @thought_type_actor_id_map[item.thought_type]

    asset_name_group
    |> Enum.map(fn asset_name_parts ->
      type = Enum.at(asset_name_parts, -1)

      transcription =
        if type == "DESCRIPTION" do
          item.description
        else
          key |> String.split("_") |> Enum.map(&String.upcase/1) |> Enum.join()
        end

      %{
        "name" => asset_name_parts |> Enum.join("-"),
        "alternative_number" => -1,
        "conversation_id" => 0,
        "dialogue_entry_id" => 0,
        "actor" => actor_id,
        "conversant" => 387,
        "transcription" => transcription
      }
      |> Elysium.AudioClip.insert_changeset()
      |> Ecto.Changeset.apply_action(:insert)
      |> case do
        {:ok, audio_clip} -> audio_clip |> Map.take(Elysium.AudioClip.__schema__(:fields))
        {:error, _changeset} -> nil
      end
    end)
  end

  def process_conversation_asset_name_groups(asset_name_groups, is_alternative \\ false) do
    asset_name_groups
    |> Enum.chunk_every(5)
    |> Enum.each(fn asset_name_groups ->
      list_audio_clip_data =
        asset_name_groups
        |> Enum.flat_map(&build_records_from_asset_name_group(&1, is_alternative))
        |> Enum.reject(&is_nil/1)

      Elysium.Repo.insert_all(
        Elysium.AudioClip,
        list_audio_clip_data,
        on_conflict: {:replace_all_except, [:name]},
        conflict_target: [:name]
      )
    end)

    IO.puts("Proccessed audio clips belonging to 5 conversations.")
  end

  def build_records_from_asset_name_group(
        {conversation_name, asset_name_group},
        is_alternative \\ false
      ) do
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

    dialogue_entry_index =
      if is_alternative do
        -2
      else
        -1
      end

    asset_name_group
    |> Enum.map(fn asset_name_parts ->
      {dialogue_entry_id, _fractional_part} =
        asset_name_parts |> Enum.at(dialogue_entry_index) |> Integer.parse()

      {alternative_number, _fraction_part} =
        if is_alternative do
          asset_name_parts |> Enum.at(-1) |> Integer.parse()
        else
          {-1, ""}
        end

      dialogue_entry = indexed_dialogue_entries[dialogue_entry_id]

      # Some audio files do not correspond to any dialogue entry
      # One example is "Inland Empire-WHIRLING F2  DREAM 2 INTRO-40"
      if not is_nil(dialogue_entry) do
        actor_id = dialogue_entry.actor

        is_narrated =
          actor_id in @book_actor_ids or actor_id in @group_1_object_actor_ids or
            actor_id in @group_2_object_actor_ids or actor_id in @skill_actor_ids

        transcription =
          if is_narrated do
            dialogue_entry.dialogue_text
          else
            # There are some dialogue entries that has a corresponding audio clip,
            # but the dialogue text is empty. Those probably are legacy conversations.
            # Dialogue entry with id = 981, conversation_id = 995, for example
            if(actor_id in @human_actor_ids and not is_nil(dialogue_entry.dialogue_text)) do
              nested_captured =
                Regex.scan(@capture_quotes_pattern, dialogue_entry.dialogue_text)
                |> Enum.map(&List.last/1)
                |> Enum.join(" ")

              if nested_captured != "" do
                nested_captured
              else
                # sometimes dialogue text belonging to a character is not wrapped in quotes
                dialogue_entry.dialogue_text
              end
            else
              dialogue_entry.dialogue_text
            end
          end

        %{
          "name" => asset_name_parts |> Enum.join("-"),
          "alternative_number" => alternative_number,
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
