defmodule Elysium.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field(:title, :string)
    field(:actor, :integer)
    field(:conversant, :integer)
    field(:description, :string)
    field(:instruction, :string)
    field(:check_type, :integer)
    field(:condition, :string)
    field(:difficulty, :integer)
    field(:placement, :string)
    field(:on_use, :string)
    field(:orb_sound_value, :string)
    field(:orb_sound_group, :string)
    field(:orb_sound_variation, :string)
    field(:alternate_orb_text, :string)
    field(:override_dialogue_condition, :string)
    field(:articy_id, :string)

    timestamps()
  end

  def insert_changeset(data) do
    %__MODULE__{}
    |> Map.merge(%{
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
    |> cast(data, __MODULE__.__schema__(:fields))
    |> validate_required([:id, :title])
  end
end
