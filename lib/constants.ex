defmodule Constants do
  @human_actor_ids Enum.to_list(1..145)
  def human_speaker_ids, do: @human_actor_ids
  def human_actor_ids, do: @human_actor_ids

  @narrator_speaker_id 501
  def narrator_speaker_id, do: @narrator_speaker_id
end
