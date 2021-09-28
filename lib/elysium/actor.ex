defmodule Elysium.Actor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "actors" do
    field(:name, :string)
    field(:short_description, :string)
    field(:description, :string)
    field(:long_description, :string)
    field(:blank_portrait, :boolean)
    field(:color, :integer)
    field(:is_female, :boolean)
    field(:is_npc, :boolean)
    field(:is_player, :boolean)
    field(:itl, :integer)
    field(:psy, :integer)
    field(:cor, :integer)
    field(:mot, :integer)
    field(:technical_name, :string)

    timestamps()
  end

  def insert_changeset(data) do
    %__MODULE__{}
    |> Map.merge(%{
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
    |> cast(data, __MODULE__.__schema__(:fields))
    |> validate_required(:name)
  end

  def upsert_changeset(actor, data) do
    actor
    |> Map.put(:updated_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> cast(data, __MODULE__.__schema__(:fields))
    |> validate_required(:name)
  end
end
