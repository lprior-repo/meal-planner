-module(meal_planner_ffi).
-export([get_current_date/0]).

get_current_date() ->
    {{Year, Month, Day}, _} = calendar:local_time(),
    MonthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ],
    MonthName = lists:nth(Month, MonthNames),
    list_to_binary(io_lib:format("~s ~2..0B, ~4..0B", [MonthName, Day, Year])).
