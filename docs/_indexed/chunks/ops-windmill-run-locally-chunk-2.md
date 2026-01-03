---
doc_id: ops/windmill/run-locally
chunk_id: ops/windmill/run-locally#chunk-2
heading_path: ["Run locally", "Deno / Bun"]
chunk_type: code
tokens: 296
summary: "Deno / Bun"
---

## Deno / Bun

Windmill [Deno](https://deno.land/) & [Bun](https://bun.sh/) scripts can be run like normal scripts. To add testing or
debugging code, add this snippet to your file:

```ts
if (import.meta.main) {
	// Add your testing & debugging code here.
}
```

You can then use your script like normal (for example,
`deno run -A --watch my_script.ts` / `bun run --watch my_script.ts`), and even write tests inside.

If you'd like to tweak the client settings more directly, use:

```ts
wmill.setClient(<TOKEN>, <API BASE URL>)
```

On import, the wmill client does the following:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
setClient(
	Deno.env.get('WM_TOKEN') ?? 'no_token',
	Deno.env.get('BASE_INTERNAL_URL') ?? 'http://localhost:8000'
);
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
setClient(
	Bun.env.get('WM_TOKEN') ?? 'no_token',
	Bun.env.get('BASE_INTERNAL_URL') ?? 'http://localhost:8000'
);
```

</TabItem>
</Tabs>

which is why we recommend setting those environment variables in the [sections below](#interacting-with-windmill-locally).

For more information on Deno & Bun development in general, see their official doc: [Deno](https://deno.land/manual@v1.36.1/getting_started), [Bun](https://bun.sh/docs).

### Python

Windmill Python scripts can be run like normal Python scripts. To add testing or
debug code, add this snippet to your file:

```py
if __name__ == '__main__':
    # Add your testing & debugging code here.
    pass
```

You can then run your script: `python -m f.folder.my_script` and even write tests inside.

For more information on Python development in general,
[see the official docs](https://www.python.org/doc/).
