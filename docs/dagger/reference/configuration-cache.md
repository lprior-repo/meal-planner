# Cache Configuration

Dagger caches three types of data:

1. **Layers**: Build instructions and the results of some API calls
2. **Volumes**: Contents of a Dagger filesystem volume, persisted across Dagger Engine sessions
3. **Function calls**: Values returned by calling a function in a module

## Cache Inspection

Show all cache entry metadata:
```bash
dagger core engine local-cache entry-set entries
```

Show high level summaries of cache usage:
```bash
dagger core engine local-cache entry-set
```

## Garbage Collection

The cache garbage collector runs in the background, looking for unused layers and artifacts, and clears them up once they exceed the storage allowed by the cache policy.

The default cache policy attempts to keep the long-term cache storage under 75% of the total disk, while ensuring at least 20% of the disk remains free.

The cache policy can be manually configured using the engine config.

## Manual Pruning

Remove all cache entries not currently being used:
```bash
dagger core engine local-cache prune
```

Prune following the configured cache garbage collection policy:
```bash
dagger core engine local-cache prune --use-default-policy
```
