# User Acceptance Testing (UAT) Plan
## meal-planner Phase 3: Autonomous Nutritional Control Plane

**Document Version:** 1.0
**Date:** 2025-12-19
**Phase:** Pre-Production UAT
**Status:** DRAFT - Pending Approval

---

## Executive Summary

This User Acceptance Testing (UAT) plan validates the meal-planner autonomous nutritional control plane from the end-user perspective. The system orchestrates weekly meal plan generation, automated FatSecret synchronization, email-based feedback loops, and adaptive meal adjustments.

**Test Duration:** 1 week (Monday-Sunday)
**Test Users:** 3 users (varied profiles)
**Success Criteria:** ≥95% generation success, ≥99% email delivery, ≥8/10 user satisfaction
**Go/No-Go Decision:** Based on critical metrics and zero P0 bugs

---

## 1. Test Scenarios

### Scenario 1: New User Onboarding

**Objective:** Verify complete onboarding flow from account creation to first meal plan generation.

**User Profile:**
- Name: Alex (Test User 1)
- FatSecret Profile: 2000 cal/day, 150g protein, 70g fat, 180g carbs
- Constraints: Travels Tuesday-Thursday, loves pasta, dislikes salmon
- Experience Level: First-time user

**Test Steps:**

1. **Account Creation (Day 1 - Monday)**
   - User registers account via web interface
   - Email verification sent and confirmed
   - FatSecret OAuth connection established
   - User profile populated with macro goals from FatSecret

   **Expected Outcome:**
   - ✓ Account created with unique user_id
   - ✓ Verification email received within 30 seconds
   - ✓ FatSecret sync successful (profile data retrieved)
   - ✓ Database has complete user record

2. **Constraint Input (Day 1 - Monday)**
   - User navigates to constraints page
   - Inputs: "I travel Tue-Thu next week, love pasta, hate salmon"
   - System parses natural language constraints
   - Locked meals: None (first week)

   **Expected Outcome:**
   - ✓ Constraints saved to database
   - ✓ Travel dates parsed: [Tuesday, Wednesday, Thursday]
   - ✓ Food preferences stored: pasta (like), salmon (dislike)
   - ✓ Confirmation message displayed

3. **First Generation Trigger (Day 1 - Monday)**
   - User clicks "Generate My Week" button
   - System creates WeeklyGeneration job
   - Scheduler executes generation within 30 seconds
   - Progress indicator shown to user

   **Expected Outcome:**
   - ✓ Job status: pending → running → completed
   - ✓ Generation completes in < 60 seconds
   - ✓ Meal plan created with 7 days (21 meals)
   - ✓ No salmon recipes included
   - ✓ Friday dinner contains pasta recipe

4. **Review Generated Plan (Day 1 - Monday)**
   - User views meal plan in web interface
   - Checks macro breakdown per day
   - Reviews grocery list
   - Verifies travel day accommodations

   **Expected Outcome:**
   - ✓ Meal plan displayed with recipe names, macros, images
   - ✓ Daily macros within ±10% of target (1800-2200 cal)
   - ✓ Grocery list consolidated (no duplicates)
   - ✓ Travel days (Tue-Thu) have quick-prep meals
   - ✓ Friday dinner: pasta recipe with ~600 cal

5. **Email Confirmation (Day 1 - Monday)**
   - User receives "Your meal plan is ready!" email
   - Email contains plan summary, grocery list link
   - Email has feedback instructions ("Reply with @Claude to adjust")

   **Expected Outcome:**
   - ✓ Email delivered within 5 minutes of generation
   - ✓ Email not in spam folder
   - ✓ Links to meal plan work correctly
   - ✓ Grocery list downloadable as PDF

**Pass Criteria:**
- All 5 steps complete successfully
- Generation time < 60 seconds
- Email delivered and functional
- User satisfaction rating ≥ 7/10 (post-scenario survey)

**Fail Criteria:**
- Generation fails or times out
- Email not delivered within 10 minutes
- Constraints ignored (salmon included, pasta missing)
- User reports confusion or frustration

---

### Scenario 2: Weekly Routine (Full Cycle)

**Objective:** Validate the complete weekly automation loop from generation to sync to advisor emails.

**User Profile:**
- Name: Jordan (Test User 2)
- FatSecret Profile: 2500 cal/day, 200g protein, 85g fat, 220g carbs
- Constraints: None (standard week)
- Experience Level: Active user (3+ weeks)

