-- Email and other contact fields are left out on purpose: nothing downstream needs them.
select
    id as user_id,
    display_name,
    jellyfin_username,
    cast(created_at as timestamptz) as created_at
from {{ source('trakt', 'users') }}
