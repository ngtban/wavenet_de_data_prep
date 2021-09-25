defmodule Elysium.Repo.Migrations.CreateAudioClipsTable do
  use Ecto.Migration

  def up do
    create table(:audio_clips) do
      add :name, :text, primary_key: true, null: false # original asset name
      add :source, :text # first part of the asset name
      add :source_type, :text # skill, character, object under examination, etc.
      add :location, :text # where the conversation/observation/description is from
      add :point_of_focus, :text # usually which object/part of the location the clip is from
      add :conversation_node, :text # number/string marking the node in the conversation graph
      add :speaker, :text # narrator, Kim Kitsuragi, Dora Ingerlund/Dolores Dei
      add :subtype, :text # sound effects, spoken words, soundtrack
    end
  end

  def down do
    drop_if_exists table(:audio_clips)
  end
end
