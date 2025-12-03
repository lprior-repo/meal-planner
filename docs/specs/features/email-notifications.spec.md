# Feature: Email Notifications

## Bead ID: meal-planner-bn3

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Dependencies
- Weekly Meal Planning
- Live Dashboard Integration

## Feature Description
Send automated email notifications for weekly meal plan summaries, daily reminders, and nutritional insights using Mailtrap API.

## Capabilities

### Capability 1: Weekly Summary Email
**Behaviors:**
- GIVEN Sunday evening WHEN scheduled THEN send weekly summary
- GIVEN past week data WHEN compiling THEN include macro averages
- GIVEN targets WHEN comparing THEN highlight achievement/gaps
- GIVEN next week plan WHEN available THEN include preview

### Capability 2: Daily Reminder Email
**Behaviors:**
- GIVEN morning time WHEN configured THEN send daily reminder
- GIVEN today's plan WHEN available THEN list planned meals
- GIVEN shopping needs WHEN detected THEN include shopping reminder

### Capability 3: NCP Reconciliation Email
**Behaviors:**
- GIVEN macro deviation WHEN significant THEN send adjustment suggestions
- GIVEN recipe recommendations WHEN generated THEN include top 3 matches
- GIVEN adjustment plan WHEN created THEN list recommended additions

### Capability 4: Email Preferences
**Behaviors:**
- GIVEN user preferences WHEN configuring THEN allow enable/disable per type
- GIVEN email frequency WHEN setting THEN support daily/weekly options
- GIVEN time preference WHEN setting THEN schedule at preferred hour

### Capability 5: Email Templates
**Behaviors:**
- GIVEN email type WHEN sending THEN use branded HTML template
- GIVEN mobile devices WHEN rendering THEN ensure responsive design
- GIVEN plain text WHEN needed THEN include text fallback

## Acceptance Criteria
- [ ] Weekly summary emails send on schedule
- [ ] Daily reminders include today's meal plan
- [ ] NCP emails suggest corrective meals
- [ ] Users can configure email preferences
- [ ] Emails render correctly on mobile

## Test Criteria (BDD)
```gherkin
Scenario: Send weekly summary email
  Given user has email notifications enabled
  And it is Sunday at 6 PM
  When weekly summary job runs
  Then email is sent via Mailtrap API
  And email contains last week's macro averages
  And email shows achievement vs targets

Scenario: NCP adjustment email
  Given user is 50g protein below target
  When NCP reconciliation runs
  Then email suggests high-protein recipes
  And lists "Grilled Chicken" as top recommendation
```
