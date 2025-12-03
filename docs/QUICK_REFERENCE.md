# UI Redesign: Quick Reference Guide

**Print this page or bookmark it for quick lookups during development.**

---

## The Three Beads at a Glance

| Bead | Name | Purpose | Effort | Key Files |
|------|------|---------|--------|-----------|
| **gli** | CSS Design System | Foundation (tokens, components) | 60-80h | tokens.css, components.css |
| **rvz** | Food Search | Autocomplete with keyboard nav | 30-40h | search.css, search logic |
| **uzr** | Dashboard | Animated charts & progress | 80-100h | dashboard.css, charts.css |

---

## Design System Color Tokens

```css
/* Primary Colors */
--color-primary-light: #5B9FD8
--color-primary: #007BFF
--color-primary-dark: #004ECB

/* Accent Colors */
--color-accent-light: #6CC24A
--color-accent: #28a745
--color-accent-dark: #1E7E34

/* Semantic Colors */
--color-success: #10B981
--color-warning: #F59E0B
--color-error: #EF4444
--color-info: #3B82F6

/* Neutral */
--color-gray-50 through 900 (10 shades)

/* Background & Text */
--color-bg-primary: white
--color-text-primary: #333
--color-text-secondary: #666
--color-text-disabled: #999
```

---

## Spacing Scale (8px base)

```
--spacing-xs: 4px
--spacing-sm: 8px
--spacing-md: 12px
--spacing-lg: 16px
--spacing-xl: 20px
--spacing-2xl: 24px
--spacing-3xl: 32px
--spacing-4xl: 40px
```

---

## Typography Scale

| Size | Px | Use Case |
|------|----|----|
| xs | 12px | Captions, small labels |
| sm | 14px | Body text, labels |
| base | 16px | Main body text |
| lg | 18px | Large body, section intro |
| xl | 20px | Subheadings |
| 2xl | 24px | Page titles |
| 3xl | 28px | Hero titles |
| 4xl | 32px | Main headings |
| 5xl | 36px | Large hero |
| 6xl | 40px | Extra large hero |

**Font Weights**: 400 (normal), 500 (medium), 600 (semibold), 700 (bold)

---

## Responsive Breakpoints

```
Mobile:   320px - 767px  (single column, stacked)
Tablet:   768px - 1023px (2 columns, flexible)
Desktop:  1024px+        (3+ columns, full layout)
```

---

## Component Variants

### Button
```
Sizes:    sm (32px) | md (40px) | lg (48px)
Variants: primary | secondary | danger | ghost
States:   default | hover | active | disabled | loading
```

### Card
```
Types:    default | elevated | interactive
Slots:    header | body | footer
```

### Progress Bar
```
Variants: standard | striped | animated
Colors:   primary | success | warning | error
```

### Badge
```
Types:    status | category
Colors:   success | warning | error | info | default
```

---

## Bead 1: Design System - Critical Path

### Must Have (MVP)
- [ ] 50+ CSS custom properties defined
- [ ] 6 button variants × 3 sizes = 18 combinations
- [ ] Card component (default + elevated)
- [ ] Form inputs (text, select, checkbox, radio)
- [ ] Progress bar component
- [ ] 3 responsive breakpoints working

### Nice to Have
- [ ] Modal component
- [ ] Table component
- [ ] Alert component
- [ ] Tooltip component
- [ ] Breadcrumb component

### Accessibility Checklist
- [ ] Color contrast ≥ 4.5:1 (AA standard)
- [ ] Focus indicators visible (not removed)
- [ ] Keyboard-only navigation works
- [ ] ARIA labels where needed
- [ ] Semantic HTML (proper heading hierarchy)

---

## Bead 2: Food Search - Critical Path

### Must Have (MVP)
- [ ] Input field with placeholder
- [ ] API call on 2+ characters
- [ ] Debounce 300ms (prevent spam)
- [ ] Dropdown with results list
- [ ] Click to select → navigate to `/foods/{id}`
- [ ] Keyboard navigation (arrow keys, enter, escape)
- [ ] Mobile responsive (44x44px targets)

