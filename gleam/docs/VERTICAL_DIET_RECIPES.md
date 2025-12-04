# Vertical Diet Recipe Collection

## Overview

This collection contains 15 Stan Efferding-approved Vertical Diet recipes designed for optimal performance, easy digestion, and muscle building.

## Database Integration

### Migration File
- **Location**: `/gleam/migrations_pg/013_add_vertical_diet_recipes.sql`
- **Tables**: Inserts into both `recipes` and `recipes_simplified`
- **All recipes marked**: `vertical_compliant = TRUE`, `fodmap_level = 'low'`

### Recipe IDs
- Format: `vd-001` through `vd-015`
- Systematic naming for easy reference

## Recipe Categories

### 1. Red Meat Mains (5 recipes)
Core meals featuring beef and bison - the foundation of the Vertical Diet.

| Recipe ID | Name | Calories | Protein | Carbs | Fat |
|-----------|------|----------|---------|-------|-----|
| vd-001 | Vertical Diet Ground Beef Bowl | 680 | 52g | 68g | 24g |
| vd-002 | Bison Burger with White Rice | 720 | 55g | 75g | 18g |
| vd-003 | Simple Ribeye Steak with Sweet Potato | 850 | 58g | 62g | 38g |
| vd-004 | Ground Beef and White Rice - Classic | 620 | 48g | 64g | 20g |
| vd-005 | Bison Sirloin with Mashed Potatoes | 680 | 54g | 58g | 22g |

**Key Benefits:**
- Complete protein with all essential amino acids
- High iron, zinc, B12, creatine
- Satiating and muscle-building
- Easy to digest when properly cooked

### 2. Post-Workout Meals (3 recipes)
High protein + high carb combinations for optimal recovery.

| Recipe ID | Name | Calories | Protein | Carbs | Fat |
|-----------|------|----------|---------|-------|-----|
| vd-006 | Post-Workout Beef and Rice | 750 | 60g | 85g | 15g |
| vd-007 | Monster Mash - Beef, Rice & Sweet Potato | 920 | 65g | 112g | 18g |
| vd-008 | Anabolic Ground Beef Power Bowl | 800 | 68g | 78g | 22g |

**Timing Guidelines:**
- Consume within 30-60 minutes post-training
- Higher carbs for glycogen replenishment
- Lower fat for faster digestion
- High protein for muscle protein synthesis

### 3. Simple Carb Sides (3 recipes)
Easy-to-digest carbohydrate sources.

| Recipe ID | Name | Calories | Protein | Carbs | Fat |
|-----------|------|----------|---------|-------|-----|
| vd-009 | White Rice with Butter and Salt | 280 | 4g | 58g | 4g |
| vd-010 | Baked Sweet Potato with Butter | 220 | 3g | 42g | 5g |
| vd-011 | White Potato Mash - Plain | 180 | 4g | 38g | 2g |

**Why These Carbs:**
- Low FODMAP = no gut irritation
- Quick energy release
- No anti-nutrients or lectins (when cooked properly)
- Easy to scale portions for calorie needs

### 4. Easy Vegetables (2 recipes)
Low FODMAP vegetables for micronutrients without digestive stress.

| Recipe ID | Name | Calories | Protein | Carbs | Fat |
|-----------|------|----------|---------|-------|-----|
| vd-012 | Steamed Carrots with Salt | 85 | 2g | 18g | 1g |
| vd-013 | Sautéed Spinach with Olive Oil | 120 | 4g | 8g | 9g |

**Micronutrient Focus:**
- **Carrots**: Beta-carotene (vitamin A), fiber
- **Spinach**: Iron, folate, vitamins A, C, K

### 5. Complete Meals (2 recipes)
Fully balanced Vertical Diet meals with protein, carbs, and vegetables.

| Recipe ID | Name | Calories | Protein | Carbs | Fat |
|-----------|------|----------|---------|-------|-----|
| vd-014 | Efferding Special - Beef, Rice, Carrots | 780 | 56g | 88g | 20g |
| vd-015 | Monster Maker - Double Beef with Sweet Potato | 1050 | 82g | 95g | 28g |

