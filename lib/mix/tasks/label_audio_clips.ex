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

  # @skill_names []
  # @character_names []

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
      # seems like that is legacy?
      asset_names =
        result
        |> String.split("\n")
        |> Enum.map(&Path.basename/1)
        |> Enum.map(&Path.basename(&1, ".wav"))
        |> Enum.filter(&String.match?(&1, ~r/[A-Z].?/))

      list_asset_name_parts =
        asset_names
        |> Enum.map(&String.split(&1, ~r/-(?![ -])/))

      %{
        true => list_alternative_asset_names,
        false => list_default_asset_names
      } = Enum.group_by(list_asset_name_parts, &(Enum.at(&1, 0) == "alternative"))

      grouped_list_asset_name_parts = Enum.group_by(list_default_asset_names, &Enum.at(&1, -2))

      grouped_list_asset_name_parts
      |> Enum.each(fn {conversation_name, asset_name_group} ->
        conversation_title =
          conversation_name
          |> String.split("  ")
          |> Enum.join(" / ")

        conversation =
          Elysium.Repo.one(
            from(c in Elysium.Conversation,
              where: c.title == ^conversation_title
            )
          )

        indexed_dialogue_entries =
          Elysium.Repo.all(
            from(de in Elysium.DialogueEntry,
              where: de.conversation_id == ^conversation.id
            )
          )
          |> Map.new(fn dialogue_entry -> {dialogue_entry.id, dialogue_entry} end)

        IEx.pry()
      end)

      grouped_alternative_asset_name_parts =
        Enum.group_by(list_alternative_asset_names, &Enum.at(&1, -3))

      # parse, match, filter, etc. and build records in memory
      # traverse the conversion objects and save the transcriptions as well
      # I should have already parsed the bundled conversations and
      # convert it into a relation format, saved it in the db.
      # insert the data into the db
    rescue
      RuntimeError -> "Invalid path given."
    end
  end
end

# r Mix.Tasks.LabelAudioClips
# Mix.Tasks.LabelAudioClips.run(["../AudioClip"])
