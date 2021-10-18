defmodule Elysium.Repo.Migrations.CreateSpeakers do
  use Ecto.Migration

  def up do
    create table(:speakers) do
      add :name, :text, null: false
      add :actor, :integer
      add :voiced_by, :text

      timestamps(default: fragment("now()"))
    end

    create index(:speakers, [:actor])
  end

  def down do
    drop table(:speakers)
  end
end
