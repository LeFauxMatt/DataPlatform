-- Jellyfin's movies and series (not episodes), keyed like the library apps' titles.
select
    {{ title_key('item_type', 'tmdb_id') }} as title_key,
    item_id as jellyfin_item_id,
    item_type as media_type,
    tmdb_id,
    name as title,
    release_year,
    added_at
from {{ ref('stg_jellyfin__items') }}
where item_type in ('movie', 'series') and tmdb_id is not null
qualify row_number() over (partition by title_key order by added_at) = 1
