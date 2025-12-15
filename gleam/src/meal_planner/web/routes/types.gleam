//// Types for the routing modules

import meal_planner/config
import pog

/// Application context passed to routers
pub type Context {
  Context(config: config.Config, db: pog.Connection)
}
