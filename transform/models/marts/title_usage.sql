-- How much each title is watched against the disk it takes, from its watch history. gb_per_hour_watched is null for a title nobody has watched.
with plays as (
    select
        title_key,
        count(*) as play_count,
        count(distinct user_name) as viewer_count,
        sum(watched_minutes) / 60.0 as hours_watched,
        max(played_at) as last_played_at
    from {{ ref('fct_plays') }}
    where title_key is not null
    group by title_key
)

select
    t.title_key,
    t.title,
    t.media_type,
    t.release_year,
    t.size_on_disk_gb,
    t.added_at,
    coalesce(p.play_count, 0) as play_count,
    coalesce(p.viewer_count, 0) as viewer_count,
    round(coalesce(p.hours_watched, 0), 1) as hours_watched,
    p.last_played_at,
    date_diff('day', coalesce(p.last_played_at, t.added_at), current_timestamp) as days_since_last_activity,
    round(t.size_on_disk_gb / nullif(p.hours_watched, 0), 2) as gb_per_hour_watched
from {{ ref('dim_titles') }} as t
left join plays as p on t.title_key = p.title_key
