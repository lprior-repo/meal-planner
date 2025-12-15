//// HTTP client helper for integration tests

import gleam/http
import gleam/http/request
import gleam/httpc

const base_url = "http://localhost:8080"

pub type HttpError {
  ServerNotRunning
  NetworkError(String)
  InvalidUrl(String)
}

pub fn get(path: String) -> Result(#(Int, String), HttpError) {
  let req =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_scheme(http.Http)
    |> request.set_host("localhost:8080")
    |> request.set_path(path)

  case httpc.send(req) {
    Ok(response) -> Ok(#(response.status, response.body))
    Error(_) -> Error(ServerNotRunning)
  }
}

pub fn post(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Http)
    |> request.set_host("localhost:8080")
    |> request.set_path(path)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)

  case httpc.send(req) {
    Ok(response) -> Ok(#(response.status, response.body))
    Error(_) -> Error(ServerNotRunning)
  }
}

pub fn patch(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let req =
    request.new()
    |> request.set_method(http.Patch)
    |> request.set_scheme(http.Http)
    |> request.set_host("localhost:8080")
    |> request.set_path(path)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(body)

  case httpc.send(req) {
    Ok(response) -> Ok(#(response.status, response.body))
    Error(_) -> Error(ServerNotRunning)
  }
}

pub fn delete(path: String) -> Result(#(Int, String), HttpError) {
  let req =
    request.new()
    |> request.set_method(http.Delete)
    |> request.set_scheme(http.Http)
    |> request.set_host("localhost:8080")
    |> request.set_path(path)

  case httpc.send(req) {
    Ok(response) -> Ok(#(response.status, response.body))
    Error(_) -> Error(ServerNotRunning)
  }
}