**Test Steps:**

1. **Friday 6 AM: Automatic Generation**
   - Scheduler triggers WeeklyGeneration job (cron: 0 6 * * 5)
   - Job executes without manual intervention
   - User receives email notification

   **Expected Outcome:**
   - ✓ Job executes at exactly 6:00 AM Friday
   - ✓ Generation completes within 2 minutes
   - ✓ Meal plan for next week (Mon-Sun) created
   - ✓ Email sent to user by 6:05 AM

2. **Saturday: Grocery Shopping**
   - User opens grocery list email
   - Downloads consolidated list
   - Shops using categorized list (proteins, veggies, starches)

   **Expected Outcome:**
   - ✓ Grocery list has all ingredients for 21 meals
   - ✓ Items grouped by category (produce, meat, dairy, pantry)
   - ✓ Quantities aggregated (e.g., "8 eggs" not "2 eggs" x4)
   - ✓ List fits on 1 page (PDF)

3. **Monday-Friday: Daily Meal Logging**
   - User logs meals in FatSecret app as consumed
   - Actual macros recorded (may differ from plan)
   - Logs breakfast (7 AM), lunch (12 PM), dinner (6 PM)

   **Expected Outcome:**
   - ✓ Each meal logged in FatSecret within 30 min of consumption
   - ✓ Meal names match plan (or user creates custom entries)
   - ✓ Macros captured in FatSecret diary

4. **Daily 8 PM: Advisor Emails**
   - Scheduler triggers DailyAdvisor job (cron: 0 20 * * *)
   - Job fetches FatSecret diary for the day
   - Advisor email sent with recommendations

   **Expected Outcome:**
   - ✓ Email delivered at 8:00-8:05 PM daily (Mon-Fri)
   - ✓ Email contains actual vs target macros
   - ✓ Recommendations personalized:
     - "Great job! 5g over protein target" (positive)
     - "Low on carbs today (-30g), add fruit tomorrow" (actionable)
   - ✓ Email tone friendly and encouraging

5. **Thursday 8 PM: Weekly Trend Analysis**
   - Scheduler triggers WeeklyTrends job (cron: 0 20 * * 4)
   - Job analyzes 7 days of FatSecret data
   - Trends email sent with charts and insights

   **Expected Outcome:**
   - ✓ Email delivered Thursday 8:00-8:05 PM
   - ✓ Email contains:
     - Average macros across week
     - Adherence rate (% meals logged)
     - Weight trend (if logged)
     - Suggestions for next week
   - ✓ Charts rendered correctly (macros over time)
   - ✓ Insights actionable ("You're low on protein on weekends")

6. **Friday 6 AM: Next Week Generation**
   - Cycle repeats (new generation for week N+1)
   - Rotation history updated (week N meals excluded)
   - User receives new plan email

   **Expected Outcome:**
   - ✓ New plan generated successfully
   - ✓ No recipe repeats from previous week
   - ✓ Rotation enforced (30-day spacing)
   - ✓ User receives email on time

**Pass Criteria:**
- All automated jobs execute on schedule (±5 min tolerance)
- 100% email delivery rate (no missed emails)
- User logs ≥85% of meals (18/21)
- Advisor emails contain accurate data
- User satisfaction rating ≥ 8/10

**Fail Criteria:**
- Any job fails or skips execution
- Email delivery < 100%
- Advisor emails have stale or incorrect data
- User reports automation "didn't feel automatic"

---

### Scenario 3: Email Feedback Loop

**Objective:** Test user's ability to adjust meal plan via natural language email commands.

**User Profile:**
- Name: Sam (Test User 3)
- FatSecret Profile: 1800 cal/day, 130g protein, 55g fat, 180g carbs
- Constraints: None initially
- Experience Level: Intermediate

**Test Steps:**

1. **Friday: Initial Plan Received**
   - User receives weekly meal plan email
   - Plan includes "Grilled Salmon" for Tuesday dinner
   - User dislikes salmon (undisclosed preference)

   **Expected Outcome:**
   - ✓ Plan delivered successfully
   - ✓ Tuesday dinner: Grilled Salmon (600 cal, 40g protein)

