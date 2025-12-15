// TODO: Fix image upload - requires binary body support in HTTP module
// Temporarily stubbed to allow builds to complete
pub fn upload_recipe_image(
  _config: client.ClientConfig,
  _recipe_id: Int,
  _image_data: String,
  _filename: String,
) -> Result(client.Recipe, client.TandoorError) {
  Error(client.NetworkError("Image upload not yet implemented"))
}

pub fn upload_recipe_image_from_file(
  _config: client.ClientConfig,
  _recipe_id: Int,
  _file_path: String,
) -> Result(client.Recipe, client.TandoorError) {
  Error(client.NetworkError("Image upload from file not yet implemented"))
}

pub fn delete_recipe_image(
  _config: client.ClientConfig,
  _recipe_id: Int,
) -> Result(Nil, client.TandoorError) {
  Error(client.NetworkError("Image deletion not yet implemented"))
}
