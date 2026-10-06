# DataPlatform

An ELT pipeline over a home media server: **dlt** extracts from the apps' APIs into **DuckDB**, **dbt** models it,
and **Forgejo Actions** runs the whole thing as CI on every change and nightly.

```
tvdb   ─┐
imdb   ─┤                 raw_*              staging          intermediate        marts
trakt  ─┼─ dlt (load/) ─► (JSON as-is) ─► stg_* (typed) ─► int_* (shared) ─► dim_titles, fct_plays,
Jellyfin┤                                                                     fct_requests, title_usage
Jellystat┘
```

The homelab it runs on is drawn in [docs/homelab-map.md](docs/homelab-map.md).

## What it answers

- **fct_requests**: how long a trakt request takes to land in the library (`hours_to_available`) and to be
  watched (`days_to_first_watch`).
- **title_usage**: plays, viewers and hours watched per title against its size on disk (`gb_per_hour_watched`):
  which titles earn their storage.
- **fct_plays** / **dim_titles**: every playback session, joined to one title across five apps by TMDB id.

## Layout

| Path | What |
|---|---|
| `load/media.py` | dlt pipelines, one per app, into schemas `raw_<app>`. Library history loads incrementally. |
| `transform/` | The dbt project: sources, staging, intermediate and mart models, tests, a seed, a unit test. |
| `ci/infisical-env.sh` | CI login to Infisical (machine identity), exporting the API keys masked. |
| `.forgejo/workflows/pipeline.yml` | Load → freshness → `dbt build` → sqlfluff → docs artifact. |
| `mise.toml` | Local tasks: `load`, `build`, `lint`, `docs`. |

## Practices on show

- **ELT with a raw layer**: dlt lands nested API fields as JSON; staging models type and rename them, so an
  API change breaks a model, not the load.
- **Testing at three levels**: generic tests (unique, not_null, relationships, accepted_values), a custom
  generic test (`tests/generic/unique_combination.sql`), a singular test, and a **unit test** of `title_usage`.
- **Source freshness** from dlt's load ids.
- **Secrets never in the repo or CI config**: one Infisical machine identity, read-only on its own project.
- **CI on real data**: every PR builds from an empty warehouse against today's data.

## Running it locally

Needs [uv](https://docs.astral.sh/uv/), [mise](https://mise.jdx.dev/) and the Infisical CLI (logged in).

```sh
uv sync
export INFISICAL_PROJECT_ID=<dataplatform project id>
mise run load      # or: mise run load -- tvdb imdb
mise run build
mise run docs      # http://localhost:8080
```

## Credentials

Infisical project `dataplatform`, environment `prod`, path `/`:

| Key | Value |
|---|---|
| `TVDB_URL`, `TVDB_API_KEY` | The TV library app's API key |
| `IMDB_URL`, `IMDB_API_KEY` | The movie library app's API key |
| `TRAKT_URL`, `TRAKT_API_KEY` | The request app's API key |
| `JELLYFIN_URL`, `JELLYFIN_API_KEY` | Jellyfin → Dashboard → API Keys |
| `JELLYSTAT_URL`, `JELLYSTAT_API_KEY` | Jellystat → Settings → API Keys |

URLs have no trailing slash, e.g. `https://tvdb.example.ts.net`. No data ever goes in git.
