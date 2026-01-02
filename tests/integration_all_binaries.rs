//! Integration tests for all Tandoor and FatSecret binaries
//! Tests run against live APIs with credentials from environment or pass
//!
//! This module is a facade that includes focused test modules from tests/tandoor/ and tests/fatsecret/

#[cfg(test)]
mod tandoor {
    #![allow(clippy::unwrap_used)]
    include!("tandoor/mod.rs");
}

#[cfg(test)]
mod fatsecret {
    #![allow(clippy::unwrap_used)]
    include!("fatsecret/mod.rs");
}
