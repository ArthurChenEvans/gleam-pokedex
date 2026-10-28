import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/string

pub type Sprite {
  Sprite(pokemon_id: Int, pokemon_name: String, url: String)
}

fn sprite_decoder() -> decode.Decoder(Sprite) {
  use pokemon_id <- decode.field("id", decode.int)
  use pokemon_name <- decode.field("name", decode.string)
  use url <- decode.subfield(["sprites", "front_default"], decode.string)

  decode.success(Sprite(pokemon_id:, pokemon_name:, url:))
}

pub fn main() -> Nil {
  let assert Ok(api_request) =
    request.to("https://pokeapi.co/api/v2/pokemon/ditto")

  let assert Ok(api_response) = httpc.send(api_request)

  let result = json.parse(from: api_response.body, using: sprite_decoder())

  case result {
    Ok(sprite) ->
      io.println(
        "Pokemon: "
        <> sprite.pokemon_name
        <> " found with sprite URL: "
        <> sprite.url,
      )
    Error(error) -> io.println("Json decode error: " <> string.inspect(error))
  }
}
