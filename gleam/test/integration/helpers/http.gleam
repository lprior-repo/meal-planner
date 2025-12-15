//// HTTP client helper for integration tests

import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/result

const base_url = "http://localhost:8080"

pub type HttpError {
  ServerNotRunning
  NetworkError(String)
  InvalidUrl(String)
}

/// Perform HTTP GET request
pub fn get(path: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path

  url
  |> request.to
  |> result.map_error(fn(_) { InvalidUrl(url) })
  |> result.try(fn(req) {
    req
    |> request.set_method(http.Get)
    |> httpc.send
    |> result.map_error(map_httpc_error)
  })
  |> result.map(fn(response) { #(response.status, response.body) })
}

/// Perform HTTP POST request with JSON body
pub fn post(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path

  url
  |> request.to
  |> result.map_error(fn(_) { InvalidUrl(url) })
  |> result.try(fn(req) {
    req
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/json")
    |> httpc.send
    |> result.map_error(map_httpc_error)
  })
  |> result.map(fn(response) { #(response.status, response.body) })
}

/// Perform HTTP PATCH request with JSON body
pub fn patch(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path

  url
  |> request.to
  |> result.map_error(fn(_) { InvalidUrl(url) })
  |> result.try(fn(req) {
    req
    |> request.set_method(http.Patch)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/json")
    |> httpc.send
    |> result.map_error(map_httpc_error)
  })
  |> result.map(fn(response) { #(response.status, response.body) })
}

/// Perform HTTP DELETE request
pub fn delete(path: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path

  url
  |> request.to
  |> result.map_error(fn(_) { InvalidUrl(url) })
  |> result.try(fn(req) {
    req
    |> request.set_method(http.Delete)
    |> httpc.send
    |> result.map_error(map_httpc_error)
  })
  |> result.map(fn(response) { #(response.status, response.body) })
}

/// Map httpc errors to our domain errors
/// We treat all httpc errors as potential connection issues
fn map_httpc_error(_error: httpc.HttpError) -> HttpError {
  // Since we can't reliably distinguish between different error types
  // from httpc, we default to ServerNotRunning for any error
  ServerNotRunning
}
