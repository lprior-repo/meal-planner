---
doc_id: ops/tandoor/import-export
chunk_id: ops/tandoor/import-export#chunk-15
heading_path: ["Import Export", "OpenEats"]
chunk_type: prose
tokens: 257
summary: "OpenEats"
---

## OpenEats

OpenEats does not provide any way to export the data using the interface. Luckily it is relatively easy to export it from the command line.
You need to run the command `python manage.py dumpdata recipe ingredient` inside of the application api container.
If you followed the default installation method you can use the following command `docker-compose -f docker-prod.yml run --rm --entrypoint 'sh' api ./manage.py dumpdata recipe ingredient`.
This command might also work `docker exec -it openeats_api_1 ./manage.py dumpdata recipe ingredient rating recipe_groups > recipe_ingredients.json`

Store the outputted json string in a `.json` file and simply import it using the importer. The file should look something like this

```json
[
   {
      "model":"recipe.recipe",
      "pk":1,
      "fields":{
         "title":"Tasty Chili",
         ...
      }
   },
  ...
    {
      "model":"ingredient.ingredientgroup",
      "pk":1,
      "fields":{
         "title":"Veges",
         "recipe":1
      }
   },
  ...
  {
      "model":"ingredient.ingredient",
      "pk":1,
      "fields":{
         "title":"black pepper",
         "numerator":1.0,
         "denominator":1.0,
         "measurement":"dash",
         "ingredient_group":1
      }
   }
]

```

To import your images you'll need to create the folder `openeats-import` in your Tandoor's `recipes` media folder (which is usually found inside `/opt/recipes/mediafiles`). After that you'll need to copy the `/code/site-media/upload` folder from the openeats API docker container to the `openeats` folder you created. You should now have the file path `/opt/recipes/mediafiles/recipes/openeats-import/upload/...` in Tandoor.
