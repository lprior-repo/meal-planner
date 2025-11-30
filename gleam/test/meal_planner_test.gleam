import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Basic sanity test
pub fn hello_world_test() {
  "hello"
  |> should.equal("hello")
}
