defmodule Elysium.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field(:name, :string)
    field(:description, :string)
    field(:medium_text_value, :string)
    field(:item_group, :integer)
    field(:stack_name, :string)
    field(:displayname, :string)
    field(:item_type, :integer)
    field(:item_value, :integer)
    field(:conversation, :string)
    field(:equip_orb, :string)
    field(:tooltip, :string)
    field(:fixture_description, :string)
    field(:fixture_bonus, :string)
    field(:requirement, :string)
    field(:is_item, :boolean)
    field(:is_substance, :boolean)
    field(:is_consumable, :boolean)
    field(:autoequip, :boolean)
    field(:multiple_allowed, :boolean)
    field(:cursed, :boolean)
    field(:is_thought, :boolean)
    field(:thought_type, :integer)
    field(:time_left, :integer)
    field(:technical_name, :string)
    field(:articy_id, :string)
    field(:sound, :integer)

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
