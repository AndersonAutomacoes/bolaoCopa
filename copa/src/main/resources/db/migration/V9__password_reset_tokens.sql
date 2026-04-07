create table if not exists password_reset_tokens (
    id bigserial primary key,
    user_id bigint not null references app_users (id) on delete cascade,
    token_hash varchar(64) not null unique,
    expires_at timestamp with time zone not null,
    used_at timestamp with time zone,
    created_at timestamp with time zone not null default now()
);

create index if not exists ix_password_reset_tokens_user_id
    on password_reset_tokens (user_id);

create index if not exists ix_password_reset_tokens_expires
    on password_reset_tokens (expires_at);
