---
doc_id: ref/fatsecret/api-image-recognition
chunk_id: ref/fatsecret/api-image-recognition#chunk-10
heading_path: ["Image Recognition API v1", "Best Practices"]
chunk_type: prose
tokens: 106
summary: "Best Practices"
---

## Best Practices

1. **Intermediate Screen**: After receiving results, show an intermediate screen allowing users to adjust servings before logging. This improves accuracy and user experience.

2. **Image Quality**: Use clear, well-lit images with the food as the primary subject for best recognition results.

3. **Eaten Foods Context**: Provide `eaten_foods` array when available to improve matching based on user's eating patterns.

4. **Error Handling**: Always handle error 211 gracefully - prompt users to try a different image or use manual food search.