2. **Sunday: User Sends Feedback Email**
   - User replies to meal plan email:
     - "**@Claude** I hate salmon! Can we swap Tuesday dinner for chicken?"
   - Email sent to system inbox

   **Expected Outcome:**
   - ✓ Email received by system within 30 seconds
   - ✓ Command parsed successfully:
     - Action: AdjustMeal
     - Day: Tuesday
     - Meal Type: Dinner
     - Replacement: Chicken recipe

3. **Sunday: System Processes Command**
   - Email parser extracts command
   - Generation engine finds alternative chicken recipe
   - New meal plan saved (only Tuesday dinner changed)
   - Confirmation email sent to user

   **Expected Outcome:**
   - ✓ Processing completes within 2 minutes
   - ✓ Tuesday dinner updated: "Herb Chicken Breast" (580 cal, 42g protein)
   - ✓ Macros stay within ±10% of target
   - ✓ Grocery list updated (salmon removed, chicken added)
   - ✓ Confirmation email: "Tuesday dinner updated to Herb Chicken Breast!"

4. **Monday: User Verifies Change**
   - User logs into web interface
   - Checks meal plan for Tuesday
   - Confirms chicken recipe shown

   **Expected Outcome:**
   - ✓ Meal plan shows updated recipe
   - ✓ Macros recalculated correctly
   - ✓ Old salmon recipe NOT in plan

5. **Next Friday: System "Learns" Preference**
   - New week generation runs
   - Salmon excluded from all future plans
   - User preference persisted in database

   **Expected Outcome:**
   - ✓ New plan has NO salmon recipes
   - ✓ Database has food_preferences entry: salmon (dislike)
   - ✓ Future generations respect this constraint

**Pass Criteria:**
- Email command parsed correctly (100% accuracy)
- Meal plan updated within 2 minutes
- Confirmation email sent and accurate
- Preference persisted for future weeks
- User satisfaction rating ≥ 9/10

**Fail Criteria:**
- Command not recognized or ignored
- Wrong meal updated or no update
- Confirmation email missing or incorrect
- Preference not learned (salmon appears again)

---

### Scenario 4: Error Recovery

**Objective:** Verify system resilience during external API failures.

**User Profile:**
- Name: Taylor (Test User 4 - Internal QA)
- FatSecret Profile: Mock account for testing
- Constraints: Standard week
- Experience Level: QA tester

**Test Steps:**

1. **Friday 6 AM: Generation with FatSecret Outage**
   - Scheduler triggers WeeklyGeneration job
   - FatSecret API returns 503 Service Unavailable
   - Job execution fails (transient error)

   **Expected Outcome:**
   - ✓ Job status: running → failed
   - ✓ Error logged: "FatSecret API unavailable (503)"
   - ✓ Retry scheduled for 1 minute later
   - ✓ User NOT notified yet (waiting for retry)

2. **Friday 6:01 AM: First Retry**
   - Scheduler retries WeeklyGeneration job
   - FatSecret API still down
   - Job fails again

   **Expected Outcome:**
   - ✓ Job status: running → failed (attempt 2/3)
   - ✓ Retry scheduled for 2 minutes later (exponential backoff)
   - ✓ Error count incremented in database

3. **Friday 6:03 AM: Second Retry Success**
   - Scheduler retries WeeklyGeneration job
   - FatSecret API back online
   - Job completes successfully

   **Expected Outcome:**
   - ✓ Job status: running → completed
   - ✓ Meal plan generated with fresh FatSecret data
   - ✓ Email sent to user (no mention of retries)
   - ✓ User experience: seamless (unaware of failures)

4. **Friday 6:10 AM: User Checks Plan**
   - User logs in to web interface
   - Views meal plan (on time despite retries)

   **Expected Outcome:**
   - ✓ Plan available (delay unnoticed by user)
   - ✓ Data accurate (from successful FatSecret sync)
   - ✓ No error messages shown to user

5. **Admin Review: Audit Log**
   - QA admin checks scheduler audit log
   - Reviews retry history and error details

   **Expected Outcome:**
   - ✓ Audit log shows 3 attempts (2 failed, 1 success)
   - ✓ Error messages descriptive:
     - "FatSecret API error: 503 Service Unavailable"
     - "Retry scheduled for 2025-12-19T06:01:00Z"
   - ✓ Backoff calculation correct (60s → 120s)

**Pass Criteria:**
- System recovers automatically (no manual intervention)
- User receives meal plan on time (within 5 min of original schedule)
- Retry logic works as designed (exponential backoff)
- Audit log captures all attempts
- No data corruption or partial state

