defmodule Elysium.Repo do
  use Ecto.Repo,
    otp_app: :data_prepration,
    adapter: Ecto.Adapters.Postgres
end
