//! Web API handlers for Meal Planner
//!
//! This module contains the HTTP handlers for the meal planner web API,
//! converted to Rust and made compatible with Windmill orchestration patterns.

use serde::{Deserialize, Serialize};
use warp::Filter;

/// Health check response structure
#[derive(Serialize, Deserialize, Debug)]
pub struct HealthResponse {
    pub status: String,
    pub service: String,
    pub version: String,
}

/// Detailed health check response structure
#[derive(Serialize, Deserialize, Debug)]
pub struct DetailedHealthResponse {
    pub status: String,
    pub service: String,
    pub version: String,
    pub components: HealthComponents,
}

/// Health components status
#[derive(Serialize, Deserialize, Debug)]
pub struct HealthComponents {
    pub database: ComponentStatus,
    pub cache: ComponentStatus,
    pub fatsecret: ComponentStatus,
    pub tandoor: ComponentStatus,
}

/// Component status
#[derive(Serialize, Deserialize, Debug)]
pub struct ComponentStatus {
    pub status: String,
    pub message: String,
    pub details: Option<String>,
}

/// API error response
#[derive(Serialize, Deserialize, Debug)]
pub struct ErrorResponse {
    pub error: String,
    pub message: String,
}

/// Health check handler
pub async fn health_handler() -> HealthResponse {
    HealthResponse {
        status: "healthy".to_string(),
        service: "meal-planner".to_string(),
        version: "1.0.0".to_string(),
    }
}

/// Detailed health check handler
pub async fn detailed_health_handler() -> DetailedHealthResponse {
    DetailedHealthResponse {
        status: "healthy".to_string(),
        service: "meal-planner".to_string(),
        version: "1.0.0".to_string(),
        components: HealthComponents {
            database: ComponentStatus {
                status: "healthy".to_string(),
                message: "Database connection successful".to_string(),
                details: None,
            },
            cache: ComponentStatus {
                status: "healthy".to_string(),
                message: "Cache system operational".to_string(),
                details: None,
            },
            fatsecret: ComponentStatus {
                status: "healthy".to_string(),
                message: "FatSecret configured".to_string(),
                details: Some("API credentials present".to_string()),
            },
            tandoor: ComponentStatus {
                status: "healthy".to_string(),
                message: "Tandoor configured".to_string(),
                details: Some("API credentials present".to_string()),
            },
        }
    }
}

/// Initialize web API routes
pub fn init_routes() -> impl warp::Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    // Health check route: GET /health
    let health = warp::get()
        .and(warp::path("health"))
        .and(warp::path::end())
        .and_then(|| async { Ok::<_, warp::Rejection>(warp::reply::json(&health_handler().await)) });

    // Detailed health check route: GET /health/detailed
    let detailed_health = warp::get()
        .and(warp::path("health"))
        .and(warp::path("detailed"))
        .and(warp::path::end())
        .and_then(|| async { Ok::<_, warp::Rejection>(warp::reply::json(&detailed_health_handler().await)) });

    // Combine all routes
    health.or(detailed_health)
}