**Fail Criteria:**
- Job gives up before API recovers
- User notified of transient errors
- Plan not delivered or delivered with stale data
- Retry logic fails (immediate retry, no backoff)

---

### Scenario 5: Macro Adjustment

**Objective:** Test dynamic macro target adjustment based on user feedback.

**User Profile:**
- Name: Casey (Test User 5)
- FatSecret Profile: 2200 cal/day, 160g protein, 70g fat, 200g carbs
- Constraints: None
- Experience Level: Advanced user

**Test Steps:**

1. **Monday: User Receives Standard Plan**
   - Weekly plan generated with standard macro targets
   - Daily target: 160g protein per day

   **Expected Outcome:**
   - ✓ Plan has balanced macros (160g protein avg)
   - ✓ Meals distributed evenly across days

2. **Tuesday: User Requests Protein Boost**
   - User sends email:
     - "**@Claude** add more protein this week, I'm training heavy"
   - Email processed by command parser

   **Expected Outcome:**
   - ✓ Email received and parsed
   - ✓ Command: AdjustMacros
   - ✓ Mode: high_protein
   - ✓ Acknowledgment email sent: "Adjusting protein targets..."

3. **Tuesday: Plan Regeneration**
   - System triggers immediate regeneration
   - Macro targets adjusted: 180g protein (was 160g)
   - New meals selected to hit higher protein

   **Expected Outcome:**
   - ✓ Regeneration completes within 3 minutes
   - ✓ Updated plan: 180g protein per day
   - ✓ Recipes swapped:
     - Breakfast: Protein Pancakes → Steak & Eggs (higher protein)
     - Lunch: Chicken Salad → Bison Burger (higher protein)
   - ✓ Calories remain close to 2200 (±100 tolerance)

4. **Tuesday: User Reviews Adjusted Plan**
   - User receives email: "Your meal plan has been updated!"
   - User logs in to view new plan

   **Expected Outcome:**
   - ✓ Meal plan shows updated recipes
   - ✓ Daily macros recalculated:
     - Protein: 180g (was 160g)
     - Fat: 75g (slight increase due to higher protein foods)
     - Carbs: 195g (slight decrease to maintain calories)
   - ✓ Grocery list updated automatically

5. **Wednesday: User Confirms Adjustment**
   - User logs meals from adjusted plan
   - Diary shows higher protein intake
   - Daily advisor email reflects new targets

   **Expected Outcome:**
   - ✓ User logs meals successfully
   - ✓ FatSecret diary shows ~180g protein
   - ✓ Advisor email: "Great! You hit 182g protein today (target: 180g)"
   - ✓ No confusion about changed targets

**Pass Criteria:**
- Macro adjustment applied correctly (160g → 180g protein)
- Plan regenerated without user manually triggering
- New recipes meet higher protein targets
- Calories stay within ±100 cal of original target
- User satisfaction rating ≥ 9/10

**Fail Criteria:**
- Adjustment ignored or applied incorrectly
- Regeneration fails or times out
- Macros wildly off target (calories > 2300 or < 2100)
- User receives no confirmation email

---

## 2. Test Environment

### 2.1 Test Infrastructure

**Database:**
- PostgreSQL 15.0+ with PostGIS extension
- Separate test database: `meal_planner_uat`
- Pre-seeded with 100+ recipes (balanced macro distribution)
- Test user accounts isolated from production

**External APIs:**
- **FatSecret API:** Test developer account (rate limit: 100 req/day)
- **Tandoor API:** Local test instance (localhost:8080)
- **Email Service:** Test SMTP server (Mailhog or similar, no real emails sent)

**Scheduler:**
- Test cron daemon with accelerated schedule (minutes instead of days)
- Manual trigger endpoints enabled for testing

### 2.2 Test User Accounts

| User ID | Name | FatSecret Profile | Constraints | Purpose |
|---------|------|-------------------|-------------|---------|
| `test-user-001` | Alex | 2000 cal, 150g protein | Travel Tue-Thu, loves pasta | Scenario 1: Onboarding |
| `test-user-002` | Jordan | 2500 cal, 200g protein | None (standard week) | Scenario 2: Full cycle |
| `test-user-003` | Sam | 1800 cal, 130g protein | Dislikes salmon | Scenario 3: Feedback loop |
| `test-user-004` | Taylor | Mock (no real FatSecret) | None | Scenario 4: Error recovery |
| `test-user-005` | Casey | 2200 cal, 160g protein | None initially | Scenario 5: Macro adjustment |

