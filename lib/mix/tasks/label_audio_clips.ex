defmodule Mix.Tasks.LabelAudioClips do
  use Mix.Task
  require IEx

  @skill_names []
  @character_names []

  @impl Mix.Task
  def run(args) do
    try do
      # use the first argument as the path to the folder containing the audio clips
      path = args[0]
      full_path = Path.expand(path)
      {result, _exit_status} = System.cmd("ls", [full_path])

      # read the file names of that folder
      asset_names =
        result
        |> String.split("\n")
        |> Enum.map(&Path.basename/1)

      IEx.pry()

      # parse, match, filter, etc. and build records in memory
      # traverse the conversion objects and save the transcriptions as well
      # insert the data into the db
    rescue
      RuntimeError -> "Invalid path given."
    end
  end
end
