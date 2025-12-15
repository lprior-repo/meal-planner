//// HTTP client helper for integration tests

import gleam/http
import gleam/http/request
import gleam/http/response
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
  case request.to(url) {
    Ok(req) -> {
      case httpc.send(req) {
        Ok(resp) -> Ok(#(resp.status, resp.body))
        Error(_) -> Error(ServerNotRunning)
      }
    }
    Error(_) -> Error(InvalidUrl(url))
  }
}

pub fn post(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path
  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Post)
        |> request.set_body(body)
      case httpc.send(req) {
        Ok(resp) -> Ok(#(resp.status, resp.body))
        Error(_) -> Error(ServerNotRunning)
      }
    }
    Error(_) -> Error(InvalidUrl(url))
  }
}

pub fn patch(path: String, body: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path
  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Patch)
        |> request.set_body(body)
      case httpc.send(req) {
        Ok(resp) -> Ok(#(resp.status, resp.body))
        Error(_) -> Error(ServerNotRunning)
      }
    }
    Error(_) -> Error(InvalidUrl(url))
  }
}

pub fn delete(path: String) -> Result(#(Int, String), HttpError) {
  let url = base_url <> path
  case request.to(url) {
    Ok(req) -> {
      let req = req |> request.set_method(http.Delete)
      case httpc.send(req) {
        Ok(resp) -> Ok(#(resp.status, resp.body))
        Error(_) -> Error(ServerNotRunning)
      }
    }
    Error(_) -> Error(InvalidUrl(url))
  }
}
