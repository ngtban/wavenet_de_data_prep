defmodule Mix.Tasks.CheckDataIntegrity do
  use Mix.Task

  @moduledoc """
    Check if there is a problem with the prepared data and extracted transcriptions
    This task does not receive any argument.
  """

  @shortdoc "Prepare actor data."

  def run(_args) do
    audio_clips_with_quoted_transcription =
      Elysium.Repo.all(
        AudioClips.CheckIntegrity.audio_clips_with_quoted_transcription_query(
          Constants.human_speaker_ids()
        )
      )

    if(audio_clips_with_quoted_transcription |> Enum.empty?()) do
      IO.puts("1) There are no transcription that contains quotes.")
    else
      IO.puts("""
      1) Warning: there are some transcriptions that contain quotes.
      This is likely because the writers forgot to put closing quotes in dialogue texts.
      """)
    end

    audio_clips_with_empty_transcription_but_not_empty_dialogue_text =
      Elysium.Repo.all(
        AudioClips.CheckIntegrity.audio_clips_with_empty_transcription_but_not_empty_dialogue_text_query()
      )

    if audio_clips_with_empty_transcription_but_not_empty_dialogue_text |> Enum.empty?() do
      IO.puts(
        "4) There are no transcription that is empty but has a corresponding non-empty dialogue text."
      )
    else
      IO.puts("""
      Warning: there are some transcriptions that are empty but each has a corresponding non-empty dialogue text.
      Something wrong happened in the process of converting dialogue texts to transcriptions.
      """)
    end
  end
end
