-- PlaybackDuration is in seconds. For an episode, EpisodeId is the episode's Jellyfin item; for a movie it's null.
select
    id as play_id,
    user_id,
    user_name,
    now_playing_item_id,
    now_playing_item_name as item_name,
    series_name,
    episode_id,
    client,
    device_name,
    play_method,
    playback_duration as duration_seconds,
    cast(activity_date_inserted as timestamptz) as played_at
from {{ source('jellystat', 'plays') }}
