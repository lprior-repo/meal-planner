# Nutrition Control Plane (NCP) Strategy

## Applying Cockcroft & Wardley Principles for Maximum Time-to-Value

---

## 1. Wardley Map: Nutritional Decision Automation

```
                                        EVOLUTION
    Genesis ──────> Custom ──────> Product ──────> Commodity
    (novel)        (bespoke)       (rental)        (utility)

    ┌────────────────────────────────────────────────────────────┐
    │                                                            │
    │  USER NEED: "Automate my nutritional decisions"            │
V   │       │                                                    │
A   │       ▼                                                    │
L   │  ┌─────────────────┐                                       │
U   │  │ Meal Selection  │◄───────── Genesis (YOU BUILD)        │
E   │  │ Automation      │           Unique to your goals        │
    │  └────────┬────────┘                                       │
C   │           │                                                │
H   │           ▼                                                │
A   │  ┌─────────────────┐                                       │
I   │  │ Deviation       │◄───────── Custom (YOU BUILD)         │
N   │  │ Controllers     │           Your tolerance thresholds   │
    │  └────────┬────────┘                                       │
    │           │                                                │
    │           ▼                                                │
    │  ┌─────────────────┐                                       │
    │  │ Reconciliation  │◄───────── Custom (EXISTS - ncp.gleam) │
    │  │ Engine          │           Already implemented!        │
    │  └────────┬────────┘                                       │
    │           │                                                │
    │           ▼                                                │
    │  ┌─────────────────┐                                       │
    │  │ Macro           │◄───────── Product (EXISTS)           │
    │  │ Calculations    │           types.gleam formulas        │
    │  └────────┬────────┘                                       │
    │           │                                                │
    │           ▼                                                │
    │  ┌─────────────────┐                                       │
    │  │ Food Data       │◄───────── Commodity (USDA API)       │
    │  │                 │           Don't build - USE           │
    │  └────────┬────────┘                                       │
    │           │                                                │
    │           ▼                                                │
    │  ┌─────────────────┐                                       │
    │  │ Storage/DB      │◄───────── Commodity (SQLite)         │
    │  │                 │           Don't build - USE           │
    │  └────────┬────────┘                                       │
    │           │                                                │
    │           ▼                                                │
    │  ┌─────────────────┐                                       │
    │  │ Compute/Runtime │◄───────── Utility (Erlang/OTP)       │
    │  │                 │           Fault tolerance built-in    │
    │  └─────────────────┘                                       │
    │                                                            │
    └────────────────────────────────────────────────────────────┘
```

---

## 2. Strategic Analysis

### What to BUILD (Differentiating Capabilities)
| Component | Evolution | Why Build? |
|-----------|-----------|------------|
| **Meal Selection Automation** | Genesis | Unique to YOUR constraints (Vertical Diet, FODMAP, macro targets) |
| **Deviation Controllers** | Custom | YOUR tolerance thresholds, YOUR intervention preferences |
| **Scheduled Reconciliation** | Custom | Specific cadence for YOUR lifestyle |
| **Proactive Notifications** | Custom | YOUR preferred alert channels |

### What to USE (Commodities - Don't Reinvent)
| Component | Evolution | Source |
|-----------|-----------|--------|
| Food Database | Commodity | USDA FoodData Central (already integrated) |
| Storage | Commodity | SQLite (already integrated) |
| Email Delivery | Utility | Mailtrap (already integrated) |
| Fault Tolerance | Utility | Erlang/OTP supervision trees |
| HTTP Server | Utility | Wisp/Mist |

---

