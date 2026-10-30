import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string

pub type BaseStats {
  BaseStats(
    hp: Int,
    attack: Int,
    defense: Int,
    special_attack: Int,
    special_defense: Int,
    speed: Int,
  )
}

pub type PokemonType {
  Normal
  Fire
  Water
  Electric
  Grass
  Ice
  Fighting
  Poison
  Ground
  Flying
  Psychic
  Bug
  Rock
  Ghost
  Dragon
  Dark
  Steel
  Fairy
}

pub type PokemonTypes {
  PokemonTypes(first: PokemonType, second: Option(PokemonType))
}

pub type Pokemon {
  Pokemon(
    id: Int,
    name: String,
    types: PokemonTypes,
    base_stats: BaseStats,
    sprite_url: String,
  )
}

fn base_stat_decoder() -> decode.Decoder(Int) {
  use base_stat <- decode.field("base_stat", decode.int)

  decode.success(base_stat)
}

fn pokemon_type_decoder() -> decode.Decoder(PokemonType) {
  use name <- decode.then(decode.string)
  case name {
    "normal" -> decode.success(Normal)
    "fire" -> decode.success(Fire)
    "water" -> decode.success(Water)
    "electric" -> decode.success(Electric)
    "grass" -> decode.success(Grass)
    "ice" -> decode.success(Ice)
    "fighting" -> decode.success(Fighting)
    "poison" -> decode.success(Poison)
    "ground" -> decode.success(Ground)
    "flying" -> decode.success(Flying)
    "psychic" -> decode.success(Psychic)
    "bug" -> decode.success(Bug)
    "rock" -> decode.success(Rock)
    "ghost" -> decode.success(Ghost)
    "dragon" -> decode.success(Dragon)
    "dark" -> decode.success(Dark)
    "steel" -> decode.success(Steel)
    "fairy" -> decode.success(Fairy)
    _ -> decode.failure(Normal, "PokemonType")
  }
}

fn type_slot_decoder() -> decode.Decoder(PokemonType) {
  decode.at(["type", "name"], pokemon_type_decoder())
}

fn pokemon_types_decoder() -> decode.Decoder(PokemonTypes) {
  use types <- decode.then(decode.list(type_slot_decoder()))
  case types {
    [first] -> decode.success(PokemonTypes(first:, second: None))
    [first, second] ->
      decode.success(PokemonTypes(first:, second: Some(second)))
    _ -> decode.failure(PokemonTypes(Normal, None), "PokemonTypes")
  }
}

fn pokemon_decoder() -> decode.Decoder(Pokemon) {
  // decode.field only grabs from top level
  // decode.subfield takes a List(a) as a first argument
  // This is for grabbing a nested set of fields, where each item is
  // nested within the previous one.
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use types <- decode.field("types", decode.list())
  use base_stats <- decode.field("stats", {
    use hp <- decode.field(0, base_stat_decoder())
    use attack <- decode.field(1, base_stat_decoder())
    use defense <- decode.field(2, base_stat_decoder())
    use special_attack <- decode.field(3, base_stat_decoder())
    use special_defense <- decode.field(4, base_stat_decoder())
    use speed <- decode.field(5, base_stat_decoder())

    decode.success(BaseStats(
      hp:,
      attack:,
      defense:,
      special_attack:,
      special_defense:,
      speed:,
    ))
  })
  use sprite_url <- decode.subfield(["sprites", "front_default"], decode.string)

  decode.success(Pokemon(id:, name:, types:, sprite_url:))
}

pub fn main() -> Nil {
  let assert Ok(api_request) =
    request.to("https://pokeapi.co/api/v2/pokemon/ditto")

  let assert Ok(api_response) = httpc.send(api_request)

  let result = json.parse(from: api_response.body, using: pokemon_decoder())

  case result {
    Ok(pokemon) ->
      io.println(
        "Pokemon: " <> pokemon.name <> " found with sprite URL: " <> sprite.url,
      )
    Error(error) -> io.println("Json decode error: " <> string.inspect(error))
  }
}
