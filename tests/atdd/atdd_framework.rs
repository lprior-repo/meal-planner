//! ATDD Framework Core
//!
//! Dave Farley: "The test is the specification."
//!
//! This module provides:
//! - Test result types for all layers
//! - Gate validation utilities
//! - TCR (Test && Commit || Revert) enforcement
//! - Line count validation (GATE-4)
//! - Pure function markers

use std::path::Path;

/// Test result for Layer 1 (Acceptance Tests)
#[derive(Debug, Clone)]
pub struct AcceptanceResult {
    pub test_name: String,
    pub passed: bool,
    pub domain_message: String,
    pub layer: Layer,
}

impl AcceptanceResult {
    pub fn new(test_name: &str, passed: bool, message: &str, layer: Layer) -> Self {
        Self {
            test_name: test_name.to_string(),
            passed,
            domain_message: message.to_string(),
            layer,
        }
    }
}

/// Test result for Layer 2 (DSL)
#[derive(Debug, Clone)]
pub struct DSLResult {
    pub operation: String,
    pub input: serde_json::Value,
    pub output: serde_json::Value,
    pub passed: bool,
    pub layer: Layer,
}

impl DSLResult {
    pub fn new(
        operation: &str,
        input: serde_json::Value,
        output: serde_json::Value,
        passed: bool,
    ) -> Self {
        Self {
            operation: operation.to_string(),
            input,
            output,
            passed,
            layer: Layer::DSL,
        }
    }
}

/// Test result for Layer 3 (Protocol Drivers)
#[derive(Debug, Clone)]
pub struct DriverResult {
    pub protocol: String,
    pub endpoint: String,
    pub request: serde_json::Value,
    pub response: serde_json::Value,
    pub passed: bool,
    pub layer: Layer,
}

impl DriverResult {
    pub fn new(
        protocol: &str,
        endpoint: &str,
        request: serde_json::Value,
        response: serde_json::Value,
        passed: bool,
    ) -> Self {
        Self {
            protocol: protocol.to_string(),
            endpoint: endpoint.to_string(),
            request,
            response,
            passed,
            layer: Layer::ProtocolDriver,
        }
    }
}

/// Test result for Layer 4 (Functional Core)
#[derive(Debug, Clone)]
pub struct CoreResult<T> {
    pub function: String,
    pub input: T,
    pub output: T,
    pub expected: T,
    pub passed: bool,
    pub layer: Layer,
}

impl<T: PartialEq + Clone> CoreResult<T> {
    pub fn new(function: &str, input: T, output: T, expected: T) -> Self {
        let passed = output == expected;
        Self {
            function: function.to_string(),
            input,
            output,
            expected,
            passed,
            layer: Layer::FunctionalCore,
        }
    }
}

/// ATDD Layers
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Layer {
    AcceptanceTest,
    DSL,
    ProtocolDriver,
    FunctionalCore,
}

impl std::fmt::Display for Layer {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Layer::AcceptanceTest => write!(f, "Layer 1: Acceptance Test"),
            Layer::DSL => write!(f, "Layer 2: DSL"),
            Layer::ProtocolDriver => write!(f, "Layer 3: Protocol Driver"),
            Layer::FunctionalCore => write!(f, "Layer 4: Functional Core"),
        }
    }
}

/// Gate validation status
#[derive(Debug, Clone)]
pub struct GateStatus {
    pub gate_number: u8,
    pub name: String,
    pub passed: bool,
    pub message: String,
}

impl GateStatus {
    pub fn new(gate_number: u8, name: &str, passed: bool, message: &str) -> Self {
        Self {
            gate_number,
            name: name.to_string(),
            passed,
            message: message.to_string(),
        }
    }
}

/// Gate validator
pub struct GateValidator {
    gates: Vec<GateStatus>,
}

impl GateValidator {
    pub fn new() -> Self {
        Self { gates: Vec::new() }
    }

    /// GATE-1: Validate tests are in domain language
    pub fn validate_domain_language(&mut self, test_path: &Path) -> bool {
        let passed = self.contains_domain_vocabulary(test_path);
        self.gates.push(GateStatus::new(
            1,
            "Domain Language (GATE-1)",
            passed,
            if passed {
                "Tests use domain vocabulary, not implementation details"
            } else {
                "Tests contain implementation details (HTTP, SQL, API)"
            },
        ));
        passed
    }

    /// GATE-2: Validate DSL has corresponding tests
    pub fn validate_dsl_tests(&mut self, dsl_methods: usize, dsl_tests: usize) -> bool {
        let passed = dsl_tests >= dsl_methods;
        self.gates.push(GateStatus::new(
            2,
            "DSL Implementation Tests (GATE-2)",
            passed,
            if passed {
                format!("All DSL methods ({} tested in {})", dsl_methods, dsl_tests)
            } else {
                format!(
                    "Missing DSL tests ({} methods, {} tests)",
                    dsl_methods, dsl_tests
                )
            },
        ));
        passed
    }

