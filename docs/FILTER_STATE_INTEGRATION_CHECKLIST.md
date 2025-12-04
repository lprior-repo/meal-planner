# Filter State Manager - Integration Checklist

Quick reference for integrating the filter state persistence system into your Meal Planner application.

## Pre-Integration

- [ ] Review `FILTER_STATE_MANAGER_README.md` for overview
- [ ] Review `FILTER_IMPLEMENTATION_EXAMPLE.html` in browser for detailed guide
- [ ] Understand the 5-minute quick start below
- [ ] Review your current dashboard HTML structure

## Quick Start (5 Minutes)

### 1. Add CSS to HTML Head
```html
<link rel="stylesheet" href="/static/css/filter-state.css">
```

### 2. Add Scripts Before Closing Body Tag
```html
<!-- Core state manager -->
<script src="/static/js/filter-state-manager.js"></script>

<!-- Existing filter system (if you have it) -->
<script src="/static/js/dashboard-filters.js"></script>

<!-- Integration layer -->
<script src="/static/js/filter-integration.js"></script>
```

### 3. Verify HTML Structure

Ensure your filter section has this structure:

```html
<div class="meal-filters" role="group" aria-label="Filter meals by type">
  <div class="filter-buttons">
    <button class="filter-btn active"
            data-filter-meal-type="all"
            aria-pressed="true">All</button>
    <button class="filter-btn"
            data-filter-meal-type="breakfast"
            aria-pressed="false">Breakfast</button>
    <button class="filter-btn"
            data-filter-meal-type="lunch"
            aria-pressed="false">Lunch</button>
    <button class="filter-btn"
            data-filter-meal-type="dinner"
            aria-pressed="false">Dinner</button>
    <button class="filter-btn"
            data-filter-meal-type="snack"
            aria-pressed="false">Snack</button>
  </div>

  <div id="filter-results-summary"
       class="filter-summary"
       aria-live="polite"></div>

  <div id="filter-announcement"
       class="sr-only"
       role="status"
       aria-live="assertive"
       aria-atomic="true"></div>
</div>
```

### 4. Update Your Meal List Handler

Connect filter changes to your API or display:

```javascript
window.FilterStateManager.onStateChange((event) => {
  // Update meal display based on new filters
  const { state } = event;

  // Option A: Call API
  fetch('/api/meals', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(state)
  })
    .then(response => response.json())
    .then(meals => updateMealDisplay(meals));

  // Option B: Client-side filtering (if data already loaded)
  filterMealsLocally(state);
});
```

### 5. Done!

The system auto-initializes. Test by:
- [ ] Clicking filter buttons
- [ ] Checking URL changes
- [ ] Reloading page - filters should persist
- [ ] Using browser back button
- [ ] Pressing Ctrl+Z to undo

## Integration Points

### A. Gleam Template Updates

If using Gleam templates, ensure:

- [ ] Dashboard page includes filter controls via `render_filter_controls()`
- [ ] Scripts included at bottom of page
- [ ] CSS stylesheet included in head
- [ ] Your meal entry layout has proper `data-` attributes

### B. JavaScript Integration

If you have existing filter code:

- [ ] Remove duplicate storage logic (if any)
- [ ] Keep `dashboard-filters.js` for UI updates (if present)
- [ ] Use FilterStateManager for persistence/URL sync
- [ ] Both systems will work together automatically

### C. API Integration

If calling backend for filtered meals:

```javascript
window.FilterStateManager.onStateChange((event) => {
  // Send filters to backend
  const { state, source } = event;

  // Only call API for user-initiated changes, not URL restoration
  if (source === 'setState') {
    callMealAPI(state);
  }
});
```

## Feature Implementation Checklist

### Core Features

- [ ] **State Persistence**
  - [ ] Filters saved in sessionStorage by default
  - [ ] Test: Set filters, reload page, filters should restore
  - [ ] Test: Close tab, reopen URL, filters should be gone (sessionStorage)

- [ ] **URL Synchronization**
  - [ ] Filters added to URL as query parameters
  - [ ] Test: Set filter, check URL for ?filter-mealType=breakfast
  - [ ] Test: Manually edit URL, change filters, navigate - should update

- [ ] **Browser Navigation**
  - [ ] Back button restores previous filter state
  - [ ] Test: Click filters, click back button multiple times
  - [ ] Test: Forward button works after back