### 2.3 Test Data

**Recipe Pool (Pre-Seeded):**
- 30 breakfast recipes (200-500 cal, 15-40g protein)
- 25 lunch recipes (400-700 cal, 30-50g protein)
- 25 dinner recipes (500-900 cal, 35-60g protein)
- All recipes tagged: vertical_compliant, fodmap_level, category

**Sample Recipes:**
1. Protein Pancakes (305 cal, 25g protein, 9g fat, 32g carbs)
2. Grilled Salmon (600 cal, 40g protein, 35g fat, 10g carbs)
3. Herb Chicken Breast (580 cal, 42g protein, 28g fat, 12g carbs)
4. Bison Burger (720 cal, 55g protein, 40g fat, 22g carbs)
5. Pasta Primavera (650 cal, 18g protein, 15g fat, 95g carbs)

**Macro Profiles:**
- Standard: 2000 cal, 150g protein, 70g fat, 180g carbs
- High Protein: 2500 cal, 200g protein, 85g fat, 220g carbs
- Low Calorie: 1800 cal, 130g protein, 55g fat, 180g carbs
- Adjusted: 2200 cal, 180g protein, 75g fat, 195g carbs

### 2.4 Testing Timeline

**Week 1 (UAT Execution):**

| Day | Time | Activity | Scenarios |
|-----|------|----------|-----------|
| Monday | 9:00 AM | Test environment setup | All |
| Monday | 10:00 AM | Scenario 1 execution (Alex onboarding) | 1 |
| Monday | 2:00 PM | Scenario 5 start (Casey macro adjustment) | 5 |
| Tuesday | 9:00 AM | Scenario 3 start (Sam feedback email) | 3 |
| Wednesday | 9:00 AM | Scenario 5 verification (Casey logs meals) | 5 |
| Thursday | 8:00 PM | Scenario 2 checkpoint (weekly trends email) | 2 |
| Friday | 6:00 AM | Scenario 2 + 4 (automated generation + error recovery) | 2, 4 |
| Friday | 10:00 AM | All scenarios review and sign-off | All |

---

## 3. Test Execution

### 3.1 Daily Test Runs

**Morning Session (9:00-11:00 AM):**
- Execute manual trigger tests (onboarding, feedback loop)
- Verify database state after each scenario
- Check email logs and delivery confirmations
- Review scheduler audit logs for overnight jobs

**Afternoon Session (2:00-4:00 PM):**
- Monitor automated job executions (if scheduled)
- Run API health checks (FatSecret, Tandoor)
- Execute error injection tests (API outages)
- Review macro calculation accuracy

**Evening Session (8:00-9:00 PM):**
- Verify daily advisor emails sent on time
- Check Thursday weekly trends email
- Confirm email content accuracy (macros, recommendations)
- Test mobile email rendering

### 3.2 Issue Logging and Tracking

**Issue Severity Levels:**

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| **P0 - Critical** | System unusable, data loss, security breach | Immediate (< 1 hour) | Generation fails all users, database corruption |
| **P1 - High** | Core feature broken, major functionality lost | Same day (< 4 hours) | Email delivery failure, macro calculations wrong |
| **P2 - Medium** | Feature degraded, workaround exists | Next day (< 24 hours) | Slow generation (> 5 min), email formatting issues |
| **P3 - Low** | Minor cosmetic issue, no user impact | Next sprint | Typo in email, minor UI alignment |

**Issue Tracking Template:**

```
Issue ID: UAT-001
Scenario: Scenario 3 (Email Feedback Loop)
Severity: P1 - High
Description: Email command "@Claude swap Tuesday dinner" not parsed correctly
Steps to Reproduce:
  1. User sends email with command
  2. System returns "Command not recognized" error
  3. Meal plan NOT updated
Expected: Tuesday dinner swapped for alternative recipe
Actual: No change, error email sent
Environment: Test database, user test-user-003
Logs: /var/log/meal-planner/email_parser.log (lines 1234-1256)
Assigned To: Email Parser Team
Status: Open
```

### 3.3 Sign-Off Procedure

**Sign-Off Checklist:**

