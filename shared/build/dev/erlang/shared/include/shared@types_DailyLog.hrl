-record(daily_log, {
    date :: binary(),
    entries :: list(shared@types:food_log_entry()),
    total_macros :: shared@types:macros()
}).
