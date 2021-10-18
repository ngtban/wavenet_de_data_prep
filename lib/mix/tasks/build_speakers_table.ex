defmodule Mix.Tasks.LabelAudioClips do
  use Mix.Task
  import Ecto.Query, only: [from: 2]
  require IEx

  @moduledoc """
    Build speakers table used for labeling audio clips.
    Supplied arguments: none.
    Note that the actors table should be built before running this task.
  """

  @shortdoc "Build speakers table used for labeling audio clips."

  @human_actor_ids 1..145

  # Taken from IMDB and processed.
  # [Snapshot](https://web.archive.org/web/20210707215915/https://www.imdb.com/title/tt14671216/fullcredits)
  # [Live link](https://www.imdb.com/title/tt14671216/fullcredits)

  @va_character_map %{
    "Lucky Singh Azad" => ["Sileng"],
    "Amy Lightowler" => ["Acele"],
    "Stephen Hill" => ["Gary the Cryptofascist"],
    "Kyle Simmons" => ["Video Revachol 24h"],
    "Suzie Sadler" => ["Annette"],
    "Mikee W. Goodman" => [
      "Horrific Necktie",
      "Beautiful Necktie",
      "Spinal Cord",
      "Ancient Reptillian Brain",
      "Limbic System",
      "Birds Nest Roy",
      "Bloated Corpse of a Drunk",
      "Don't Call Abigail",
      "Ruud Hoenkloewen",
      "The Hanged Man",
      "Cuno's Dad",
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
    "David Meyrat" => ["Jean Viquemare", "Man With Sunglasses"],
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
      "Jamrock Pulic Library",
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
      "Raul Kortenaer",
      "Scab Leader",
      "Mysterious Eyes",
      "Sleeping Dockworker",
      "Moneyman",
      "Working Class Drunk",
      "Barry the Butcher",
      "Job Market Loser",
      "Old Scab"
    ],
    "Marine d'Aure" => ["Klaasje (Miss Oranje Disco Dancer)", "Alice", "Radio", "Tutorial Agent"],
    "Xiayah St. Ruth" => ["Cindy the Skull"],
    "Margaret Ashley" => ["The Pigs", "Baroness", "Mother of a Scab"],
    "Kaur Kender" => ["Goracy Kubek"],
    "Elena Dent" => ["Frittte Clerk"],
    "Christopher Gee" => ["Nix Gottlieb", "Large Scab"],
    "Honor Davis-Pye" => ["Little Lily"],
    "Jonny El Hage" => ["Easy Leo", "Chester McLaine", "Another Scab", "DJ Flacio"],
    "Dizzy Dros" => ["Measurehead"],
    "Catherine Blandford" => ["Plaisance"],
    "Peter Svatik" => ["Trant Heidelstam", "Former Coal Miner"],
    "Zachary Sowden" => ["Lilienne's Twins"],
    "Luisa Guerreiro" => ["East Insulindian Repeater Station"],
    "Lenval Brown" => ["Narrator", "Skills", "Objects & Items", "Various"],
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

  def character_va_map do
    Enum.reduce(@va_character_map, %{}, fn {va, characters}, acc ->
      va_character_submap = Map.new(characters, &{&1, va})
      Map.merge(acc, va_character_submap)
    end)
  end

  @impl Mix.Task
  def run(_args) do
    character_va_map = character_va_map()

    list_actor_data =
      Elysium.Repo.all(
        from(actor in Elysium.Actor,
          where: actor.id in @human_actor_ids,
          select: %{
            "id" => actor.id,
            "name" => actor.name
          }
        )
      )

    Enum.map(list_actor_data, fn actor_data ->
      character = actor["name"]

      %{
        "id" => actor["id"],
        "name" => character,
        "actor" => actor["id"],
        "voiced_by" => character_va_map[character]
      }
    end)

    the_narrator_speaker_data = %{
      "id" => 501,
      "name" => "The Narrator",
      "actor" => 0,
      "voiced_by" => "Lenval Brown"
    }

    # a.k.a La Revacholiere
    the_city_speaker_data = %{
      "id" => 502,
      "actor" => nil,
      "voiced_by" => "Linah Rocio"
    }
  end
end
