# Import/Export API Examples

This document provides examples of how to use the import_export_api module to interact with Tandoor's import and export log endpoints.

## Setup

First, create a client configuration with your Tandoor API credentials:

```gleam
import meal_planner/tandoor/client
import meal_planner/tandoor/api/import_export/import_export_api
import gleam/option

let config = client.bearer_config("http://localhost:8000", "your-api-token")
```

## Import Logs

### List All Import Logs

```gleam
// List all import logs (no pagination)
case import_export_api.list_import_logs(config, limit: option.None, offset: option.None) {
  Ok(import_log_list) -> {
    io.println("Total import logs: " <> int.to_string(import_log_list.count))

    // Process each import log
    list.each(import_log_list.results, fn(log) {
      io.println("Import " <> int.to_string(log.id) <> ": " <> log.msg)
      io.println("  Type: " <> log.import_type)
      io.println("  Progress: " <> int.to_string(log.imported_recipes) <> "/" <> int.to_string(log.total_recipes))
      io.println("  Running: " <> bool.to_string(log.running))
    })
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

### List Import Logs with Pagination

```gleam
// Get 20 import logs starting from offset 0
case import_export_api.list_import_logs(config, limit: option.Some(20), offset: option.Some(0)) {
  Ok(import_log_list) -> {
    io.println("Showing " <> int.to_string(list.length(import_log_list.results)) <> " of " <> int.to_string(import_log_list.count))

    // Check for next page
    case import_log_list.next {
      option.Some(next_url) -> io.println("Next page: " <> next_url)
      option.None -> io.println("No more pages")
    }
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

### Get a Specific Import Log

```gleam
// Get import log with ID 123
case import_export_api.get_import_log(config, log_id: 123) {
  Ok(log) -> {
    io.println("Import Log #" <> int.to_string(log.id))
    io.println("Type: " <> log.import_type)
    io.println("Status: " <> log.msg)
    io.println("Progress: " <> int.to_string(log.imported_recipes) <> "/" <> int.to_string(log.total_recipes))

    // Check if import is still running
    case log.running {
      True -> io.println("Import is in progress...")
      False -> io.println("Import completed")
    }

    // Check for keyword tagging
    case log.keyword {
      option.Some(keyword) -> io.println("Tagged with: " <> keyword.name)
      option.None -> io.println("No keyword tag")
    }
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

## Export Logs

### List All Export Logs

```gleam
// List all export logs (no pagination)
case import_export_api.list_export_logs(config, limit: option.None, offset: option.None) {
  Ok(export_log_list) -> {
    io.println("Total export logs: " <> int.to_string(export_log_list.count))

    // Process each export log
    list.each(export_log_list.results, fn(log) {
      io.println("Export " <> int.to_string(log.id) <> ": " <> log.msg)
      io.println("  Type: " <> log.export_type)
      io.println("  Progress: " <> int.to_string(log.exported_recipes) <> "/" <> int.to_string(log.total_recipes))
      io.println("  Running: " <> bool.to_string(log.running))

      // Check cache status
      case log.possibly_not_expired {
        True -> io.println("  Cache may still be valid (expires in " <> int.to_string(log.cache_duration) <> "s)")
        False -> io.println("  Cache expired")
      }
    })
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

### List Export Logs with Pagination

```gleam
// Get 10 export logs starting from offset 20
case import_export_api.list_export_logs(config, limit: option.Some(10), offset: option.Some(20)) {
  Ok(export_log_list) -> {
    io.println("Page 3: Showing " <> int.to_string(list.length(export_log_list.results)) <> " of " <> int.to_string(export_log_list.count))

    // Check for previous page
    case export_log_list.previous {
      option.Some(prev_url) -> io.println("Previous page: " <> prev_url)
      option.None -> io.println("First page")
    }
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

### Get a Specific Export Log

```gleam
// Get export log with ID 321
case import_export_api.get_export_log(config, log_id: 321) {
  Ok(log) -> {
    io.println("Export Log #" <> int.to_string(log.id))
    io.println("Type: " <> log.export_type)
    io.println("Status: " <> log.msg)
    io.println("Progress: " <> int.to_string(log.exported_recipes) <> "/" <> int.to_string(log.total_recipes))

    // Check if export is still running
    case log.running {
      True -> io.println("Export is in progress...")
      False -> io.println("Export completed")
    }

    // Check cache validity
    case log.possibly_not_expired {
      True -> io.println("Cached export may still be valid for " <> int.to_string(log.cache_duration) <> " seconds")
      False -> io.println("Export cache has expired")
    }
  }
  Error(err) -> io.println("Error: " <> string.inspect(err))
}
```

## Monitoring Import/Export Progress

Here's an example of monitoring an active import/export operation:

```gleam
import gleam/erlang/process

/// Poll an import log until it completes
pub fn monitor_import(config: client.ClientConfig, log_id: Int) -> Result(ImportLog, client.TandoorError) {
  case import_export_api.get_import_log(config, log_id: log_id) {
    Ok(log) -> {
      io.println("Progress: " <> int.to_string(log.imported_recipes) <> "/" <> int.to_string(log.total_recipes))

      case log.running {
        True -> {
          // Still running, wait and check again
          process.sleep(5000)  // Wait 5 seconds
          monitor_import(config, log_id)
        }
        False -> {
          // Completed
          io.println("Import completed: " <> log.msg)
          Ok(log)
        }
      }
    }
    Error(err) -> Error(err)
  }
}
```

## Error Handling

All functions return `Result(T, TandoorError)`. Here are the possible error types:

- `NetworkError(String)` - Failed to connect to the API
- `ParseError(String)` - Failed to parse the JSON response
- `AuthenticationError(String)` - Invalid or missing authentication
- `NotFoundError(String)` - Resource not found (404)
- `BadRequestError(String)` - Invalid request (400)

Example error handling:

```gleam
case import_export_api.get_import_log(config, log_id: 999) {
  Ok(log) -> {
    // Success
    io.println("Got log: " <> int.to_string(log.id))
  }
  Error(client.NotFoundError(msg)) -> {
    io.println("Import log not found: " <> msg)
  }
  Error(client.NetworkError(msg)) -> {
    io.println("Network error: " <> msg)
  }
  Error(client.ParseError(msg)) -> {
    io.println("Parse error: " <> msg)
  }
  Error(_) -> {
    io.println("Unknown error occurred")
  }
}
```