- [ ] All 5 test scenarios executed successfully
- [ ] Zero P0 (critical) bugs remaining
- [ ] All P1 (high) bugs resolved or have workarounds
- [ ] Go/no-go criteria met (see Section 4)
- [ ] User satisfaction surveys completed (≥8/10 average)
- [ ] Performance benchmarks within targets (see Section 4.2)
- [ ] Security audit passed (no vulnerabilities found)
- [ ] Documentation reviewed and approved
- [ ] Rollback plan documented and tested
- [ ] Production deployment plan approved

**Sign-Off Authorities:**

1. **QA Lead** - Confirms all tests passed, issues tracked
2. **Product Owner** - Confirms user experience meets requirements
3. **Engineering Lead** - Confirms system performance and stability
4. **Security Lead** - Confirms no security vulnerabilities
5. **Stakeholder** - Final approval for production deployment

---

## 4. Go/No-Go Criteria

### 4.1 Success Metrics

**Critical Metrics (Must Pass All):**

| Metric | Target | Measurement | Pass/Fail |
|--------|--------|-------------|-----------|
| **Generation Success Rate** | ≥ 95% | (Successful generations / Total attempts) × 100 | |
| **Email Delivery Rate** | ≥ 99% | (Emails delivered / Emails sent) × 100 | |
| **User Satisfaction** | ≥ 8/10 | Post-scenario survey (NPS-style) | |
| **System Uptime** | ≥ 99.5% | (Time available / Total test time) × 100 | |
| **API Response Time** | ≤ 2 seconds | P95 latency for generation API | |
| **Zero Critical Bugs** | 0 P0 bugs | Count of open P0 issues | |

**Secondary Metrics (Should Pass 4/6):**

| Metric | Target | Measurement | Pass/Fail |
|--------|--------|-------------|-----------|
| **Macro Accuracy** | ±10% daily | (Actual macros - Target macros) / Target macros | |
| **Rotation Compliance** | 100% | Recipes NOT repeated within 30 days | |
| **Feedback Loop Latency** | ≤ 2 minutes | Time from email received to plan updated | |
| **Grocery List Accuracy** | ≥ 98% | Ingredients match all 21 meals | |
| **Advisor Email Relevance** | ≥ 7/10 | User rating of email usefulness | |
| **Retry Success Rate** | ≥ 90% | (Successful retries / Failed first attempts) × 100 | |

### 4.2 Performance Benchmarks

**Generation Performance:**
- Generation time: ≤ 60 seconds (P95)
- Database queries: ≤ 50 queries per generation
- Memory usage: ≤ 512 MB per generation

**Email Performance:**
- Email send latency: ≤ 30 seconds
- Email rendering time: ≤ 5 seconds (mobile)
- Spam score: ≤ 2.0 (SpamAssassin)

**Scheduler Performance:**
- Job queue processing: ≤ 5 seconds
- Concurrent job limit: 5 jobs (no failures)
- Retry backoff accuracy: ±10 seconds

### 4.3 Go Decision Matrix

**GO Criteria (All Must Be True):**
1. ✓ All 6 critical metrics PASS
2. ✓ At least 4/6 secondary metrics PASS
3. ✓ Zero P0 bugs, ≤ 2 P1 bugs (with workarounds)
4. ✓ All 5 test scenarios complete successfully
5. ✓ User satisfaction ≥ 8/10 (average across all users)
6. ✓ Sign-off checklist 100% complete

**NO-GO Criteria (Any Triggers Delay):**
1. ✗ Any critical metric FAILS
2. ✗ ≥ 1 P0 bug OR ≥ 3 P1 bugs
3. ✗ Any test scenario blocked (cannot complete)
4. ✗ User satisfaction < 8/10
5. ✗ Security vulnerability found (OWASP Top 10)
6. ✗ Performance degradation > 20% from baseline

**Conditional GO (Requires Stakeholder Approval):**
- 5/6 critical metrics PASS (1 marginal failure)
- 3/6 secondary metrics PASS (acceptable for MVP)
- 2 P1 bugs (mitigation plan documented)
- User satisfaction = 7.5-7.9/10 (close to target)

---

## 5. Test Deliverables

### 5.1 Test Reports

**Daily Test Summary (Due: End of each test day)**
- Scenarios executed (pass/fail status)
- Issues discovered (with severity and descriptions)
- Metrics collected (generation success, email delivery, etc.)
- Observations and notes

