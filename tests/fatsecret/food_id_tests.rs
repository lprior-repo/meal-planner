#![allow(clippy::unwrap_used)]

use meal_planner::fatsecret::foods::types::{FoodId, ServingId};

#[test]
fn test_food_id_creation() {
    let id1 = FoodId::new("12345");
    let id2 = FoodId::from("12345");
    let id3 = FoodId::from("12345".to_string());

    assert_eq!(id1.as_str(), "12345");
    assert_eq!(id2.as_str(), "12345");
    assert_eq!(id3.as_str(), "12345");
    assert_eq!(id1, id2);
    assert_eq!(id2, id3);
}

#[test]
fn test_food_id_display() {
    let id = FoodId::new("98765");
    assert_eq!(format!("{}", id), "98765");
    assert_eq!(id.to_string(), "98765");
}

#[test]
fn test_food_id_hash_equality() {
    use std::collections::HashSet;

    let id1 = FoodId::new("12345");
    let id2 = FoodId::new("12345");
    let id3 = FoodId::new("67890");

    let mut set = HashSet::new();
    set.insert(id1.clone());
    set.insert(id2);
    set.insert(id3.clone());

    assert_eq!(set.len(), 2);
    assert!(set.contains(&id1));
    assert!(set.contains(&id3));
}

#[test]
fn test_serving_id_creation() {
    let id1 = ServingId::new("67890");
    let id2 = ServingId::from("67890");

    assert_eq!(id1.as_str(), "67890");
    assert_eq!(id2.as_str(), "67890");
    assert_eq!(id1, id2);
}

#[test]
fn test_serving_id_display() {
    let id = ServingId::new("11111");
    assert_eq!(format!("{}", id), "11111");
}

#[test]
fn test_serialize_opaque_ids() {
    let food_id = FoodId::new("12345");
    let serving_id = ServingId::new("67890");

    let food_json = serde_json::to_string(&food_id).expect("Failed to serialize FoodId");
    let serving_json = serde_json::to_string(&serving_id).expect("Failed to serialize ServingId");

    assert_eq!(food_json, r#""12345""#);
    assert_eq!(serving_json, r#""67890""#);

    let food_id_back: FoodId = serde_json::from_str(&food_json).expect("Failed to deserialize");
    let serving_id_back: ServingId =
        serde_json::from_str(&serving_json).expect("Failed to deserialize");

    assert_eq!(food_id, food_id_back);
    assert_eq!(serving_id, serving_id_back);
}
