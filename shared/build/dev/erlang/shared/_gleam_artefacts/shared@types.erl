-module(shared@types).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/shared/types.gleam").
-export([macros_calories/1, macros_add/2, macros_scale/2, macros_zero/0, macros_sum/1, daily_macro_targets/1, macros_to_json/1, ingredient_to_json/1, fodmap_level_to_string/1, recipe_to_json/1, activity_level_to_string/1, goal_to_string/1, user_profile_to_json/1, meal_type_to_string/1, food_log_entry_to_json/1, daily_log_to_json/1, macros_decoder/0, ingredient_decoder/0, fodmap_level_decoder/0, activity_level_decoder/0, goal_decoder/0, meal_type_decoder/0, recipe_decoder/0, user_profile_decoder/0, food_log_entry_decoder/0, daily_log_decoder/0]).
-export_type([macros/0, ingredient/0, fodmap_level/0, recipe/0, activity_level/0, goal/0, user_profile/0, meal_type/0, food_log_entry/0, daily_log/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Shared types for the meal planner application.\n"
    " These types work on both JavaScript (client) and Erlang (server) targets.\n"
).

-type macros() :: {macros, float(), float(), float()}.

-type ingredient() :: {ingredient, binary(), binary()}.

-type fodmap_level() :: low | medium | high.

-type recipe() :: {recipe,
        binary(),
        binary(),
        list(ingredient()),
        list(binary()),
        macros(),
        integer(),
        binary(),
        fodmap_level(),
        boolean()}.

-type activity_level() :: sedentary | moderate | active.

-type goal() :: gain | maintain | lose.

-type user_profile() :: {user_profile,
        binary(),
        float(),
        activity_level(),
        goal(),
        integer()}.

-type meal_type() :: breakfast | lunch | dinner | snack.

-type food_log_entry() :: {food_log_entry,
        binary(),
        binary(),
        binary(),
        float(),
        macros(),
        meal_type(),
        binary()}.

-type daily_log() :: {daily_log, binary(), list(food_log_entry()), macros()}.

-file("src/shared/types.gleam", 19).
?DOC(
    " Calculate total calories from macros\n"
    " Uses: 4cal/g protein, 9cal/g fat, 4cal/g carbs\n"
).
-spec macros_calories(macros()) -> float().
macros_calories(M) ->
    ((erlang:element(2, M) * 4.0) + (erlang:element(3, M) * 9.0)) + (erlang:element(
        4,
        M
    )
    * 4.0).

-file("src/shared/types.gleam", 24).
?DOC(" Add two Macros together\n").
-spec macros_add(macros(), macros()) -> macros().
macros_add(A, B) ->
    {macros,
        erlang:element(2, A) + erlang:element(2, B),
        erlang:element(3, A) + erlang:element(3, B),
        erlang:element(4, A) + erlang:element(4, B)}.

-file("src/shared/types.gleam", 33).
?DOC(" Scale macros by a factor\n").
-spec macros_scale(macros(), float()) -> macros().
macros_scale(M, Factor) ->
    {macros,
        erlang:element(2, M) * Factor,
        erlang:element(3, M) * Factor,
        erlang:element(4, M) * Factor}.

-file("src/shared/types.gleam", 42).
?DOC(" Empty macros (zero values)\n").
-spec macros_zero() -> macros().
macros_zero() ->
    {macros, +0.0, +0.0, +0.0}.

-file("src/shared/types.gleam", 47).
?DOC(" Sum a list of macros\n").
-spec macros_sum(list(macros())) -> macros().
macros_sum(Macros) ->
    gleam@list:fold(Macros, macros_zero(), fun macros_add/2).

-file("src/shared/types.gleam", 121).
-spec calculate_protein_target(user_profile()) -> float().
calculate_protein_target(U) ->
    Multiplier = case {erlang:element(4, U), erlang:element(5, U)} of
        {active, _} ->
            1.0;

        {_, gain} ->
            1.0;

        {sedentary, _} ->
            0.8;

        {_, lose} ->
            0.8;

        {_, _} ->
            0.9
    end,
    erlang:element(3, U) * Multiplier.

-file("src/shared/types.gleam", 132).
-spec calculate_fat_target(user_profile()) -> float().
calculate_fat_target(U) ->
    erlang:element(3, U) * 0.3.

-file("src/shared/types.gleam", 136).
-spec calculate_calorie_target(user_profile()) -> float().
calculate_calorie_target(U) ->
    Base_multiplier = case erlang:element(4, U) of
        sedentary ->
            12.0;

        moderate ->
            15.0;

        active ->
            18.0
    end,
    Base = erlang:element(3, U) * Base_multiplier,
    case erlang:element(5, U) of
        gain ->
            Base * 1.15;

        lose ->
            Base * 0.85;

        maintain ->
            Base
    end.

-file("src/shared/types.gleam", 150).
-spec calculate_carb_target(float(), float(), float()) -> float().
calculate_carb_target(Calories, Protein, Fat) ->
    Protein_calories = Protein * 4.0,
    Fat_calories = Fat * 9.0,
    Remaining = (Calories - Protein_calories) - Fat_calories,
    case Remaining < +0.0 of
        true ->
            +0.0;

        false ->
            Remaining / 4.0
    end.

-file("src/shared/types.gleam", 112).
?DOC(" Calculate daily macro targets for a user profile\n").
-spec daily_macro_targets(user_profile()) -> macros().
daily_macro_targets(U) ->
    Protein = calculate_protein_target(U),
    Fat = calculate_fat_target(U),
    Calories = calculate_calorie_target(U),
    Carbs = calculate_carb_target(Calories, Protein, Fat),
    {macros, Protein, Fat, Carbs}.

-file("src/shared/types.gleam", 198).
-spec macros_to_json(macros()) -> gleam@json:json().
macros_to_json(M) ->
    gleam@json:object(
        [{<<"protein"/utf8>>, gleam@json:float(erlang:element(2, M))},
            {<<"fat"/utf8>>, gleam@json:float(erlang:element(3, M))},
            {<<"carbs"/utf8>>, gleam@json:float(erlang:element(4, M))},
            {<<"calories"/utf8>>, gleam@json:float(macros_calories(M))}]
    ).

-file("src/shared/types.gleam", 207).
-spec ingredient_to_json(ingredient()) -> gleam@json:json().
ingredient_to_json(I) ->
    gleam@json:object(
        [{<<"name"/utf8>>, gleam@json:string(erlang:element(2, I))},
            {<<"quantity"/utf8>>, gleam@json:string(erlang:element(3, I))}]
    ).

-file("src/shared/types.gleam", 214).
-spec fodmap_level_to_string(fodmap_level()) -> binary().
fodmap_level_to_string(F) ->
    case F of
        low ->
            <<"low"/utf8>>;

        medium ->
            <<"medium"/utf8>>;

        high ->
            <<"high"/utf8>>
    end.

-file("src/shared/types.gleam", 222).
-spec recipe_to_json(recipe()) -> gleam@json:json().
recipe_to_json(R) ->
    gleam@json:object(
        [{<<"id"/utf8>>, gleam@json:string(erlang:element(2, R))},
            {<<"name"/utf8>>, gleam@json:string(erlang:element(3, R))},
            {<<"ingredients"/utf8>>,
                gleam@json:array(erlang:element(4, R), fun ingredient_to_json/1)},
            {<<"instructions"/utf8>>,
                gleam@json:array(erlang:element(5, R), fun gleam@json:string/1)},
            {<<"macros"/utf8>>, macros_to_json(erlang:element(6, R))},
            {<<"servings"/utf8>>, gleam@json:int(erlang:element(7, R))},
            {<<"category"/utf8>>, gleam@json:string(erlang:element(8, R))},
            {<<"fodmap_level"/utf8>>,
                gleam@json:string(fodmap_level_to_string(erlang:element(9, R)))},
            {<<"vertical_compliant"/utf8>>,
                gleam@json:bool(erlang:element(10, R))}]
    ).

-file("src/shared/types.gleam", 236).
-spec activity_level_to_string(activity_level()) -> binary().
activity_level_to_string(A) ->
    case A of
        sedentary ->
            <<"sedentary"/utf8>>;

        moderate ->
            <<"moderate"/utf8>>;

        active ->
            <<"active"/utf8>>
    end.

-file("src/shared/types.gleam", 244).
-spec goal_to_string(goal()) -> binary().
goal_to_string(G) ->
    case G of
        gain ->
            <<"gain"/utf8>>;

        maintain ->
            <<"maintain"/utf8>>;

        lose ->
            <<"lose"/utf8>>
    end.

-file("src/shared/types.gleam", 252).
-spec user_profile_to_json(user_profile()) -> gleam@json:json().
user_profile_to_json(U) ->
    Targets = daily_macro_targets(U),
    gleam@json:object(
        [{<<"id"/utf8>>, gleam@json:string(erlang:element(2, U))},
            {<<"bodyweight"/utf8>>, gleam@json:float(erlang:element(3, U))},
            {<<"activity_level"/utf8>>,
                gleam@json:string(
                    activity_level_to_string(erlang:element(4, U))
                )},
            {<<"goal"/utf8>>,
                gleam@json:string(goal_to_string(erlang:element(5, U)))},
            {<<"meals_per_day"/utf8>>, gleam@json:int(erlang:element(6, U))},
            {<<"daily_targets"/utf8>>, macros_to_json(Targets)}]
    ).

-file("src/shared/types.gleam", 264).
-spec meal_type_to_string(meal_type()) -> binary().
meal_type_to_string(M) ->
    case M of
        breakfast ->
            <<"breakfast"/utf8>>;

        lunch ->
            <<"lunch"/utf8>>;

        dinner ->
            <<"dinner"/utf8>>;

        snack ->
            <<"snack"/utf8>>
    end.

-file("src/shared/types.gleam", 273).
-spec food_log_entry_to_json(food_log_entry()) -> gleam@json:json().
food_log_entry_to_json(E) ->
    gleam@json:object(
        [{<<"id"/utf8>>, gleam@json:string(erlang:element(2, E))},
            {<<"recipe_id"/utf8>>, gleam@json:string(erlang:element(3, E))},
            {<<"recipe_name"/utf8>>, gleam@json:string(erlang:element(4, E))},
            {<<"servings"/utf8>>, gleam@json:float(erlang:element(5, E))},
            {<<"macros"/utf8>>, macros_to_json(erlang:element(6, E))},
            {<<"meal_type"/utf8>>,
                gleam@json:string(meal_type_to_string(erlang:element(7, E)))},
            {<<"logged_at"/utf8>>, gleam@json:string(erlang:element(8, E))}]
    ).

-file("src/shared/types.gleam", 285).
-spec daily_log_to_json(daily_log()) -> gleam@json:json().
daily_log_to_json(D) ->
    gleam@json:object(
        [{<<"date"/utf8>>, gleam@json:string(erlang:element(2, D))},
            {<<"entries"/utf8>>,
                gleam@json:array(
                    erlang:element(3, D),
                    fun food_log_entry_to_json/1
                )},
            {<<"total_macros"/utf8>>, macros_to_json(erlang:element(4, D))}]
    ).

-file("src/shared/types.gleam", 298).
?DOC(" Decoder for Macros\n").
-spec macros_decoder() -> gleam@dynamic@decode:decoder(macros()).
macros_decoder() ->
    gleam@dynamic@decode:field(
        <<"protein"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_float/1},
        fun(Protein) ->
            gleam@dynamic@decode:field(
                <<"fat"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_float/1},
                fun(Fat) ->
                    gleam@dynamic@decode:field(
                        <<"carbs"/utf8>>,
                        {decoder, fun gleam@dynamic@decode:decode_float/1},
                        fun(Carbs) ->
                            gleam@dynamic@decode:success(
                                {macros, Protein, Fat, Carbs}
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/shared/types.gleam", 306).
?DOC(" Decoder for Ingredient\n").
-spec ingredient_decoder() -> gleam@dynamic@decode:decoder(ingredient()).
ingredient_decoder() ->
    gleam@dynamic@decode:field(
        <<"name"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Name) ->
            gleam@dynamic@decode:field(
                <<"quantity"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Quantity) ->
                    gleam@dynamic@decode:success({ingredient, Name, Quantity})
                end
            )
        end
    ).

-file("src/shared/types.gleam", 313).
?DOC(" Decoder for FodmapLevel\n").
-spec fodmap_level_decoder() -> gleam@dynamic@decode:decoder(fodmap_level()).
fodmap_level_decoder() ->
    gleam@dynamic@decode:then(
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(S) -> case S of
                <<"low"/utf8>> ->
                    gleam@dynamic@decode:success(low);

                <<"medium"/utf8>> ->
                    gleam@dynamic@decode:success(medium);

                <<"high"/utf8>> ->
                    gleam@dynamic@decode:success(high);

                _ ->
                    gleam@dynamic@decode:failure(low, <<"FodmapLevel"/utf8>>)
            end end
    ).

-file("src/shared/types.gleam", 324).
?DOC(" Decoder for ActivityLevel\n").
-spec activity_level_decoder() -> gleam@dynamic@decode:decoder(activity_level()).
activity_level_decoder() ->
    gleam@dynamic@decode:then(
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(S) -> case S of
                <<"sedentary"/utf8>> ->
                    gleam@dynamic@decode:success(sedentary);

                <<"moderate"/utf8>> ->
                    gleam@dynamic@decode:success(moderate);

                <<"active"/utf8>> ->
                    gleam@dynamic@decode:success(active);

                _ ->
                    gleam@dynamic@decode:failure(
                        sedentary,
                        <<"ActivityLevel"/utf8>>
                    )
            end end
    ).

-file("src/shared/types.gleam", 335).
?DOC(" Decoder for Goal\n").
-spec goal_decoder() -> gleam@dynamic@decode:decoder(goal()).
goal_decoder() ->
    gleam@dynamic@decode:then(
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(S) -> case S of
                <<"gain"/utf8>> ->
                    gleam@dynamic@decode:success(gain);

                <<"maintain"/utf8>> ->
                    gleam@dynamic@decode:success(maintain);

                <<"lose"/utf8>> ->
                    gleam@dynamic@decode:success(lose);

                _ ->
                    gleam@dynamic@decode:failure(maintain, <<"Goal"/utf8>>)
            end end
    ).

-file("src/shared/types.gleam", 346).
?DOC(" Decoder for MealType\n").
-spec meal_type_decoder() -> gleam@dynamic@decode:decoder(meal_type()).
meal_type_decoder() ->
    gleam@dynamic@decode:then(
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(S) -> case S of
                <<"breakfast"/utf8>> ->
                    gleam@dynamic@decode:success(breakfast);

                <<"lunch"/utf8>> ->
                    gleam@dynamic@decode:success(lunch);

                <<"dinner"/utf8>> ->
                    gleam@dynamic@decode:success(dinner);

                <<"snack"/utf8>> ->
                    gleam@dynamic@decode:success(snack);

                _ ->
                    gleam@dynamic@decode:failure(snack, <<"MealType"/utf8>>)
            end end
    ).

-file("src/shared/types.gleam", 358).
?DOC(" Decoder for Recipe\n").
-spec recipe_decoder() -> gleam@dynamic@decode:decoder(recipe()).
recipe_decoder() ->
    gleam@dynamic@decode:field(
        <<"id"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Id) ->
            gleam@dynamic@decode:field(
                <<"name"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Name) ->
                    gleam@dynamic@decode:field(
                        <<"ingredients"/utf8>>,
                        gleam@dynamic@decode:list(ingredient_decoder()),
                        fun(Ingredients) ->
                            gleam@dynamic@decode:field(
                                <<"instructions"/utf8>>,
                                gleam@dynamic@decode:list(
                                    {decoder,
                                        fun gleam@dynamic@decode:decode_string/1}
                                ),
                                fun(Instructions) ->
                                    gleam@dynamic@decode:field(
                                        <<"macros"/utf8>>,
                                        macros_decoder(),
                                        fun(Macros) ->
                                            gleam@dynamic@decode:field(
                                                <<"servings"/utf8>>,
                                                {decoder,
                                                    fun gleam@dynamic@decode:decode_int/1},
                                                fun(Servings) ->
                                                    gleam@dynamic@decode:field(
                                                        <<"category"/utf8>>,
                                                        {decoder,
                                                            fun gleam@dynamic@decode:decode_string/1},
                                                        fun(Category) ->
                                                            gleam@dynamic@decode:field(
                                                                <<"fodmap_level"/utf8>>,
                                                                fodmap_level_decoder(
                                                                    
                                                                ),
                                                                fun(
                                                                    Fodmap_level
                                                                ) ->
                                                                    gleam@dynamic@decode:field(
                                                                        <<"vertical_compliant"/utf8>>,
                                                                        {decoder,
                                                                            fun gleam@dynamic@decode:decode_bool/1},
                                                                        fun(
                                                                            Vertical_compliant
                                                                        ) ->
                                                                            gleam@dynamic@decode:success(
                                                                                {recipe,
                                                                                    Id,
                                                                                    Name,
                                                                                    Ingredients,
                                                                                    Instructions,
                                                                                    Macros,
                                                                                    Servings,
                                                                                    Category,
                                                                                    Fodmap_level,
                                                                                    Vertical_compliant}
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/shared/types.gleam", 382).
?DOC(" Decoder for UserProfile\n").
-spec user_profile_decoder() -> gleam@dynamic@decode:decoder(user_profile()).
user_profile_decoder() ->
    gleam@dynamic@decode:field(
        <<"id"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Id) ->
            gleam@dynamic@decode:field(
                <<"bodyweight"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_float/1},
                fun(Bodyweight) ->
                    gleam@dynamic@decode:field(
                        <<"activity_level"/utf8>>,
                        activity_level_decoder(),
                        fun(Activity_level) ->
                            gleam@dynamic@decode:field(
                                <<"goal"/utf8>>,
                                goal_decoder(),
                                fun(Goal) ->
                                    gleam@dynamic@decode:field(
                                        <<"meals_per_day"/utf8>>,
                                        {decoder,
                                            fun gleam@dynamic@decode:decode_int/1},
                                        fun(Meals_per_day) ->
                                            gleam@dynamic@decode:success(
                                                {user_profile,
                                                    Id,
                                                    Bodyweight,
                                                    Activity_level,
                                                    Goal,
                                                    Meals_per_day}
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/shared/types.gleam", 398).
?DOC(" Decoder for FoodLogEntry\n").
-spec food_log_entry_decoder() -> gleam@dynamic@decode:decoder(food_log_entry()).
food_log_entry_decoder() ->
    gleam@dynamic@decode:field(
        <<"id"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Id) ->
            gleam@dynamic@decode:field(
                <<"recipe_id"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Recipe_id) ->
                    gleam@dynamic@decode:field(
                        <<"recipe_name"/utf8>>,
                        {decoder, fun gleam@dynamic@decode:decode_string/1},
                        fun(Recipe_name) ->
                            gleam@dynamic@decode:field(
                                <<"servings"/utf8>>,
                                {decoder,
                                    fun gleam@dynamic@decode:decode_float/1},
                                fun(Servings) ->
                                    gleam@dynamic@decode:field(
                                        <<"macros"/utf8>>,
                                        macros_decoder(),
                                        fun(Macros) ->
                                            gleam@dynamic@decode:field(
                                                <<"meal_type"/utf8>>,
                                                meal_type_decoder(),
                                                fun(Meal_type) ->
                                                    gleam@dynamic@decode:field(
                                                        <<"logged_at"/utf8>>,
                                                        {decoder,
                                                            fun gleam@dynamic@decode:decode_string/1},
                                                        fun(Logged_at) ->
                                                            gleam@dynamic@decode:success(
                                                                {food_log_entry,
                                                                    Id,
                                                                    Recipe_id,
                                                                    Recipe_name,
                                                                    Servings,
                                                                    Macros,
                                                                    Meal_type,
                                                                    Logged_at}
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/shared/types.gleam", 418).
?DOC(" Decoder for DailyLog\n").
-spec daily_log_decoder() -> gleam@dynamic@decode:decoder(daily_log()).
daily_log_decoder() ->
    gleam@dynamic@decode:field(
        <<"date"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_string/1},
        fun(Date) ->
            gleam@dynamic@decode:field(
                <<"entries"/utf8>>,
                gleam@dynamic@decode:list(food_log_entry_decoder()),
                fun(Entries) ->
                    gleam@dynamic@decode:field(
                        <<"total_macros"/utf8>>,
                        macros_decoder(),
                        fun(Total_macros) ->
                            gleam@dynamic@decode:success(
                                {daily_log, Date, Entries, Total_macros}
                            )
                        end
                    )
                end
            )
        end
    ).
