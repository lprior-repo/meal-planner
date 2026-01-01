use serde::Deserialize;
use serde_json::json;

// Copy the current serde_utils functions for testing
pub fn deserialize_flexible_float<'de, D>(deserializer: D) -> Result<f64, D::Error>
where
    D: serde::Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleFloat {
        Float(f64),
        String(String),
    }

    match FlexibleFloat::deserialize(deserializer)? {
        FlexibleFloat::Float(f) => Ok(f),
        FlexibleFloat::String(s) => {
            if s.is_empty() {
                Err(serde::de::Error::custom("empty string cannot be deserialized as a number"))
            } else {
                s.parse::<f64>().map_err(serde::de::Error::custom)
            }
        }
    }
}

pub fn deserialize_optional_flexible_float<'de, D>(deserializer: D) -> Result<Option<f64>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleFloat {
        Float(f64),
        String(String),
    }

    match Option::<FlexibleFloat>::deserialize(deserializer)? {
        Some(FlexibleFloat::Float(f)) => Ok(Some(f)),
        Some(FlexibleFloat::String(s)) => {
            if s.is_empty() || s == "None" || s == "null" {
                Ok(None)
            } else {
                s.parse::<f64>().map(Some).map_err(serde::de::Error::custom)
            }
        }
        _ => Ok(None),
    }
}

#[derive(Debug, Deserialize)]
struct TestFloatStruct {
    #[serde(deserialize_with = "deserialize_flexible_float")]
    value: f64,
}

#[derive(Debug, Deserialize)]
struct TestOptionalFloatStruct {
    #[serde(deserialize_with = "deserialize_optional_flexible_float")]
    value: Option<f64>,
}

fn main() {
    println!("Testing current serde_utils behavior...");
    
    // Test 1: Non-empty string should work
    let json = json!({"value": "95.5"});
    let result: TestFloatStruct = serde_json::from_value(json).unwrap();
    println!("✓ Non-empty string: {}", result.value);
    
    // Test 2: Empty string should ERROR (not silently convert to 0)
    let json = json!({"value": ""});
    let result: Result<TestFloatStruct, _> = serde_json::from_value(json);
    match result {
        Ok(_) => println!("✗ FAIL: Empty string was silently converted"),
        Err(e) => println!("✓ PASS: Empty string correctly errors: {}", e),
    }
    
    // Test 3: Optional empty string should become None
    let json = json!({"value": ""});
    let result: TestOptionalFloatStruct = serde_json::from_value(json).unwrap();
    println!("✓ Optional empty string: {:?}", result.value);
    
    // Test 4: Optional None string should become None
    let json = json!({"value": "None"});
    let result: TestOptionalFloatStruct = serde_json::from_value(json).unwrap();
    println!("✓ Optional 'None' string: {:?}", result.value);
    
    // Test 5: Optional null string should become None
    let json = json!({"value": "null"});
    let result: TestOptionalFloatStruct = serde_json::from_value(json).unwrap();
    println!("✓ Optional 'null' string: {:?}", result.value);
    
    // Test 6: Optional actual null should become None
    let json = json!({"value": null});
    let result: TestOptionalFloatStruct = serde_json::from_value(json).unwrap();
    println!("✓ Optional null: {:?}", result.value);
    
    println!("All tests completed!");
}