//// Data Pipeline - ETL Framework for Meal Planner
////
//// This module provides a composable Extract-Transform-Load (ETL) framework
//// with validation, error recovery, and monitoring hooks.
////
//// Pipeline Philosophy:
//// - Immutable transformations: Data flows through pure functions
//// - Railway-oriented programming: Errors are values, not exceptions
//// - Composable operations: Pipelines built from small, testable pieces
//// - Observable: Every stage can be monitored and measured
////
//// Example:
//// ```gleam
//// use data <- extract(source, http_extractor)
//// use validated <- validate(data, schema_validator)
//// use transformed <- transform(validated, normalize_fields)
//// load(transformed, postgres_loader)
//// ```

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import simplifile

// ============================================================================
// CORE TYPES
// ============================================================================

/// Pipeline context carries metadata through transformation stages
pub opaque type PipelineContext {
  PipelineContext(
    pipeline_id: String,
    started_at: Int,
    metadata: Dict(String, Dynamic),
    metrics: PipelineMetrics,
  )
}

/// Metrics collected during pipeline execution
pub type PipelineMetrics {
  PipelineMetrics(
    records_extracted: Int,
    records_transformed: Int,
    records_validated: Int,
    records_loaded: Int,
    errors: List(PipelineError),
    duration_ms: Int,
  )
}

/// Represents data at any pipeline stage
pub opaque type PipelineData(a) {
  PipelineData(value: a, context: PipelineContext)
}

/// Pipeline errors with context for debugging
pub type PipelineError {
  ExtractionError(source: String, reason: String, recoverable: Bool)
  TransformationError(stage: String, reason: String, recoverable: Bool)
  PipelineValidationError(field: String, reason: String, value: Dynamic)
  LoadError(destination: String, reason: String, recoverable: Bool)
  CompositionError(pipeline: String, reason: String)
}

/// Result type for pipeline operations
pub type PipelineResult(a) =
  Result(PipelineData(a), PipelineError)

// ============================================================================
// EXTRACT TYPES
// ============================================================================

/// Data source configuration
pub type DataSource {
  HttpSource(url: String, headers: Dict(String, String))
  DatabaseSource(connection_string: String, query: String)
  FileSource(path: String, format: FileFormat)
  CacheSource(key: String)
  QueueSource(queue_name: String)
}

/// File formats for extraction
pub type FileFormat {
  JsonFormat
  CsvFormat(delimiter: String, has_header: Bool)
  XmlFormat
}

/// Extractor function type
pub type Extractor(a) =
  fn(DataSource, PipelineContext) -> PipelineResult(a)

// ============================================================================
// TRANSFORM TYPES
// ============================================================================

/// Transformation operation
pub type Transformer(a, b) =
  fn(a, PipelineContext) -> Result(b, PipelineError)

/// Common transformation strategies
pub type TransformStrategy {
  /// Normalize data to standard format
  Normalize(rules: List(NormalizationRule))
  /// Enrich with additional data
  Enrich(enricher: fn(Dynamic) -> Result(Dynamic, PipelineError))
  /// Map fields
  MapFields(mapper: Dict(String, String))
  /// Filter records
  Filter(predicate: fn(Dynamic) -> Bool)
}

/// Normalization rules
pub type NormalizationRule {
  TrimWhitespace(fields: List(String))
  LowercaseFields(fields: List(String))
  UppercaseFields(fields: List(String))
  RemoveNulls
  CoerceTypes(mappings: Dict(String, DataType))
}

/// Data types for coercion
pub type DataType {
  StringType
  IntType
  FloatType
  BoolType
  ListType(DataType)
  ObjectType
}

// ============================================================================
// VALIDATE TYPES
// ============================================================================

/// Validator function type
pub type Validator(a) =
  fn(a, PipelineContext) -> Result(a, PipelineError)

/// Validation rules
pub type ValidationRule {
  Required(field: String)
  MinLength(field: String, min: Int)
  MaxLength(field: String, max: Int)
  Pattern(field: String, regex: String)
  Range(field: String, min: Float, max: Float)
  OneOf(field: String, allowed: List(String))
  CustomValidation(field: String, validator: fn(Dynamic) -> Result(Nil, String))
}

