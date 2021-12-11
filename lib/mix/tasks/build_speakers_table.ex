defmodule Mix.Tasks.BuildSpeakersTable do
  use Mix.Task
  import Ecto.Query, only: [from: 2]

  @moduledoc """
    Build speakers table used for labeling audio clips.
    Supplied arguments: none.
    Note that the actors table should be built before running this task.
  """

  @shortdoc "Build speakers table used for labeling audio clips."

  # Taken from IMDB, processed, corrected.
  # [Snapshot](https://web.archive.org/web/20210707215915/https://www.imdb.com/title/tt14671216/fullcredits)
  # [Live link](https://www.imdb.com/title/tt14671216/fullcredits)

  @va_character_map %{
    "Lucky Singh Azad" => ["Siileng"],
    "Amy Lightowler" => ["Acele"],
    "Stephen Hill" => ["Gary the Cryptofascist"],
    "Kyle Simmons" => ["Video Revachol 24h"],
    "Suzie Sadler" => ["Annette"],
    "Mikee W. Goodman" => [
      "Horrific Necktie",
      "Beautiful Necktie",
      "Spinal Cord",
      "Ancient Reptilian Brain",
      "Limbic System",
      "Birds Nest Roy",
      "Bloated Corpse of a Drunk",
      "Don't Call Abigail",
      "Ruud Hoenkloewen",
      "The Hanged Man",
      "A Shadow on the Bed",
      "Girard",
      "Writer",
      "The Great Doorgunner Megamix",
      "Strikebreaker",
      "Tare Drunk"
    ],
    "Adam Lawton Stanley" => [
      "Garte the Cafeteria Manager",
      "Unemployed Person",
      "Sad Scab",
      "Banger Scab"
    ],
    "Xander J Phillips" => ["Mikael Heidelstam"],
    "Benji Webbe" => ["Eugene", "DJ Mesh"],
    "David Meyrat" => ["Jean Vicquemare", "Man With Sunglasses"],
    "Adi Alfa" => ["Elizabeth", "The Gardener"],
    "Dot Major" => ["Noid"],
    "Hayley Leggs" => ["Real Estate Agent", "Tricentennial Electrics"],
    "Tegen Hitchens" => [
      "Joyce Messier",
      "Sylvie",
      "Lena the Cryptozoologist's wife",
      "Lilienne the Net Picker",
      "De Paule",
      "Working Class Woman",
      "Electronic Doorbell: 24h Window Company",
      "Women's Rights"
    ],
    "Jonathon West" => [
      "Idiot Doom Spiral",
      "Man on Waterlock",
      "Jamrock Public Library",
      "Shanky",
      "Probably a Migrant",
      "Scab",
      "Fat Angus"
    ],
    "Amber Janelle Putnam" => ["Ruby the Instigator"],
    "Oliver Dabiri" => ["Cuno", "Boy Strikebreaker"],
    "Heti Tulve" => ["Scabette"],
    "Moritz Bäckerling" => ["Echo Maker"],
    "Mark Holcomb" => ["Call Me Mañana", "Tommy Le Homme", "Smoker on the Balcony"],
    "Pierre Maubouche" => ["Racist Lorry Driver"],
    "Mack Padraig McGuire" => [
      "Titus Hardie",
      "Kortenaer",
      "Scab Leader",
      "Mysterious Eyes",
      "Sleeping Dockworker",
      "Moneyman",
      "Working Class Drunk",
      "Barry the Butcher",
      "Job Market Loser",
      "Old Scab",
      "Mysterious Pair of Eyes"
    ],
    "Marine d'Aure" => ["Klaasje (Miss Oranje Disco Dancer)", "Alice", "Radio", "Tutorial Agent"],
    "Xiayah St. Ruth" => ["Cindy the Skull"],
    "Margaret Ashley" => ["The Pigs", "Baroness", "Mother of a Scab"],
    "Kaur Kender" => ["Gorący Kubek"],
    "Elena Dent" => ["Frittte Clerk"],
    "Christopher Gee" => ["Nix Gottlieb", "Large Scab"],
    "Honor Davis-Pye" => ["Little Lily"],
    "Jonny El Hage" => ["Easy Leo", "Chester McLaine", "Another Scab", "DJ Flacio"],
    "Dizzy Dros" => ["Measurehead"],
    "Catherine Blandford" => ["Plaisance"],
    "Peter Svatik" => ["Trant Heidelstam", "Former Coal Miner"],
    "Zachary Sowden" => ["Lilienne's Twin", "Lilienne's Other Twin", "Netpicker's Twins"],
    "Luisa Guerreiro" => ["East Insulindian Repeater Station"],
    "Lenval Brown" => [
      "Narrator",
      "Skills",
      "Objects & Items",
      "Various",
      "Game Over",
      "Coupris Kineema"
    ],
    "Jullian Champenois" => ["Kim Kitsuragi"],
    "Maria Elena Carbonell Abors" => ["Paledriver"],
    "Tariq Khan" => [
      "Steban the Student Communist",
      "Evrart Claire",
      "Andre",
      "Glen",
      "Egg Head",
      "Rosemary"
    ],
    "Yuan Zhang-Taal" => ["Insulindian Phasmid"],
    "Chris Lines" => ["The Deserter"],
    "Ev Ryan" => ["Cleaning Lady"],
    "Yoana Nikolova" => ["Measurehead's Babe", "Novelty Dicemaker"],
    "Miroslav Kokenov" => ["Mega Rich Light-Bending Guy"],
    "Jean-Pascal Heynemand" => ["Sunday Friend"],
    "Jonathan G. Rodriguez" => ["Tiago", "Alphonse the Scab"],
    "Kyle James" => ["Pissf****t"],
    "Hervé Carrascosa" => ["Gaston Martin"],
    "Alexandre Déwen" => ["Jules Pidieu"],
    "Carla Weingarten" => ["Woman from Gottwald"],
    "Jafro" => [
      "Fuck the World",
      "Payphone: Young Man",
      "Very Hard to Exploit Handicapped Person"
    ],
    "Veronica Too" => ["Washerwoman"],
    "Elina Hietala" => ["Soona the Programmer"],
    "Setty Brosevelt" => ["Mack Torson", "Canal Crew", "Right-to-Worker"],
    "Paul Delaross" => ["Morell the Cryptozoologist"],
    "Annie Warburton" => ["Cunoesse", "Judit Minot", "Horse-Faced Woman", "Dora", "Dolores Dei"],
    "Jorel Paul" => ["Theo", "René Arnoux"],
    "Anita Kyoda" => ["Coalition Warship Archer"],
    "Linah Rocio" => ["La Revacholiere"]
  }

  defp character_va_map do
    Enum.reduce(@va_character_map, %{}, fn {va, characters}, acc ->
      va_character_submap =
        Map.new(characters, fn character ->
          key = va_map_key(character)

          {key, va}
        end)

      Map.merge(acc, va_character_submap)
    end)
  end

  defp va_map_key(character) do
    character
    |> String.graphemes()
    |> Enum.filter(&String.match?(&1, ~r/[a-zA-Z]/))
    |> Enum.join()
    |> String.downcase()
  end

  @impl Mix.Task
  def run(_args) do
    character_va_map = character_va_map()

    list_human_actor_id = Constants.human_actor_ids()

    list_actor_data =
      Elysium.Repo.all(
        from(actor in Elysium.Actor,
          where: actor.id in ^list_human_actor_id,
          select: %{
            "id" => actor.id,
            "name" => actor.name
          }
        )
      )

    list_existing_speaker_data =
      Enum.map(list_actor_data, fn actor_data ->
        character = actor_data["name"]
        va_map_key = va_map_key(character)

        %{
          "id" => actor_data["id"],
          "name" => character,
          "actor" => actor_data["id"],
          "voiced_by" => character_va_map[va_map_key]
        }
      end)

    the_narrator_speaker_data = %{
      "id" => Constants.narrator_speaker_id(),
      "name" => "The Narrator",
      "actor" => 0,
      "voiced_by" => "Lenval Brown"
    }

    the_city_speaker_data = %{
      "id" => Constants.city_speaker_id(),
      "name" => "Le Revacholiere",
      "actor" => nil,
      "voiced_by" => "Linah Rocio"
    }

    list_speaker_data =
      [the_narrator_speaker_data, the_city_speaker_data | list_existing_speaker_data]
      |> Enum.map(fn speaker_data ->
        Elysium.Speaker.insert_changeset(speaker_data)
        |> Ecto.Changeset.apply_action(:upsert)
        |> case do
          {:ok, speaker} -> Map.take(speaker, Elysium.Speaker.__schema__(:fields))
          {:error, _changeset} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Elysium.Repo.insert_all(
      Elysium.Speaker,
      list_speaker_data,
      on_conflict: :replace_all,
      conflict_target: [:id]
    )
  end
end
