# dbt-workshop

A dbt workshop project targeted primarily at **Snowflake**. It builds a star schema
(staging → intermediate → marts) from the TPC-H practice dataset, running on the dbt
Fusion engine — either locally or natively as a dbt Projects on Snowflake object.

See `CLAUDE.md` for model layer conventions, reuse rules, and testing standards.

## Deployment

Get the project running in an **editable Snowflake Workspace** on a fresh account — the place to work live on the
models. A stable, deployed project object (for scheduling etc.) is optional; see the note at the end.

### Prerequisites

- A role with `ACCOUNTADMIN`, or at least: `CREATE INTEGRATION` (account-level, for API/External
  Access integrations), `CREATE NETWORK RULE` on the target schema, `CREATE SCHEMA` on the target
  database
- An active virtual warehouse (any size is fine for the workshop)
- An existing target database — replace `<your_database>` / `<your_schema>` throughout with your
  real names (the schema itself is created in step 1)

### 1. One-time account setup (SQL)

```sql
-- schema
CREATE SCHEMA IF NOT EXISTS <your_database>.<your_schema>;

-- network access for `dbt deps` (Snowflake blocks outbound access by default)
CREATE
OR REPLACE NETWORK RULE <your_database>.<your_schema>.DBT_HUB_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE
OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_ACCESS_INTEGRATION
  ALLOWED_NETWORK_RULES = (<your_database>.<your_schema>.DBT_HUB_NETWORK_RULE)
  ENABLED = TRUE;

-- GitHub access (repo is public, no secret/PAT needed)
CREATE
OR REPLACE API INTEGRATION GITHUB_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/stefannegele/')
  ENABLED = TRUE;
```

For a private repo, also create a `SECRET` (personal access token) and reference it when creating
the API integration.

### 2. Create a Git Workspace (Snowsight UI, per person)

No SQL command links a Workspace to a git branch — each participant does this once in Snowsight:

1. **Projects → Workspaces → "+ Add new" → "Git Workspace"** (not "Private" or "Shared")
2. Repository URL `https://github.com/stefannegele/dbt-workshop`, branch `main`
3. API integration: the `GITHUB_API_INTEGRATION` created above
4. Under **"Advanced options"**, pick the dbt version directly — set it to Fusion
   (`2.0.0-preview.186`)

dbt features (run/test/build, DAG view) activate automatically once Snowflake finds
`dbt_project.yml` at the repo root.

> Prefer not to set this per workspace? Set an account-wide default instead, applied to any new
> workspace/project that doesn't set one explicitly (requires `ACCOUNTADMIN`):
> ```sql
> ALTER ACCOUNT SET DEFAULT_DBT_VERSION = '2.0.0-preview.186';
> ```

### 3. Run `dbt deps`

In the Workspace editor's run menu, select **Deps**. Since this needs outbound network access, an
extra **"External Access Integration"** field appears — set it to `DBT_HUB_ACCESS_INTEGRATION`
*before* running. Leaving it blank fails with:

```
Ensure you have selected a valid external access integration.
```

...even though the integration already exists — it isn't pre-filled automatically.

### 4. Check `profiles.yml`

Confirm it points at the right target database/schema/warehouse (see repo). `account`/`user` can
stay blank — execution runs under the logged-in user's session.

From here on, `dbt run` / `dbt build` work as usual in the Workspace editor.

### Notes

- **Deployed project object (optional):** for a stable, schedulable snapshot (e.g. a Snowflake Task
  or a demo), the project can also be deployed directly from a git repository stage via SQL,
  independent of any Workspace. Ask if this is needed.