- [ ] **History/Undo-Redo**
  - [ ] UI shows undo/redo buttons (auto-created)
  - [ ] Test: Set filters, click undo button
  - [ ] Test: Keyboard shortcut Ctrl+Z / Ctrl+Y
  - [ ] Test: Buttons disabled when history unavailable

- [ ] **Clear Filters**
  - [ ] "Clear Filters" button appears when filters are active
  - [ ] Button disappears when all filters cleared
  - [ ] Test: Set filter, click clear, all should reset

- [ ] **Export/Import**
  - [ ] Export button creates modal with URL and JSON options
  - [ ] Test: Export as URL, copy link, send to another user
  - [ ] Test: Import via pasting URL or JSON

### UI Features

- [ ] **Filter Status Display**
  - [ ] Shows "No filters applied" or filter description
  - [ ] Badge shows count of active filters
  - [ ] Automatically updates when filters change

- [ ] **Keyboard Support**
  - [ ] Tab through filter buttons
  - [ ] Enter/Space to click buttons
  - [ ] Ctrl+Z for undo
  - [ ] Ctrl+Y for redo
  - [ ] Ctrl+Shift+F to focus filters
  - [ ] Ctrl+Alt+C to clear all

- [ ] **Accessibility**
  - [ ] ARIA labels and roles present
  - [ ] Focus visible on all interactive elements
  - [ ] Live regions announce filter changes
  - [ ] Screen reader friendly
  - [ ] High contrast mode works
  - [ ] Reduced motion respected

## Testing Checklist

### Manual Tests

- [ ] **Persistence**
  - [ ] Set breakfast filter → reload page → breakfast still selected
  - [ ] Set date range → close tab → reopen → date range gone
  - [ ] Set filter → click browser back → filter changes

- [ ] **URL**
  - [ ] Current URL shows filter parameters
  - [ ] Sharing URL shows same filtered view to others
  - [ ] Direct URL with parameters auto-applies filters

- [ ] **History**
  - [ ] Click undo button → returns to previous state
  - [ ] Click redo button → goes forward in history
  - [ ] Ctrl+Z / Ctrl+Y shortcuts work
  - [ ] Buttons disabled when history exhausted

- [ ] **Export/Import**
  - [ ] Export as URL copies correct URL
  - [ ] Export as JSON downloads JSON file
  - [ ] Import JSON file restores filters
  - [ ] Import URL from another tab works

- [ ] **UI**
  - [ ] Filter badge shows when filters active
  - [ ] "Clear Filters" button visible only when needed
  - [ ] Undo/Redo buttons enable/disable correctly
  - [ ] All buttons keyboard accessible
  - [ ] All buttons have clear labels/titles

### Automated Tests

- [ ] Run test suite: `jest filter-state-manager.test.js`
- [ ] All 30+ tests pass
- [ ] Coverage above 90%

### Browser Tests

- [ ] Chrome 90+ ✓
- [ ] Firefox 88+ ✓
- [ ] Safari 14+ ✓
- [ ] Edge 90+ ✓

## Debugging Checklist

If something doesn't work:

- [ ] **Check Browser Console**
  ```javascript
  // In browser console, check:
  console.log(window.FilterStateManager); // Should exist
  console.log(window.FilterIntegration);  // Should exist
  ```

- [ ] **Check Debug Info**
  ```javascript
  const debug = window.FilterStateManager.getDebugInfo();
  console.log(debug);
  // Check config, state, history, storage size
  ```

- [ ] **Check Storage**
  ```javascript
  // F12 → Application/Storage → sessionStorage
  // Should see "meal-planner-filters" key
  ```

- [ ] **Check URL**
  ```javascript
  console.log(window.location.href);
  // Should show filter parameters: ?filter-mealType=breakfast
  ```

- [ ] **Verify Script Loading**
  - [ ] F12 → Network tab → verify all 3 JS files load (200 status)
  - [ ] F12 → Network tab → verify CSS loads (200 status)
  - [ ] F12 → Console → check for errors/warnings

- [ ] **Listen for Errors**
  ```javascript
  window.FilterStateManager.onError((event) => {
    console.error('Filter error:', event);
  });
  ```

## Performance Checklist

- [ ] Scripts load quickly (monitor Network tab)
- [ ] Filter changes feel instant (<100ms)
- [ ] No console warnings or errors
- [ ] URL updates don't block UI (debounced)
- [ ] Storage operations don't lag

## Accessibility Checklist

- [ ] **Keyboard Navigation**
  - [ ] Tab through all filter buttons
  - [ ] Enter key activates button
  - [ ] Ctrl+Z works for undo
  - [ ] Ctrl+Y works for redo

