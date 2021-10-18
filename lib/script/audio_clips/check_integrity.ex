defmodule AudioClips.CheckIntegrity do
  import Ecto.Query, only: [from: 2]

  @human_speaker_ids 1..145
  @narrator_speaker_id 501

  def character_transcription_not_in_quotes do
    human_speaker_ids = Enum.to_list(@human_speaker_ids)

    dialogue_with_quoted_transcription =
      Elysium.Repo.all(
        from(ac in Elysium.AudioClip,
          where:
            fragment("? ~ ?", ac.transcription, "\"") and
              ac.speaker in ^human_speaker_ids,
          select: ac.name
        )
      )

    dialogue_with_quoted_transcription == []
  end

  def marked_as_narrated_clip_all_have_transcription do
    narrated_clips =
      Elysium.Repo.all(
        from(ac in Elysium.AudioClip,
          where:
            (is_nil(ac.transcription) or ac.transcription == "") and
              ac.speaker == ^@narrator_speaker_id,
          select: ac.name
        )
      )

    narrated_clips == []
  end

  def human_speakers_not_narrated_have_same_actor_ids do
    human_speaker_ids = Enum.to_list(@human_speaker_ids)

    not_narrated_clips =
      Elysium.Repo.all(
        from(ac in Elysium.AudioClip,
          where: ac.speaker in ^human_speaker_ids and ac.speaker != ac.actor,
          select: ac.name
        )
      )

    not_narrated_clips == []
  end

  def audio_clips_without_matching_dialogue_entry do
  end

  def audio_clips_with_dialogue_entry_without_transcription do
  end
end
