# Architecture Documentation Index

This directory contains system architecture documentation for the meal planner application.

## Documents

### Recipe Form Architecture
- **[recipe-form-architecture.md](./recipe-form-architecture.md)** - Complete architectural design for recipe creation functionality
  - Route structure and API endpoints
  - Component hierarchy and data flow
  - Validation rules (client + server)
  - Error handling strategy
  - Security and performance considerations
  - Implementation phases (1-4)
  - ADRs (Architecture Decision Records)

- **[recipe-form-data-flow.md](./recipe-form-data-flow.md)** - Detailed data flow diagrams
  - Sequence diagrams (happy path + error paths)
  - State transition diagrams
  - Component interaction diagrams
  - Data transformation flows
  - Validation pipeline visualization

## Quick Reference

### Recipe Form - Key Decisions

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **Rendering** | Server-Side (SSR) | Consistent with app, better SEO, simpler state |
| **Validation** | Dual (client + server) | UX (immediate feedback) + security (data integrity) |
| **Routes** | RESTful (/recipes/new, POST /api/recipes) | Standard patterns, SEO-friendly |
| **Storage** | PostgreSQL with current serialization | No migration needed, defer JSON to v2 |
| **Framework** | Gleam + Wisp + Lustre | Existing tech stack |

### New Modules

1. **recipe_handlers.gleam** - Route handlers and business logic
   - `new_recipe_page()` - Render empty form
   - `edit_recipe_page(id)` - Render form with recipe data
   - `create_recipe(req, ctx)` - Handle POST /api/recipes
   - `update_recipe(req, id, ctx)` - Handle PUT /api/recipes/:id

2. **recipe_validation.gleam** - Validation rules
   - `validate_recipe_input()` - Main validation orchestrator
   - Field validators: name, category, ingredients, instructions, macros, servings
   - Error types and result types

3. **recipe_forms.gleam** - Lustre form components
   - `recipe_form_component()` - Main form layout
   - `ingredient_input()` - Dynamic ingredient list
   - `instruction_input()` - Dynamic instruction list
   - `macro_inputs()` - Macro input fields with calculated calories

### Implementation Phases

- **Phase 1**: Core create flow (MVP) - Basic recipe creation with validation
- **Phase 2**: Edit flow - Update existing recipes
- **Phase 3**: Enhanced UX - Dynamic lists, autosave, real-time calculation
- **Phase 4**: Advanced features - Photos, autocomplete, sharing

### Validation Rules Summary

| Field | Rules | Error Codes |
|-------|-------|-------------|
| name | Required, 1-100 chars | required, too_long |
| category | Required, from list | required, invalid |
| ingredients | Min 1, max 50 | required, too_many |
| instructions | Min 1, max 20 | required, too_many |
| macros | >= 0.0, <= 1000.0 | required, invalid_range |
| servings | >= 1, <= 50 | required, invalid_range |
| fodmap_level | Enum (low/medium/high) | required, invalid |
| vertical_compliant | Bool | (none) |

### HTTP Status Codes

- **200 OK** - Form rendered successfully
- **201 Created** - Recipe created (with Location header)
- **302 Found** - Redirect to recipe detail after save
- **400 Bad Request** - Validation errors
- **404 Not Found** - Recipe not found (edit)
- **409 Conflict** - Duplicate recipe name
- **500 Internal Server Error** - Database error

## Related Documentation

- **[/home/lewis/src/meal-planner/gleam/src/meal_planner/web.gleam](../../gleam/src/meal_planner/web.gleam)** - Current routing implementation
- **[/home/lewis/src/meal-planner/gleam/src/meal_planner/storage.gleam](../../gleam/src/meal_planner/storage.gleam)** - Database layer
- **[/home/lewis/src/meal-planner/shared/src/shared/types.gleam](../../shared/src/shared/types.gleam)** - Shared type definitions
- **[/home/lewis/src/meal-planner/gleam/src/meal_planner/validation.gleam](../../gleam/src/meal_planner/validation.gleam)** - Existing validation (Vertical Diet)

## How to Use This Documentation

### For Developers Implementing Recipe Form

1. Read **recipe-form-architecture.md** sections 1-6 (Overview, Routes, Data Flow, Components, Validation, Error Handling)
2. Review **recipe-form-data-flow.md** for detailed sequence diagrams
3. Follow implementation plan in architecture doc section 11
4. Reference validation rules in section 5 while coding
5. Use testing strategy in section 12 for TDD approach

### For Product/UX Designers

1. Review **recipe-form-architecture.md** section 8 (Form UI Specification)
2. Check accessibility requirements in section 8.3
3. Review error handling strategy in section 6 for UX flows
4. Reference data flow diagrams for user journey understanding

### For QA/Testing

1. Review **recipe-form-architecture.md** section 12 (Testing Strategy)
2. Use validation rules table (section 5.2) for test case generation
3. Check error handling classification (section 6.1) for error scenarios
4. Review acceptance criteria in implementation plan (section 11)

### For Operations/DevOps

1. Review **recipe-form-architecture.md** section 13 (Monitoring & Observability)
2. Check performance considerations in section 15
3. Review deployment process in section 16.1
4. Check rollback plan in section 16.2

## Architecture Principles

This design follows these key principles:

1. **Progressive Enhancement** - Works without JavaScript, enhanced with JS
2. **Defense in Depth** - Multiple validation layers (client + server)
3. **Fail Fast** - Validate early, provide immediate feedback
4. **DRY (Don't Repeat Yourself)** - Reusable form components
5. **SOLID** - Single responsibility modules (handlers, validation, forms)
6. **Accessibility First** - ARIA labels, keyboard navigation, semantic HTML
7. **Type Safety** - Leverage Gleam's type system for compile-time guarantees

## Contact & Questions

For questions about this architecture:
- Review ADRs in recipe-form-architecture.md section 10
- Check future enhancements in section 17
- Refer to appendix in section 18 for examples

---

**Last Updated**: 2025-12-03
**Status**: Design Complete - Ready for Implementation
**Next Step**: Begin Phase 1 implementation (Core create flow)
