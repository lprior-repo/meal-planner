---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-10
heading_path: ["Rich display rendering", "GIF"]
chunk_type: code
tokens: 61
summary: "GIF"
---

## GIF

The `gif` key allows returning the value as a GIF.

The gif must be encoded in base64.

```ts
return { "gif": { "content": base64Image } }
```

or

```ts
return { "gif": base64Image }
```
<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/gif.mp4"
/>
