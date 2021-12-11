defmodule AudioClips.CheckIntegrity do
  import Ecto.Query, only: [from: 2]

  def audio_clips_with_quoted_transcription_query(human_speaker_ids) do
    from(ac in Elysium.AudioClip,
      where:
        fragment("? ~ ?", ac.transcription, "\"") and
          ac.speaker in ^human_speaker_ids,
      select: %{
        name: ac.name,
        conversation_id: ac.conversation_id,
        dialogue_entry_id: ac.dialogue_entry_id,
        transcription: ac.transcription
      }
    )
  end

  def audio_clips_with_empty_transcription_but_not_empty_dialogue_text_query do
    speaker_ids = [
      Constants.narrator_speaker_id(),
      Constants.city_speaker_id() | Constants.human_speaker_ids()
    ]

    from(ac in Elysium.AudioClip,
      join: de in Elysium.DialogueEntry,
      on: ac.conversation_id == de.conversation_id and ac.dialogue_entry_id == de.id,
      where:
        not is_nil(ac.transcription) and not (ac.transcription == "") and
          ac.speaker in ^speaker_ids and (is_nil(de.dialogue_text) or de.dialogue_text == ""),
      select: %{
        name: ac.name,
        conversation_id: ac.conversation_id,
        dialogue_entry_id: ac.dialogue_entry_id,
        transcription: ac.transcription
      }
    )
  end
end