## 3. Control Plane Architecture (Kubernetes-Inspired)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         NUTRITION CONTROL PLANE                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        DESIRED STATE                             │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │   │
│  │  │ Macro Goals │  │ Meal Timing │  │ Dietary Constraints     │  │   │
│  │  │ P:180g      │  │ 3 meals/day │  │ - Low FODMAP            │  │   │
│  │  │ F:60g       │  │ 8am,12pm,6pm│  │ - Vertical Diet         │  │   │
│  │  │ C:250g      │  │             │  │ - No seed oils          │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        CONTROLLERS                               │   │
│  │                                                                  │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐  │   │
│  │  │ Reconciliation   │  │ Deviation Alert  │  │ Meal Suggest  │  │   │
│  │  │ Controller       │  │ Controller       │  │ Controller    │  │   │
│  │  │                  │  │                  │  │               │  │   │
│  │  │ Every 15min:     │  │ On deviation:    │  │ On deficit:   │  │   │
│  │  │ Compare actual   │  │ > 10% → notify   │  │ Score recipes │  │   │
│  │  │ vs. desired      │  │ > 20% → escalate │  │ Suggest best  │  │   │
│  │  └────────┬─────────┘  └────────┬─────────┘  └───────┬───────┘  │   │
│  │           │                     │                    │          │   │
│  └───────────┼─────────────────────┼────────────────────┼──────────┘   │
│              │                     │                    │              │
│              ▼                     ▼                    ▼              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                         ACTUATORS                                │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │   │
│  │  │ Dashboard    │  │ Email/Push   │  │ Shopping List        │   │   │
│  │  │ Update       │  │ Notification │  │ Generator            │   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    ▲                                    │
│                                    │                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        ACTUAL STATE                              │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │   │
│  │  │ Food Logs   │  │ Today's     │  │ Trend Analysis          │  │   │
│  │  │ (meals      │  │ Macros      │  │ (7-day rolling)         │  │   │
│  │  │  consumed)  │  │ P:120g/180g │  │ Protein: ↗ Increasing   │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Cockcroft Principles Applied

### 4.1 Speed of Delivery
- **Existing foundation**: NCP reconciliation engine already works
- **Fastest path**: Add controller loop + scheduler on top of existing code
- **No new frameworks**: Use Erlang/OTP timers (built-in)

### 4.2 Automation Over Manual Toil
| Manual Task Today | Automated Tomorrow |
|-------------------|-------------------|
| Check macro status | Scheduled reconciliation every 15 min |
| Look up suggestions | Proactive recipe recommendations |
| Track deviations | Automatic alerts when off-track |
| Plan weekly meals | Auto-generate based on remaining macros |

### 4.3 Observability (Metrics-Driven)
- **Key Metrics to Track**:
  - `ncp_deviation_protein_pct` - Protein deviation percentage
  - `ncp_deviation_fat_pct` - Fat deviation percentage
  - `ncp_deviation_carbs_pct` - Carbs deviation percentage
  - `ncp_reconciliation_count` - Number of reconciliations run
  - `ncp_alerts_sent` - Number of alerts triggered
  - `ncp_consistency_rate` - % of days within tolerance

### 4.4 Self-Healing Systems
- **Deviation > 10%**: Suggest corrective meal
- **Deviation > 20%**: Email alert + shopping list for deficit foods
- **Trend analysis**: Detect patterns, adjust meal timing recommendations

---

## 5. Implementation Phases

### Phase 1: Controller Infrastructure (Fastest Time-to-Value)
1. Add `ncp_controller.gleam` - Scheduled reconciliation loop
2. Add `ncp_scheduler.gleam` - Erlang timer-based scheduling
3. Wire into OTP supervision tree for fault tolerance

### Phase 2: Proactive Notifications
1. Enhance email.gleam with deviation alerts
2. Add meal suggestion emails when off-track
3. Daily summary emails at end of day

### Phase 3: Full Automation
1. Auto-generate next meal recommendation
2. Shopping list automation for weekly prep
3. Trend-based goal adjustments

---

## 6. Key Files to Create/Modify

| File | Purpose |
|------|---------|
| `gleam/src/meal_planner/ncp_controller.gleam` | Control loop implementation |
| `gleam/src/meal_planner/ncp_scheduler.gleam` | OTP-based scheduler |
| `gleam/src/meal_planner/ncp_alerts.gleam` | Alert/notification logic |
| `gleam/src/meal_planner/ncp_metrics.gleam` | Observability metrics |
| Modify `supervisor.gleam` | Add controllers to supervision tree |

---

## 7. Success Metrics

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| **Manual decisions/day** | 0 | Full automation |
| **Time to corrective action** | < 15 min | Fast feedback loop |
| **Consistency rate** | > 90% | Hitting macro targets |
| **Reconciliation frequency** | Every 15 min | Tight control loop |
