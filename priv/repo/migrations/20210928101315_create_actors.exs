defmodule Elysium.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def up do
    create table(:actors) do
      add :name, :text, null: false
      add :short_description, :text
      add :description, :text
      add :long_description, :text
      add :blank_portrait, :boolean
      add :color, :integer
      add :is_female, :boolean
      add :is_npc, :boolean
      add :is_player, :boolean
      add :itl, :integer
      add :psy, :integer
      add :cor, :integer
      add :mot, :integer
      add :articy_id, :text
      add :technical_name, :text

      timestamps(default: fragment("now()"))
    end
  end

  def down do
    drop_if_exists table(:actors)
  end
end
