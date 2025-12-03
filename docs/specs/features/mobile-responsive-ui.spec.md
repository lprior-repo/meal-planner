# Feature: Mobile-Responsive UI

## Bead ID: meal-planner-for

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Feature Description
Ensure all web pages are fully responsive and provide an optimal experience on mobile devices, tablets, and desktops.

## Capabilities

### Capability 1: Responsive Layout
**Behaviors:**
- GIVEN mobile viewport WHEN rendering THEN use single-column layout
- GIVEN tablet viewport WHEN rendering THEN use 2-column grid
- GIVEN desktop viewport WHEN rendering THEN use full multi-column layout
- GIVEN breakpoints WHEN crossing THEN smoothly transition layouts

### Capability 2: Touch-Friendly Controls
**Behaviors:**
- GIVEN buttons WHEN on mobile THEN have minimum 44px tap target
- GIVEN forms WHEN on mobile THEN use appropriate input types
- GIVEN navigation WHEN on mobile THEN use hamburger menu
- GIVEN swipe gestures WHEN available THEN support for navigation

### Capability 3: Optimized Performance
**Behaviors:**
- GIVEN images WHEN loading THEN use responsive srcset
- GIVEN CSS WHEN serving THEN minimize and bundle
- GIVEN mobile network WHEN slow THEN prioritize critical content
- GIVEN offline WHEN detected THEN show cached content

### Capability 4: Dashboard Mobile View
**Behaviors:**
- GIVEN macro bars WHEN on mobile THEN stack vertically
- GIVEN meal cards WHEN on mobile THEN show compact view
- GIVEN quick actions WHEN on mobile THEN show as floating button

### Capability 5: Recipe Mobile View
**Behaviors:**
- GIVEN recipe list WHEN on mobile THEN show card grid
- GIVEN recipe detail WHEN on mobile THEN collapse sections
- GIVEN ingredients WHEN on mobile THEN show checkable list

## Acceptance Criteria
- [ ] All pages pass mobile usability tests
- [ ] Navigation works on touch devices
- [ ] Forms are easy to use on mobile
- [ ] Performance scores 90+ on mobile Lighthouse
- [ ] No horizontal scrolling on any viewport

## Test Criteria (BDD)
```gherkin
Scenario: Dashboard on mobile
  Given user is on iPhone viewport (375px)
  When user views /dashboard
  Then macro bars stack vertically
  And navigation uses hamburger menu
  And all tap targets are >= 44px

Scenario: Recipe detail on tablet
  Given user is on iPad viewport (768px)
  When user views recipe detail
  Then ingredients and instructions show side-by-side
  And images resize appropriately
```
