select
    id as item_id,
    lower(type) as item_type,
    name,
    series_id,
    series_name,
    parent_index_number as season_number,
    index_number as episode_number,
    production_year as release_year,
    cast(provider_ids ->> '$.Tmdb' as integer) as tmdb_id,
    cast(provider_ids ->> '$.Tvdb' as integer) as tvdb_id,
    provider_ids ->> '$.Imdb' as imdb_id,
    cast(date_created as timestamptz) as added_at
from {{ source('jellyfin', 'items') }}
