defmodule Elysium.DialogueEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "dialogue_entries" do
    field(:id, :integer)
    field(:conversation_id, :integer, primary_key: true)
    field(:title, :string)
    field(:dialogue_text, :string)
    field(:sequence, :string)
    field(:actor, :integer)
    field(:conversant, :integer)
    field(:outgoing_links, {:array, :map})
    field(:input_id, :string)
    field(:output_id, :string)
    field(:is_root, :boolean)
    field(:is_group, :boolean)
    field(:node_color, :string)
    field(:delay_sim_status, :integer)
    field(:condition_string, :string)
    field(:false_condition_action, :string)
    field(:user_script, :string)
    field(:on_execute, :map)
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
    |> validate_required(:name)
  end
end
