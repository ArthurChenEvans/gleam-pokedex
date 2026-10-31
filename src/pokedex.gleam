import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
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

fn pokemon_type_to_string(pokemon_type: PokemonType) -> String {
  case pokemon_type {
    Normal -> "normal"
    Fire -> "fire"
    Water -> "water"
    Electric -> "electric"
    Grass -> "grass"
    Ice -> "ice"
    Fighting -> "fighting"
    Poison -> "poison"
    Ground -> "ground"
    Flying -> "flying"
    Psychic -> "psychic"
    Bug -> "bug"
    Rock -> "rock"
    Ghost -> "ghost"
    Dragon -> "dragon"
    Dark -> "dark"
    Steel -> "steel"
    Fairy -> "fairy"
  }
}

// To handle nested JSON values you essentially call decoders within decoders
// This one is called by the main decoder. It's handy when you know there is
// a fixed number of elements in a JSON list.
fn base_stat_decoder() -> decode.Decoder(Int) {
  use base_stat <- decode.field("base_stat", decode.int)

  decode.success(base_stat)
}

// Used to decode the type name from type
fn pokemon_type_decoder() -> decode.Decoder(PokemonType) {
  // .then used when you want to do something with the value
  // and then you pass a decoder to continue with
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

/// Returns a decoder. Basically once we are at a type section like:
/// ```json
///  "types": [
///   {
///     "slot": 1,
///     "type": {
///       "name": "grass",
///       "url": "https://pokeapi.co/api/v2/type/12/"
///     }
///   },
///   {
///     "slot": 2,
///     "type": {
///       "name": "poison",
///       "url": "https://pokeapi.co/api/v2/type/4/"
///     }
///   }
/// ],
/// ```
/// `type_slot_decoder()` is called to search through
/// `"type"` and then `"name"`. It then calls the
/// `pokemon_type_decoder` on it to convert it into a `PokemonType`
/// and reutrn that value as a successful decode. Note:
/// `pokemon_type_decoder` is purely for mapping a string to an Enum.
/// `type_slot_decoder` is for actually **FINDING** the string to map.
fn type_slot_decoder() -> decode.Decoder(PokemonType) {
  decode.at(["type", "name"], pokemon_type_decoder())
}

/// This is where we pattern match types. Notice the above JSON
/// has two types. How do we know which goes to what? We make a custom
/// `PokemonTypes` to limit how many properties it has to just two. Because with
/// `List(String)` you could get more than two values. Second, by having named
/// properties, we can match based on how many items was found in the list.
fn pokemon_types_decoder() -> decode.Decoder(PokemonTypes) {
  // decode.list makes you perform the decoder function on each item in the list
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
  use types <- decode.field("types", pokemon_types_decoder())
  // If you know there is always n fields in that exact order
  //  you can just set the first value as a number matching the index
  // of the element you want to target
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

  decode.success(Pokemon(id:, name:, types:, base_stats:, sprite_url:))
}

pub fn main() -> Nil {
  let assert Ok(api_request) = request.to("https://pokeapi.co/api/v2/pokemon/1")

  let assert Ok(api_response) = httpc.send(api_request)

  let result = json.parse(from: api_response.body, using: pokemon_decoder())

  case result {
    Ok(pokemon) ->
      io.println(
        "Pokemon: "
        <> pokemon.name
        <> " found with sprite URL: "
        <> pokemon.sprite_url
        <> "\nWith types: "
        <> pokemon_type_to_string(pokemon.types.first)
        <> " and base stats:"
        <> "\nHP: "
        <> int.to_string(pokemon.base_stats.hp)
        <> "\nAttack: "
        <> int.to_string(pokemon.base_stats.attack)
        <> "\nDefense: "
        <> int.to_string(pokemon.base_stats.defense)
        <> "\nSpecial Attack: "
        <> int.to_string(pokemon.base_stats.special_attack)
        <> "\nSpecial Defense: "
        <> int.to_string(pokemon.base_stats.special_defense)
        <> "\nSpeed: "
        <> int.to_string(pokemon.base_stats.speed),
      )
    Error(error) -> io.println("Json decode error: " <> string.inspect(error))
  }
}
