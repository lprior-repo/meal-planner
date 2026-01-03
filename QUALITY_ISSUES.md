# Quality Issues Found (Non-Critical)

All 252 documents pass schema validation. The following 14 items are quality recommendations that do not affect schema compliance.

## 1. Duplicate Section Names (13 files)

These files have sections with duplicate names at different heading levels, which may cause confusion in navigation or TOC generation.

### Files with Duplicate Sections:

1. **concept-windmill-flow.md**
   - Duplicate sections: 'Examples', 'Arguments'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/concept-windmill-flow.md

2. **concept-windmill-script.md**
   - Duplicate sections: 'Examples', 'Arguments'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/concept-windmill-script.md

3. **concept-windmill-user.md**
   - Duplicate sections: 'Examples', 'Arguments'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/concept-windmill-user.md

4. **concept-windmill-variable.md**
   - Duplicate sections: 'Arguments', 'Options'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/concept-windmill-variable.md

5. **ops-moonrepo-extensions.md**
   - Duplicate sections: 'Arguments'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-moonrepo-extensions.md

6. **ops-moonrepo-profile.md**
   - Duplicate sections: 'Record a profile', 'Analyze in Chrome'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-moonrepo-profile.md

7. **ops-moonrepo-toolchain.md**
   - Duplicate sections: '`version`'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-moonrepo-toolchain.md

8. **ops-windmill-gitsync-settings.md**
   - Duplicate sections: 'Options'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-windmill-gitsync-settings.md

9. **ops-windmill-rust-client.md**
   - Duplicate sections: 'Usage'
   - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-windmill-rust-client.md

10. **ops-windmill-sync.md**
    - Duplicate sections: 'Options'
    - Location: /home/lewis/src/meal-planner/docs/_indexed/docs/ops-windmill-sync.md

11-13. **Additional files** (3 more with similar issues)

### Recommendation:
Consider renaming duplicate sections to be more specific or merging content. For example:
- "Arguments" → "Command Arguments" and "Function Arguments"
- "Options" → "Configuration Options" and "CLI Options"
- "Examples" → "Basic Examples" and "Advanced Examples"

## 2. Title Too Short (1 file)

**File:** concept-tandoor-ai.md
- **Current title:** "Ai"
- **Location:** /home/lewis/src/meal-planner/docs/_indexed/docs/concept-tandoor-ai.md
- **Recommendation:** Expand to "AI Features", "Artificial Intelligence", or "AI Integration"
- **Issue:** Single/two-letter titles may not be descriptive enough for search and navigation

## Summary

- **Total quality issues:** 14
- **Critical issues:** 0
- **Schema compliance impact:** None
- **Action priority:** Low (cosmetic improvements)

All issues are cosmetic and do not affect:
- Schema validation
- XML parsing
- Required field presence
- Data type correctness
- Search functionality

These recommendations are for improving user experience and documentation clarity.
