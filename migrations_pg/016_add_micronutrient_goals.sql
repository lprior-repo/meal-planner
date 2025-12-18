-- Add micronutrient goals to user_profile table
-- Migration 016: Add micronutrient_goals column to track daily micronutrient targets

ALTER TABLE user_profile
ADD COLUMN IF NOT EXISTS micronutrient_goals TEXT;

-- Set default FDA RDA values for existing users
-- Values are in standard units (mg, mcg, IU) as stored in USDA database
UPDATE user_profile
SET micronutrient_goals = '{
  "fiber": 28.0,
  "sugar": 50.0,
  "sodium": 2300.0,
  "cholesterol": 300.0,
  "vitamin_a": 900.0,
  "vitamin_c": 90.0,
  "vitamin_d": 20.0,
  "vitamin_e": 15.0,
  "vitamin_k": 120.0,
  "vitamin_b6": 1.7,
  "vitamin_b12": 2.4,
  "folate": 400.0,
  "thiamin": 1.2,
  "riboflavin": 1.3,
  "niacin": 16.0,
  "calcium": 1000.0,
  "iron": 8.0,
  "magnesium": 420.0,
  "phosphorus": 700.0,
  "potassium": 3400.0,
  "zinc": 11.0
}'
WHERE micronutrient_goals IS NULL;

-- Add comment explaining the column
COMMENT ON COLUMN user_profile.micronutrient_goals IS
'JSON object storing daily micronutrient goals/targets. Based on FDA RDA values for adult males. Users can customize per micronutrient.';
