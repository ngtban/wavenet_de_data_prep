defmodule Elysium.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def up do
    create table(:conversations) do
      add :title, :text
      add :actor, :integer
      add :conversant, :integer
      add :description, :text
      add :instruction, :text
      add :check_type, :integer
      add :condition, :text
      add :difficulty, :integer
      add :placement, :text
      add :on_use, :text
      add :orb_sound_value, :text
      add :orb_sound_group, :text
      add :orb_sound_variation, :text
      add :alternate_orb_text, :text
      add :override_dialogue_condition, :text
      add :articy_id, :text

      timestamps(default: fragment("now()"))
    end
  end

  def down do
    drop_if_exists table(:conversations)
  end
end
