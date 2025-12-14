/// Analytics stub module
///
/// TODO: Implement analytics functionality
import pog

pub type SearchEvent {
  SearchEvent(query: String, results: Int)
}

pub fn record_search_event(_conn: pog.Connection, _event: SearchEvent) -> Nil {
  // Stub implementation - does nothing for now
  Nil
}
