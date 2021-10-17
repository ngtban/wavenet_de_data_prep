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

      %{
        true => list_alternative_asset_names,
        false => list_default_conversation_asset_names
      } =
        Enum.group_by(
          list_conversation_asset_name_parts,
          &(Enum.at(&1, 0) == "alternative")
        )

      grouped_list_conversation_asset_name_parts =
        Enum.group_by(list_default_conversation_asset_names, &Enum.at(&1, -2))

      grouped_list_conversation_asset_name_parts
      |> process_conversation_asset_name_groups()

      grouped_alternative_asset_name_parts =
        Enum.group_by(list_alternative_asset_names, &Enum.at(&1, -3))

      grouped_alternative_asset_name_parts
      |> process_conversation_asset_name_groups(true)

      IO.puts("Done.")
    rescue
      e in RuntimeError -> IO.puts("An error happened while parsing actor data: #{e.message}")
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
    4 => 420,
    # Col De Ma Ma Daqua is marked as thought type 1
    1 => 0
  }

  def process_thought_asset_name_groups(asset_name_groups) do
    indexed_items =
      Elysium.Repo.all(
        from(i in Elysium.Item,
          where: i.is_thought == true
        )
      )
      |> Map.new(fn item -> {String.downcase(item.displayname), item} end)

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

  @mispelled_thoughts_map %{
    "THE BOW COLLECTER" => "The Bow Collector",
    "ACES HIGH" => "Ace's High",
    "ACES LOW" => "Ace's Low",
    "MOZOVIAN SOCIO- ECONOMICS" => "Mazovian Socio-Economics",
    "DECTETIVE COSTEU" => "Les Adventures Du Detective Costeau",
    "OPOID RECEPTOR ANTAGONIST" => "Officer Opioid Receptor Antagonist",
    "RIGEROUS SELF CRITIQUE" => "Rigorous Self-Critique",
    "ANTI OBJECT TASK FORCE" => "Anti-Object Task Force",
    "MAGNESIUM - BASED LIFEFORM" => "Magnesium-Based Lifeform",
    "BRINGING OF THE LAW (LAW-JAW)" => "Bringing of the Law (Law-Jaw)",
    "HOMOSEXUAL UNDERGROUND" => "Homo-Sexual Underground",
    "GUILLAUM LE MILLION" => "Guillaume le Million",
    "COL DE MA MA DAQUA" => "Col Do Ma Ma Daqua",
    "REMOTE VIEWERS DIVISION" => "Searchlight Division",
    "APRICOT CHEWING GUN SCENETED ONE" => "Apricot Chewing Gum Scented One",
    "FINGER PISTOLS" => "Finger Pistols (9mm)",
    "FAIRWEATHER" => "Fairweather T-500",
    "COP OF THE APOCOLYPSE" => "Cop of the Apocalypse",
    "WOMPTY DOMPTY DOM CENTRE" => "The Wompty-Dompty-Dom Centre",
    "BANKRUPTSY SEQUENCE" => "Bankruptcy Sequence",
    "KINGDOM OF CONCIENCE" => "Kingdom of Conscience"
  }

  def build_records_from_thought_asset_name_group({thought_name, asset_name_group}, indexed_items) do
    spelling_corrected = @mispelled_thoughts_map[thought_name] || thought_name

    item_key = String.downcase(spelling_corrected)

    item = indexed_items[item_key]

    actor_id = @thought_type_actor_id_map[item.thought_type]

    asset_name_group
    |> Enum.map(fn asset_name_parts ->
      type = Enum.at(asset_name_parts, -1)

      transcription =
        if type == "DESCRIPTION" do
          item.fixture_description
        else
          item.displayname
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
              if dialogue_entry.dialogue_text |> String.match?(~r/".+"/) do
                extract_text_in_quotes(dialogue_entry.dialogue_text)
              else
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

  # crude, recursive, stack-like, state-machine-like extraction
  # I assume that the devs never ever nest double quotes within double quotes
  # very bad if the text is very long.
  def extract_text_in_quotes(text_with_quotes) do
    remaining = String.graphemes(text_with_quotes)
    extract_text_in_quotes_helper(remaining, "no_quote", "")
  end

  def extract_text_in_quotes_helper(remaining, current_state, accumulator) do
    case {remaining, current_state, accumulator} do
      {["\"" | rest], "no_quote", accumulator} ->
        extract_text_in_quotes_helper(rest, "open_double_quote", accumulator)

      {["\"" | rest], "open_double_quote", accumulator} ->
        extract_text_in_quotes_helper(rest, "no_quote", accumulator <> " ")

      {[char | rest], "open_double_quote", accumulator} ->
        extract_text_in_quotes_helper(rest, "open_double_quote", accumulator <> char)

      {[_ | rest], "no_quote", accumulator} ->
        extract_text_in_quotes_helper(rest, "no_quote", accumulator)

      {[], _, accumulator} ->
        accumulator
    end
  end
end

# r Mix.Tasks.LabelAudioClips
# Mix.Tasks.LabelAudioClips.run(["../AudioClip"])