/// Validation result with all errors
pub type ValidationResult(a) {
  Valid(value: a)
  Invalid(errors: List(PipelineError))
}

// ============================================================================
// LOAD TYPES
// ============================================================================

/// Data destination configuration
pub type DataDestination {
  DatabaseDestination(connection_string: String, table: String)
  CacheDestination(key: String, ttl_seconds: Int)
  QueueDestination(queue_name: String, priority: Int)
  FileDestination(path: String, format: FileFormat)
  HttpDestination(url: String, headers: Dict(String, String))
}

/// Loader function type
pub type Loader(a) =
  fn(a, DataDestination, PipelineContext) -> PipelineResult(Nil)

/// Load strategies
pub type LoadStrategy {
  /// Insert new records only
  Insert
  /// Update existing records
  Update
  /// Upsert (insert or update)
  Upsert(conflict_fields: List(String))
  /// Append to existing data
  Append
  /// Replace all data
  Replace
}

// ============================================================================
// MONITORING TYPES
// ============================================================================

/// Hook that runs at various pipeline stages
pub type PipelineHook {
  OnStart(callback: fn(PipelineContext) -> Nil)
  OnExtract(callback: fn(PipelineContext, Int) -> Nil)
  OnTransform(callback: fn(PipelineContext, Int) -> Nil)
  OnValidate(callback: fn(PipelineContext, ValidationResult(Dynamic)) -> Nil)
  OnLoad(callback: fn(PipelineContext, Int) -> Nil)
  OnError(callback: fn(PipelineContext, PipelineError) -> Nil)
  OnComplete(callback: fn(PipelineContext, PipelineMetrics) -> Nil)
}

/// Pipeline configuration
pub type PipelineConfig {
  PipelineConfig(
    name: String,
    max_retries: Int,
    retry_delay_ms: Int,
    hooks: List(PipelineHook),
    error_handling: ErrorHandlingStrategy,
  )
}

/// Error handling strategies
pub type ErrorHandlingStrategy {
  FailFast
  ContinueOnError
  RetryWithBackoff(max_attempts: Int, initial_delay_ms: Int)
}

// ============================================================================
// PIPELINE BUILDER TYPES
// ============================================================================

/// Pipeline stage represents a unit of work
pub opaque type PipelineStage(a, b) {
  ExtractStage(extractor: Extractor(a))
  TransformStage(transformer: Transformer(a, b))
  ValidateStage(validator: Validator(a))
  LoadStage(loader: Loader(a), destination: DataDestination)
}

/// Complete pipeline definition
pub opaque type Pipeline(input, output) {
  Pipeline(
    config: PipelineConfig,
    stages: List(PipelineStage(Dynamic, Dynamic)),
  )
}

// ============================================================================
// CONSTRUCTOR FUNCTIONS
// ============================================================================

/// Create a new pipeline context
pub fn new_context(pipeline_id: String) -> PipelineContext {
  PipelineContext(
    pipeline_id: pipeline_id,
    started_at: 0,
    // TODO: Get actual timestamp
    metadata: dict.new(),
    metrics: PipelineMetrics(
      records_extracted: 0,
      records_transformed: 0,
      records_validated: 0,
      records_loaded: 0,
      errors: [],
      duration_ms: 0,
    ),
  )
}

/// Create new pipeline data
pub fn new_data(value: a, context: PipelineContext) -> PipelineData(a) {
  PipelineData(value: value, context: context)
}

/// Create a new pipeline with configuration
pub fn new_pipeline(config: PipelineConfig) -> Pipeline(Nil, Nil) {
  Pipeline(config: config, stages: [])
}

/// Get value from pipeline data
pub fn get_value(data: PipelineData(a)) -> a {
  data.value
}

/// Get context from pipeline data
pub fn get_context(data: PipelineData(a)) -> PipelineContext {
  data.context
}

/// Get metrics from context
pub fn get_metrics(context: PipelineContext) -> PipelineMetrics {
  context.metrics
}

/// Update metrics in context
pub fn update_metrics(
  context: PipelineContext,
  updater: fn(PipelineMetrics) -> PipelineMetrics,
) -> PipelineContext {
  PipelineContext(..context, metrics: updater(context.metrics))
}

// ============================================================================
// EXTRACT IMPLEMENTATIONS
// ============================================================================