**Weekly UAT Report (Due: Friday 5:00 PM)**
- Overall test coverage (% scenarios complete)
- Metrics summary (all 12 metrics with pass/fail)
- Issue summary (count by severity, resolved vs open)
- User satisfaction survey results
- Go/no-go recommendation
- Appendices: Issue logs, audit logs, performance charts

### 5.2 User Satisfaction Surveys

**Post-Scenario Survey (5 questions, 5 minutes):**

1. **Ease of Use:** "How easy was it to complete this scenario?" (1-10 scale)
2. **Accuracy:** "Did the system meet your expectations?" (1-10 scale)
3. **Performance:** "Was the system responsive and fast?" (1-10 scale)
4. **Reliability:** "Did you encounter any errors or issues?" (Yes/No + description)
5. **Overall Satisfaction:** "Would you use this system regularly?" (1-10 scale)

**Net Promoter Score (NPS):**
- "How likely are you to recommend this system to a friend?" (0-10 scale)
- Calculation: % Promoters (9-10) - % Detractors (0-6)

### 5.3 Sign-Off Documentation

**UAT Sign-Off Form:**

```
Project: meal-planner Phase 3 UAT
Date: _____________
Test Duration: _____________
Test Lead: _____________

Test Summary:
- Scenarios Executed: ___/5
- Critical Metrics Passed: ___/6
- Secondary Metrics Passed: ___/6
- P0 Bugs: ___
- P1 Bugs: ___
- User Satisfaction: ___/10

Go/No-Go Decision: [ ] GO  [ ] NO-GO  [ ] CONDITIONAL GO

Sign-Off:
QA Lead: _________________ Date: _______
Product Owner: _________________ Date: _______
Engineering Lead: _________________ Date: _______
Security Lead: _________________ Date: _______
Stakeholder: _________________ Date: _______

Notes:
_______________________________________________________
_______________________________________________________
```

---

## 6. Risk Assessment

### 6.1 Identified Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **FatSecret API rate limit exceeded** | Medium | High | Use test account with 100 req/day limit, throttle tests |
| **Email spam filtering** | High | Medium | Use test SMTP (Mailhog), verify SPF/DKIM in production |
| **Macro calculation errors** | Low | High | Validate against known recipes, manual spot checks |
| **Database connection failures** | Low | Critical | Use connection pooling, retry logic tested in Scenario 4 |
| **Scheduler timing drift** | Low | Medium | Monitor cron execution logs, allow ±5 min tolerance |
| **User confusion with email commands** | Medium | Low | Provide clear examples in initial email, FAQ link |

### 6.2 Contingency Plans

**If Generation Fails (Scenario 1, 2, 5):**
1. Check FatSecret API status (use /health endpoint)
2. Review database logs for constraint violations
3. Retry with relaxed constraints (remove locked meals)
4. Escalate to engineering if > 3 consecutive failures

**If Email Delivery Fails (All Scenarios):**
1. Check SMTP server logs (Mailhog or test service)
2. Verify email addresses configured correctly
3. Test with manual email send (bypassing automation)
4. Escalate to DevOps if SMTP service down

**If Macro Calculations Wrong (Scenario 2, 5):**
1. Recalculate manually for sample day
2. Check recipe data for missing/incorrect values
3. Verify summation logic in code (sum_day_macros function)
4. Roll back to previous generation if data corruption suspected

**If User Satisfaction < 8/10:**
1. Conduct follow-up interviews with users
2. Identify specific pain points (UI, performance, accuracy)
3. Document improvement backlog
4. Decide if issues block production or can be post-launch fixes

---

## 7. Success Indicators

### 7.1 Quantitative Indicators

**System Reliability:**
- [ ] 95%+ generation success rate across all scenarios
- [ ] 99%+ email delivery rate (no bounces, no spam folder)
- [ ] 0 P0 bugs, ≤ 2 P1 bugs at sign-off

**User Experience:**
- [ ] 8/10+ average user satisfaction score
- [ ] ≥ 60 NPS (Net Promoter Score)
- [ ] ≤ 2 minutes average feedback loop latency

**Performance:**
- [ ] ≤ 60 seconds generation time (P95)
- [ ] ≤ 5 seconds email rendering (mobile)
- [ ] 99.5%+ system uptime during test week

**Accuracy:**
- [ ] ±10% macro accuracy daily (all 5 users)
- [ ] 100% rotation compliance (no 30-day repeats)
- [ ] 98%+ grocery list accuracy

