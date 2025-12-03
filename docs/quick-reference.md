# Quick Reference - Implementation Tasks

## 📋 At a Glance

**Total Beads**: 22 tasks
**Estimated Effort**: 78 hours (4 weeks @ 20 hrs/week)
**Current Status**: READY TO START

---

## 🎯 What We're Building

### Backend Features
1. ✅ Custom food entry (create/edit/delete)
2. ✅ Unified search (USDA + custom foods)
3. ✅ Food logging for any food type
4. ✅ Micronutrient tracking (already in database!)

### Frontend Features
1. ✅ Modern, beautiful UI with professional design system
2. ✅ Custom food entry form
3. ✅ Enhanced search interface with tabs
4. ✅ Food logging modal with portion calculator
5. ✅ Redesigned dashboard with progress visualization

---

## 🚀 Quick Start (First 3 Tasks)

### Task 1: Custom Foods Database (2 hours)
```bash
# Create migration file
touch gleam/migrations_pg/004_custom_foods.sql

# Add custom_foods table with:
# - id, user_id, name, description
# - serving_size, serving_unit
# - macros (protein, fat, carbs, calories)
# - micronutrients (fiber, sodium, sugar, vitamins)
# - Full-text search index on name
```

### Task 2: Add CustomFood Type (1 hour)
```gleam
// In gleam/src/meal_planner/types.gleam
pub type CustomFood {
  CustomFood(
    id: String,
    user_id: String,
    name: String,
    serving_size: Float,
    serving_unit: String,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    // ... timestamps
  )
}

// Add JSON encoders/decoders
pub fn custom_food_to_json(food: CustomFood) -> Json { ... }
pub fn custom_food_decoder() -> Decoder(CustomFood) { ... }
```

### Task 3: Storage Functions (4 hours)
```gleam
// In gleam/src/meal_planner/storage.gleam
pub fn create_custom_food(...) -> Result(Nil, StorageError)
pub fn update_custom_food(...) -> Result(Nil, StorageError)
pub fn delete_custom_food(...) -> Result(Nil, StorageError)
pub fn get_custom_food_by_id(...) -> Result(CustomFood, StorageError)
pub fn search_custom_foods(...) -> Result(List(CustomFood), StorageError)

// Write unit tests immediately!
```

---

## 📊 Phase Breakdown

| Phase | What Gets Built | When | Hours |
|-------|----------------|------|-------|
| **Phase 1** | Database layer for custom foods | Week 1 | 10 |
| **Phase 2** | Enhanced food logging system | Week 1-2 | 7 |
| **Phase 3** | Beautiful, modern UI | Week 2-3 | 26 |
| **Phase 4** | REST API endpoints | Week 2 | 8 |
| **Phase 5** | Comprehensive tests | Week 3 | 13 |
| **Phase 6** | Polish & optimization | Week 4 | 14 |

---

## ✅ Priority Tasks (Do These First)

### P0 - Critical (Must Have)
- [x] Bead 1.1: Custom foods database migration
- [x] Bead 1.2: CustomFood type definition
- [x] Bead 1.3: Storage CRUD functions
- [x] Bead 2.1: Enhanced food_logs schema
- [x] Bead 2.2: Updated FoodLogEntry type
- [x] Bead 2.3: Food log creation functions
- [x] Bead 3.3: Custom food entry form
- [x] Bead 3.5: Food logging modal
- [x] Bead 4.1: Custom food API
- [x] Bead 4.2: Food log API

### P1 - Important (Should Have)
- [x] Bead 1.4: Unified search
- [x] Bead 3.1: CSS design system
- [x] Bead 3.2: Dashboard redesign
- [x] Bead 3.4: Search interface
- [x] Bead 6.3: Accessibility
- [x] Bead 6.4: Mobile responsive

### P2 - Nice to Have (Could Have)
- [x] Bead 6.1: Database optimization
- [x] Bead 6.2: Caching layer

---

## 🎨 UI Design Quick Specs

### Color Palette
- Primary: `#0066ff` (bright blue)
- Success: `#00c853` (green)
- Warning: `#ff9800` (orange)
- Error: `#f44336` (red)
- Background: `#ffffff` / `#f8f9fa`
- Text: `#1a1a1a` / `#666666`

### Typography
- Font: `system-ui, -apple-system, sans-serif`
- Base size: `16px`
- Scale: `xs(12px) → sm(14px) → base(16px) → lg(18px) → xl(24px)`

### Spacing Scale
- xs: `4px`
- sm: `8px`
- md: `16px`
- lg: `24px`
- xl: `32px`

### Components
- Border radius: `8px` (default), `12px` (cards)
- Shadows: 3 levels (sm, md, lg)
- Buttons: 44px minimum height (touch-friendly)
- Form inputs: Inline validation with helpful error messages

---

## 🗄️ Database Schema Quick View

### New Tables

**custom_foods**
```sql
id TEXT PRIMARY KEY
user_id TEXT NOT NULL
name TEXT NOT NULL (searchable)
serving_size REAL
serving_unit TEXT
protein, fat, carbs, calories REAL
fiber, sodium, sugar, vitamin_c, iron, calcium REAL (nullable)
created_at, updated_at TIMESTAMP
```

**food_logs** (enhanced)
```sql
id TEXT PRIMARY KEY
date DATE
food_source TEXT ('recipe'|'usda'|'custom')
recipe_id TEXT (nullable)
fdc_id INTEGER (nullable)
custom_food_id TEXT (nullable)
food_name TEXT (denormalized)
servings REAL
serving_size, serving_unit (nullable)
protein, fat, carbs REAL
meal_type TEXT
logged_at TIMESTAMP
```

