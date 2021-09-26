defmodule AudioClipTest do
  use ExUnit.Case
  doctest DataPrepration

  @audio_clip %{
    name: "something"
  }

  test "inserting valid audio clip metadata" do
    audio_clip = Elysium.AudioClip.insert_changeset(@audio_clip)

    assert match?({:ok, data}, Elysium.Repo.insert(audio_clip)) == true
  end
end
