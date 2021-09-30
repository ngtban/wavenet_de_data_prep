defmodule Elysium.AudioClip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audio_clips" do
    # original asset name
    field(:name, :string)
    field(:conversation_id, :integer)
    field(:dialogue_entry_id, :integer)
    # id of actor
    field(:actor, :integer)
    # id of conversant
    field(:conversant, :integer)
    # narrator, Kim Kitsuragi, Dora Ingerlund/Dolores Dei
    field(:speaker, :string)
    field(:transcription, :string)

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
    |> unique_constraint(:name)
  end
end