**Usage:**
- vd-014: Perfect balanced meal for most athletes
- vd-015: Mass-building meal for strength athletes (1000+ calories)

## Vertical Diet Principles

### Core Philosophy
The Vertical Diet focuses on **easy digestion** and **nutrient density** to support:
- Heavy training and recovery
- Optimal hormone production
- Reduced inflammation
- Maximum nutrient absorption

### Food Selection Criteria

#### ✅ Approved Foods (Used in these recipes)
- **Proteins**: Beef, bison, eggs
- **Carbs**: White rice, white potatoes, sweet potatoes
- **Vegetables**: Carrots, spinach, bell peppers, cucumbers
- **Fats**: Butter, olive oil, avocado oil
- **Dairy**: Whole milk, yogurt (if tolerated)

#### ❌ Avoided Foods (NOT in these recipes)
- Beans and legumes (high FODMAP, anti-nutrients)
- Whole grains (phytates, lectins)
- Cruciferous vegetables (can cause gas)
- Onions and garlic (high FODMAP)
- Most nuts and seeds (hard to digest in large amounts)

## Macro Guidelines by Goal

### Mass Building (Bulking)
```
Protein: 1.0g per lb bodyweight
Carbs: 2.5-4.0g per lb bodyweight
Fat: 0.4-0.5g per lb bodyweight

Example for 200lb athlete:
- Protein: 200g
- Carbs: 500-800g
- Fat: 80-100g
- Total: 3500-4500 calories

Recommended recipes:
- Monster Maker (vd-015) - 2x per day
- Post-Workout Beef and Rice (vd-006)
- Extra white rice sides (vd-009)
```

### Maintenance
```
Protein: 1.0g per lb bodyweight
Carbs: 1.5-2.5g per lb bodyweight
Fat: 0.4-0.5g per lb bodyweight

Example for 200lb athlete:
- Protein: 200g
- Carbs: 300-500g
- Fat: 80-100g
- Total: 2800-3500 calories

Recommended recipes:
- Efferding Special (vd-014)
- Ground Beef and Rice Classic (vd-004)
- Ribeye with Sweet Potato (vd-003)
```

### Cutting (Fat Loss)
```
Protein: 1.2g per lb bodyweight
Carbs: 1.0-1.5g per lb bodyweight
Fat: 0.3-0.4g per lb bodyweight

Example for 200lb athlete:
- Protein: 240g
- Carbs: 200-300g
- Fat: 60-80g
- Total: 2300-2800 calories

Recommended recipes:
- Use leaner beef (93/7 or 96/4)
- Reduce rice portions by 25-50%
- Add extra vegetables (vd-012, vd-013)
- Bison options (vd-002, vd-005) for lower fat
```

## Meal Planning Examples

### 3-Meal Structure (3000 calories)

**Meal 1 (10am) - 900 calories**
- vd-003: Simple Ribeye Steak with Sweet Potato (850 cal)
- vd-012: Steamed Carrots (85 cal)

**Meal 2 (2pm - Post Workout) - 1050 calories**
- vd-015: Monster Maker - Double Beef with Sweet Potato (1050 cal)

**Meal 3 (7pm) - 1050 calories**
- vd-001: Vertical Diet Ground Beef Bowl (680 cal)
- vd-010: Baked Sweet Potato with Butter x2 (440 cal)

**Total:** ~3000 calories, 196g protein, 305g carbs, 90g fat

### 5-Meal Structure (4000 calories)

**Meal 1 (8am) - 720 calories**
- vd-002: Bison Burger with White Rice (720 cal)

**Meal 2 (12pm) - 680 calories**
- vd-001: Vertical Diet Ground Beef Bowl (680 cal)

**Meal 3 (3pm - Post Workout) - 920 calories**
- vd-007: Monster Mash (920 cal)