- [ ] **Screen Reader**
  - [ ] All buttons have labels
  - [ ] Live regions announce changes
  - [ ] Status updates announced
  - [ ] Modals are properly structured

- [ ] **Visual**
  - [ ] Focus indicators visible
  - [ ] Color not sole indicator
  - [ ] High contrast mode works
  - [ ] Reduced motion animations disabled

- [ ] **Mobile**
  - [ ] Touch buttons are adequate size
  - [ ] Export/Import dialogs fit screen
  - [ ] Notifications visible
  - [ ] All features work on mobile

## Documentation Checklist

For your team:

- [ ] Share README: `FILTER_STATE_MANAGER_README.md`
- [ ] Share Interactive Guide: `FILTER_IMPLEMENTATION_EXAMPLE.html`
- [ ] Share Technical Docs: `FILTER_STATE_MANAGEMENT.md`
- [ ] Train team on keyboard shortcuts
- [ ] Document any custom integration code
- [ ] Add to team wiki/documentation

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Filters not persisting | Check sessionStorage available (DevTools > Storage) |
| URL not updating | Check `enableUrlSync: true` in config |
| Undo button disabled | Check `enableHistory: true` and has history |
| Export/Import missing | Verify filter-integration.js loaded |
| Storage quota error | Clear old history or switch to smaller storage |
| Mobile layout broken | Check CSS file loaded and responsive styles applied |
| Screen reader quiet | Check ARIA attributes in HTML structure |

## Post-Integration

### 1. Monitor Usage

```javascript
// Track filter usage
window.FilterStateManager.onStateChange((event) => {
  analytics.trackEvent('filter_changed', {
    mealType: event.state.mealType,
    source: event.source
  });
});
```

### 2. Gather User Feedback

- [ ] Ask users if filter persistence is helpful
- [ ] Monitor undo/redo button usage
- [ ] Check if URL sharing is used
- [ ] Get feedback on keyboard shortcuts

### 3. Optimize Based on Usage

- [ ] Monitor storage quota usage
- [ ] Track common filter combinations
- [ ] Consider adding preset filter buttons
- [ ] Monitor performance metrics

### 4. Future Enhancements

Consider adding:
- [ ] Preset/favorite filter combinations
- [ ] More export formats (CSV, JSON, etc.)
- [ ] Filter templates/saved searches
- [ ] Multi-filter analytics
- [ ] Filter recommendations based on history

## Rollback Plan

If you need to roll back:

1. [ ] Remove `filter-state.css` from HTML head
2. [ ] Remove all three filter scripts from HTML
3. [ ] Clear sessionStorage: `sessionStorage.clear()`
4. [ ] Page reloads, existing dashboard still works

**No data loss** - system doesn't modify existing meal data.

## Success Criteria

Integration is successful when:

- [ ] All 3 files included and loading
- [ ] No console errors
- [ ] Filters persist on page reload
- [ ] URL updates with filter parameters
- [ ] Back button works correctly
- [ ] Undo/Redo buttons function
- [ ] Clear filters button appears/disappears
- [ ] Export/Import modals open
- [ ] Keyboard shortcuts work
- [ ] All tests pass
- [ ] Mobile version responsive
- [ ] Screen reader announces changes
- [ ] Users can share filter URLs

## Final Checklist

- [ ] All requirements from "Quick Start" section completed
- [ ] All "Integration Points" addressed
- [ ] All "Feature Implementation" tests passing
- [ ] "Manual Tests" completed successfully
- [ ] "Automated Tests" passing
- [ ] "Browser Tests" verified
- [ ] "Accessibility Checklist" completed
- [ ] "Performance Checklist" verified
- [ ] Documentation shared with team
- [ ] Success criteria all met

## Questions or Issues?

1. Check `FILTER_STATE_MANAGEMENT.md` for detailed API
2. Review `FILTER_IMPLEMENTATION_EXAMPLE.html` in browser
3. Look at test suite: `filter-state-manager.test.js`
4. Check browser console for specific errors
5. Use `getDebugInfo()` to verify state

## Next Steps

1. Complete this checklist
2. Test in development environment
3. Gather user feedback
4. Deploy to production
5. Monitor usage and performance
6. Consider future enhancements

---

**Total Integration Time: 15-30 minutes**

**Difficulty Level: Easy** (just copy/paste files and verify)

**Risk Level: Minimal** (no existing code changes required)
