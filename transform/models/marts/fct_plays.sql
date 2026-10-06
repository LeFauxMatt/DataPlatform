-- One row per playback session. An episode's play is attributed to its series' title.
with plays as (
    select * from {{ ref('stg_jellystat__plays') }}
),

items as (
    select * from {{ ref('stg_jellyfin__items') }}
)

select
    p.play_id,
    p.played_at,
    cast(p.played_at as date) as played_date,
    p.user_name,
    {{ title_key('t.item_type', 't.tmdb_id') }} as title_key,
    coalesce(t.item_type, case when p.episode_id is null then 'movie' else 'series' end) as media_type,
    coalesce(t.name, p.series_name, p.item_name) as title,
    e.season_number,
    e.episode_number,
    p.client,
    p.device_name,
    p.play_method,
    coalesce(p.play_method ilike 'transcode%', false) as is_transcode,
    round(p.duration_seconds / 60.0, 1) as watched_minutes
from plays as p
left join items as e on p.episode_id = e.item_id
left join items as t on t.item_id = coalesce(e.series_id, p.now_playing_item_id)
