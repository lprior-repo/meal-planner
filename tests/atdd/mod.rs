//! ATDD Four-Layer Architecture Framework
//!
//! Following Dave Farley's Modern Software Engineering principles:
//! - Functional Core / Imperative Shell
//!
//! ## Four Layers (GATE-1 to GATE-6)
//!
//! ### Layer 1: Acceptance Tests (WHAT, not HOW)
//! - Domain language, business rules expressed as examples
//! - NO implementation details (SQL, HTTP, API endpoints)
//! - Uses DSL (Layer 2) for all operations
//!
//! ### Layer 2: Domain Specific Language (DSL)
//! - Domain vocabulary hiding all technical details
//! - Test data builders and domain operations
//! - ONE implementation change, tests stay GREEN
//!
//! ### Layer 3: Protocol Drivers (Adapters)
//! - I/O boundaries (HTTP, database, file system)
//! - Pure functions where possible
//! - Translates between DSL and external systems
//!
//! ### Layer 4: System Under Test (Functional Core)
//! - Pure business logic
//! - No I/O, no external dependencies
//! - All functions ≤25 lines (GATE-4)
//!
//! ## Gates
//!
//! | Gate | Requirement | Enforcement |
//! |------|-------------|-------------|
//! | GATE-1 | Tests in domain language | Code review |
//! | GATE-2 | DSL implementation tests | Layer 2 tests |
//! | GATE-3 | Protocol drivers pure | Function signatures |
//! | GATE-4 | All functions ≤25 lines | TCR script |
//! | GATE-5 | All layers GREEN | CI pipeline |
//! | GATE-6 | TCR enforcement | Pre-commit hook |

pub mod atdd_framework;
pub mod layer1_acceptancetest;
pub mod layer2_dsl;
pub mod layer3_protocol_driver;
pub mod layer4_functional_core;
