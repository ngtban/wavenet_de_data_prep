import Config

Code.require_file("config/database.exs")

config :data_prepration, ecto_repos: [Elysium.Repo]
