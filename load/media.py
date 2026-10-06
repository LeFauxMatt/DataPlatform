"""Load raw media data from the homelab's apps into DuckDB with dlt.

Each app lands in its own schema of the DuckDB file: raw_tvdb, raw_imdb, raw_trakt, raw_jellyfin and
raw_jellystat. dbt reads them as sources (transform/models/staging).

Usage: uv run load/media.py [app ...]      (default: every app)

Every app needs <APP>_URL and <APP>_API_KEY in the environment, e.g. TVDB_URL=https://tvdb.example.ts.net.
CI reads the keys from Infisical; locally, `mise run load` does the same (see README).
The DuckDB file is DUCKDB_PATH, default data/media.duckdb.
"""

import os
import sys
from pathlib import Path

import dlt
from dlt.sources.helpers.rest_client import RESTClient
from dlt.sources.helpers.rest_client.auth import APIKeyAuth
from dlt.sources.helpers.rest_client.paginators import (
    OffsetPaginator,
    PageNumberPaginator,
    SinglePagePaginator,
)

DUCKDB_PATH = os.environ.get("DUCKDB_PATH", str(Path(__file__).resolve().parent.parent / "data" / "media.duckdb"))
EPOCH = "2000-01-01T00:00:00Z"


def env(app: str, name: str) -> str:
    key = f"{app.upper()}_{name}"
    value = os.environ.get(key)
    if not value:
        sys.exit(f"{key} is not set (see README: Credentials)")
    return value


def client(app: str, auth: APIKeyAuth) -> RESTClient:
    return RESTClient(base_url=env(app, "URL").rstrip("/"), auth=auth)


# tvdb (TV) and imdb (movies) are two library apps sharing one API (v3): a full library listing plus an
# event history.
# History is loaded incrementally: /history/since returns every event after a date, unpaginated,
# and dlt keeps the newest date it has seen as the next run's start.


def library_source(app: str, library: str, include: str):
    api = client(app, APIKeyAuth(name="X-Api-Key", api_key=env(app, "API_KEY")))

    # max_table_nesting=0 everywhere: nested objects and lists (statistics, quality, images) land as JSON
    # columns with the API's own camelCase keys, and the staging models pick out what they need.
    @dlt.resource(name=library, primary_key="id", write_disposition="replace", max_table_nesting=0)
    def library_items():
        yield from api.paginate(f"/api/v3/{library}", paginator=SinglePagePaginator())

    @dlt.resource(name="history", primary_key="id", write_disposition="merge", max_table_nesting=0)
    def history(date=dlt.sources.incremental("date", initial_value=EPOCH)):
        yield from api.paginate(
            "/api/v3/history/since",
            params={"date": date.last_value, include: "true"},
            paginator=SinglePagePaginator(),
        )

    return [library_items, history]


def tvdb():
    return library_source("tvdb", "series", "includeEpisode")


def imdb():
    return library_source("imdb", "movie", "includeMovie")


# trakt, the request app: who asked for what. Paged by take/skip; pageInfo.results is the total.


def trakt():
    api = client("trakt", APIKeyAuth(name="X-Api-Key", api_key=env("trakt", "API_KEY")))

    def paged(path: str, **params):
        return api.paginate(
            path,
            params=params,
            paginator=OffsetPaginator(
                limit=100, offset_param="skip", limit_param="take", total_path="pageInfo.results"
            ),
            data_selector="results",
        )

    @dlt.resource(name="requests", primary_key="id", write_disposition="replace", max_table_nesting=0)
    def requests():
        yield from paged("/api/v1/request", filter="all", sort="added")

    @dlt.resource(name="users", primary_key="id", write_disposition="replace", max_table_nesting=0)
    def users():
        yield from paged("/api/v1/user")

    return [requests, users]


# Jellyfin: every movie, series and episode, with the TMDB/TVDB/IMDb ids that join it to the library apps and trakt.


def jellyfin():
    token = env("jellyfin", "API_KEY")
    api = client("jellyfin", APIKeyAuth(name="Authorization", api_key=f'MediaBrowser Token="{token}"'))

    @dlt.resource(name="items", primary_key="id", write_disposition="replace", max_table_nesting=0)
    def items():
        yield from api.paginate(
            "/Items",
            params={
                "Recursive": "true",
                "IncludeItemTypes": "Movie,Series,Episode",
                "Fields": "ProviderIds,DateCreated,Path",
            },
            paginator=OffsetPaginator(
                limit=500, offset_param="StartIndex", limit_param="Limit", total_path="TotalRecordCount"
            ),
            data_selector="Items",
        )

    return [items]


# Jellystat: Jellyfin's playback history. /api/getHistory groups plays by (item, episode, user) and nests
# each group's individual plays under `results`; this yields the plays themselves, one row each.
# A movie's group comes back with `results: null` and only its latest play (Jellystat groups on
# COALESCE(EpisodeId, '1') but joins back on the raw, null EpisodeId), so movies' plays come from
# /api/getItemHistory instead: every play of one item, all users, unnested.


def jellystat():
    api = client("jellystat", APIKeyAuth(name="x-api-token", api_key=env("jellystat", "API_KEY")))

    def pages(path: str, **kwargs):
        return api.paginate(
            path,
            params={"size": 500},
            paginator=PageNumberPaginator(base_page=1, page_param="page", total_path="pages"),
            data_selector="results",
            **kwargs,
        )

    @dlt.resource(name="plays", primary_key="Id", write_disposition="merge", max_table_nesting=0)
    def plays():
        ungrouped = set()
        for page in pages("/api/getHistory"):
            for group in page:
                if group.get("results") is None:
                    ungrouped.add(group["NowPlayingItemId"])
                else:
                    yield from group["results"]
        for item_id in sorted(ungrouped):
            for page in pages("/api/getItemHistory", method="POST", json={"itemid": item_id}):
                yield from page

    return [plays]


SOURCES = {"tvdb": tvdb, "imdb": imdb, "trakt": trakt, "jellyfin": jellyfin, "jellystat": jellystat}


def main(apps: list[str]) -> None:
    unknown = set(apps) - SOURCES.keys()
    if unknown:
        sys.exit(f"unknown app(s): {', '.join(sorted(unknown))}; choose from {', '.join(SOURCES)}")
    Path(DUCKDB_PATH).parent.mkdir(parents=True, exist_ok=True)
    for app in apps or SOURCES:
        pipeline = dlt.pipeline(
            pipeline_name=f"media_{app}",
            destination=dlt.destinations.duckdb(DUCKDB_PATH),
            dataset_name=f"raw_{app}",
        )
        print(pipeline.run(SOURCES[app]()))


if __name__ == "__main__":
    main(sys.argv[1:])
