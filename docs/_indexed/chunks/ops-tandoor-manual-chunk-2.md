---
doc_id: ops/tandoor/manual
chunk_id: ops/tandoor/manual#chunk-2
heading_path: ["Manual installation instructions", "Prerequisites"]
chunk_type: prose
tokens: 126
summary: "Prerequisites"
---

## Prerequisites

Setup user: `sudo useradd recipes`

Update the repositories and upgrade your OS: `sudo apt update && sudo apt upgrade -y`

Install all prerequisits `sudo apt install -y git curl python3 python3-pip python3-venv nginx`

Get the last version from the repository: `git clone https://github.com/vabene1111/recipes.git -b master`

Move it to the `/var/www` directory: `mv recipes /var/www`

Change to the directory: `cd /var/www/recipes`

Give the user permissions: `chown -R recipes:www-data /var/www/recipes`

Create virtual env: `python3 -m venv /var/www/recipes`

Activate virtual env: `source /var/www/recipes/bin/activate`

Install Javascript Tools (nodejs >= 12 required)
```shell
### Just use one of these possibilites!
