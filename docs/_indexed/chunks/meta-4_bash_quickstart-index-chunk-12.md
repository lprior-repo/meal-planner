---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-12
heading_path: ["TypeScript quickstart", "A new type of shell"]
chunk_type: prose
tokens: 291
summary: "A new type of shell"
---

## A new type of shell
def main [
    no_default: string,
    name = "Nicolas Bourbaki",
    age: int = 42,
    date_of_birth?: datetime,
    obj: record = {"records": "included"},
    l: list<string> = ["or", "lists!"],
    tables?: table,
    enable_kill_mode?: bool = true,
] {
    # Test
    # https://www.nushell.sh/book/testing.html
		assert ($age == 42)

    print $"Hello World and a warm welcome especially to ($name)"
    print "and its acolytes.." $age $obj $l
    print $tables

    let secret = try { 
      get_variable f/examples/secret
    } catch { 
      'No secret yet at f/examples/secret !' 
    };

    print $"The variable at \`f/examples/secret\`: ($secret)"
    # fetch context variables
    let user = $env.WM_USERNAME

    # Nu pipelines
    ls | where size > 1kb | sort-by modified | print "ls:" $in

    # Nu works with existing data
    # Nu speaks JSON, YAML, SQLite, Excel, and more out of the box. 
    # It's easy to bring data into a Nu pipeline whether it's in a file, a database, or a web API:
    let nu_license = http get https://api.github.com/repos/nushell/nushell | get license

    return { splitted: ($name | split words), user: $user, nu_license: $nu_license}
    # Interested in learning more?
    # https://www.nushell.sh/book/getting_started.html

```

</TabItem>
</Tabs>

One of the strong sides of `Nu` is that it is cross-platform. If you have linux workers and [windows workers](../../../misc/17_windows_workers/index.mdx)
Nushell scripts will be able to run on both!

If you are interested in `Nu` you can read their [official documentation](https://www.nushell.sh/book/getting_started.html)
