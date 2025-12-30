---
doc_id: meta/13_java_quickstart/index
chunk_id: meta/13_java_quickstart/index#chunk-3
heading_path: ["Java quickstart", "Code"]
chunk_type: code
tokens: 560
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for Java](./java_exec.png "Editor for Java")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Code editor"
		description="The code editor is Windmill's integrated development environment."
		href="/docs/code_editor"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

As we picked `Java` for this example, Windmill provided some
boilerplate. Let's take a look:

```java
//requirements:
//com.google.code.gson:gson:2.8.9
//com.github.ricksbrown:cowsay:1.1.0
//com.github.ricksbrown:cowsay:1.1.0

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.github.ricksbrown.cowsay.Cowsay;
import com.github.ricksbrown.cowsay.plugin.CowExecutor;

public class Main {
  public static class Person {
    private String name;
    private int age;

    // Constructor
    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
  }

  public static Object main(
    // Primitive
    int a,
    float b,
    // Objects
    Integer age,
    Float d,
    Object e,
    String name,
    // Lists
    String[] f
    // No trailing commas!
    ){
    Gson gson = new Gson();

    // Get resources
    var theme = Wmill.getResource("f/app_themes/theme_0");
    System.out.println("Theme: " + theme);
    
    // Create a Person object
    Person person = new Person( (name == "") ? "Alice" : name, (age == null) ? 30 : age);

    // Serialize the Person object to JSON
    String json = gson.toJson(person);
    System.out.println("Serialized JSON: " + json);

    // Use cowsay
    String[] args = new String[]{"-f", "dragon", json };
    String result = Cowsay.say(args);
    return result;
  }
}

```

In Java you need `Main` public class and public static `main` function.
Return type can either be an `Object` or `void`. Any primitive java type can be automatically converted to `Object`.

 There are a few important things to note about the `Main`.

- The arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Type annotations are used to generate the UI form, and help pre-validate
  inputs. While not mandatory, they are highly recommended. You can customize
  the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

Packages can be installed through [Coursier](https://get-coursier.io/). Just add the dependencies you need at the top of the file, using the following format:

```java
//requirements: 
//groupId:artifact:Id:version
//com.google.code.gson:gson:2.8.9
//com.github.ricksbrown:cowsay:1.1.0
```
It supports [Maven](https://maven.apache.org/what-is-maven.html) and [Ivy](https://ant.apache.org/ivy/) repositories.
