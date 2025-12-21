import gleam/dynamic/decode

/// Type-safe wrapper for Recipe IDs
pub opaque type RecipeId {
  RecipeId(Int)
}

/// Type-safe wrapper for Food IDs
pub opaque type FoodId {
  FoodId(Int)
}

/// Type-safe wrapper for Unit IDs
pub opaque type UnitId {
  UnitId(Int)
}

/// Type-safe wrapper for Keyword IDs
pub opaque type KeywordId {
  KeywordId(Int)
}

/// Type-safe wrapper for MealPlan IDs
pub opaque type MealPlanId {
  MealPlanId(Int)
}

/// Type-safe wrapper for Step IDs
pub opaque type StepId {
  StepId(Int)
}

/// Type-safe wrapper for Ingredient IDs
pub opaque type IngredientId {
  IngredientId(Int)
}

/// Type-safe wrapper for User IDs
pub opaque type UserId {
  UserId(Int)
}

/// Type-safe wrapper for Supermarket IDs
pub opaque type SupermarketId {
  SupermarketId(Int)
}

/// Type-safe wrapper for Storage IDs
pub opaque type StorageId {
  StorageId(Int)
}

/// Type-safe wrapper for ShoppingList IDs
pub opaque type ShoppingListId {
  ShoppingListId(Int)
}

/// Type-safe wrapper for ShoppingListEntry IDs
pub opaque type ShoppingListEntryId {
  ShoppingListEntryId(Int)
}

/// Type-safe wrapper for Property IDs
pub opaque type PropertyId {
  PropertyId(Int)
}

/// Type-safe wrapper for ExportLog IDs
pub opaque type ExportLogId {
  ExportLogId(Int)
}

/// Type-safe wrapper for ImportLog IDs
pub opaque type ImportLogId {
  ImportLogId(Int)
}

/// Type-safe wrapper for Cuisine IDs
pub opaque type CuisineId {
  CuisineId(Int)
}

/// Type-safe wrapper for Category IDs
pub opaque type CategoryId {
  CategoryId(Int)
}

// RecipeId functions
pub fn recipe_id_to_int(id: RecipeId) -> Int {
  let RecipeId(n) = id
  n
}

pub fn recipe_id_from_int(n: Int) -> RecipeId {
  RecipeId(n)
}

pub fn recipe_id_decoder() -> decode.Decoder(RecipeId) {
  decode.int
  |> decode.map(RecipeId)
}

// FoodId functions
pub fn food_id_to_int(id: FoodId) -> Int {
  let FoodId(n) = id
  n
}

pub fn food_id_from_int(n: Int) -> FoodId {
  FoodId(n)
}

pub fn food_id_decoder() -> decode.Decoder(FoodId) {
  decode.int
  |> decode.map(FoodId)
}

// UnitId functions
pub fn unit_id_to_int(id: UnitId) -> Int {
  let UnitId(n) = id
  n
}

pub fn unit_id_from_int(n: Int) -> UnitId {
  UnitId(n)
}

pub fn unit_id_decoder() -> decode.Decoder(UnitId) {
  decode.int
  |> decode.map(UnitId)
}

// KeywordId functions
pub fn keyword_id_to_int(id: KeywordId) -> Int {
  let KeywordId(n) = id
  n
}

pub fn keyword_id_from_int(n: Int) -> KeywordId {
  KeywordId(n)
}

pub fn keyword_id_decoder() -> decode.Decoder(KeywordId) {
  decode.int
  |> decode.map(KeywordId)
}

// MealPlanId functions
pub fn meal_plan_id_to_int(id: MealPlanId) -> Int {
  let MealPlanId(n) = id
  n
}

pub fn meal_plan_id_from_int(n: Int) -> MealPlanId {
  MealPlanId(n)
}

pub fn meal_plan_id_decoder() -> decode.Decoder(MealPlanId) {
  decode.int
  |> decode.map(MealPlanId)
}

// StepId functions
pub fn step_id_to_int(id: StepId) -> Int {
  let StepId(n) = id
  n
}

pub fn step_id_from_int(n: Int) -> StepId {
  StepId(n)
}

pub fn step_id_decoder() -> decode.Decoder(StepId) {
  decode.int
  |> decode.map(StepId)
}

