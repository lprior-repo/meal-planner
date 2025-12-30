---
doc_id: ops/commands/overview
chunk_id: ops/commands/overview#chunk-5
heading_path: ["Overview", "Or"]
chunk_type: prose
tokens: 159
summary: "Or"
---

## Or
$ MOON_COLOR=2 moon run app:build
```

When forcing colors with `MOON_COLOR` or `FORCE_COLOR`, you may set it to one of the following numerical values for the desired level of color support. This is automatically inferred if you use `--color`.

-   `0` - No colors
-   `1` - 16 colors (standard terminal colors)
-   `2` - 256 colors
-   `3` - 16 million colors (truecolor)

### Themes (v1.35.0)

By default, moon assumes a dark themed terminal is being used, and will output colors accordingly. However, if you use a light theme, these colors are hard to read. To mitigate this, we support changing the theme with the `--theme` global option, or the `MOON_THEME` environment variable.

```
$ moon run app:build --theme light
