-- A singular test: returns the plays whose length is impossible (negative, or a whole day or more),
-- which would mean Jellystat lost a session's stop event. Warns rather than fails: the play is still real.
{{ config(severity='warn') }}

select play_id, played_at, watched_minutes
from {{ ref('fct_plays') }}
where watched_minutes < 0 or watched_minutes >= 24 * 60
