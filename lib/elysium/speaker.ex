defmodule Elysium.Speaker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "speakers" do
    field(:name, :string)
    field(:actor, :integer)
    field(:voiced_by, :string)

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
end
