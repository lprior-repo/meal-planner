---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-2
heading_path: ["Rich display rendering", "Tables"]
chunk_type: code
tokens: 950
summary: "Tables"
---

## Tables

There are various ways to display results as tables within Windmill. [Rich Table Display](#rich-table-display) automatically renders results as an interactive table, or you can force a table view with specific keys.

If the result matches the table format (either `table-col`, `table-row`, or `table-row-object`), it will be automatically detected and [displayed as a table](#rich-table-display) even if the data is not nested under the key `table-*`.

There are 3 table shapes that are supported:
- [table-row-object](#table-row-object) (list of objects)
- [table-col](#table-column) (list of columns)
- [table-row](#table-row) (list of values)

### Rich table display

The rich table display does not require a specific key and will be enabled for [scripts](./meta-script_editor-index.md) or [flows](./tutorial-flows-1-flow-editor.md) when the result is an array of objects.

You can also force table display with a key ([table-col](#table-column), [table-row](#table-row), [table-row-object](#table-row-object)).

![Default](./default.png 'Rich Table Display')

#### Example

Try with this [Python](./meta-2_python_quickstart-index.md):

```py
from typing import List, Dict

def main() -> List[Dict[str, str]]:

    pokemon_data = [
        {"Pokemon name": "Pikachu", "Type": "Electric", "Main strength": "Speed"},
        {"Pokemon name": "Charizard", "Type": "Fire/Flying", "Main strength": "Attack"},
        {"Pokemon name": "Bulbasaur", "Type": "Grass/Poison", "Main strength": "Defense"},
        {"Pokemon name": "Squirtle", "Type": "Water", "Main strength": "Defense"},
        {"Pokemon name": "Jigglypuff", "Type": "Normal/Fairy", "Main strength": "HP"},
    ]

    return pokemon_data
```

![Rich Table Display](./rich_table_display.png "Rich Table Display")

#### Force column order

As you can see in the example above, the columns are not properly ordered. You can force column order with [Table Row Object](#table-row-object).

For example, with columns ordered:

```py
from typing import List, Dict

def main() -> List[Dict[str, str]]:

    pokemon_data = [
        ["Pokemon name", "Type", "Main strength"],

        {"Pokemon name": "Pikachu", "Type": "Electric", "Main strength": "Speed"},
        {"Pokemon name": "Charizard", "Type": "Fire/Flying", "Main strength": "Attack"},
        {"Pokemon name": "Bulbasaur", "Type": "Grass/Poison", "Main strength": "Defense"},
        {"Pokemon name": "Squirtle", "Type": "Water", "Main strength": "Defense"},
        {"Pokemon name": "Jigglypuff", "Type": "Normal/Fairy", "Main strength": "HP"},
    ]

    return pokemon_data
```

![Rich Table Display Ordered](./rich_table_display_ordered.png "Rich Table Display Ordered")

Additionaly, you can force column orders with a variable, for example `columns` in

```ts
export async function main(values: string[]) {
  let columns = ["column1","column2","column3"]
  return [columns, ...values]
}
```

Here is a more dense example:

```ts
export async function main(): Promise<Array<{ "Pokemon name": string, "Type": string, "Main strength": string } | string[]>> {
  const pokemonData = [
    { "Pokemon name": "Pikachu", "Type": "Electric", "Main strength": "Speed" },
    { "Pokemon name": "Charizard", "Type": "Fire/Flying", "Main strength": "Attack" },
    { "Pokemon name": "Bulbasaur", "Type": "Grass/Poison", "Main strength": "Defense" },
    { "Pokemon name": "Squirtle", "Type": "Water", "Main strength": "Defense" },
    { "Pokemon name": "Jigglypuff", "Type": "Normal/Fairy", "Main strength": "HP" }
  ];

  const columns: string[] = ["Pokemon name", "Main strength", "Type"];

  return [columns, ...pokemonData];
}
```

![Columns not ordered](./columns_not_ordered.png "Columns not ordered")

![Columns ordered](./columns_ordered.png "Columns ordered")

### Table column

The `table-col` key allows returning the value as a column-wise table.

If the result matches the table format, it will be displayed as a table even if the data is not nested under the key `table-col`.

```ts
return { "foo": [42, 8], "bar": [38, 12] }
```

or

```ts
return { "table-col": { "foo": [42, 8], "bar": [38, 12] } }
```

![Rich display Table Column](./table-col.png "Rich display Table Column")

### Table row

The `table-row` key allows returning the value as a row-wise table.

If the result matches the table format, it will be displayed as a table even if the data is not nested under the key `table-row`.

```ts
return { [ [ "foo", "bar" ], [ 42, 38 ], [ 8, 12 ] ] }
```

or

```ts
return { "table-row": [ [ "foo", "bar" ], [ 42, 38 ], [ 8, 12 ] ] }
```

![Rich display Table Row](./table-row.png "Rich display Table Row")

### Table row object

The `table-row-object` key allows returning the value as a row-wise table but where each row is an object (optionally the first row can be an array of strings to enforce column order).

If the result matches the table format, it will be displayed as a table even if the data is not nested under the key `table-row-object`.

List of columns is not mandatory but it allows [forcing their order](#force-column-order).

```ts
return [ { "foo": 42, "bar": 38 }, { "foo": 8, "bar": 12 } ]
```

![Rich display Table Row Object 1](./table-row-object-1.png "Table Row Object 1")

or

```ts
return [ ["foo", "bar" ], { "foo": 42, "bar": 38 }, { "foo": 8, "bar": 12 } ]
```

![Rich display Table Row Object 2](./table-row-object-2.png "Table Row Object 2")
