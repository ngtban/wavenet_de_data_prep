defmodule Elysium.Repo.Migrations.CreateAudioClipsTable do
  use Ecto.Migration

  def up do
    create table(:audio_clips, primary_key: false) do
      add :name, :text, primary_key: true, null: false # original asset name
      add :alternative_number,:integer
      add :conversation_id, :integer
      add :dialogue_entry_id, :integer
      add :actor, :integer # id of actor
      add :conversant, :integer # id of conversant
      add :speaker, :integer # id of speaker
      add :transcription, :text

      timestamps(default: fragment("now()"))
    end

    create index(:audio_clips, [:conversation_id, :dialogue_entry_id])
  end

  def down do
    drop_if_exists table(:audio_clips)
  end
end
