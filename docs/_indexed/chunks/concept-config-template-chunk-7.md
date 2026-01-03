---
doc_id: concept/config/template
chunk_id: concept/config/template#chunk-7
heading_path: ["template.{pkl,yml}", "`variables`"]
chunk_type: code
tokens: 591
summary: "`variables`"
---

## `variables`

A mapping of variables that will be interpolated into all template files and file system paths when [rendering with Tera](https://tera.netlify.app/docs/#variables). The map key is the variable name (in camelCase or snake_case), while the value is a configuration object, as described with the settings below.

template.yml

```yaml
variables:
  name:
    type: 'string'
    default: ''
    required: true
    prompt: 'Package name?'
```

### `type` (Required)

The type of value for the variable. Accepts `array`, `boolean`, `string`, `object`, `number`, or `enum`. Floats *are not supported*, use strings instead.

For arrays and objects, the value of each member must be a JSON compatible type.

### `internal` (v1.23.0)

Marks a variable as internal only, which avoids the variable value being overwritten by command line arguments.

### `order` (v1.23.0)

The order in which the variable will be prompted to the user. By default, variables are prompted in the order they are defined in the `template.yml` file.

### Primitives & collections

Your basic primitives: boolean, numbers, strings, and collections: arrays, objects.

#### array

template.yml

```yaml
variables:
  type:
    type: 'array'
    prompt: 'Type?'
    default: ['app', 'lib']
```

#### boolean

template.yml

```yaml
variables:
  private:
    type: 'boolean'
    prompt: 'Private?'
    default: false
```

#### number

template.yml

```yaml
variables:
  age:
    type: 'number'
    prompt: 'Age?'
    default: 0
    required: true
```

#### object

template.yml

```yaml
variables:
  metadata:
    type: 'object'
    prompt: 'Metadata?'
    default:
      type: 'lib'
      dev: true
```

#### string

template.yml

```yaml
variables:
  name:
    type: 'string'
    prompt: 'Name?'
    required: true
```

### `default` (Required)

The default value of the variable. When `--defaults` is passed to [`moon generate`](/docs/commands/generate) or [`prompt`](#prompt) is not defined, the default value will be used, otherwise the user will be prompted to enter a custom value.

### `prompt`

When defined, will prompt the user with a message in the terminal to input a custom value, otherwise [`default`](#default) will be used.

For arrays and objects, a valid JSON string must be provided as the value.

### `required`

Marks the variable as required during *prompting only*. For arrays, strings, and objects, will error for empty values (`''`). For numbers, will error for zero's (`0`).

### Enums

An enum is an explicit list of string values that a user can choose from.

template.yml

```yaml
variables:
  color:
    type: 'enum'
    values: ['red', 'green', 'blue', 'purple']
    default: 'purple'
    prompt: 'Favorite color?'
```

### `multiple`

Allows multiple values to be chosen during prompting. In the template, an array or strings will be rendered, otherwise when not-multiple, a single string will be.

### `values` (Required)

List of explicit values to choose from. Can either be defined with a string, which acts as a value and label, or as an object, which defines an explicit value and label.

template.yml

```yaml
variables:
  color:
    type: 'enum'
    values:
      - 'red'
      # OR
      - value: 'red'
        label: 'Red'
    # ...
```
