-record(recipe, {
    id :: binary(),
    name :: binary(),
    ingredients :: list(shared@types:ingredient()),
    instructions :: list(binary()),
    macros :: shared@types:macros(),
    servings :: integer(),
    category :: binary(),
    fodmap_level :: shared@types:fodmap_level(),
    vertical_compliant :: boolean()
}).
