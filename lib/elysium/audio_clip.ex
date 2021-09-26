defmodule Elysium.AudioClip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audio_clips" do
    # original asset name
    field(:name, :string, default: "")
    # first part of the asset name
    field(:source, :string)
    # skill, character, object under examination, etc.
    field(:source_type, :string)
    # where the conversation/observation/description is from
    field(:location, :string)
    # usually which object/part of the location the clip is from
    field(:point_of_focus, :string)
    # number/string marking the node in the conversation graph
    field(:conversation_node, :string)
    # narrator, Kim Kitsuragi, Dora Ingerlund/Dolores Dei
    field(:speaker, :string)
    # sound effects, spoken words, soundtrack
    field(:subtype, :string)

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

  def upsert_changeset(audio_clip, data) do
    audio_clip
    |> Map.put(:updated_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> cast(data, __MODULE__.__schema__(:fields))
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
