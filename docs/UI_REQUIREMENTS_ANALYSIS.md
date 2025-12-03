# UI Requirements Analysis: Modern Redesign for Meal Planner

**Document Status**: Requirements Clarification
**Date**: 2025-12-03
**Target Beads**: meal-planner-gli, meal-planner-rvz, meal-planner-uzr

---

## Executive Summary

The meal-planner application currently features a **basic Lustre SSR web app** with minimal styling. This document defines acceptance criteria for three integrated design beads that will transform it into a **world-class designer-quality UI**. The redesign maintains the existing Gleam/Lustre stack while introducing a modern design system, enhanced food search, and data visualization capabilities.

---

## Current State Analysis

### ✅ Existing Architecture

**Stack:**
- Framework: Lustre (server-side rendered)
- Language: Gleam
- Styling: Plain CSS (minimal, utility-focused)
- Deployment: Wisp web server on port 8080
- Database: PostgreSQL with USDA FoodData Central

**Current CSS Characteristics:**
- ~750 lines of basic CSS
- Semantic HTML structure
- Responsive grid layout (mobile-first breakpoint at 768px)
- Limited color palette: Blues (#007bff), Grays, Greens (#28a745)
- Basic button and card components
- Progress bars for macro tracking
- No design tokens or variable system
- Hardcoded values throughout

**Existing Pages (All SSR):**
1. Home page - Navigation cards with emoji icons
2. Dashboard - Calorie summary + macro progress bars
3. Profile - Stats and daily targets (definition list)
4. Recipes - Grid layout with recipe cards
5. Recipe detail - Macros, ingredients, instructions
6. Food Search - Form with results list
7. Food detail - Nutrition table
8. 404 page

**Styling Gaps:**
- No consistent spacing system
- No typography scale
- No shadows/elevation system
- Minimal accessibility considerations
- No dark mode support
- No animation/transition framework
- Hardcoded colors throughout
- Limited mobile optimization
- No component library structure

---

## Bead 1: CSS Design System (meal-planner-gli)

### Purpose
Establish a cohesive, scalable design system using CSS custom properties and modern CSS features. This serves as the foundation for all UI components.

### Acceptance Criteria

#### 1.1 Design Tokens System
- **Color Palette**
  - Primary: Modern blue spectrum (light: #5B9FD8, base: #007BFF, dark: #004ECB)
  - Accent: Emerald green (light: #6CC24A, base: #28a745, dark: #1E7E34)
  - Neutral: Gray scale (50, 100, 200, 300, 400, 500, 600, 700, 800, 900)
  - Status colors: Success (#10B981), Warning (#F59E0B), Error (#EF4444)
  - Semantic colors: Info (#3B82F6), Disabled (#D1D5DB)
- **Typography Scale**
  - Base font: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif
  - Sizes: 12px, 14px, 16px, 18px, 20px, 24px, 28px, 32px, 36px, 40px
  - Font weights: 400 (normal), 500 (medium), 600 (semibold), 700 (bold)
  - Line heights: 1.2, 1.4, 1.5, 1.6
- **Spacing Scale** (8px base unit)
  - xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 20px, 2xl: 24px, 3xl: 32px, 4xl: 40px
- **Border Radius**
  - sm: 4px, md: 8px, lg: 12px, xl: 16px, full: 9999px
- **Shadows** (elevation system)
  - sm: 0 1px 2px rgba(0,0,0,0.05)
  - md: 0 4px 6px rgba(0,0,0,0.07)
  - lg: 0 10px 15px rgba(0,0,0,0.1)
  - xl: 0 20px 25px rgba(0,0,0,0.15)
- **Z-index Scale**: 0, 10, 20, 30, 40, 50 (modals, dropdowns, tooltips)

**Measurement**: CSS file includes `:root` with 50+ CSS custom properties, all referenced by components (0 hardcoded values in component CSS)

#### 1.2 Component Library (Base Components)
- **Buttons**: Variants (primary, secondary, danger, ghost), sizes (sm, md, lg), states (hover, active, disabled, loading)
- **Cards**: Default, elevated, interactive, with header/body/footer slots
- **Forms**: Input, textarea, select, checkbox, radio (with labels, validation states)
- **Badges**: Status badges, category badges with color variants
- **Progress Bars**: Macro progress with striped variant, circular progress indicator
- **Tables**: Responsive tables with zebra striping, sortable headers
- **Navigation**: Breadcrumbs, tab navigation, pagination
- **Alerts**: Success, warning, error, info with icon/close button
- **Modals**: Standard modal with header/body/footer

**Measurement**: Each component has documented CSS class names, responsive variants, and interactive states documented in design-system.css

#### 1.3 Responsive Design System
- **Breakpoints**: Mobile 320px-767px, tablet 768px-1023px, desktop 1024px+
- **Container Queries**: CSS container layout support (if available) or fallback to media queries
- **Fluid Typography**: Responsive font sizes between breakpoints
- **Mobile-First Grid**: Base single column, 2-column at tablet, 3-4 columns at desktop
- **Touch-Friendly**: Minimum 44x44px tap targets on mobile

**Measurement**: All breakpoints tested on real devices; CSS uses `@media` queries with documented breakpoint variables

#### 1.4 Accessibility Features
- **Color Contrast**: All text meets WCAG AA standard (4.5:1 for normal text, 3:1 for large text)
- **Focus Indicators**: Clear, high-contrast focus rings (not removed)
- **Semantic HTML**: Proper heading hierarchy, ARIA labels where needed
- **Motion**: Reduced motion support via `@prefers-reduced-motion`
- **Skip Links**: Hidden skip-to-content link available to keyboard users

**Measurement**: WAVE or Axe accessibility audit passes with 0 critical/serious errors

#### 1.5 Documentation
- **Design system guide** (Markdown): Token definitions, color palette, typography, spacing, component gallery
- **CSS organization**: Structured as: tokens.css → base.css → components.css → utilities.css
- **Component patterns**: Code examples for all base components with class naming conventions

**Measurement**: /docs/DESIGN_SYSTEM.md with complete reference and examples

---

## Bead 2: Food Search UI Component (meal-planner-rvz)

### Purpose
Transform the basic food search from form + list into a modern, interactive autocomplete component with rich interactions and keyboard navigation.

### Acceptance Criteria

#### 2.1 Search Component Features
- **Autocomplete Functionality**
  - Real-time search triggered after 2+ characters
  - API endpoint: `GET /api/foods?q={query}` returns up to 50 results
  - Results cached per query to minimize API calls
  - Clear visual indication when searching (loading state)
- **Result Display**
  - Food name as primary text
  - Food type/category as secondary text
  - Calorie/macro summary on hover (from API preview)
  - Result count display (e.g., "Showing 47 of 500 results")
- **User Interactions**
  - Click to select food item
  - Arrow keys (↑/↓) to navigate results
  - Enter to select highlighted result
  - Escape to close dropdown
  - Focus returns to input after selection

**Measurement**: E2E test suite covers all keyboard interactions; no mouse-only functionality

#### 2.2 Input Field Behavior
- **Field States**
  - Empty (placeholder: "Search 50,000+ USDA foods...")
  - Typing (shows live result count)
  - Searching (spinner/skeleton state)
  - Results (shows dropdown)
  - No results (helpful message: "No foods match 'xyz'")
  - Error (if API fails, fallback message)
- **Debounce Logic**
  - 300ms debounce between keystrokes
  - Immediate clearance when field is empty
  - Cancel pending requests on new input
- **Clear Button**
  - 'X' icon inside input field
  - Clears results and input
  - Only visible when input has text

**Measurement**: Network monitor shows no duplicate API calls for same query within 5s window

#### 2.3 Dropdown Behavior
- **Positioning**
  - Dropdown appears below input
  - Auto-flips above if near viewport bottom (mobile: always below)
  - Matches input width or slightly wider
  - Max height with scroll (recommended: 400px)
- **Result Items**
  - Hover state: background highlight
  - Active/keyboard-selected: different color + focus ring
  - Click to select, navigate to `/foods/{id}`
  - Loading skeletons during search (placeholder bars)
- **Dismiss Behavior**
  - Click outside closes dropdown
  - Escape key closes dropdown
  - Selecting item closes dropdown and navigates
  - Blur (tab away) closes dropdown

**Measurement**: Dropdown positioning tested on viewports 320px-1920px; no overflow

#### 2.4 Accessibility Requirements
- **ARIA Attributes**
  - `role="combobox"` on input
  - `aria-expanded="true|false"` on input
  - `role="listbox"` on results container
  - `role="option"` on each result item
  - `aria-selected="true"` on highlighted option
  - `aria-live="polite"` region for result count announcements
- **Keyboard Access**
  - Full navigation without mouse
  - Tab order follows DOM
  - Focus visible at all times
  - Result list announced by screen readers
- **Label Association**
  - `<label>` with `for` attribute linked to input
  - Form context preserved

**Measurement**: WCAG 2.1 AA accessibility audit; tested with NVDA/JAWS

#### 2.5 Mobile Optimization
- **Touch Targets**: Minimum 44x44px (input height: 44px, result items: 48px)
- **On-Screen Keyboard**: Input field stays visible, dropdown scrollable without closing
- **Gesture Support**: Swipe down on results scrolls list (not page)
- **Responsive Width**: Full width on mobile (padding from viewport), constrained on desktop

**Measurement**: Tested on actual iOS (Safari) and Android (Chrome); no layout shift on keyboard appearance

---

## Bead 3: Nutrition Dashboard Redesign (meal-planner-uzr)

### Purpose
Modernize the dashboard from basic progress bars into a rich, data-driven visualization component with charts, animated indicators, and responsive layouts.

### Acceptance Criteria

#### 3.1 Calorie Summary Card
- **Visual Design**
  - Large, prominent display: "1,850 / 2,100 cal"
  - Percentage indicator: "88% of goal" with color coding (green <100%, yellow 100-110%, red >110%)
  - Animated counter: Numbers animate from 0 to current value on page load (1s animation)
  - Date selector: Toggle between dates (prev/next day buttons or date picker)
- **Information Density**
  - Macro breakdown below: P: 120g / 150g | F: 65g / 70g | C: 180g / 200g
  - Quick stats: "Remaining: 250 cal" or "Over by 50 cal" (color-coded)
- **Responsive Behavior**
  - Desktop (1024px+): Card layout with side-by-side display
  - Tablet (768px+): Stacked but readable
  - Mobile: Simplified to essential values, full width

**Measurement**: Visual design passes designer review; animations smooth at 60fps

#### 3.2 Macro Progress Visualization
- **Macro Bars Component**
  - Three horizontal bars (Protein, Fat, Carbs) with color coding
  - Each bar shows: label, current/target, and filled percentage
  - Color scheme: Protein (blue #5B9FD8), Fat (orange #F59E0B), Carbs (emerald #28a745)
  - Overflow handling: Bar caps at 100% but shows actual value (e.g., "125g / 100g" in red)
  - Smooth animation: Bar fills on load (0.6s duration, ease-out)
- **Circular Progress (Optional Enhancement)**
  - Alternative view: SVG circular indicator for calorie goal
  - Donut chart showing macro breakdown
  - Interactive: Hover/tap to show macro details
- **Tooltips**
  - Hover over bar segment: shows "X remaining" or "X over"
  - Color-coded: Green (under), amber (90-100%), red (over)

**Measurement**: Animations tested in DevTools Performance tab; no jank >16ms frames

#### 3.3 Daily Macro Entries List (New Section)
- **Meal Log Display**
  - Timeline of meals logged: Breakfast, Lunch, Dinner, Snacks
  - Each entry shows: Meal time, food name, portion, macros, calories
  - Action buttons: Edit, Delete, Quick add
  - Collapsible sections (expand/collapse by meal type)
- **Quick Stats**
  - Meals remaining today
  - Most logged category/food
  - Consistency streak (days logged in a row)
- **Empty State**
  - Helpful message: "No meals logged yet. Add your first meal to get started."
  - CTA button: "+ Log Meal"

**Measurement**: All data loads within 500ms; meal add/edit operations update UI instantly

#### 3.4 Responsive Layout
- **Desktop (1024px+)**
  - Three-column layout: Calorie summary (left) | Macro bars (center) | Quick stats (right)
  - Meal log below, full width
- **Tablet (768px+)**
  - Two-row layout: Calorie summary + quick stats (top) | Macro bars (bottom)
  - Meal log full width
- **Mobile (320-767px)**
  - Single column, stacked vertically
  - Macro bars horizontally scrollable (if needed)
  - Meal log as collapsed sections

**Measurement**: Layout tested on actual devices in responsive mode; no horizontal scroll on mobile

#### 3.5 Interactive Features
- **Date Navigation**
  - Previous/Next buttons to switch between days
  - Date input field (calendar picker or text input YYYY-MM-DD)
  - "Today" quick button
  - Date range: Past 30 days available
- **Filtering/Sorting**
  - Sort meals by time or macro content
  - Filter by meal type (Breakfast, Lunch, Dinner, Snacks)
- **Quick Actions**
  - "+ Add Meal" button (navigates to /log)
  - "+ Add Recipe" button (navigates to /recipes)
  - Edit/Delete on each meal entry (inline or modal)

**Measurement**: All interactions respond within 100ms; state updates reflected immediately

#### 3.6 Accessibility & Performance
- **Accessibility**
  - Semantic HTML: Headings, landmarks, lists
  - ARIA: `role="region"`, `aria-label` for macro cards
  - Color not sole indicator: Macro status also uses icon (✓, ⚠, ✗)
  - Focus indicators: Clear, visible throughout
  - Mobile: Touch-friendly buttons (44x44px minimum)
- **Performance**
  - Initial load: < 500ms (with data)
  - Interactive: < 100ms response time
  - Animations: Smooth at 60fps (use CSS transforms, not layout-triggering properties)
  - Bundle size: Design system + components < 100KB minified + gzipped

**Measurement**: Lighthouse score ≥ 90 for Performance; WebPageTest < 1s interactive

#### 3.7 Data Visualization (Charts)
- **Chart Library**: Consider Gleam-compatible charting (SVG-based, no JavaScript library)
  - Alternative: Custom SVG charts using Lustre elements
- **Chart Types Needed**
  - Bar chart: Daily calories past 7 days
  - Doughnut/pie: Macro distribution (P:F:C ratio)
  - Line chart: Weekly macro trends (optional)
- **Chart Features**
  - Responsive sizing (scale to container)
  - No interactive tooltips (to keep it simple for SSR)
  - Legend with color coding
  - Accessible data table alternative

**Measurement**: Charts render correctly on all screen sizes; accessible fallback text provided

---

## Technical Constraints & Assumptions

### Browser Support
- **Target**: Modern browsers (last 2 versions)
  - Chrome 120+
  - Firefox 121+
  - Safari 17+
  - Edge 120+
- **Mobile**: iOS Safari 14+, Chrome Android 120+
- **Graceful Degradation**: No CSS Grid fallback needed; CSS Flexbox as baseline
- **JavaScript**: Minimal JS (Lustre SSR handles most); vanilla JS for search debounce only

### Accessibility Standards
- **WCAG 2.1 Level AA** compliance (AAA where feasible)
- **ARIA Implementation**: Best practices for screen readers
- **Color Contrast**: All text ≥ 4.5:1 (normal), ≥ 3:1 (large)
- **Testing**: Manual testing with keyboard + screen reader (NVDA/JAWS)

### Mobile-First Approach
- **Design Assumption**: Designed for 320px-width first, enhanced for larger screens
- **Touch-Friendly**: 44x44px minimum tap targets
- **Viewport Optimization**: `<meta name="viewport" content="width=device-width, initial-scale=1">`
- **Image Optimization**: Responsive images with `srcset` (if needed)

### Performance Targets
- **CSS Bundle**: < 50KB minified + gzipped
- **Page Load**: < 1s to interactive
- **API Response**: < 300ms for food search queries
- **Animations**: 60fps, 16ms frame budget
- **Network**: Works with 4G LTE connections

### Design Principles
1. **Clarity**: Information hierarchy is clear; no visual noise
2. **Consistency**: All components follow the design system
3. **Feedback**: All interactions provide visual/audio feedback
4. **Efficiency**: Common tasks completed in ≤ 3 clicks
5. **Delightful**: Smooth animations, micro-interactions, playful copy

---

## Questions for Human Clarification

### Design Direction
1. **Dark Mode**: Should the design system include dark mode support? (Estimated effort: +40% CSS)
2. **Color Palette**: Are the suggested colors acceptable, or should we review brand guidelines?
3. **Typography**: Any preference on serif vs. sans-serif for headings?

### Feature Scope
4. **Food Search**: Should "favorites" or "recent foods" be displayed in dropdown? (Not in current spec)
5. **Dashboard Charts**: Which chart type is most important (bar, line, pie)?
6. **Meal Logging**: Should meals be editable inline or via modal form?

### Data/API Constraints
7. **Food Database**: Are the API response times predictable? (Assumed < 300ms)
8. **Daily Log**: What's the max number of meals logged per day? (Affects performance)
9. **Nutrition Values**: Should we display all nutrients or just macros + calories?

### Mobile Strategy
10. **App Shell**: Should we implement a native mobile wrapper (PWA or React Native)?
11. **Offline Support**: Should the dashboard work with cached data when offline?

### Testing & QA
12. **Browser Coverage**: Are specific browsers required beyond "modern browsers"?
13. **Accessibility Testing**: Who will conduct final accessibility audit (in-house or third-party)?

### Rollout Plan
14. **Phased Rollout**: Should beads be deployed separately or together?
15. **Backward Compatibility**: Are there existing UI customizations to preserve?

---

## File Organization

### Proposed Directory Structure
```
gleam/priv/static/
├── styles/
│   ├── design-system.css       (Tokens + base components)
│   ├── components.css          (Reusable UI components)
│   ├── utilities.css           (Helper classes)
│   ├── responsive.css          (Mobile/tablet/desktop breakpoints)
│   └── animations.css          (Transitions, keyframes)
├── styles.css                  (Main entry point - imports all above)
└── assets/
    ├── icons/                  (SVG icons)
    └── fonts/                  (Web fonts if custom)

docs/
├── DESIGN_SYSTEM.md            (Design tokens, component gallery)
├── UI_REQUIREMENTS_ANALYSIS.md (This file)
└── ACCESSIBILITY.md            (ARIA patterns, testing guidelines)
```

---

## Success Metrics

### Bead 1: CSS Design System
- ✅ 50+ CSS custom properties defined
- ✅ 0 hardcoded color/spacing values in component CSS
- ✅ All components have documented variants
- ✅ WCAG AA contrast passed
- ✅ Responsive design tested on 3+ screen sizes

### Bead 2: Food Search
- ✅ Autocomplete working with keyboard + mouse
- ✅ Debounce prevents API spam (< 1 call per 300ms)
- ✅ WCAG AA accessibility audit passed
- ✅ Mobile-optimized (tested on device)
- ✅ Keyboard navigation fully functional

### Bead 3: Dashboard Redesign
- ✅ Calorie card with animated counters
- ✅ Macro progress bars with animations
- ✅ Responsive layout for mobile/tablet/desktop
- ✅ Charts rendering correctly
- ✅ Lighthouse score ≥ 90 for Performance

---

## Next Steps

1. **Human Review**: Clarify the 15 questions above
2. **Design Approval**: Validate color palette, typography, layout mockups
3. **Bead Assignment**: Assign each bead to development team
4. **Implementation**: Start with Bead 1 (design system) as dependency for others
5. **Integration**: Ensure all beads work together seamlessly
6. **Testing**: Full QA cycle (functional, accessibility, performance)
7. **Launch**: Phased rollout with monitoring

---

## Appendix: Current CSS Inventory

**Analyzed from `/gleam/priv/static/styles.css`:**
- Total rules: ~150
- Color values used: 6 (hardcoded hex colors)
- Component classes: 40+
- Responsive breakpoints: 1 (768px)
- Z-index usage: Limited
- No CSS variables (custom properties)
- No animation framework

**Recommendation**: Complete rewrite using design system approach; preserve responsive grid foundation.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Status**: Awaiting Clarification
