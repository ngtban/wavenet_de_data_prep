defmodule Constants do
  @human_actor_ids Enum.to_list(1..145)

  def human_actor_ids, do: @human_actor_ids
  def human_speaker_ids, do: @human_actor_ids

  @narrator_speaker_id 501
  def narrator_speaker_id, do: @narrator_speaker_id
  def narrator_actor_id, do: @narrator_speaker_id

  @city_speaker_id 502
  def city_speaker_id, do: @city_speaker_id
  def city_actor_id, do: @city_speaker_id
end
