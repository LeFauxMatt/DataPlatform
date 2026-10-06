-- One row per trakt request, with how long it took to land in the library and to be watched.
with requests as (
    select
        r.*,
        {{ title_key('r.media_type', 'r.tmdb_id') }} as title_key
    from {{ ref('stg_trakt__requests') }} as r
),

lifecycle as (
    select
        r.request_id,
        min(i.imported_at) as first_imported_at,
        min(p.played_at) as first_played_at
    from requests as r
    left join {{ ref('int_library_imports') }} as i
        on r.title_key = i.title_key and i.imported_at >= r.requested_at
    left join {{ ref('fct_plays') }} as p
        on r.title_key = p.title_key and p.played_at >= r.requested_at
    group by r.request_id
)

select
    r.request_id,
    r.title_key,
    r.media_type,
    r.is_4k,
    u.display_name as requested_by,
    rs.status_name as request_status,
    ms.status_name as media_status,
    r.requested_at,
    l.first_imported_at,
    l.first_played_at,
    round(date_diff('minute', r.requested_at, l.first_imported_at) / 60.0, 1) as hours_to_available,
    round(date_diff('hour', r.requested_at, l.first_played_at) / 24.0, 1) as days_to_first_watch
from requests as r
inner join lifecycle as l on r.request_id = l.request_id
left join {{ ref('stg_trakt__users') }} as u on r.requested_by_user_id = u.user_id
left join {{ ref('trakt_statuses') }} as rs
    on rs.status_kind = 'request' and r.request_status_code = rs.status_code
left join {{ ref('trakt_statuses') }} as ms
    on ms.status_kind = 'media' and r.media_status_code = ms.status_code