**Meal 4 (6pm) - 850 calories**
- vd-003: Ribeye with Sweet Potato (850 cal)

**Meal 5 (9pm) - 800 calories**
- vd-008: Anabolic Ground Beef Power Bowl (800 cal)

**Total:** ~4000 calories, 288g protein, 438g carbs, 120g fat

## Preparation Tips

### Batch Cooking
**White Rice:**
- Cook 5-7 cups dry rice on Sunday
- Portion into containers (1.5-2 cups each)
- Refrigerate up to 5 days
- Reheat with splash of water

**Ground Beef:**
- Cook 5 lbs at once in large skillet
- Season with salt while cooking
- Portion into 7-8oz servings
- Refrigerate up to 4 days, freeze remainder

**Sweet Potatoes:**
- Bake 8-10 at once at 400°F
- Store whole in refrigerator
- Reheat in microwave (2-3 minutes)

**Vegetables:**
- Pre-cut carrots on Sunday
- Steam fresh daily (5-7 minutes)
- Spinach cooks in 2-3 minutes (make fresh)

### Time-Saving Strategies
1. **Rice Cooker**: Set it and forget it
2. **Instant Pot**: Potatoes in 12 minutes
3. **Cast Iron**: Perfect for steaks and burgers
4. **Meal Prep Sundays**: Cook rice + beef for entire week

### Quality Ingredients
- **Beef**: Grass-fed when possible, 85/15 or 93/7
- **Bison**: Naturally lean, ranch-raised preferred
- **Rice**: White jasmine or basmati (not instant)
- **Potatoes**: Russet, Yukon gold, or Japanese sweet potatoes
- **Salt**: Sea salt or Himalayan pink salt

## Digestion Optimization

### Cooking Methods
1. **Ground Beef**: Cook thoroughly (160°F+)
2. **Steaks**: Medium-rare to medium (easier to digest than well-done)
3. **Rice**: Rinse before cooking, don't overcook
4. **Potatoes**: Cook until soft (easier to digest)

### Portion Sizes
- Start with smaller portions if new to Vertical Diet
- Gradually increase as digestion adapts
- Monitor energy levels and digestion quality
- Adjust based on training intensity

### Meal Timing
- **Pre-workout** (2-3 hours before): Medium protein + carbs
- **Post-workout** (within 60 min): High protein + high carbs
- **Before bed**: Moderate protein, lower carbs
- **Spacing**: 3-5 hours between meals ideal

## Troubleshooting

### Issue: Still Hungry
**Solution:**
- Add extra white rice (vd-009)
- Use fattier beef (85/15 instead of 93/7)
- Add second sweet potato
- Increase meal frequency

### Issue: Too Full
**Solution:**
- Reduce rice portions by 25%
- Use leaner beef (93/7)
- Split large meals into 2 smaller meals
- Chew thoroughly

### Issue: Low Energy
**Solution:**
- Increase carbs by 20-30%
- Add pre-workout meal (vd-009 white rice + small protein)
- Ensure adequate salt intake
- Check sleep quality

### Issue: Digestive Discomfort
**Solution:**
- Cook beef more thoroughly
- Reduce portion sizes
- Increase meal frequency
- Avoid eating too fast
- Consider digestive enzymes

## Scientific Rationale

### Why Red Meat?
- **Complete Protein**: All 9 essential amino acids
- **Heme Iron**: 2-3x more bioavailable than plant iron
- **Zinc**: Essential for testosterone production
- **B12**: Critical for energy and nervous system
- **Creatine**: Pre-formed, no conversion needed

### Why White Rice?
- **Low FODMAP**: No gut irritation
- **Quick Digestion**: 2-3 hour transit time
- **No Anti-nutrients**: Unlike brown rice (phytates)
- **Easy to Scale**: Adjust calories easily
- **Stable Blood Sugar**: When paired with protein

### Why Low FODMAP?
- Reduces gas and bloating
- Improves nutrient absorption
- Less inflammation
- Better training performance
- Improved gut health

