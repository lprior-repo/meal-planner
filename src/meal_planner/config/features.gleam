//// Feature Flags for Meal Planner
////
//// This module provides:
//// - Feature flag type definitions
////
//// Features represent optional functionality that can be enabled/disabled:
//// - External integrations (FatSecret, Tandoor, OpenAI, USDA, Todoist)
//// - System features (health checks, rate limiting, CORS)
////
//// Feature checking logic is in config.gleam to avoid circular dependencies.

// ============================================================================
// TYPES
// ============================================================================

/// Feature flags for runtime behavior control
///
/// External integrations (enabled when configured):
/// - FeatureFatSecret: FatSecret nutrition tracking API
/// - FeatureTandoor: Tandoor recipe management API
/// - FeatureOpenAI: OpenAI AI/ML features
/// - FeatureUSDA: USDA nutrition database
/// - FeatureTodoist: Todoist task management integration
///
/// System features (configurable):
/// - FeatureHealthCheck: Health check endpoint
/// - FeatureRateLimiting: API rate limiting
/// - FeatureCORS: Cross-origin resource sharing
pub type Feature {
  FeatureFatSecret
  FeatureTandoor
  FeatureOpenAI
  FeatureUSDA
  FeatureTodoist
  FeatureHealthCheck
  FeatureRateLimiting
  FeatureCORS
}