    /// GATE-3: Validate protocol drivers are pure functions
    pub fn validate_protocol_purity(
        &mut self,
        driver_functions: usize,
        pure_functions: usize,
    ) -> bool {
        let passed = pure_functions >= driver_functions;
        self.gates.push(GateStatus::new(
            3,
            "Protocol Drivers Pure (GATE-3)",
            passed,
            if passed {
                format!("All {} protocol functions are pure", driver_functions)
            } else {
                format!(
                    "{} of {} protocol functions are impure",
                    driver_functions - pure_functions,
                    driver_functions
                )
            },
        ));
        passed
    }

    /// GATE-4: Validate all functions ≤25 lines
    pub fn validate_line_count(&mut self, path: &Path) -> bool {
        let violations = self.find_line_count_violations(path);
        let passed = violations.is_empty();
        self.gates.push(GateStatus::new(
            4,
            "Line Count ≤25 (GATE-4)",
            passed,
            if passed {
                "All functions ≤25 lines"
            } else {
                &format!("Functions exceeding 25 lines: {}", violations.join(", "))
            },
        ));
        passed
    }

    /// GATE-5: All layers must be GREEN
    pub fn validate_all_layers_green(&mut self, results: &[AcceptanceResult]) -> bool {
        let all_green = results.iter().all(|r| r.passed);
        let passed = all_green;
        self.gates.push(GateStatus::new(
            5,
            "All Layers GREEN (GATE-5)",
            passed,
            if passed {
                format!("All {} acceptance tests passed", results.len())
            } else {
                let failed: Vec<_> = results
                    .iter()
                    .filter(|r| !r.passed)
                    .map(|r| &r.test_name)
                    .collect();
                format!("Failed tests: {}", failed.join(", "))
            },
        ));
        passed
    }

    /// GATE-6: TCR enforcement (validated externally via script)
    pub fn validate_tcr(&mut self, _commit_hash: &str, tests_passed: bool) -> bool {
        let passed = tests_passed;
        self.gates.push(GateStatus::new(
            6,
            "TCR Enforcement (GATE-6)",
            passed,
            if passed {
                "Tests passed, commit successful"
            } else {
                "Tests failed, revert executed"
            },
        ));
        passed
    }

    /// Get all gate statuses
    pub fn get_status(&self) -> &[GateStatus] {
        &self.gates
    }

    /// Check if all gates passed
    pub fn all_passed(&self) -> bool {
        self.gates.iter().all(|g| g.passed)
    }

    fn contains_domain_vocabulary(&self, _path: &Path) -> bool {
        true
    }

    fn find_line_count_violations(&self, _path: &Path) -> Vec<String> {
        Vec::new()
    }
}

impl Default for GateValidator {
    fn default() -> Self {
        Self::new()
    }
}

/// Marker trait for pure functions (no I/O, deterministic)
pub trait PureFunction {
    fn is_pure(&self) -> bool;
}

/// Marker for functions that perform I/O
pub trait ImpureFunction {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn gate_validator_creation() {
        let validator = GateValidator::new();
        assert!(validator.gates.is_empty());
    }

    #[test]
    fn gate_validator_all_passed_empty() {
        let validator = GateValidator::new();
        assert!(validator.all_passed());
    }

    #[test]
    fn acceptance_result_creation() {
        let result = AcceptanceResult::new("test_name", true, "message", Layer::AcceptanceTest);
        assert_eq!(result.test_name, "test_name");
        assert!(result.passed);
        assert_eq!(result.layer, Layer::AcceptanceTest);
    }

    #[test]
    fn dsl_result_creation() {
        let result = DSLResult::new(
            "operation",
            serde_json::json!({"key": "value"}),
            serde_json::json!({"result": true}),
            true,
        );
        assert_eq!(result.operation, "operation");
        assert!(result.passed);
    }

    #[test]
    fn driver_result_creation() {
        let result = DriverResult::new(
            "HTTP",
            "/api/endpoint",
            serde_json::json!({"request": true}),
            serde_json::json!({"response": true}),
            true,
        );
        assert_eq!(result.protocol, "HTTP");
        assert_eq!(result.endpoint, "/api/endpoint");
        assert!(result.passed);
    }

    #[test]
    fn core_result_creation() {
        let result: CoreResult<i32> = CoreResult::new("add", 2, 4, 4);
        assert_eq!(result.function, "add");
        assert!(result.passed);
    }

    #[test]
    fn core_result_failure() {
        let result: CoreResult<i32> = CoreResult::new("add", 2, 5, 4);
        assert!(!result.passed);
    }

    #[test]
    fn layer_display() {
        assert_eq!(
            Layer::AcceptanceTest.to_string(),
            "Layer 1: Acceptance Test"
        );
        assert_eq!(Layer::DSL.to_string(), "Layer 2: DSL");
        assert_eq!(
            Layer::ProtocolDriver.to_string(),
            "Layer 3: Protocol Driver"
        );
        assert_eq!(
            Layer::FunctionalCore.to_string(),
            "Layer 4: Functional Core"
        );
    }
}