### Nice to Have
- [ ] Result caching
- [ ] Loading skeleton states
- [ ] Clear (X) button in input
- [ ] Favorites/recent foods
- [ ] Result count display

### Accessibility Checklist
- [ ] `role="combobox"` on input
- [ ] `aria-expanded` on input
- [ ] `role="listbox"` on dropdown
- [ ] `role="option"` on items
- [ ] Screen reader announces result count
- [ ] Full keyboard navigation without mouse

---

## Bead 3: Dashboard - Critical Path

### Must Have (MVP)
- [ ] Calorie summary display: "1,850 / 2,100 cal"
- [ ] Animated counter (0 → current value)
- [ ] Three macro progress bars (P, F, C)
- [ ] Bar animations (smooth fill)
- [ ] Date selector (prev/next buttons)
- [ ] Meal log list (Breakfast, Lunch, Dinner, Snacks)
- [ ] Responsive layout (3 cols → 1 col)

### Nice to Have
- [ ] Charts (bar: 7-day calories, doughnut: macros)
- [ ] Quick stats (streak, meals remaining)
- [ ] Color-coded overflow handling
- [ ] Tooltips on hover
- [ ] Edit/delete meal inline

### Accessibility Checklist
- [ ] Semantic HTML (heading hierarchy)
- [ ] ARIA: `role="region"`, `aria-label`
- [ ] Color not sole indicator (use icons too)
- [ ] Keyboard navigable buttons
- [ ] Focus indicators visible

### Performance Checklist
- [ ] Initial load < 500ms
- [ ] Animations smooth at 60fps
- [ ] No layout shift (CLS ≤ 0.1)
- [ ] Lighthouse Performance ≥ 90
- [ ] CSS bundle < 50KB (gzipped)

---

## Common Class Naming Convention

```css
/* Component base */
.button
.button--primary    /* Variant: BEM modifier */
.button--md         /* Size: BEM modifier */
.button:hover       /* State: pseudo-class */
.button:disabled    /* State: pseudo-class */
.button:focus       /* Accessibility: pseudo-class */

/* Responsive utilities */
@media (min-width: 768px) {
  .button--md { /* tablet styles */ }
}

@media (min-width: 1024px) {
  .button--md { /* desktop styles */ }
}
```

---

## Testing Checklist (Per Bead)

### Visual Testing
- [ ] On desktop (1024px)
- [ ] On tablet (768px)
- [ ] On mobile (320px)
- [ ] In light theme
- [ ] At 200% zoom (accessibility)

### Interaction Testing
- [ ] Mouse clicks work
- [ ] Keyboard (Tab, Enter, Arrow keys) works
- [ ] Touch taps work (mobile)
- [ ] Long press/hold works (if needed)
- [ ] Escape key closes dropdowns

### Accessibility Testing
- [ ] Tab order logical (top→bottom, left→right)
- [ ] Focus visible at all times
- [ ] Screen reader (NVDA/JAWS) announces text
- [ ] No keyboard trap
- [ ] Color contrast checked (WAVE/Axe)

### Performance Testing
- [ ] Lighthouse Performance ≥ 90
- [ ] Network tab: < 300ms API response
- [ ] DevTools: animations 60fps (no 16ms+ frames)
- [ ] Mobile: tested on actual slow device

---

## Accessibility Shortcuts

### ARIA Template (Search)
```html
<input
  role="combobox"
  aria-expanded="false"
  aria-autocomplete="list"
  aria-controls="search-results"
/>
<div role="listbox" id="search-results">
  <div role="option" aria-selected="false">
    Item 1
  </div>
</div>
```

### ARIA Template (Dashboard Region)
```html
<section aria-label="Calorie Summary">
  <h2>Calories Today</h2>
  <div role="region" aria-live="polite">
    1,850 / 2,100 cal
  </div>
</section>
```

