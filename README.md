## What does this repository do?

This repository is for extracting asset data, namely voice clips and their corresponding transcriptions, from the game [Disco Elysium](https://zaumstudio.com/#disco-elysium), specifically the "Final Cut" version, and reformat the extracted data into a format that [ESPnet](https://github.com/espnet/espnet) understands and could use to train a vocoder.

My goal is to at the very least 1) have a vocoder using [WaveNet](https://arxiv.org/abs/1609.03499) with the characteristics of the narrator in the "Final Cut" version of the game, and 2) package and publish the vocoder as a mobile app, as the open source ones I found so far are not really great.

To these ends, I intend to have three repositories:
1. One to extract the dialogue data, audio clips, and match them together in a format understood by ESPnet for training, which is this repository.
2. One dedicated to problems that arise when training the vocoder.
3. One (or maybe two for each currently dominant mobile platforms) for the packaging and publishing of the vocoder on the mobile platform.

I put the code for preparing the data into [Mix tasks](https://hexdocs.pm/mix/1.12/Mix.Task.html). You can check them under `mix/tasks` to see the details.

## Why?

I love the game and the voice of its narrator, and perhaps out of vanity I think I could do better than current open-source text-to-speech solutions available on mobile platforms.

## Cautions

This project is written with the Final Cut version of the game in mind, specifically version `2832f901`, released on 2021-04-19.

I cannot ensure the correctness of the app for earlier or later versions, for now. You can help me with this though!

Please also note that you will need around 65GB of free disk space to store the extracted audio clips.

## Getting the project up and running
Should you wish to try out the code in this repo, please follow the instructions below:

### Prerequisites

You should have these installed:

1. Elixir 1.14.0
2. Erlang OTP 25.1
2. PostgreSQL 13.3

I cannot guarantee that the code works for lower versions of the applications listed above.

Please also make sure that you have a around 65GB of free disk space for the audio clips.

### Fetching dependencies
Create a `database.exs` file under the folder `config` of the repository. The content of the file should look like this:

```Elixir
import Config

config :data_prepration, Elysium.Repo,
  database: "elysium",
  username: "<Your Database Username Here>",
  password: "<Your Database Password Here>",
  hostname: "localhost",
  log: :info # Change this to false to mute ecto debug logs. Keep it otherwise.
```

Then run `mix deps.get` to install dependencies of the project. Note that the file `database.exs` is necessary for setting up the database as well.

### Setting up a database connection.

Make sure that you have created a user within PostgreSQL using the credentials in the file `database.exs`. Then run these commands to setup the database:

```Bash
mix ecto.create
mix ecto.migrate
```

## Using the mix tasks to prepare the extracted data for training.

### Extracting dialogue data and audio clips from the asset files
You will need to use [Asset Studio](https://github.com/Perfare/AssetStudio/) to extract data from the asset files. Please purchase a copy of the game. If you have some financial troubles, or find it a hassle to buy one just to see what this repo does, I can give you the extracted files and you can skip this part.

However, I assure you that the game is worth your time and your money. Buy it, if not to sate your curiosity, then for the appreciation of art.

With all that said:

#### Extracting the dialogue data, which contains transcription of conversations:
1. Locate your local installation of the game.
2. Open Asset Studio.
3. Load the file at `<game root>/disco_Data/StreamingAssets/aa/StandaloneWindows64/dialoguebundle_assets_all_e4239cda0ff6c4eae0918569b6988e3c.bundle`.
4. Export all the assets you see in Asset Studio. There should only be one asset containing the bundled dialogue data.

You should see the folder `MonoBehaviour` within the location you chose in step #4.

#### Extracting the audio clips files.
1. Please make sure that you have the free disk space needed to store the audio clips. You should have around 65GBs of free disk.
2. Open Asset Studio.
3. Load the **folder** at  `<game root>/disco_Data/StreamingAssets/aa/StandaloneWindows64/`.
4. Filter the asset by type, make sure that only `AudioClip` is checked.
5. Export the files. It will take a while.
6. You should see a new folder "MonoBehaviour" that contains a json file named "Disco Elysium".

#### Extracting the dialogue data and matching the the transcriptions to the audio clips.

So far I have only completed the task for extrating the transcription data from the dialogue bundle. I am having a bit of a problem when it comes to matching the transcription.

If you want to have a try at extracting the dialogue data and save the resulting data in a database, run this mix task:
`mix prepare_bundle <path to the json file containing dialogue data>`

You can check issue #6 to see what I am really doing in that mix task.

For a list of other mix tasks used for processing the bundled dialogue data, check the folder at the path `lib/mix/tasks`.

## Feedback
If you are interested in contributing or reporting bugs, please check the [Issues](https://github.com/ngtban/wavenet_de_data_prep/issues) page of this repository. Any feedback is appreciated.
