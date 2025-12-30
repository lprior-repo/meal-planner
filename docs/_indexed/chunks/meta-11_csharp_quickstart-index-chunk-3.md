---
doc_id: meta/11_csharp_quickstart/index
chunk_id: meta/11_csharp_quickstart/index#chunk-3
heading_path: ["C# quickstart", "Code"]
chunk_type: code
tokens: 533
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for C#](./editor_csharp.png "Editor for C#")

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

As we picked `C#` for this example, Windmill provided some
boilerplate. Let's take a look:

```cs
#r "nuget: Humanizer, 2.14.1"

using System;
using System.Linq;
using Humanizer;


class Script
{
    public static DateTime Main(string[] extraWords, string word = "clue", int highNumberThreshold = 50)
    {
        Console.WriteLine("Hello, World!");

        Console.WriteLine("Your chosen words are pluralized here:");

        string[] newWordArray = extraWords.Concat(new[] { word }).ToArray();

        foreach (var s in newWordArray)
        {
            Console.WriteLine($"  {s.Pluralize()}");
        }

        var random = new Random();
        int randomNumber = random.Next(1, 101);

        Console.WriteLine($"Random number: {randomNumber}");

        string greeting = randomNumber > highNumberThreshold ? "High number!" : "Low number!";
        greeting += " (according to the threshold parameter)";
        Console.WriteLine(greeting);
         // Humanize a timespan
        var timespan = TimeSpan.FromMinutes(90);
        Console.WriteLine($"Timespan: {timespan.Humanize()}");

        // Humanize numbers into words
        int number = 123;
        Console.WriteLine($"Number: {number.ToWords()}");

        // Pluralize words
        string singular = "apple";

        // Humanize date difference
        var date = DateTime.UtcNow.AddDays(-3);
        Console.WriteLine($"Date: {date.Humanize()}");
        return date;
    }
}
```

In Windmill, scripts need to have a main function that will be the script's
entrypoint. There are a few important things to note about the `Main`.

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

Packages can be installed through NuGet. Just add the dependencies you need at the top of the file, using the following format:

```cs
#r "nuget: Humanizer, 2.14.1"
#r "nuget: AutoMapper, 6.1.0"
```

::: warn
Note that only the lines at the very top will be taken into account.
:::
