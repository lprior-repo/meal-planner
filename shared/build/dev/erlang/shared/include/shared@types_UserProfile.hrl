-record(user_profile, {
    id :: binary(),
    bodyweight :: float(),
    activity_level :: shared@types:activity_level(),
    goal :: shared@types:goal(),
    meals_per_day :: integer()
}).
