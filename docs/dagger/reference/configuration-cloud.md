# Dagger Cloud Configuration

Dagger Cloud is a browser-based interface focused on tracing and debugging Dagger workflows.

## Organizations

A Dagger Cloud "organization" refers to a group of member accounts linked to a single team.

### Create a Dagger Cloud organization

1. Sign up for Dagger Cloud at [dagger.io/cloud](https://www.dagger.io/cloud)
2. Log in with your GitHub account
3. Create your organization (names contain alphanumeric characters and dashes)
4. Review and select a subscription plan

## Traces

### Connect to Dagger Cloud

#### From local development

```bash
dagger login
```

Or set the token directly:

```bash
export DAGGER_CLOUD_TOKEN={your token}
```

#### From CI environment

1. Find your token in Dagger Cloud settings under Tokens
2. Store the token as a secret in your CI environment
3. Add it as `DAGGER_CLOUD_TOKEN` environment variable
4. For GitHub Actions, install the Dagger Cloud GitHub app for GitHub Checks

### Public traces

Dagger Cloud automatically detects if traces originate from a public repository and allows public access without requiring an invitation.

### Make an individual trace public

Admin users can make individual private traces public for sharing.

### Delete a trace

Admin users can delete individual traces.

## Modules

Dagger Cloud lets you see all your organization's modules with metadata like engine versions, descriptions, and linked repositories.

### Add modules

1. Navigate to organization settings -> Git Sources
2. Click "Install the GitHub Application"
3. Select GitHub accounts and repositories
4. Click "Enable module scanning"

### Manage and inspect modules

- View API documentation for each module
- See activity (commits sorted by date)
- Trace dependencies and dependents
- List traces triggered by a module

## Roles and Permissions

| Actions | Admin | Member |
|---------|-------|--------|
| View Dagger workflow runs and changes | | X |
| View members of an org | X | X |
| Invite new members to an org | X | |
| Delete an existing member from an org | X | |
| Make an individual trace public | X | |
| Delete an individual trace | X | |

## Cache Pruning

Navigate to organization settings -> Tokens and click the broom icon to prune the cache for a specific token.
