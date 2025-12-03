# Acceptance Criteria Checklist: UI Design Beads

**Quick Reference Guide for QA and Development**

---

## Bead 1: CSS Design System (meal-planner-gli)

### Criteria 1.1: Design Tokens System

#### Color Palette
- [ ] Primary colors defined: light (#5B9FD8), base (#007BFF), dark (#004ECB)
- [ ] Accent colors defined: light (#6CC24A), base (#28a745), dark (#1E7E34)
- [ ] Neutral gray scale (50, 100, 200, 300, 400, 500, 600, 700, 800, 900)
- [ ] Status colors: Success (#10B981), Warning (#F59E0B), Error (#EF4444), Info (#3B82F6)
- [ ] All colors implemented as CSS custom properties
- [ ] Color palette documented in DESIGN_SYSTEM.md

#### Typography Scale
- [ ] Base font: system fonts specified
- [ ] 10 font sizes defined (12px-40px)
- [ ] Font weights: 400, 500, 600, 700
- [ ] Line heights: 1.2, 1.4, 1.5, 1.6
- [ ] Typography scale matches design mockups
- [ ] Tested at 16px base size

#### Spacing System
- [ ] 8 spacing values defined (4px-40px, multiples of 4)
- [ ] Spacing used consistently throughout components
- [ ] No hardcoded margins/padding values (except in utilities)
- [ ] Spacing scale documented

#### Border Radius
- [ ] 4 radius values: sm (4px), md (8px), lg (12px), xl (16px), full (9999px)
- [ ] Applied consistently to buttons, cards, inputs

#### Shadows (Elevation)
- [ ] 4 shadow levels defined
- [ ] Used for: sm (cards), md (dropdowns), lg (popovers), xl (modals)
- [ ] Shadows enhance visual hierarchy

#### Z-index Scale
- [ ] Scale defined: 0, 10, 20, 30, 40, 50
- [ ] Applied to: tooltips, popovers, modals, dropdowns
- [ ] No z-index conflicts

### Criteria 1.2: Component Library

#### Button Component
- [ ] Variants: primary, secondary, danger, ghost
- [ ] Sizes: sm (32px), md (40px), lg (48px)
- [ ] States: default, hover, active, disabled, loading
- [ ] Accessible: proper focus indicators
- [ ] Touch-friendly on mobile (44px minimum height)

#### Card Component
- [ ] Default card with shadow
- [ ] Elevated variant
- [ ] Interactive (hover state)
- [ ] Header/body/footer slots
- [ ] Responsive padding

#### Form Elements
- [ ] Input field with label, placeholder, validation states
- [ ] Textarea with label
- [ ] Select dropdown
- [ ] Checkbox with label
- [ ] Radio button group
- [ ] All form inputs: 44px minimum height on mobile
- [ ] Focus indicators visible

#### Badge Component
- [ ] Status badges (success, warning, error, info)
- [ ] Category badges
- [ ] Color variants matching design system
- [ ] Size variants (sm, md)

#### Progress Component
- [ ] Horizontal progress bar
- [ ] Circular/donut progress indicator
- [ ] Striped variant
- [ ] Animated fill
- [ ] Color variants (success, warning, error)

#### Table Component
- [ ] Semantic HTML structure
- [ ] Zebra striping (alternating row colors)
- [ ] Sortable headers (visual indicator)
- [ ] Responsive: scrollable on mobile
- [ ] Accessible: proper ARIA labels

#### Navigation Components
- [ ] Breadcrumbs
- [ ] Tab navigation with active state
- [ ] Pagination
- [ ] Mobile hamburger menu (if needed)

#### Alert Component
- [ ] Variants: success, warning, error, info
- [ ] Icon support
- [ ] Close button
- [ ] Dismissible

#### Modal Component
- [ ] Header with title and close button
- [ ] Body content area
- [ ] Footer with action buttons
- [ ] Backdrop (semi-transparent)
- [ ] Accessible: focus trap, escape to close

### Criteria 1.3: Responsive Design

#### Breakpoints
- [ ] Mobile: 320px-767px
- [ ] Tablet: 768px-1023px
- [ ] Desktop: 1024px+
- [ ] Breakpoint variables defined in CSS
- [ ] All components tested at each breakpoint

#### Layouts
- [ ] Mobile-first approach
- [ ] Single column on mobile
- [ ] 2 columns on tablet where appropriate
- [ ] 3+ columns on desktop
- [ ] No horizontal scrolling on mobile (≤ 320px width)

#### Fluid Typography
- [ ] Font sizes scale between breakpoints
- [ ] Readability maintained on all sizes
- [ ] Line length optimal (40-75 characters)

#### Touch Targets
- [ ] All interactive elements: 44x44px minimum
- [ ] Spacing between touch targets: 8px minimum
- [ ] Mobile: tested on actual device

#### Container Queries
- [ ] Container queries used where supported
- [ ] Fallback to media queries
- [ ] Component-specific responsive behavior

### Criteria 1.4: Accessibility

#### Color Contrast
- [ ] All text vs. background: 4.5:1 (normal text)
- [ ] Large text (18px+ or 14px bold): 3:1
- [ ] Verified with WAVE or Axe auditor
- [ ] No contrast issues reported

#### Focus Indicators
- [ ] All interactive elements have visible focus ring
- [ ] Focus ring not removed (no `outline: none`)
- [ ] Focus order logical (top-to-bottom, left-to-right)
- [ ] Focus visible on keyboard navigation

#### Semantic HTML
- [ ] Proper heading hierarchy (h1 > h2 > h3, no skips)
- [ ] Meaningful link text (not "click here")
- [ ] Form labels associated with inputs (`<label for>`)
- [ ] Landmark roles used correctly
- [ ] List semantics for grouped items

#### ARIA
- [ ] Buttons labeled correctly
- [ ] Form fields have `aria-label` or associated label
- [ ] Live regions for dynamic content (`aria-live`)
- [ ] Hidden elements use `aria-hidden="true"`
- [ ] Custom components have proper roles

#### Motion
- [ ] Animations respect `@prefers-reduced-motion`
- [ ] No auto-playing videos or animations
- [ ] Animations have pause controls (if needed)

#### Skip Links
- [ ] Skip-to-content link on every page
- [ ] Hidden by default (visible on focus)
- [ ] Keyboard accessible

### Criteria 1.5: Documentation

#### Design System Guide
- [ ] File: `/docs/DESIGN_SYSTEM.md` exists
- [ ] Token definitions with hex values
- [ ] Color palette with visual swatches
- [ ] Typography scale with examples
- [ ] Spacing scale with visual reference
- [ ] Component gallery with code examples
- [ ] Usage guidelines and do's/don'ts
- [ ] Breakpoints documented

#### CSS Organization
- [ ] File structure: tokens → base → components → utilities
- [ ] Each file has header comment explaining purpose
- [ ] Variables used consistently (no magic numbers)
- [ ] Comments on complex selectors
- [ ] File sizes reasonable (< 50KB total gzipped)

#### Component Patterns
- [ ] Each component: class name, markup, CSS, variants
- [ ] Examples for common use cases
- [ ] Accessibility requirements listed
- [ ] Mobile considerations noted
- [ ] Code is copy-paste ready

---

## Bead 2: Food Search UI Component (meal-planner-rvz)

### Criteria 2.1: Autocomplete Functionality

#### Search Logic
- [ ] Search triggered after 2+ characters typed
- [ ] API endpoint: `GET /api/foods?q={query}` working
- [ ] Results returned: up to 50 items
- [ ] Results cached per query (avoid duplicate API calls)
- [ ] "Searching..." state shown during API call
- [ ] Error handling: graceful message if API fails

#### User Feedback
- [ ] Result count displayed (e.g., "Showing 47 of 500")
- [ ] Loading spinner/skeleton during fetch
- [ ] Empty state message if no results
- [ ] Clear visual distinction between searching/results states

### Criteria 2.2: Input Field Behavior

#### Field States
- [ ] Empty: placeholder visible ("Search 50,000+ USDA foods...")
- [ ] Typing: shows live result count or "Searching..."
- [ ] Results: dropdown appears with suggestions
- [ ] No results: message like "No foods match 'xyz'"
- [ ] Error: fallback message shown

#### Debounce Logic
- [ ] 300ms debounce between keystrokes
- [ ] Immediate clear when field is emptied
- [ ] Pending API requests cancelled on new input
- [ ] No duplicate API calls within 5-second window
- [ ] Network tab shows ≤ 1 request per 300ms

#### Clear Button
- [ ] 'X' icon visible inside input when text present
- [ ] Click clears input field
- [ ] Click clears results dropdown
- [ ] Accessible: proper ARIA label
- [ ] Mobile: large enough to tap (44x44px)

### Criteria 2.3: Dropdown Behavior

#### Positioning
- [ ] Dropdown appears below input (default)
- [ ] Auto-flips above if near viewport bottom
- [ ] On mobile: always below (no flip)
- [ ] Width matches input or slightly wider
- [ ] Max height: ~400px with scrolling
- [ ] No viewport overflow on any screen size

#### Result Items
- [ ] Food name displayed as primary text
- [ ] Food type/category as secondary text
- [ ] Hover state: background highlight
- [ ] Keyboard-selected (arrow keys): different color + focus ring
- [ ] Click selects item and navigates to `/foods/{id}`
- [ ] Loading skeletons shown during search

#### Dismiss Behavior
- [ ] Click outside dropdown closes it
- [ ] Escape key closes dropdown
- [ ] Selecting item closes dropdown and navigates
- [ ] Blur (tab away) closes dropdown
- [ ] Subsequent typing reopens dropdown

### Criteria 2.4: Accessibility

#### ARIA Attributes
- [ ] Input has `role="combobox"`
- [ ] Input has `aria-expanded="true|false"`
- [ ] Results container has `role="listbox"`
- [ ] Each result has `role="option"`
- [ ] Selected result has `aria-selected="true"`
- [ ] Result count in `aria-live="polite"` region

#### Keyboard Navigation
- [ ] Focus starts in input field
- [ ] Arrow Down: moves focus to first result
- [ ] Arrow Down/Up: navigates through results
- [ ] Arrow Up: returns to input if at first result
- [ ] Enter: selects highlighted result
- [ ] Escape: closes dropdown, focus stays in input
- [ ] Tab: closes dropdown, moves to next element
- [ ] Tab+Shift: closes dropdown, moves to previous element
- [ ] Full navigation without mouse possible

#### Screen Reader Testing
- [ ] NVDA announces input correctly
- [ ] JAWS announces dropdown opening
- [ ] Results list announced
- [ ] Selected result announced
- [ ] Result count updates announced

#### Label Association
- [ ] `<label>` element with `for` attribute
- [ ] Label properly associated with input
- [ ] Form context preserved

### Criteria 2.5: Mobile Optimization

#### Touch Targets
- [ ] Input height: ≥ 44px
- [ ] Result items: ≥ 48px height
- [ ] Clear button: ≥ 44x44px
- [ ] Spacing between targets: ≥ 8px

#### On-Screen Keyboard
- [ ] Input field stays visible when keyboard appears
- [ ] Dropdown scrollable without closing
- [ ] Viewport doesn't jump when keyboard appears
- [ ] Text cursor visible in input

#### Gesture Support
- [ ] Swipe down on results scrolls list (not page)
- [ ] Double-tap zooms (or disabled appropriately)
- [ ] Long-press shows optional context menu

#### Responsive Width
- [ ] Mobile (< 768px): full width with padding
- [ ] Tablet (768-1024px): 70-80% width
- [ ] Desktop (> 1024px): constrained width (400-500px)
- [ ] Layout remains usable at 320px

#### Testing on Real Devices
- [ ] Tested on iOS Safari (iPhone)
- [ ] Tested on Android Chrome
- [ ] No layout shift on keyboard appearance
- [ ] Performance acceptable on slower devices

---

## Bead 3: Nutrition Dashboard Redesign (meal-planner-uzr)

### Criteria 3.1: Calorie Summary Card

#### Visual Design
- [ ] Prominent display: "1,850 / 2,100 cal"
- [ ] Percentage: "88% of goal"
- [ ] Animated counter: 0 → current value (1s animation)
- [ ] Color-coded indicator: green (<100%), yellow (100-110%), red (>110%)
- [ ] Macro breakdown visible: P / F / C values
- [ ] Date displayed clearly

#### Information Density
- [ ] Remaining calories or overage shown
- [ ] Color coding on remaining/overage text
- [ ] All essential info visible without scrolling (on mobile)

#### Animation
- [ ] Counter animates on page load
- [ ] Smooth easing (ease-out)
- [ ] No performance impact (60fps)
- [ ] Respects `@prefers-reduced-motion`

#### Responsive
- [ ] Desktop: side-by-side layout works
- [ ] Tablet: stacked but readable
- [ ] Mobile: essential values visible, full width

### Criteria 3.2: Macro Progress Visualization

#### Macro Bars
- [ ] Three bars: Protein (blue), Fat (orange), Carbs (emerald)
- [ ] Each bar shows: label, current/target, percentage
- [ ] Bar fills to percentage of goal
- [ ] Overflow handling: bar caps at 100% (actual value shown as text)
- [ ] Smooth animation: 0.6s, ease-out
- [ ] Colors match design system

#### Micro-interactions
- [ ] Hover/tap bar segment: shows "X remaining" or "X over"
- [ ] Tooltip color-coded: green (under), amber (90-100%), red (over)
- [ ] Smooth tooltip appearance

#### Optional: Circular Progress
- [ ] SVG donut chart for calories (if implemented)
- [ ] Responsive sizing
- [ ] Legend with macro colors

#### Performance
- [ ] Animations smooth at 60fps
- [ ] No layout shift during animation
- [ ] No performance degradation on low-end devices

### Criteria 3.3: Daily Macro Entries List

#### Meal Log Display
- [ ] Meals grouped by type: Breakfast, Lunch, Dinner, Snacks
- [ ] Each meal shows: time, food name, portion, macros, calories
- [ ] Action buttons: Edit, Delete, Quick add
- [ ] Sections collapsible/expandable
- [ ] Add new meal inline or via modal

#### Quick Stats
- [ ] Meals remaining today
- [ ] Most logged category/food
- [ ] Consistency streak (days logged)
- [ ] All stats calculated correctly

#### Empty State
- [ ] Helpful message shown (not just blank)
- [ ] CTA button: "+ Log Meal"
- [ ] Button links to `/log`

#### Data Updates
- [ ] New meals appear instantly
- [ ] Edits reflected immediately
- [ ] Deletions remove item from list
- [ ] Totals recalculated instantly

### Criteria 3.4: Responsive Layout

#### Desktop (1024px+)
- [ ] Three-column layout works
- [ ] Column widths balanced
- [ ] No text wrapping issues
- [ ] Meal log below, full width

#### Tablet (768px+)
- [ ] Two-row layout with proper spacing
- [ ] Columns stack appropriately
- [ ] Touch targets remain ≥ 44px

#### Mobile (320-767px)
- [ ] Single column, stacked vertically
- [ ] Full width utilization
- [ ] No horizontal scroll needed
- [ ] Touch targets ≥ 44px

#### Layout Shifts
- [ ] No unexpected layout shift on any screen size
- [ ] Cumulative Layout Shift (CLS) ≤ 0.1
- [ ] Content reflow smooth on orientation change

### Criteria 3.5: Interactive Features

#### Date Navigation
- [ ] Previous/Next buttons functional
- [ ] Date input field (YYYY-MM-DD format)
- [ ] Calendar picker (optional, if implemented)
- [ ] "Today" quick button
- [ ] Date range: past 30 days available
- [ ] Navigation doesn't scroll page

#### Filtering/Sorting
- [ ] Filter by meal type works
- [ ] Sort by time works
- [ ] Sort by macro content works (if implemented)
- [ ] Filters apply without page reload
- [ ] Filter state persists during session

#### Quick Actions
- [ ] "+ Add Meal" button present, functional
- [ ] "+ Add Recipe" button present, functional
- [ ] Edit button on each meal
- [ ] Delete button with confirmation
- [ ] Action buttons mobile-friendly (44x44px)

#### Response Time
- [ ] All interactions respond within 100ms
- [ ] State updates reflected immediately
- [ ] No loading spinners needed (instant updates)

### Criteria 3.6: Accessibility & Performance

#### Accessibility
- [ ] Semantic HTML: proper heading hierarchy
- [ ] Landmark roles: `<main>`, `<nav>`, `<section>`
- [ ] Lists: proper `<ul>`/`<ol>` structure
- [ ] ARIA: `role="region"`, `aria-label` on macro cards
- [ ] Color not sole indicator: macros also use icons (✓, ⚠, ✗)
- [ ] Focus indicators visible throughout
- [ ] Button labels descriptive
- [ ] Form inputs labeled

#### Mobile Accessibility
- [ ] Touch targets: 44x44px minimum
- [ ] Spacing between targets: 8px minimum
- [ ] Text size: readable without zoom
- [ ] Tap to focus, tap again to activate (not tap-and-hold)

#### Performance (Lighthouse)
- [ ] Performance score: ≥ 90
- [ ] Largest Contentful Paint (LCP): ≤ 2.5s
- [ ] First Input Delay (FID): ≤ 100ms
- [ ] Cumulative Layout Shift (CLS): ≤ 0.1

#### Bundle Size
- [ ] CSS: < 50KB minified + gzipped
- [ ] JavaScript (if any): < 20KB minified + gzipped
- [ ] Total page size: < 150KB (with images)

#### Network Performance
- [ ] Initial load: < 500ms (with data)
- [ ] API response times: < 300ms
- [ ] No render-blocking resources
- [ ] Assets cached appropriately

### Criteria 3.7: Data Visualization (Charts)

#### Chart Rendering
- [ ] Bar chart: daily calories (7 days) renders
- [ ] Doughnut chart: macro distribution (P:F:C) renders
- [ ] Line chart: weekly trends (optional) renders
- [ ] No JavaScript charting library bloat
- [ ] Charts are SVG-based (crisp on all resolutions)

#### Chart Features
- [ ] Responsive: scales to container width
- [ ] Legend with color coding
- [ ] Tooltip with values (on hover, if not SSR)
- [ ] Data labels on chart elements
- [ ] No interactive features (simplified for SSR)

#### Chart Accessibility
- [ ] Data table alternative provided
- [ ] Table shows exact values
- [ ] Chart has `role="img"` and descriptive `aria-label`
- [ ] No essential data only in visual chart
- [ ] Colors distinguishable (not just red/green)

#### Chart Responsiveness
- [ ] Charts render at 320px width
- [ ] Charts render at 768px width
- [ ] Charts render at 1024px width
- [ ] No label overlap on small screens
- [ ] Legends stack/resize appropriately

---

## QA Sign-Off Checklist

### Bead 1: CSS Design System
- [ ] All 5 criteria sections completed
- [ ] Design system doc reviewed by designer
- [ ] WCAG AA audit passed
- [ ] Cross-browser tested (Chrome, Firefox, Safari, Edge)
- [ ] Mobile tested (iOS, Android)
- [ ] Ready for development team

### Bead 2: Food Search Component
- [ ] All 5 criteria sections completed
- [ ] Keyboard navigation tested by QA
- [ ] Accessibility audit passed
- [ ] API integration tested
- [ ] Mobile tested on real devices
- [ ] Ready for production

### Bead 3: Dashboard Redesign
- [ ] All 7 criteria sections completed
- [ ] Visual design reviewed by designer
- [ ] All charts rendering correctly
- [ ] Performance audit (Lighthouse) passed
- [ ] Mobile tested on real devices
- [ ] Accessibility audit passed
- [ ] Ready for production

---

**Checklist Version**: 1.0
**Last Updated**: 2025-12-03
**Use This To**: Track bead completion, QA testing, and sign-off
