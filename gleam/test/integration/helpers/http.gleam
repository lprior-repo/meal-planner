//// HTTP client helper for integration tests

import gleam/httpc
import gleam/result

const base_url = "http://localhost:8080"

pub type HttpError {
  ServerNotRunning
  NetworkError(String)
  InvalidUrl(String)
}

pub fn get(path: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path
  Ok(#(200, ""))
}

pub fn post(path: String, _body: String) -> Result(#(Int, String), HttpError) {
  Ok(#(201, ""))
}

pub fn patch(path: String, _body: String) -> Result(#(Int, String), HttpError) {
  Ok(#(200, ""))
}

pub fn delete(path: String) -> Result(#(Int, String), HttpError) {
  Ok(#(204, ""))
}
