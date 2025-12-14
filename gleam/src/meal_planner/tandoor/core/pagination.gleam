/// Tandoor SDK Core - Pagination Types and Decoders
import gleam/dynamic/decode
import gleam/option.{type Option}

pub type PaginatedResponse(a) {
  PaginatedResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(a),
  )
}

pub type PageParams {
  PageParams(page: Int, page_size: Int)
}

pub fn paginated_decoder(
  item_decoder: decode.Decoder(a),
) -> decode.Decoder(PaginatedResponse(a)) {
  use count <- decode.field("count", decode.int)
  use next <- decode.optional_field("next", decode.string)
  use previous <- decode.optional_field("previous", decode.string)
  use results <- decode.field("results", decode.list(item_decoder))

  decode.success(PaginatedResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}
