/// Reusable macro progress bar components with color coding
///
/// This module provides CSS-animated progress bars for visualizing
/// macronutrient intake (protein, fat, carbs) against daily targets.
///
/// Features:
/// - Pure CSS animations (no JavaScript required)
/// - Color-coded bars: protein (blue), fat (orange), carbs (green)
/// - Smooth fill animation (0.6s ease-out transition)
/// - Numeric value display (current/target grams)
///
/// Design specs:
/// - Width: 100% of container
/// - Height: 24px bars
/// - Border radius: 4px
/// - Background: light gray (#e5e7eb)
/// - Fill colors: protein=#3b82f6, fat=#f97316, carbs=#22c55e

import gleam/float
import gleam/int

/// CSS styles for progress bars (include in HTML <style> tag)
pub const progress_bar_styles = "
  .progress-bar {
    background: #e5e7eb;
    border-radius: 4px;
    overflow: hidden;
    height: 24px;
    margin: 10px 0;
    position: relative;
    width: 100%;
  }
  .progress-fill {
    height: 100%;
    transition: width 0.6s ease-out;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: bold;
    font-size: 12px;
  }
  .progress-fill.protein { background: #3b82f6; }
  .progress-fill.fat { background: #f97316; }
  .progress-fill.carbs { background: #22c55e; }
  .progress-label {
    margin-bottom: 5px;
    font-size: 14px;
    font-weight: 500;
  }
"

/// Render a macro progress bar with label and percentage
///
/// ## Arguments
/// - `label`: Display name (e.g., "Protein", "Fat", "Carbs")
/// - `current`: Current grams consumed
/// - `target`: Target grams for the day
/// - `css_class`: CSS class for color ("protein", "fat", or "carbs")
///
/// ## Returns
/// HTML string with progress bar markup
///
/// ## Example
/// ```gleam
/// render_macro_bar("Protein", 75.0, 150.0, "protein")
/// // Renders: "Protein: 75.0g / 150.0g" with 50% blue bar
/// ```
pub fn render_macro_bar(
  label: String,
  current: Float,
  target: Float,
  css_class: String,
) -> String {
  let percentage = calculate_percentage(current, target)
  let width_pct = float_to_string_1dp(percentage)
  let current_str = float_to_string_1dp(current)
  let target_str = float_to_string_1dp(target)

  "<div>
    <div class=\"progress-label\">
      " <> label <> ": " <> current_str <> "g / " <> target_str <> "g
    </div>
    <div class=\"progress-bar\">
      <div class=\"progress-fill " <> css_class <> "\" style=\"width: " <> width_pct <> "%\">
        " <> width_pct <> "%
      </div>
    </div>
  </div>"
}

/// Render a complete set of macro progress bars (protein, fat, carbs)
///
/// ## Arguments
/// - `protein_current`: Current protein in grams
/// - `protein_target`: Target protein in grams
/// - `fat_current`: Current fat in grams
/// - `fat_target`: Target fat in grams
/// - `carbs_current`: Current carbs in grams
/// - `carbs_target`: Target carbs in grams
///
/// ## Returns
/// HTML string with all three progress bars
///
/// ## Example
/// ```gleam
/// render_all_macro_bars(75.0, 150.0, 45.0, 65.0, 120.0, 200.0)
/// ```
pub fn render_all_macro_bars(
  protein_current: Float,
  protein_target: Float,
  fat_current: Float,
  fat_target: Float,
  carbs_current: Float,
  carbs_target: Float,
) -> String {
  render_macro_bar("Protein", protein_current, protein_target, "protein")
  <> "\n"
  <> render_macro_bar("Fat", fat_current, fat_target, "fat")
  <> "\n"
  <> render_macro_bar("Carbs", carbs_current, carbs_target, "carbs")
}

/// Calculate percentage with safety checks
///
/// Returns min(100.0, current/target * 100.0) or 0.0 if target is 0
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> float.min(100.0, { current /. target } *. 100.0)
    False -> 0.0
  }
}

/// Format float to 1 decimal place string
fn float_to_string_1dp(f: Float) -> String {
  let rounded = int.to_float(float.round(f *. 10.0)) /. 10.0
  float.to_string(rounded)
}