## Additional Resources

### Stan Efferding's Guidelines
- Focus on micronutrients ("horizontal" nutrition)
- Then add volume ("vertical" calories)
- Prioritize digestion and absorption
- Track progress and adjust

### Monitoring Progress
Track these metrics:
- **Weight**: Weekly average
- **Strength**: Main lift progress
- **Energy**: Training intensity
- **Digestion**: Quality and comfort
- **Sleep**: Hours and quality
- **Recovery**: Soreness and fatigue

### When to Adjust
Increase calories if:
- Weight stable for 2+ weeks (bulking goal)
- Strength plateaued
- Low energy in training

Decrease calories if:
- Weight increasing too fast (>2 lbs/week)
- Fat gain too rapid
- Digestion struggles

## Database Queries

### Find All Vertical Diet Recipes
```sql
SELECT id, name, protein, carbs, fat, calories, category
FROM recipes
WHERE vertical_compliant = TRUE
ORDER BY category, name;
```

### Post-Workout Meals Only
```sql
SELECT name, calories, protein, carbs
FROM recipes_simplified
WHERE category IN ('lunch', 'dinner')
  AND protein >= 50
  AND carbs >= 75
ORDER BY protein DESC;
```

### High-Protein Recipes
```sql
SELECT name, protein, calories, protein*4*100/calories as protein_percent
FROM recipes
WHERE vertical_compliant = TRUE
  AND protein >= 50
ORDER BY protein DESC;
```

### Recipes by Calorie Range
```sql
-- Mass building (800+ calories)
SELECT name, calories, protein
FROM recipes_simplified
WHERE calories >= 800
  AND verified = TRUE;

-- Cutting (400-700 calories)
SELECT name, calories, protein
FROM recipes_simplified
WHERE calories BETWEEN 400 AND 700
  AND verified = TRUE;
```

## Integration with Meal Planner

### Adding Recipes to Daily Log
```sql
INSERT INTO food_logs (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type)
VALUES (
  gen_random_uuid()::TEXT,
  CURRENT_DATE,
  'vd-014',
  'Efferding Special - Beef, Rice, Carrots',
  1.0,
  56.0,
  20.0,
  88.0,
  'dinner'
);
```

### Macro Totals for Day
```sql
SELECT
  date,
  SUM(protein) as total_protein,
  SUM(carbs) as total_carbs,
  SUM(fat) as total_fat,
  SUM(protein * 4 + carbs * 4 + fat * 9) as total_calories
FROM food_logs
WHERE date = CURRENT_DATE
GROUP BY date;
```

## Success Tips

1. **Start Simple**: Begin with vd-004 (Ground Beef and Rice Classic)
2. **Master Basics**: Perfect your beef cooking technique
3. **Batch Prep**: Sunday meal prep saves hours
4. **Track Macros**: Log everything for first 2 weeks
5. **Listen to Body**: Adjust portions based on hunger and energy
6. **Stay Consistent**: Same meals daily = easier to track progress
7. **Quality Matters**: Good beef tastes better and digests easier
8. **Salt Adequately**: Don't fear salt, especially if training hard
9. **Chew Thoroughly**: Better digestion, better nutrient absorption
10. **Be Patient**: Body adapts in 2-3 weeks

## Conclusion

These 15 recipes provide a complete Vertical Diet meal system. They're designed to:
- Maximize nutrient absorption
- Support heavy training
- Build muscle efficiently
- Minimize digestive stress
- Simplify meal planning

Start with the basics (vd-004), expand to complete meals (vd-014), and scale up for mass building (vd-015). Track your progress and adjust based on results.

**Remember Stan Efferding's core principle:**
> "The goal is not just to eat more, but to digest and absorb more."

---

*These recipes are educational examples based on Vertical Diet principles. Adjust portions and ingredients based on individual needs, training intensity, and health conditions. Consult with a registered dietitian for personalized nutrition advice.*
