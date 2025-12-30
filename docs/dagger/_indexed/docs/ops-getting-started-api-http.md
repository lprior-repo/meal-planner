---
id: ops/getting-started/api-http
title: "Using the Dagger API with HTTP and GraphQL"
category: ops
tags: ["ops", "file", "directory", "git", "container"]
---

# Using the Dagger API with HTTP and GraphQL

> **Context**: The Dagger API is an HTTP API that uses GraphQL as its low-level language-agnostic framework. Therefore, it's possible to call the Dagger API using ra...


The Dagger API is an HTTP API that uses GraphQL as its low-level language-agnostic framework. Therefore, it's possible to call the Dagger API using raw HTTP queries, from [any language that supports GraphQL](https://graphql.org/code/). GraphQL has a large and growing list of client implementations in over 20 languages.

> **Note:** In practice, calling the API using HTTP or GraphQL is optional. Typically, you will instead use a custom Dagger function created with a type-safe Dagger SDK, or from the command line using the Dagger CLI.

Dagger creates a unique local API endpoint for GraphQL HTTP queries for every Dagger session. This API endpoint is served by the local host at the port specified by the `DAGGER_SESSION_PORT` environment variable, and can be directly read from the environment in your client code. For example, if `DAGGER_SESSION_PORT` is set to `12345`, the API endpoint can be reached at `http://127.0.0.1:$DAGGER_SESSION_PORT/query`

> **Warning:** Dagger protects the exposed API with an HTTP Basic authentication token which can be retrieved from the `DAGGER_SESSION_TOKEN` variable. Treat the `DAGGER_SESSION_TOKEN` value as you would any other sensitive credential. Store it securely and avoid passing it to, or over, insecure applications and networks.

## Command-line HTTP clients

This example demonstrates how to connect to the Dagger API and run a simple workflow using `curl`:

```bash
echo '{"query":"{
  container {
    from(address:\"alpine:latest\") {
      file(path:\"/etc/os-release\") {
        contents
      }
    }
  }
}"}'|
  dagger run sh -c 'curl -s \
    -u $DAGGER_SESSION_TOKEN: \
    -H "content-type:application/json" \
    -d @- \
    http://127.0.0.1:$DAGGER_SESSION_PORT/query'
```

## Language-native HTTP clients

This example demonstrates how to connect to the Dagger API and run a simple workflow using various languages:

### Rust

Using the [gql_client library](https://github.com/arthurkhlghatyan/gql-client-rs) (MIT License):

```bash
mkdir my-project
cd my-project
cargo init
cargo add gql_client@1.0.7
cargo add serde_json@1.0.125
cargo add tokio@1.39.3 -F full
cargo add base64@0.22.1
```

Add the following code to `src/main.rs`:

```rust
use base64::encode;
use gql_client::Client;
use serde_json::Value;
use std::collections::HashMap;
use std::env;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let port = env::var("DAGGER_SESSION_PORT").expect("$DAGGER_SESSION_PORT doesn't exist");
    let token = env::var("DAGGER_SESSION_TOKEN").expect("$DAGGER_SESSION_TOKEN doesn't exist");

    let query = r#"
    query {
      container {
        from (address: "alpine:latest") {
          withExec(args:["uname", "-nrio"]) {
            stdout
          }
        }
      }
    } "#;

    let mut headers = HashMap::new();
    headers.insert(
        "authorization",
        format!("Basic {}", encode(format!("{}:", token))),
    );
    let client = Client::new_with_headers(format!("http://127.0.0.1:{}/query", port), headers);
    let data = client.query_unwrap::<Value>(query).await.unwrap();
    println!(
        "{}",
        data["container"]["from"]["withExec"]["stdout"]
            .as_str()
            .unwrap()
    );

    Ok(())
}
```

Run with:
```bash
dagger run cargo run
```

### PHP

Using the [php-graphql-client library](https://github.com/mghoneimy/php-graphql-client) (MIT License):

```bash
mkdir my-project
cd my-project
composer require gmostafa/php-graphql-client
```

Create a new file named `client.php`:

```php
<?php

// include auto-loader
include 'vendor/autoload.php';

use GraphQL\Client;

try {
  // initialize client with
  // endpoint from environment
  $sessionPort = getenv('DAGGER_SESSION_PORT') or throw new Exception("DAGGER_SESSION_PORT doesn't exist");
  $sessionToken = getenv('DAGGER_SESSION_TOKEN') or throw new Exception("DAGGER_SESSION_TOKEN doesn't exist");

  $client = new Client(
    'http://127.0.0.1:' . $sessionPort . '/query',
    ['Authorization' => 'Basic ' . base64_encode($sessionToken . ':')]
  );

  // define raw GraphQL query
  $query = <<<QUERY
  query {
    container {
      from (address: "alpine:latest") {
        withExec(args:["uname", "-nrio"]) {
          stdout
        }
      }
    }
  }
  QUERY;

  // execute query and print result
  $results = $client->runRawQuery($query);
  print_r($results->getData()->container->from->withExec->stdout);
} catch (Exception $e) {
  print_r($e->getMessage());
  exit;
}
```

Run with:
```bash
dagger run php client.php
```

## Dagger CLI

The Dagger CLI offers a `dagger query` sub-command, which provides an easy way to send raw GraphQL queries to the Dagger API from the command line.

This example demonstrates how to build a Go application by cloning the canonical Git repository for Go and building the "Hello, world" example program:

Create a new shell script named `build.sh`:

```bash
#!/bin/bash

## get Go examples source code repository
source=$(dagger query <<EOF | jq -r .git.branch.tree.id
{
  git(url:"https://go.googlesource.com/example") {
    branch(name:"master") {
      tree {
        id
      }
    }
  }
}
EOF
)

## mount source code repository in golang container
## build Go binary
## export binary from container to host filesystem
build=$(dagger query <<EOF | jq -r .container.from.withDirectory.withWorkdir.withExec.file.export
{
  container {
    from(address:"golang:latest") {
      withDirectory(path:"/src", directory:"$source") {
        withWorkdir(path:"/src/hello") {
          withExec(args:["go", "build", "-o", "dagger-builds-hello", "."]) {
            file(path:"./dagger-builds-hello") {
              export(path:"./dagger-builds-hello")
            }
          }
        }
      }
    }
  }
}
EOF
)

if [ -n "$build" ]; then
	echo "Build successful"
else
	echo "Build unsuccessful"
fi
```

Run it:
```bash
chmod +x ./build.sh
./build.sh
```

On completion, the built Go application will be available in the working directory on the host.

## See Also

- [Documentation Overview](./COMPASS.md)
