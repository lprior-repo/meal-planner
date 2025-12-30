---
doc_id: ref/fatsecret/guides-parameters
chunk_id: ref/fatsecret/guides-parameters#chunk-6
heading_path: ["FatSecret Platform API - Parameters Reference", "Date Calculation"]
chunk_type: prose
tokens: 68
summary: "Date Calculation"
---

## Date Calculation

FatSecret uses "days since epoch" for date parameters. To convert:

```python
from datetime import date

def to_fatsecret_date(d):
    """Convert a date to FatSecret days-since-epoch format."""
    epoch = date(1970, 1, 1)
    return (d - epoch).days

def from_fatsecret_date(days):
    """Convert FatSecret days-since-epoch to a date."""
    epoch = date(1970, 1, 1)
    return epoch + timedelta(days=days)
