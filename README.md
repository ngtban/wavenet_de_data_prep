# What does this repository do?

This repository is for extracting asset data, namely voice clips and their corresponding transcriptions, from the game [Disco Elysium](https://zaumstudio.com/#disco-elysium) and reformat the extracted data into a format that [ESPnet](https://github.com/espnet/espnet) understands and could use to train a vocoder.

My goal is to at the very least 1) have a vocoder using [WaveNet](https://arxiv.org/abs/1609.03499) with the characteristics of the narrator in the "Final Cut" version of the game 2) package and publish the vocoder as a mobile app, as the open source ones I found so far are not really great.

To these ends, I intend to have three repositories:
1. One to extract the dialogue data, audio clips, and match them together in a format understod by ESPnet for training.
2. One dedicated to problems that arise when training the vocoder.
3. One (or maybe two for each currently dominant mobile platforms) for the packaging and publishing of the vocoder on the mobile platform.

I put the code for preparing the data into [Mix tasks](https://hexdocs.pm/mix/1.12/Mix.Task.html). You can check them under `mix/tasks` to see the details.

# Why?

I love the game and the voice of its narrator, and, perhaps out of vanity, I think I could do better than current open-source text-to-speech solutions available on mobile platforms.

# Could you have chosen something other than a relational database for this job...
*... or another language entirely*?

Well I am much more familiar with relation databases than NoSQL ones. And I found out that I really like the Elixir+Ecto way of handling relation databases.

## Setup
Should you wish to try out the code in this repo, please follow the instructions below:
### Prerequisites

You should have these installed:

1. Elixir 1.10.4
2. PostgreSQL 13.3

I cannot guarantee that the code workers for lower versions of the applications listed above.

Please also make sure that you have a around 65GB of free disk space for the audio clips.

### Fetching dependencies

Run `mix deps.get` to install dependencies of the project.

### Setting up a database connection.

Create a `database.exs` file under the folder `config` of the repository. The content of the file should look like this:

```elixir
config :data_prepration, Elysium.Repo,
  database: "elysium",
  username: "<Your Username Here>",
  password: "<Your Password Here>",
  hostname: "localhost",
  log: :info # Change this to false to mute ecto debug logs. Keep it otherwise.
```

Make sure that you have created a user within PSQL using the credentials above.

Then run:

```
mix ecto.create
mix ecto.migrate
```

to setup the database.

## Using the mix tasks to prepare the extracted data for training.

### Extracting dialogue data and audio clips from the asset files
You will need to use [Asset Studio](https://github.com/Perfare/AssetStudio/) to extract data from the asset files. Please purchase a copy of the game. If you have some financial troubles, or find it a hassle to buy one just to see what this repo does, I can give you the extracted files and you can skip this part.

However, I assure you that the game is worth your time and your money. Buy it, if not to sate your curiosity, then for the appreciation of art.

With all that said:
#### Extracting the dialogue data, which contains transcription of conversations:
1. Locate your local installation of the game.
2. Open Asset Studio.
3. Load the file at `<game root>/disco_Data/StreamingAssets/aa/StandaloneWindows64/dialoguebundle_assets_all_e4239cda0ff6c4eae0918569b6988e3c.bundle`.
4. Export all the assets you listed in Asset Studio. There should only be one asset, though.

You should see the folder `MonoBehaviour` within the location you chose in step #4.

#### Extracting the audio clips files.
1. Please make sure that you have the free space needed to store the audio clips. You should have around 65GBs of free disk.
2. Open Asset Studio.
3. Load the *folder& at  `<game root>/disco_Data/StreamingAssets/aa/StandaloneWindows64/`.
4. Filter the asset by type, make sure that only `AudioClip` is checked.
5. Export the files. It will take a while.
6. You should see a new folder "MonoBehaviour" that contains a json file named "Disco Elysium".

#### Extracting the dialogue data and matching the the transcriptions to the audio clips.

So far I have only completed the task for extrating the transcription data from the dialogue bundle. I am having a bit of a problem when it comes to matching the transcription.

If you want to have a try at extracting the dialogue data and save it in tables, run this mix task:
`mix prepare_bundle <path to the json file containt dialogue data>`

You can check issue #6 to see what I am reallying doing in that mix task.

For a list of other mix tasks used for processing the bundled dialogue data, check the folder at the path `lib/mix/tasks`.

I am currently stuck at matching the transcriptions to the audio files, more precisely I am figuring out how to extract character dialogue wrapped in quotes. Please check [#2](https://github.com/ngtban/wavenet_de_data_prep/issues/2).

Any feedback is appreciated.
