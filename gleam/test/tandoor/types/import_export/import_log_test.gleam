/// Tests for ImportLog and ExportLog types
///
/// This test module verifies the ImportLog and ExportLog types
/// can be constructed correctly and have the expected fields.
import gleeunit/should
import gleam/option.{None, Some}
import meal_planner/tandoor/types/import_export/import_log.{ImportLog}
import meal_planner/tandoor/types/import_export/export_log.{ExportLog}
import meal_planner/tandoor/types/keyword/keyword.{Keyword}

pub fn import_log_construction_test() {
  // Arrange
  let keyword =
    Keyword(
      id: 1,
      name: "italian",
      label: "Italian",
      description: "Italian recipes",
      icon: None,
      parent: None,
      numchild: 0,
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-01T00:00:00Z",
      full_name: "Italian",
    )

  // Act
  let log =
    ImportLog(
      id: 123,
      import_type: "nextcloud",
      msg: "Import in progress",
      running: True,
      keyword: Some(keyword),
      total_recipes: 50,
      imported_recipes: 25,
      created_by: 1,
      created_at: "2024-12-14T12:00:00Z",
    )

  // Assert
  log.id |> should.equal(123)
  log.import_type |> should.equal("nextcloud")
  log.msg |> should.equal("Import in progress")
  log.running |> should.equal(True)
  log.total_recipes |> should.equal(50)
  log.imported_recipes |> should.equal(25)
  log.created_by |> should.equal(1)
  log.created_at |> should.equal("2024-12-14T12:00:00Z")
}

pub fn export_log_construction_test() {
  // Arrange & Act
  let log =
    ExportLog(
      id: 321,
      export_type: "zip",
      msg: "Export in progress",
      running: True,
      total_recipes: 100,
      exported_recipes: 45,
      cache_duration: 3600,
      possibly_not_expired: True,
      created_by: 3,
      created_at: "2024-12-14T13:00:00Z",
    )

  // Assert
  log.id |> should.equal(321)
  log.export_type |> should.equal("zip")
  log.running |> should.equal(True)
}