### Focus Visible (Don't Remove!)
```css
:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

:focus:not(:focus-visible) {
  outline: none; /* Remove outline for mouse users only */
}
```

### Color Contrast Formula
```
Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)

Where L = (0.299 × R + 0.587 × G + 0.114 × B) / 255

Result: ≥ 4.5:1 for AA (normal text)
        ≥ 3:1 for AA (large text or UI)
```

---

## Common Gotchas

❌ **Don't**: Hardcode colors
✅ **Do**: Use CSS variables (`var(--color-primary)`)

❌ **Don't**: Remove focus indicators
✅ **Do**: Style them nicely (2px outline, 2px offset)

❌ **Don't**: Use layout properties for animations
✅ **Do**: Use `transform` and `opacity` (60fps safe)

❌ **Don't**: Make touch targets < 44x44px
✅ **Do**: Include padding around interactive elements

❌ **Don't**: Rely on color alone for status
✅ **Do**: Use icons/text + color (green ✓, red ✗)

❌ **Don't**: Forget `role` and `aria-` attributes
✅ **Do**: Add semantic ARIA for custom components

❌ **Don't**: Test only desktop/modern browsers
✅ **Do**: Test mobile (iOS Safari, Android Chrome)

---

## Quick Git Workflow

```bash
# Create feature branch per bead
git checkout -b feature/bead-gli-design-system

# Make changes in gleam/priv/static/styles/
# Commit frequently
git commit -m "feat: add color palette tokens"
git commit -m "feat: add button component variants"

# Push and create PR
git push origin feature/bead-gli-design-system

# After review, merge to main
git merge --squash feature/bead-gli-design-system
git commit -m "feat: complete CSS design system (Bead 1)"
```

---

## File Structure Reference

```
gleam/priv/static/
├── styles/
│   ├── tokens.css         (Colors, spacing, typography)
│   ├── base.css           (Reset, defaults, body)
│   ├── components.css     (Buttons, cards, forms, etc.)
│   ├── utilities.css      (Helpers, margins, alignment)
│   └── animations.css     (Keyframes, transitions)
├── styles.css             (Main imports all above)
└── assets/
    ├── icons/             (SVG files)
    └── fonts/             (Web fonts)

docs/
├── UI_REQUIREMENTS_ANALYSIS.md    (Full spec)
├── ACCEPTANCE_CRITERIA_CHECKLIST.md (QA ref)
├── UI_REDESIGN_SUMMARY.md         (Overview)
└── QUICK_REFERENCE.md             (This file)
```

---

## Key Contacts & Resources

**Requirements**: See `/docs/UI_REQUIREMENTS_ANALYSIS.md` (15 clarification questions)
**QA Checklist**: See `/docs/ACCEPTANCE_CRITERIA_CHECKLIST.md`
**Executive Summary**: See `/docs/UI_REDESIGN_SUMMARY.md`

**Tools**:
- Accessibility: WAVE browser extension, Axe DevTools
- Performance: Lighthouse (Chrome DevTools)
- Responsive Design: Chrome DevTools device emulation
- Screen Reader: NVDA (Windows), JAWS (Windows), VoiceOver (Mac/iOS)

---

## Success Criteria (TL;DR)

| Criterion | Target | How to Verify |
|-----------|--------|---|
| Design System Complete | 50+ tokens, 12+ components | CSS file, DESIGN_SYSTEM.md |
| Accessibility | WCAG AA | WAVE audit, manual NVDA test |
| Mobile | 44x44px targets, 320px width | Real device test, DevTools |
| Performance | Lighthouse ≥90, <60fps jank | Lighthouse, DevTools |
| Responsive | 320px, 768px, 1024px | DevTools media queries |
| Keyboard Nav | Full functionality without mouse | Tab through, test arrow keys |

---

**Last Updated**: 2025-12-03
**Version**: 1.0
**Status**: Ready for Development
