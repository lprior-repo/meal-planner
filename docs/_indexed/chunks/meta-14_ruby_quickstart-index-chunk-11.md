---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-11
heading_path: ["Ruby quickstart", "Dependencies management"]
chunk_type: code
tokens: 323
summary: "Dependencies management"
---

## Dependencies management

Ruby dependencies are managed using a `gemfile` block that is fully compatible with bundler/inline syntax. The gemfile block must include a single global source:

```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty', '~> 0.21'
  gem 'redis', '>= 4.0'
  gem 'activerecord', '7.0.0'
  gem 'pg', require: 'pg'
  gem 'dotenv', require: false
end
```

### Private gem sources

You can use private gem repositories using different syntax options:

**Option 1: Per-gem source specification**
```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty'
  gem 'private-gem', source: 'https://gems.example.com'
end
```

**Option 2: Source block syntax**
```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  
  source 'https://gems.example.com' do
    gem 'private-gem-1'
    gem 'private-gem-2'
  end
end
```

For authentication with private sources, specify the source URL without credentials in your script. For [Enterprise Edition](/pricing) users, add the authenticated URL to Ruby repositories in instance settings. Navigate to **Instance Settings > Registries > Ruby Repos** and add:

```yaml
https://admin:123@gems.example.com/
```

![Ruby Private repos Instance Settings](./ruby-gems-instance-settings.png "Ruby Private repos Instance Settings")

Windmill will automatically match the source URL from your script with the authenticated URL from settings and handle authentication seamlessly.

### Network configuration

- **TLS/SSL**: Automatically handled as long as the remote certificate is trusted by the system
- **Proxy**: Proxy environment variables are automatically handled during lockfile generation, gem installation, and runtime stages

Windmill will automatically:
- Parse your gemfile block when you save the script
- Generate a Gemfile and Gemfile.lock
- Install dependencies in an isolated environment
- Cache dependencies for faster execution