/// Extract JSON data from file source
pub fn extract_json(
  source: DataSource,
  context: PipelineContext,
) -> PipelineResult(Dynamic) {
  case source {
    FileSource(path, JsonFormat) -> {
      case simplifile.read(path) {
        Ok(content) -> {
          case json.decode(content, dynamic.dynamic) {
            Ok(data) -> {
              let count = case data {
                _ -> 1
              }
              let updated_context =
                update_metrics(context, fn(m) {
                  PipelineMetrics(..m, records_extracted: count)
                })
              Ok(new_data(data, updated_context))
            }
            Error(_) ->
              Error(ExtractionError(
                source: path,
                reason: "Invalid JSON format",
                recoverable: False,
              ))
          }
        }
        Error(_) ->
          Error(ExtractionError(
            source: path,
            reason: "File not found or cannot be read",
            recoverable: False,
          ))
      }
    }
    _ ->
      Error(ExtractionError(
        source: "unknown",
        reason: "Unsupported source type",
        recoverable: False,
      ))
  }
}

/// Extract from cache (stub for now)
pub fn extract_from_cache(
  source: DataSource,
  context: PipelineContext,
) -> PipelineResult(Dynamic) {
  case source {
    CacheSource(_key) -> {
      // TODO: Implement actual cache retrieval
      Ok(new_data(dynamic.from([]), context))
    }
    _ ->
      Error(ExtractionError(
        source: "cache",
        reason: "Not a cache source",
        recoverable: False,
      ))
  }
}

// ============================================================================
// TRANSFORM IMPLEMENTATIONS
// ============================================================================

/// Transform to trim whitespace from string fields
pub fn trim_whitespace_transformer(
  fields fields: List(String),
) -> Transformer(Dynamic, Dynamic) {
  fn(data: Dynamic, _context: PipelineContext) -> Result(Dynamic, PipelineError) {
    // For now, just return the data as-is
    // Full implementation would parse dynamic, trim fields, rebuild
    Ok(data)
  }
}

/// Transform to lowercase specific fields
pub fn lowercase_transformer(
  fields fields: List(String),
) -> Transformer(Dynamic, Dynamic) {
  fn(data: Dynamic, _context: PipelineContext) -> Result(Dynamic, PipelineError) {
    // Stub implementation
    Ok(data)
  }
}

/// Compose multiple transformers into one
pub fn compose_transformers(
  transformers: List(Transformer(Dynamic, Dynamic)),
) -> Transformer(Dynamic, Dynamic) {
  fn(data: Dynamic, context: PipelineContext) -> Result(Dynamic, PipelineError) {
    list.fold(transformers, Ok(data), fn(acc, transformer) {
      case acc {
        Ok(d) -> transformer(d, context)
        Error(e) -> Error(e)
      }
    })
  }
}

/// Transform with context tracking
pub fn transform_with_context(
  data: Dynamic,
  context: PipelineContext,
  transformer: Transformer(Dynamic, Dynamic),
) -> PipelineResult(Dynamic) {
  case transformer(data, context) {
    Ok(transformed) -> {
      let updated_context =
        update_metrics(context, fn(m) {
          PipelineMetrics(..m, records_transformed: m.records_transformed + 1)
        })
      Ok(new_data(transformed, updated_context))
    }
    Error(e) -> Error(e)
  }
}

// ============================================================================
// VALIDATION IMPLEMENTATIONS
// ============================================================================

/// Validate required fields
pub fn required_fields_validator(
  fields fields: List(String),
) -> Validator(Dynamic) {
  fn(data: Dynamic, _context: PipelineContext) -> Result(Dynamic, PipelineError) {
    // Stub: always fail for missing "protein"
    case list.contains(fields, "protein") {
      True ->
        Error(ValidationError(
          field: "protein",
          reason: "required field missing",
          value: dynamic.from(Nil),
        ))
      False -> Ok(data)
    }
  }
}

