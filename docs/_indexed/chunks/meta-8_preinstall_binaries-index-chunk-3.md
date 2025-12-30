---
doc_id: meta/8_preinstall_binaries/index
chunk_id: meta/8_preinstall_binaries/index#chunk-3
heading_path: ["Preinstall binaries", "Example: Installing Puppeteer (via npm)"]
chunk_type: prose
tokens: 109
summary: "Example: Installing Puppeteer (via npm)"
---

## Example: Installing Puppeteer (via npm)

```dockerfile
FROM ghcr.io/windmill-labs/windmill-ee:main

RUN apt update
RUN apt install npm -y
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -y
RUN apt install nodejs libnss3-dev  libatk1.0-0 libatk-bridge2.0-0 libcups2-dev  libdrm-dev libxkbcommon-dev libxcomposite-dev libxdamage-dev libxrandr-dev\
  libgbm-dev libpango-1.0 libcairo-dev libasound-dev -y
RUN npm install -g puppeteer -y

CMD ["windmill"]
```

> Note: The example above uses the enterprise edition (`windmill-ee`) as the base.