### 7.2 Qualitative Indicators

**User Testimonials (Target: 4/5 users positive):**
- "I love how automatic this is—I don't have to think about meals!"
- "The feedback loop is amazing, it actually listens to my preferences."
- "Macros are spot-on, this is way better than manual planning."

**Observed Behaviors (During Testing):**
- Users complete scenarios without assistance
- Users intuitively understand email commands
- Users trust the system (don't double-check every meal)
- Users express excitement about production launch

**Team Confidence (Sign-Off Survey):**
- QA team rates system stability: 8/10+
- Engineering team rates code quality: 8/10+
- Product team rates feature completeness: 8/10+

---

## 8. Appendices

### Appendix A: Test Scenario Checklists

**Scenario 1: New User Onboarding**
- [ ] Account creation successful
- [ ] Email verification works
- [ ] FatSecret OAuth connected
- [ ] Constraints parsed correctly
- [ ] First generation completes
- [ ] Email delivered with plan

**Scenario 2: Weekly Routine**
- [ ] Friday 6 AM generation automatic
- [ ] Grocery list accurate
- [ ] Daily advisor emails (Mon-Fri)
- [ ] Weekly trends email (Thursday)
- [ ] Next week generation (following Friday)
- [ ] No recipe repeats

**Scenario 3: Email Feedback Loop**
- [ ] User sends feedback email
- [ ] Command parsed correctly
- [ ] Meal plan updated
- [ ] Confirmation email sent
- [ ] Preference learned for future

**Scenario 4: Error Recovery**
- [ ] Job fails with API error
- [ ] Retry scheduled (1 min backoff)
- [ ] Second retry succeeds
- [ ] User receives plan on time
- [ ] Audit log accurate

**Scenario 5: Macro Adjustment**
- [ ] User requests protein boost
- [ ] Plan regenerated with higher protein
- [ ] Macros updated (160g → 180g)
- [ ] Confirmation email sent
- [ ] Advisor emails reflect new targets

### Appendix B: Sample Test Data

**Test User 1 (Alex) Constraints:**
```json
{
  "locked_meals": [],
  "travel_dates": ["Tuesday", "Wednesday", "Thursday"],
  "food_preferences": {
    "likes": ["pasta"],
    "dislikes": ["salmon"]
  }
}
```

**Test User 3 (Sam) Email Command:**
```
From: sam@example.com
To: meal-planner@example.com
Subject: Re: Your meal plan is ready!

@Claude I hate salmon! Can we swap Tuesday dinner for chicken?
```

**Expected Email Parser Output:**
```json
{
  "command": "AdjustMeal",
  "day": "Tuesday",
  "meal_type": "dinner",
  "replacement": "chicken",
  "user_id": "test-user-003"
}
```

### Appendix C: Performance Baseline

**Generation Benchmarks (from performance tests):**
- Average time: 45 seconds
- P95 time: 58 seconds
- P99 time: 72 seconds

**Email Benchmarks:**
- SMTP send: 12 seconds (average)
- Email delivery: 18 seconds (average)
- Spam score: 1.2 (SpamAssassin)

**Database Benchmarks:**
- Query count per generation: 42 queries
- Total query time: 320 ms
- Connection pool size: 10 connections

### Appendix D: Glossary

**Terms:**
- **Generation:** Process of creating a 7-day meal plan from recipes and constraints
- **Auto-sync:** Scheduled job that syncs meal plan to FatSecret diary
- **Advisor Email:** Daily email with macro recommendations based on logged meals
- **Rotation:** 30-day rule preventing recipe repeats
- **Locked Meal:** User-specified meal that must be included in plan
- **Feedback Loop:** Email-based system for adjusting meal plans
- **Retry Policy:** Exponential backoff strategy for failed jobs
- **Macro Profile:** User's daily calorie and macronutrient targets

---

## Document Approval

**Prepared By:** Claude Code (UAT Specialist)
**Review Status:** DRAFT
**Next Review:** After stakeholder feedback
**Version History:**
- v1.0 (2025-12-19): Initial UAT plan created

**Approval Signatures:**

QA Lead: _________________ Date: _______
Product Owner: _________________ Date: _______
Engineering Lead: _________________ Date: _______
Stakeholder: _________________ Date: _______

---

**End of UAT Plan**
