import gleam/http/request
import gleam/httpc
import gleam/io

pub fn main() -> Nil {
  let assert Ok(api_request) =
    request.to("https://pokeapi.co/api/v2/pokemon/ditto")

  let assert Ok(api_response) = httpc.send(api_request)
  io.println(api_response.body)
}
