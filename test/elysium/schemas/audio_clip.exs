data = %{
  name: "something"
}

thing =
  Elysium.AudioClip.insert_changeset(data)
  |> Ecto.Changeset.apply_action(:insert)
  |> case do
    {:ok, new_data} -> Map.from_struct(new_data)
    {:error, changes} -> nil
  end
  |> Map.take(Elysium.AudioClip.__schema__(:fields))

Elysium.Repo.insert(thing)
