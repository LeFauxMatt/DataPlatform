-- One row per movie or series known to the library apps or to Jellyfin. A title in Jellyfin alone was added by hand;
-- one in a library app alone hasn't been downloaded, or Jellyfin hasn't scanned it yet.
select
    coalesce(l.title_key, j.title_key) as title_key,
    coalesce(l.media_type, j.media_type) as media_type,
    coalesce(l.tmdb_id, j.tmdb_id) as tmdb_id,
    coalesce(l.title, j.title) as title,
    coalesce(l.release_year, j.release_year) as release_year,
    l.library_id,
    j.jellyfin_item_id,
    l.title_key is not null as is_in_library,
    coalesce(l.is_downloaded, j.title_key is not null) as is_downloaded,
    coalesce(l.size_on_disk_bytes, 0) as size_on_disk_bytes,
    round(coalesce(l.size_on_disk_bytes, 0) / 1e9, 2) as size_on_disk_gb,
    coalesce(l.added_at, j.added_at) as added_at
from {{ ref('int_library_titles') }} as l
full outer join {{ ref('int_jellyfin_titles') }} as j on l.title_key = j.title_key
where coalesce(l.title_key, j.title_key) is not null
