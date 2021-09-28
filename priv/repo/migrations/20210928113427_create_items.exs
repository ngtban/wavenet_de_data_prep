defmodule Elysium.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def up do
    create table(:items) do
      add :name, :text
      add :description, :text
      add :medium_text_value, :text
      add :item_group, :integer
      add :stack_name, :text
      add :displayname, :text
      add :item_type, :integer
      add :item_value, :integer
      add :conversation, :text
      add :equip_orb, :text
      add :tooltip, :text
      add :fixture_description, :text
      add :fixture_bonus, :text
      add :requirement, :text
      add :is_item, :boolean
      add :is_substance, :boolean
      add :is_consumable, :boolean
      add :autoequip, :boolean
      add :multiple_allowed, :boolean
      add :cursed, :boolean
      add :is_thought, :boolean
      add :thought_type, :integer
      add :time_left, :integer
      add :technical_name, :text
      add :articy_id, :text
      add :sound, :integer

      timestamps(default: fragment("now()"))
    end
  end

  def down do
    drop_if_exists table(:items)
  end
end