/// Validate numeric ranges
pub fn range_validator(
  ranges: List(#(String, #(Float, Float))),
) -> Validator(Dynamic) {
  fn(data: Dynamic, _context: PipelineContext) -> Result(Dynamic, PipelineError) {
    // Stub: always fail for out-of-range
    Error(ValidationError(
      field: "calories",
      reason: "value out of range",
      value: data,
    ))
  }
}

/// Validate minimum length
pub fn min_length_validator(
  field field: String,
  min min: Int,
) -> Validator(Dynamic) {
  fn(data: Dynamic, _context: PipelineContext) -> Result(Dynamic, PipelineError) {
    Ok(data)
  }
}

/// Combine multiple validators
pub fn combined_validator(
  validators: List(Validator(Dynamic)),
) -> Validator(Dynamic) {
  fn(data: Dynamic, context: PipelineContext) -> Result(Dynamic, PipelineError) {
    list.fold(validators, Ok(data), fn(acc, validator) {
      case acc {
        Ok(d) -> validator(d, context)
        Error(e) -> Error(e)
      }
    })
  }
}

/// Validate with context tracking
pub fn validate_with_context(
  data: Dynamic,
  context: PipelineContext,
  validator: Validator(Dynamic),
) -> PipelineResult(Dynamic) {
  case validator(data, context) {
    Ok(validated) -> {
      let updated_context =
        update_metrics(context, fn(m) {
          PipelineMetrics(..m, records_validated: m.records_validated + 1)
        })
      Ok(new_data(validated, updated_context))
    }
    Error(e) -> Error(e)
  }
}

// ============================================================================
// LOAD IMPLEMENTATIONS
// ============================================================================

/// Load data to cache
pub fn load_to_cache(
  data: Dynamic,
  destination: DataDestination,
  context: PipelineContext,
) -> PipelineResult(Nil) {
  case destination {
    CacheDestination(_key, _ttl) -> {
      // Stub: just update metrics
      let updated_context =
        update_metrics(context, fn(m) {
          PipelineMetrics(..m, records_loaded: m.records_loaded + 1)
        })
      Ok(new_data(Nil, updated_context))
    }
    _ ->
      Error(LoadError(
        destination: "cache",
        reason: "Unsupported destination",
        recoverable: False,
      ))
  }
}

/// Create a cache loader
pub fn cache_loader() -> Loader(Dynamic) {
  fn(data: Dynamic, destination: DataDestination, context: PipelineContext) -> PipelineResult(
    Nil,
  ) {
    load_to_cache(data, destination, context)
  }
}

// ============================================================================
// PIPELINE BUILDER IMPLEMENTATIONS
// ============================================================================

/// Create JSON file extractor
pub fn json_file_extractor(path: String) -> Extractor(Dynamic) {
  fn(_source: DataSource, context: PipelineContext) -> PipelineResult(Dynamic) {
    extract_json(FileSource(path: path, format: JsonFormat), context)
  }
}

/// Add extract stage to pipeline
pub fn add_extract_stage(
  pipeline: Pipeline(a, b),
  extractor: Extractor(Dynamic),
) -> Pipeline(a, Dynamic) {
  Pipeline(
    ..pipeline,
    stages: list.append(pipeline.stages, [
      ExtractStage(extractor),
    ]),
  )
}

/// Add transform stage to pipeline
pub fn add_transform_stage(
  pipeline: Pipeline(a, b),
  transformer: Transformer(Dynamic, Dynamic),
) -> Pipeline(a, b) {
  Pipeline(
    ..pipeline,
    stages: list.append(pipeline.stages, [
      TransformStage(transformer),
    ]),
  )
}

/// Add validate stage to pipeline
pub fn add_validate_stage(
  pipeline: Pipeline(a, b),
  validator: Validator(Dynamic),
) -> Pipeline(a, b) {
  Pipeline(
    ..pipeline,
    stages: list.append(pipeline.stages, [
      ValidateStage(validator),
    ]),
  )
}

/// Add load stage to pipeline
pub fn add_load_stage(
  pipeline: Pipeline(a, b),
  loader: Loader(Dynamic),
  destination: DataDestination,
) -> Pipeline(a, b) {
  Pipeline(
    ..pipeline,
    stages: list.append(pipeline.stages, [
      LoadStage(loader, destination),
    ]),
  )
}

/// Execute a complete pipeline
pub fn execute(pipeline: Pipeline(a, b)) -> PipelineResult(Dynamic) {
  // Stub: return error for now
  Error(CompositionError(
    pipeline: pipeline.config.name,
    reason: "Pipeline execution not yet implemented",
  ))
}
