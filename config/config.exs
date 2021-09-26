import Config

Code.require_file("config/database.exs")

config :data_prepration, ecto_repos: [Elysium.Repo]

import_config "#{Mix.env()}.exs"
