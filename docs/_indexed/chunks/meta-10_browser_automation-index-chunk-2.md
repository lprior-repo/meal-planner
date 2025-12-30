---
doc_id: meta/10_browser_automation/index
chunk_id: meta/10_browser_automation/index#chunk-2
heading_path: ["Browser automation", "Examples"]
chunk_type: code
tokens: 127
summary: "Examples"
---

## Examples

### Playwright (Bun)

```typescript
import { chromium } from "playwright"

export async function main() {
  const browser = await chromium.launch({
    executablePath: "/usr/bin/chromium",
    args: ['--no-sandbox', '--single-process', '--no-zygote', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  });
  
  const page = await browser.newPage();
  await page.goto("https://google.com");

  const title = await page.title();

  await browser.close()
  
  return title
}
```

### Puppeteer (Bun)

```typescript
import puppeteer from "puppeteer-core";

export async function main() {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: "/usr/bin/chromium",
    args: ['--no-sandbox', '--single-process', '--no-zygote', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  });

  const page = await browser.newPage();
  await page.goto("https://google.com");

  const title = await page.title();

  await browser.close();

  return title;
}
```