### Existing Tables (Already Available)
- **foods**: 400K+ USDA foods with full-text search
- **nutrients**: All micronutrient definitions
- **food_nutrients**: Complete micronutrient data per food
- **recipes**: User's saved recipes
- **user_profile**: Goals and preferences

---

## 🔍 Key Files to Modify

### Backend
- `gleam/src/meal_planner/types.gleam` (+200 lines)
  - Add CustomFood, Micronutrients, FoodSource types
  - Add JSON encoders/decoders

- `gleam/src/meal_planner/storage.gleam` (+600 lines)
  - Custom food CRUD
  - Unified search
  - Enhanced food logging

- `gleam/src/meal_planner/web.gleam` (+900 lines)
  - New pages (custom food form, enhanced search)
  - API endpoints
  - UI components

### Frontend
- `gleam/priv/static/styles.css` (NEW, ~800 lines)
  - Design system
  - Component styles
  - Responsive utilities

- `gleam/priv/static/components.css` (NEW, ~400 lines)
  - Card components
  - Form styling
  - Modal/dialog

- `gleam/priv/static/modal.js` (NEW, ~100 lines)
  - Modal interactions
  - Form validation
  - Portion calculator

### Migrations
- `gleam/migrations_pg/004_custom_foods.sql` (NEW)
- `gleam/migrations_pg/005_enhance_food_logs.sql` (NEW)
- `gleam/migrations_pg/006_performance_indexes.sql` (NEW)

### Tests
- `gleam/test/meal_planner/custom_foods_test.gleam` (NEW, ~300 lines)
- `gleam/test/meal_planner/food_log_integration_test.gleam` (NEW, ~400 lines)
- `gleam/test/meal_planner/web_test.gleam` (+300 lines)

---

## 🧪 Testing Checklist

### Unit Tests (As You Build)
- [x] CustomFood type construction
- [x] JSON encoding/decoding
- [x] Storage CRUD operations
- [x] Search functionality
- [x] Macro calculations

### Integration Tests (After Backend Complete)
- [x] Log USDA food → verify macros
- [x] Log custom food → verify macros
- [x] Log recipe → verify macros
- [x] Daily log aggregation
- [x] Search across all sources

### UI Tests (After Frontend Complete)
- [x] Custom food form submission
- [x] Search with filters
- [x] Log modal workflow
- [x] Dashboard rendering
- [x] Mobile responsive behavior

### Manual Testing (Before Launch)
- [x] Accessibility (keyboard navigation, screen reader)
- [x] Cross-browser (Chrome, Firefox, Safari)
- [x] Mobile devices (iOS Safari, Android Chrome)
- [x] Performance (search speed, page load)

---

## 🚦 How to Know You're Done

### Backend Complete When:
- [x] Can create/edit/delete custom foods via API
- [x] Search returns USDA + custom foods in <100ms
- [x] Can log any food type (USDA, custom, recipe)
- [x] Micronutrients display correctly
- [x] All storage tests pass

### Frontend Complete When:
- [x] Custom food form works on mobile
- [x] Search interface has tabs (All/USDA/Custom)
- [x] Log modal calculates portions in real-time
- [x] Dashboard shows today's progress
- [x] Fully keyboard accessible
- [x] Works without JavaScript (progressive enhancement)

### Production Ready When:
- [x] All tests pass (80%+ coverage)
- [x] No compiler warnings
- [x] Migrations are reversible
- [x] API has rate limiting
- [x] WCAG AA compliance
- [x] Mobile-tested on real devices
- [x] Documentation updated

---

## 💡 Pro Tips

### Development Flow
1. **Always write tests first** (TDD approach)
2. **Use the REPL** for quick type checking
3. **Run `gleam format` often** to maintain code style
4. **Check database with `psql`** to verify migrations
5. **Use browser DevTools** for UI debugging

### Common Pitfalls
- ❌ Don't forget to update JSON decoders when adding fields
- ❌ Don't skip database indexes (performance killer)
- ❌ Don't hardcode user_id (prepare for multi-user)
- ❌ Don't forget nullable columns in food_logs
- ❌ Don't skip accessibility testing

### Performance Tips
- ✅ Use prepared statements (pog handles this)
- ✅ Add composite indexes for common queries
- ✅ Paginate search results
- ✅ Cache USDA food details
- ✅ Minimize database round trips

---

## 📞 Getting Help

### Documentation
- [Full Implementation Plan](./implementation-plan.md)
- [Gleam Language Guide](https://gleam.run/book/)
- [Wisp Web Framework](https://hexdocs.pm/wisp/)
- [PostgreSQL with pog](https://hexdocs.pm/pog/)

### Key Decisions Already Made
- ✅ Use separate table for custom foods (not extending USDA)
- ✅ Discriminated union for food_logs (food_source column)
- ✅ Server-side rendering with progressive enhancement
- ✅ Mobile-first responsive design
- ✅ Optional micronutrients for custom foods

### Still Need to Decide
- [ ] Caching strategy (ETS vs external cache)
- [ ] Image uploads for custom foods (future feature)
- [ ] Social features (sharing custom foods)
- [ ] Meal planning integration

---

**Last Updated**: 2025-12-03
**Status**: Ready to implement
**Next Step**: Start with Bead 1.1 (Custom foods database migration)

