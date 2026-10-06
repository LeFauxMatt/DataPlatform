-- The request app calls series "tv"; this project calls them "series" everywhere.
select
    id as request_id,
    case type when 'tv' then 'series' else type end as media_type,
    cast(media ->> '$.tmdbId' as integer) as tmdb_id,
    cast(media ->> '$.tvdbId' as integer) as tvdb_id,
    status as request_status_code,
    cast(media ->> '$.status' as integer) as media_status_code,
    cast(requested_by ->> '$.id' as integer) as requested_by_user_id,
    is4k as is_4k,
    cast(created_at as timestamptz) as requested_at,
    cast(updated_at as timestamptz) as updated_at
from {{ source('trakt', 'requests') }}
