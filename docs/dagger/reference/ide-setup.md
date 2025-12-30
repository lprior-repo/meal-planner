# IDE Setup

Dagger uses GraphQL as its low-level language-agnostic API query language, and each Dagger SDK generates native code-bindings for all dependencies from this API. This gives you all the benefits of type-checking, code completion and other IDE features.

## Go

To get your IDE to recognize a Dagger Go module, configure your `go.work` file to include the path to your module.

```bash
# in the root of your repository
go work init
go work use ./
go work use ./path/to/mod
```

## Python

To get your IDE to recognize a Dagger Python module, all dependencies must be installed in an activated virtual environment.

```bash
dagger develop
uv run code .
```

### Package Managers

- **uv**: `uv sync`
- **pip**: `pip install -r requirements.lock -e ./sdk -e .`
- **poetry**: `poetry run vim .`
- **hatch**: `hatch run dev:vim .`

## TypeScript

For Dagger modules initialized using `dagger init`, the default template is already configured with the correct `tsconfig.json`:

```json
{
    "experimentalDecorators": true,
    "paths": {
      "@dagger.io/dagger": ["./sdk"]
    }
}
```

## PHP

Ensure your `composer.json` has a path configured to the generated `dagger/dagger` package:

```json
"repositories": [
  {
    "type": "path",
    "url": "./sdk"
  }
],
"require": {
  "dagger/dagger": "*@dev"
}
```

## Java

The Dagger dependency code is available under `target/generated-sources`. Import the project into your favorite IDE as a Maven project.
