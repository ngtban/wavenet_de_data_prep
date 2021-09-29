defmodule Elysium.Repo.Migrations.CreateDialogueEntries do
  use Ecto.Migration

  def up do
    add table(:dialogue_entries, primary_key: false) do
      add :id, :integer, primary_key: true
      add :conversation_id, :integer, primary_key: true
      add :title, :text
      add :dialogue_text, :text
      add :sequence, :text
      add :actor, :integer
      add :conversant, :integer
      add :outgoing_links, :jsonb
      add :input_id, :text
      add :output_id, :text
      add :is_root, :boolean
      add :is_group, :boolean
      add :node_color, :text
      add :delay_sim_status, :integer
      add :condition_string, :text
      add :false_condition_action, :text
      add :user_script, :text
      add :on_execute, :jsonb
      add :articy_id, :text

      timestamps(default: fragment("now()"))
    end
  end

  def down do
    drop_if_exists table(:dialogue_entries)
  end
end