// IngredientId functions
pub fn ingredient_id_to_int(id: IngredientId) -> Int {
  let IngredientId(n) = id
  n
}

pub fn ingredient_id_from_int(n: Int) -> IngredientId {
  IngredientId(n)
}

pub fn ingredient_id_decoder() -> decode.Decoder(IngredientId) {
  decode.int
  |> decode.map(IngredientId)
}

// UserId functions
pub fn user_id_to_int(id: UserId) -> Int {
  let UserId(n) = id
  n
}

pub fn user_id_from_int(n: Int) -> UserId {
  UserId(n)
}

pub fn user_id_decoder() -> decode.Decoder(UserId) {
  decode.int
  |> decode.map(UserId)
}

// SupermarketId functions
pub fn supermarket_id_to_int(id: SupermarketId) -> Int {
  let SupermarketId(n) = id
  n
}

pub fn supermarket_id_from_int(n: Int) -> SupermarketId {
  SupermarketId(n)
}

pub fn supermarket_id_decoder() -> decode.Decoder(SupermarketId) {
  decode.int
  |> decode.map(SupermarketId)
}

// StorageId functions
pub fn storage_id_to_int(id: StorageId) -> Int {
  let StorageId(n) = id
  n
}

pub fn storage_id_from_int(n: Int) -> StorageId {
  StorageId(n)
}

pub fn storage_id_decoder() -> decode.Decoder(StorageId) {
  decode.int
  |> decode.map(StorageId)
}

// ShoppingListId functions
pub fn shopping_list_id_to_int(id: ShoppingListId) -> Int {
  let ShoppingListId(n) = id
  n
}

pub fn shopping_list_id_from_int(n: Int) -> ShoppingListId {
  ShoppingListId(n)
}

pub fn shopping_list_id_decoder() -> decode.Decoder(ShoppingListId) {
  decode.int
  |> decode.map(ShoppingListId)
}

// ShoppingListEntryId functions
pub fn shopping_list_entry_id_to_int(id: ShoppingListEntryId) -> Int {
  let ShoppingListEntryId(n) = id
  n
}

pub fn shopping_list_entry_id_from_int(n: Int) -> ShoppingListEntryId {
  ShoppingListEntryId(n)
}

pub fn shopping_list_entry_id_decoder() -> decode.Decoder(ShoppingListEntryId) {
  decode.int
  |> decode.map(ShoppingListEntryId)
}

// ImportLogId functions
pub fn import_log_id_to_int(id: ImportLogId) -> Int {
  let ImportLogId(n) = id
  n
}

pub fn import_log_id_from_int(n: Int) -> ImportLogId {
  ImportLogId(n)
}

pub fn import_log_id_decoder() -> decode.Decoder(ImportLogId) {
  decode.int
  |> decode.map(ImportLogId)
}

// ExportLogId functions
pub fn export_log_id_to_int(id: ExportLogId) -> Int {
  let ExportLogId(n) = id
  n
}

pub fn export_log_id_from_int(n: Int) -> ExportLogId {
  ExportLogId(n)
}

pub fn export_log_id_decoder() -> decode.Decoder(ExportLogId) {
  decode.int
  |> decode.map(ExportLogId)
}

// PropertyId functions
pub fn property_id_to_int(id: PropertyId) -> Int {
  let PropertyId(n) = id
  n
}

pub fn property_id_from_int(n: Int) -> PropertyId {
  PropertyId(n)
}

pub fn property_id_decoder() -> decode.Decoder(PropertyId) {
  decode.int
  |> decode.map(PropertyId)
}

// CuisineId functions
pub fn cuisine_id_to_int(id: CuisineId) -> Int {
  let CuisineId(n) = id
  n
}

pub fn cuisine_id_from_int(n: Int) -> CuisineId {
  CuisineId(n)
}

pub fn cuisine_id_decoder() -> decode.Decoder(CuisineId) {
  decode.int
  |> decode.map(CuisineId)
}

// CategoryId functions
pub fn category_id_to_int(id: CategoryId) -> Int {
  let CategoryId(n) = id
  n
}

pub fn category_id_from_int(n: Int) -> CategoryId {
  CategoryId(n)
}

pub fn category_id_decoder() -> decode.Decoder(CategoryId) {
  decode.int
  |> decode.map(CategoryId)
}
