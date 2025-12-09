# OTP Supervisor Architecture

## Overview

The meal planner application now implements a proper OTP supervisor tree for fault tolerance and process management.

## Supervisor Hierarchy

```
RootSupervisor (one_for_one)
├── ActorsSupervisor (one_for_one)
│   ├── SchedulerActor (weekly email notifications)
│   └── TodoistActor (API synchronization)
└── CacheSupervisor (one_for_one)
    └── QueryCache (in-memory query cache)
```

## Components

### 1. Root Supervisor

**Strategy**: `one_for_one`
- If a child crashes, only that specific child is restarted
- Other children continue running unaffected

**Children**:
- ActorsSupervisor: Manages background worker actors
- CacheSupervisor: Manages the query cache process

### 2. Actors Supervisor

**Children**:
- **SchedulerActor**: Sends weekly email notifications
- **TodoistActor**: Synchronizes with Todoist API

### 3. Cache Supervisor

**Children**:
- **QueryCache**: In-memory LRU cache with TTL

## Usage

```gleam
import meal_planner/supervisor
import meal_planner/postgres

pub fn main() {
  let assert Ok(db_conn) = postgres.connect()
  let assert Ok(sup) = supervisor.start(db_conn)
}
```

See full documentation in `/home/lewis/src/meal-planner/gleam/src/meal_planner/supervisor.gleam`
