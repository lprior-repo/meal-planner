---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-14
heading_path: ["Rich display rendering", "Map"]
chunk_type: prose
tokens: 59
summary: "Map"
---

## Map

The `map` key allows returning a map with a given location.

```ts
return { "map": { lat: 40, lon: 0, zoom: 3, markers: [{lat: 50.6, lon: 3.1, title: "Home", radius: 5, color: "yellow", strokeWidth: 3, strokeColor: "Black"}]}}
```
![Rich display map](./rich_display_map.png "Rich display map")
