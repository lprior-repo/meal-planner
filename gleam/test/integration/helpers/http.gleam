//// HTTP client helper for integration tests

import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/result

pub type HttpError {
  ServerNotRunning
  NetworkError(String)
  InvalidUrl(String)
}

pub fn get(path: String) -> Result(#(Int, String), HttpError) {
  request.new()
  |> request.set_method(http.Get)
  |> request.set_host("localhost")
  |> request.set_port(8080)
  |> request.set_path(path)
  |> httpc.send
  |> result.map(fn(resp: response.Response(String)) {
    #(resp.status, resp.body)
  })
  |> result.map_error(fn(_) { ServerNotRunning })
}

pub fn post(path: String, body: String) -> Result(#(Int, String), HttpError) {
  request.new()
  |> request.set_method(http.Post)
  |> request.set_host("localhost")
  |> request.set_port(8080)
  |> request.set_path(path)
  |> request.set_body(body)
  |> httpc.send
  |> result.map(fn(resp: response.Response(String)) {
    #(resp.status, resp.body)
  })
  |> result.map_error(fn(_) { ServerNotRunning })
}

pub fn patch(path: String, body: String) -> Result(#(Int, String), HttpError) {
  request.new()
  |> request.set_method(http.Patch)
  |> request.set_host("localhost")
  |> request.set_port(8080)
  |> request.set_path(path)
  |> request.set_body(body)
  |> httpc.send
  |> result.map(fn(resp: response.Response(String)) {
    #(resp.status, resp.body)
  })
  |> result.map_error(fn(_) { ServerNotRunning })
}

pub fn delete(path: String) -> Result(#(Int, String), HttpError) {
  request.new()
  |> request.set_method(http.Delete)
  |> request.set_host("localhost")
  |> request.set_port(8080)
  |> request.set_path(path)
  |> httpc.send
  |> result.map(fn(resp: response.Response(String)) {
    #(resp.status, resp.body)
  })
  |> result.map_error(fn(_) { ServerNotRunning })
}
