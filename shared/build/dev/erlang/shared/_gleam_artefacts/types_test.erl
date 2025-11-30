-module(types_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/types_test.gleam").
-export([main/0, macros_calories_test/0, macros_add_test/0, macros_scale_test/0, macros_zero_test/0, macros_sum_test/0, daily_macro_targets_active_gain_test/0, daily_macro_targets_sedentary_lose_test/0, macros_to_json_test/0, fodmap_level_to_string_test/0, activity_level_to_string_test/0, goal_to_string_test/0, meal_type_to_string_test/0, macros_decoder_test/0, ingredient_decoder_test/0, fodmap_level_decoder_test/0, activity_level_decoder_test/0, goal_decoder_test/0, meal_type_decoder_test/0, macros_roundtrip_test/0, recipe_roundtrip_test/0, user_profile_roundtrip_test/0]).

-file("test/types_test.gleam", 11).
-spec main() -> nil.
main() ->
    gleeunit:main().

-file("test/types_test.gleam", 19).
-spec macros_calories_test() -> nil.
macros_calories_test() ->
    M = {macros, 30.0, 20.0, 50.0},
    _pipe = shared@types:macros_calories(M),
    gleeunit@should:equal(_pipe, 500.0).

-file("test/types_test.gleam", 26).
-spec macros_add_test() -> nil.
macros_add_test() ->
    A = {macros, 10.0, 5.0, 20.0},
    B = {macros, 5.0, 10.0, 15.0},
    Result = shared@types:macros_add(A, B),
    _pipe = erlang:element(2, Result),
    gleeunit@should:equal(_pipe, 15.0),
    _pipe@1 = erlang:element(3, Result),
    gleeunit@should:equal(_pipe@1, 15.0),
    _pipe@2 = erlang:element(4, Result),
    gleeunit@should:equal(_pipe@2, 35.0).

-file("test/types_test.gleam", 35).
-spec macros_scale_test() -> nil.
macros_scale_test() ->
    M = {macros, 10.0, 5.0, 20.0},
    Result = shared@types:macros_scale(M, 2.0),
    _pipe = erlang:element(2, Result),
    gleeunit@should:equal(_pipe, 20.0),
    _pipe@1 = erlang:element(3, Result),
    gleeunit@should:equal(_pipe@1, 10.0),
    _pipe@2 = erlang:element(4, Result),
    gleeunit@should:equal(_pipe@2, 40.0).

-file("test/types_test.gleam", 43).
-spec macros_zero_test() -> nil.
macros_zero_test() ->
    M = shared@types:macros_zero(),
    _pipe = erlang:element(2, M),
    gleeunit@should:equal(_pipe, +0.0),
    _pipe@1 = erlang:element(3, M),
    gleeunit@should:equal(_pipe@1, +0.0),
    _pipe@2 = erlang:element(4, M),
    gleeunit@should:equal(_pipe@2, +0.0).

-file("test/types_test.gleam", 50).
-spec macros_sum_test() -> nil.
macros_sum_test() ->
    Macros = [{macros, 10.0, 5.0, 20.0},
        {macros, 20.0, 10.0, 30.0},
        {macros, 5.0, 2.5, 10.0}],
    Result = shared@types:macros_sum(Macros),
    _pipe = erlang:element(2, Result),
    gleeunit@should:equal(_pipe, 35.0),
    _pipe@1 = erlang:element(3, Result),
    gleeunit@should:equal(_pipe@1, 17.5),
    _pipe@2 = erlang:element(4, Result),
    gleeunit@should:equal(_pipe@2, 60.0).

-file("test/types_test.gleam", 66).
-spec daily_macro_targets_active_gain_test() -> nil.
daily_macro_targets_active_gain_test() ->
    Profile = {user_profile, <<"test"/utf8>>, 200.0, active, gain, 4},
    Targets = shared@types:daily_macro_targets(Profile),
    _pipe = erlang:element(2, Targets),
    gleeunit@should:equal(_pipe, 200.0),
    _pipe@1 = erlang:element(3, Targets),
    gleeunit@should:equal(_pipe@1, 60.0),
    _pipe@2 = erlang:element(4, Targets),
    gleeunit@should:equal(_pipe@2, 700.0).

-file("test/types_test.gleam", 84).
-spec daily_macro_targets_sedentary_lose_test() -> nil.
daily_macro_targets_sedentary_lose_test() ->
    Profile = {user_profile, <<"test"/utf8>>, 180.0, sedentary, lose, 3},
    Targets = shared@types:daily_macro_targets(Profile),
    _pipe = erlang:element(2, Targets),
    gleeunit@should:equal(_pipe, 144.0),
    _pipe@1 = erlang:element(3, Targets),
    gleeunit@should:equal(_pipe@1, 54.0),
    _pipe@2 = erlang:element(4, Targets),
    gleeunit@should:equal(_pipe@2, 193.5).

-file("test/types_test.gleam", 106).
-spec macros_to_json_test() -> nil.
macros_to_json_test() ->
    M = {macros, 25.0, 10.0, 30.0},
    Json_str = begin
        _pipe = shared@types:macros_to_json(M),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    gleeunit@should:not_equal(_pipe@1, <<""/utf8>>).

-file("test/types_test.gleam", 113).
-spec fodmap_level_to_string_test() -> nil.
fodmap_level_to_string_test() ->
    _pipe = shared@types:fodmap_level_to_string(low),
    gleeunit@should:equal(_pipe, <<"low"/utf8>>),
    _pipe@1 = shared@types:fodmap_level_to_string(medium),
    gleeunit@should:equal(_pipe@1, <<"medium"/utf8>>),
    _pipe@2 = shared@types:fodmap_level_to_string(high),
    gleeunit@should:equal(_pipe@2, <<"high"/utf8>>).

-file("test/types_test.gleam", 119).
-spec activity_level_to_string_test() -> nil.
activity_level_to_string_test() ->
    _pipe = shared@types:activity_level_to_string(sedentary),
    gleeunit@should:equal(_pipe, <<"sedentary"/utf8>>),
    _pipe@1 = shared@types:activity_level_to_string(moderate),
    gleeunit@should:equal(_pipe@1, <<"moderate"/utf8>>),
    _pipe@2 = shared@types:activity_level_to_string(active),
    gleeunit@should:equal(_pipe@2, <<"active"/utf8>>).

-file("test/types_test.gleam", 125).
-spec goal_to_string_test() -> nil.
goal_to_string_test() ->
    _pipe = shared@types:goal_to_string(gain),
    gleeunit@should:equal(_pipe, <<"gain"/utf8>>),
    _pipe@1 = shared@types:goal_to_string(maintain),
    gleeunit@should:equal(_pipe@1, <<"maintain"/utf8>>),
    _pipe@2 = shared@types:goal_to_string(lose),
    gleeunit@should:equal(_pipe@2, <<"lose"/utf8>>).

-file("test/types_test.gleam", 131).
-spec meal_type_to_string_test() -> nil.
meal_type_to_string_test() ->
    _pipe = shared@types:meal_type_to_string(breakfast),
    gleeunit@should:equal(_pipe, <<"breakfast"/utf8>>),
    _pipe@1 = shared@types:meal_type_to_string(lunch),
    gleeunit@should:equal(_pipe@1, <<"lunch"/utf8>>),
    _pipe@2 = shared@types:meal_type_to_string(dinner),
    gleeunit@should:equal(_pipe@2, <<"dinner"/utf8>>),
    _pipe@3 = shared@types:meal_type_to_string(snack),
    gleeunit@should:equal(_pipe@3, <<"snack"/utf8>>).

-file("test/types_test.gleam", 142).
-spec macros_decoder_test() -> nil.
macros_decoder_test() ->
    Json_str = <<"{\"protein\": 25.0, \"fat\": 10.0, \"carbs\": 30.0}"/utf8>>,
    Result = gleam@json:parse(Json_str, shared@types:macros_decoder()),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    Macros = case Result of
        {ok, M} ->
            M;

        {error, _} ->
            {macros, +0.0, +0.0, +0.0}
    end,
    _pipe@1 = erlang:element(2, Macros),
    gleeunit@should:equal(_pipe@1, 25.0),
    _pipe@2 = erlang:element(3, Macros),
    gleeunit@should:equal(_pipe@2, 10.0),
    _pipe@3 = erlang:element(4, Macros),
    gleeunit@should:equal(_pipe@3, 30.0).

-file("test/types_test.gleam", 155).
-spec ingredient_decoder_test() -> nil.
ingredient_decoder_test() ->
    Json_str = <<"{\"name\": \"Chicken breast\", \"quantity\": \"8 oz\"}"/utf8>>,
    Result = gleam@json:parse(Json_str, shared@types:ingredient_decoder()),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    Ingredient = case Result of
        {ok, I} ->
            I;

        {error, _} ->
            {ingredient, <<""/utf8>>, <<""/utf8>>}
    end,
    _pipe@1 = erlang:element(2, Ingredient),
    gleeunit@should:equal(_pipe@1, <<"Chicken breast"/utf8>>),
    _pipe@2 = erlang:element(3, Ingredient),
    gleeunit@should:equal(_pipe@2, <<"8 oz"/utf8>>).

-file("test/types_test.gleam", 167).
-spec fodmap_level_decoder_test() -> nil.
fodmap_level_decoder_test() ->
    _pipe = gleam@json:parse(
        <<"\"low\""/utf8>>,
        shared@types:fodmap_level_decoder()
    ),
    gleeunit@should:equal(_pipe, {ok, low}),
    _pipe@1 = gleam@json:parse(
        <<"\"medium\""/utf8>>,
        shared@types:fodmap_level_decoder()
    ),
    gleeunit@should:equal(_pipe@1, {ok, medium}),
    _pipe@2 = gleam@json:parse(
        <<"\"high\""/utf8>>,
        shared@types:fodmap_level_decoder()
    ),
    gleeunit@should:equal(_pipe@2, {ok, high}).

-file("test/types_test.gleam", 178).
-spec activity_level_decoder_test() -> nil.
activity_level_decoder_test() ->
    _pipe = gleam@json:parse(
        <<"\"sedentary\""/utf8>>,
        shared@types:activity_level_decoder()
    ),
    gleeunit@should:equal(_pipe, {ok, sedentary}),
    _pipe@1 = gleam@json:parse(
        <<"\"moderate\""/utf8>>,
        shared@types:activity_level_decoder()
    ),
    gleeunit@should:equal(_pipe@1, {ok, moderate}),
    _pipe@2 = gleam@json:parse(
        <<"\"active\""/utf8>>,
        shared@types:activity_level_decoder()
    ),
    gleeunit@should:equal(_pipe@2, {ok, active}).

-file("test/types_test.gleam", 189).
-spec goal_decoder_test() -> nil.
goal_decoder_test() ->
    _pipe = gleam@json:parse(<<"\"gain\""/utf8>>, shared@types:goal_decoder()),
    gleeunit@should:equal(_pipe, {ok, gain}),
    _pipe@1 = gleam@json:parse(
        <<"\"maintain\""/utf8>>,
        shared@types:goal_decoder()
    ),
    gleeunit@should:equal(_pipe@1, {ok, maintain}),
    _pipe@2 = gleam@json:parse(<<"\"lose\""/utf8>>, shared@types:goal_decoder()),
    gleeunit@should:equal(_pipe@2, {ok, lose}).

-file("test/types_test.gleam", 200).
-spec meal_type_decoder_test() -> nil.
meal_type_decoder_test() ->
    _pipe = gleam@json:parse(
        <<"\"breakfast\""/utf8>>,
        shared@types:meal_type_decoder()
    ),
    gleeunit@should:equal(_pipe, {ok, breakfast}),
    _pipe@1 = gleam@json:parse(
        <<"\"lunch\""/utf8>>,
        shared@types:meal_type_decoder()
    ),
    gleeunit@should:equal(_pipe@1, {ok, lunch}),
    _pipe@2 = gleam@json:parse(
        <<"\"dinner\""/utf8>>,
        shared@types:meal_type_decoder()
    ),
    gleeunit@should:equal(_pipe@2, {ok, dinner}),
    _pipe@3 = gleam@json:parse(
        <<"\"snack\""/utf8>>,
        shared@types:meal_type_decoder()
    ),
    gleeunit@should:equal(_pipe@3, {ok, snack}).

-file("test/types_test.gleam", 218).
-spec macros_roundtrip_test() -> nil.
macros_roundtrip_test() ->
    Original = {macros, 45.5, 22.3, 100.0},
    Json_str = begin
        _pipe = shared@types:macros_to_json(Original),
        gleam@json:to_string(_pipe)
    end,
    Result = gleam@json:parse(Json_str, shared@types:macros_decoder()),
    _pipe@1 = Result,
    gleeunit@should:be_ok(_pipe@1),
    Decoded = case Result of
        {ok, M} ->
            M;

        {error, _} ->
            {macros, +0.0, +0.0, +0.0}
    end,
    _pipe@2 = erlang:element(2, Decoded),
    gleeunit@should:equal(_pipe@2, 45.5),
    _pipe@3 = erlang:element(3, Decoded),
    gleeunit@should:equal(_pipe@3, 22.3),
    _pipe@4 = erlang:element(4, Decoded),
    gleeunit@should:equal(_pipe@4, 100.0).

-file("test/types_test.gleam", 232).
-spec recipe_roundtrip_test() -> nil.
recipe_roundtrip_test() ->
    Original = {recipe,
        <<"recipe-123"/utf8>>,
        <<"Grilled Chicken"/utf8>>,
        [{ingredient, <<"Chicken breast"/utf8>>, <<"8 oz"/utf8>>},
            {ingredient, <<"Olive oil"/utf8>>, <<"1 tbsp"/utf8>>}],
        [<<"Season chicken"/utf8>>, <<"Grill for 6 minutes per side"/utf8>>],
        {macros, 50.0, 8.0, +0.0},
        2,
        <<"chicken"/utf8>>,
        low,
        true},
    Json_str = begin
        _pipe = shared@types:recipe_to_json(Original),
        gleam@json:to_string(_pipe)
    end,
    Result = gleam@json:parse(Json_str, shared@types:recipe_decoder()),
    _pipe@1 = Result,
    gleeunit@should:be_ok(_pipe@1),
    Decoded = case Result of
        {ok, R} ->
            R;

        {error, _} ->
            Original
    end,
    _pipe@2 = erlang:element(2, Decoded),
    gleeunit@should:equal(_pipe@2, <<"recipe-123"/utf8>>),
    _pipe@3 = erlang:element(3, Decoded),
    gleeunit@should:equal(_pipe@3, <<"Grilled Chicken"/utf8>>),
    _pipe@4 = erlang:element(7, Decoded),
    gleeunit@should:equal(_pipe@4, 2),
    _pipe@5 = erlang:element(9, Decoded),
    gleeunit@should:equal(_pipe@5, low),
    _pipe@6 = erlang:element(10, Decoded),
    gleeunit@should:be_true(_pipe@6).

-file("test/types_test.gleam", 261).
-spec user_profile_roundtrip_test() -> nil.
user_profile_roundtrip_test() ->
    Original = {user_profile, <<"user-456"/utf8>>, 185.0, moderate, maintain, 4},
    Json_str = begin
        _pipe = shared@types:user_profile_to_json(Original),
        gleam@json:to_string(_pipe)
    end,
    Result = gleam@json:parse(Json_str, shared@types:user_profile_decoder()),
    _pipe@1 = Result,
    gleeunit@should:be_ok(_pipe@1),
    Decoded = case Result of
        {ok, U} ->
            U;

        {error, _} ->
            Original
    end,
    _pipe@2 = erlang:element(2, Decoded),
    gleeunit@should:equal(_pipe@2, <<"user-456"/utf8>>),
    _pipe@3 = erlang:element(3, Decoded),
    gleeunit@should:equal(_pipe@3, 185.0),
    _pipe@4 = erlang:element(4, Decoded),
    gleeunit@should:equal(_pipe@4, moderate),
    _pipe@5 = erlang:element(5, Decoded),
    gleeunit@should:equal(_pipe@5, maintain),
    _pipe@6 = erlang:element(6, Decoded),
    gleeunit@should:equal(_pipe@6, 4).
