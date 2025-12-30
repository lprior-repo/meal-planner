---
doc_id: concept/extending/custom-types
chunk_id: concept/extending/custom-types#chunk-1
heading_path: ["custom-types"]
chunk_type: code
tokens: 667
summary: "> **Context**: A Dagger module can have multiple object types defined."
---
# Custom Types

> **Context**: A Dagger module can have multiple object types defined. It's important to understand that they are only accessible through chaining, starting from a f...


A Dagger module can have multiple object types defined. It's important to understand that they are only accessible through chaining, starting from a function in the main object.

**Go:**

Here is an example of a `github` Dagger module, with a function named `DaggerOrganization` that returns a custom `Organization` type, itself containing a collection of `Account` types:

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

func (module *MyModule) DaggerOrganization() *Organization {
	url := "https://github.com/dagger"
	return &Organization{
		URL:          url,
		Repositories: []*dagger.GitRepository{dag.Git(url + "/dagger")},
		Members: []*Account{
			{"jane", "jane@example.com"},
			{"john", "john@example.com"},
		},
	}
}

type Organization struct {
	URL          string
	Repositories []*dagger.GitRepository
	Members      []*Account
}

type Account struct {
	Username string
	Email    string
}

func (account *Account) URL() string {
	return "https://github.com/" + account.Username
}
```

**Python:**

Here is an example of a `github` Dagger module, with a function named `dagger_organization` that returns a custom `Organization` type, itself containing a collection of `Account` types:

```python
import dagger
from dagger import dag, field, function, object_type


@object_type
class Account:
    username: str = field()
    email: str = field()

    @function
    def url(self) -> str:
        return f"https://github.com/{self.username}"


@object_type
class Organization:
    url: str = field()
    repositories: list[dagger.GitRepository] = field()
    members: list[Account] = field()


@object_type
class MyModule:
    @function
    def dagger_organization(self) -> Organization:
        url = "https://github.com/dagger"
        return Organization(
            url=url,
            repositories=[dag.git(f"{url}/dagger")],
            members=[
                Account(username="jane", email="jane@example.com"),
                Account(username="john", email="john@example.com"),
            ],
        )
```

The [`dagger.field`](https://dagger-io.readthedocs.io/en/latest/module.html#dagger.field) descriptors expose getter functions without arguments, for their [attributes](./concept-extending-state.md).

**TypeScript:**

Here is an example of a `github` Dagger module, with a function named `daggerOrganization` that returns a custom `Organization` type, itself containing a collection of `Account` types:

```typescript
import { dag, object, func, GitRepository } from "@dagger.io/dagger"

@object()
class Account {
  @func()
  username: string

  @func()
  email: string

  constructor(username: string, email: string) {
    this.username = username
    this.email = email
  }

  @func()
  url(): string {
    return `https://github.com/${this.username}`
  }
}

/**
 * Organization has no specific methods, only exposed fields so
 * we can define it with `type` instead of `class` to
 * avoid the boilerplate of defining a constructor.
 */
export type Organization = {
  url: string
  repositories: GitRepository[]
  members: Account[]
}

@object()
class MyModule {
  @func()
  daggerOrganization(): Organization {
    const url = "https://github.com/dagger"
    const organization: Organization = {
      url,
      repositories: [dag.git(`${url}/dagger`)],
      members: [
        new Account("jane", "jane@example.com"),
        new Account("john", "john@example.com"),
      ],
    }
    return organization
  }
}
```

TypeScript has multiple ways to support complex data types. Use a `class` when you need methods and privacy, use `type` for plain data objects with only public fields.

> **Note:** When the Dagger Engine extends the Dagger API schema with these types, it prefixes their names with the name of the main object:
>
> - Github
> - GithubAccount
> - GithubOrganization
>
> This is to prevent possible naming conflicts when loading multiple modules, which is reflected in code generation (for example, when using this module in another one as a dependency).

Here's an example of calling a Dagger Function from this module to get all member URLs:

```bash
