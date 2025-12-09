-module(meal_planner_ffi).
-export([get_current_date/0]).

%% Get current date in YYYY-MM-DD format
get_current_date() ->
    {{Year, Month, Day}, _Time} = calendar:universal_time(),
    YearStr = integer_to_list(Year),
    MonthStr = pad_zero(Month),
    DayStr = pad_zero(Day),
    list_to_binary([YearStr, <<"-">>, MonthStr, <<"-">>, DayStr]).

%% Pad single digit numbers with leading zero
pad_zero(N) when N < 10 ->
    list_to_binary(["0", integer_to_list(N)]);
pad_zero(N) ->
    integer_to_binary(N).
