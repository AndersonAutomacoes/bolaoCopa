-- Evita NOTICE "relação ... já existe" ao reexecutar manualmente (IF NOT EXISTS).
-- Na primeira aplicação pelo Flyway não altera o comportamento útil.
SET client_min_messages TO WARNING;

-- Core auth tables (compatible with existing Spring Security entities)
create table if not exists app_users (
    id bigserial primary key,
    email varchar(255) not null unique,
    password varchar(255) not null,
    roles varchar(255) not null,
    mfa_enabled boolean not null default false,
    totp_secret varchar(255)
);

create table if not exists refresh_tokens (
    id bigserial primary key,
    token_id varchar(255) not null unique,
    family_id varchar(255) not null,
    parent_token_id varchar(255),
    user_id bigint not null,
    created_at timestamp with time zone not null,
    expires_at timestamp with time zone not null,
    last_used_at timestamp with time zone,
    created_by_ip varchar(255),
    last_used_ip varchar(255),
    user_agent varchar(500),
    revoked boolean not null default false,
    replaced_by_token_id varchar(255),
    revoked_reason varchar(255),
    constraint fk_refresh_tokens_user_id
        foreign key (user_id) references app_users(id)
);

create index if not exists ix_refresh_tokens_family_id
    on refresh_tokens (family_id);

create index if not exists ix_refresh_tokens_user_id
    on refresh_tokens (user_id);

-- Profile extension for betting/ranking fields requested by the business
create table if not exists user_profiles (
    user_id bigint primary key,
    full_name varchar(150) not null,
    idade integer not null check (idade >= 13),
    sexo varchar(20) not null,
    telefone varchar(30) not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_user_profiles_user_id
        foreign key (user_id) references app_users(id) on delete cascade
);

create index if not exists ix_user_profiles_full_name
    on user_profiles (full_name);

-- Copa domain
create table if not exists selecoes (
    id bigserial primary key,
    nome varchar(120) not null unique,
    bandeira_url text not null,
    created_at timestamp with time zone not null default now()
);

create table if not exists jogos (
    id bigserial primary key,
    fifa_match_id varchar(100) unique,
    fase varchar(60) not null,
    rodada varchar(60),
    estadio varchar(120),
    kickoff_at timestamp with time zone not null,
    selecao_casa_id bigint not null,
    selecao_fora_id bigint not null,
    gols_casa integer check (gols_casa >= 0),
    gols_fora integer check (gols_fora >= 0),
    status varchar(20) not null default 'SCHEDULED',
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_jogos_selecao_casa
        foreign key (selecao_casa_id) references selecoes(id),
    constraint fk_jogos_selecao_fora
        foreign key (selecao_fora_id) references selecoes(id),
    constraint ck_jogos_selecoes_diferentes
        check (selecao_casa_id <> selecao_fora_id),
    constraint ck_jogos_status
        check (status in ('SCHEDULED', 'IN_PROGRESS', 'FINISHED'))
);

create index if not exists ix_jogos_kickoff_at
    on jogos (kickoff_at);

create index if not exists ix_jogos_status
    on jogos (status);

create table if not exists palpites (
    id bigserial primary key,
    user_id bigint not null,
    jogo_id bigint not null,
    gols_casa_palpite integer not null check (gols_casa_palpite >= 0),
    gols_fora_palpite integer not null check (gols_fora_palpite >= 0),
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_palpites_user_id
        foreign key (user_id) references app_users(id) on delete cascade,
    constraint fk_palpites_jogo_id
        foreign key (jogo_id) references jogos(id) on delete cascade,
    constraint uk_palpites_user_jogo unique (user_id, jogo_id)
);

create index if not exists ix_palpites_jogo_id
    on palpites (jogo_id);

create index if not exists ix_palpites_created_at
    on palpites (created_at);

create table if not exists pontuacoes_palpite (
    id bigserial primary key,
    palpite_id bigint not null unique,
    pontos integer not null check (pontos in (0, 3, 5)),
    acerto_exato boolean not null default false,
    processado_em timestamp with time zone not null default now(),
    constraint fk_pontuacoes_palpite_palpite_id
        foreign key (palpite_id) references palpites(id) on delete cascade
);

create index if not exists ix_pontuacoes_palpite_pontos
    on pontuacoes_palpite (pontos);

-- Ranking view with tie-break:
-- 1) total_pontos DESC
-- 2) total_acertos_exatos DESC
-- 3) primeiro_palpite_em ASC
create or replace view v_ranking_usuarios as
with agg as (
    select
        p.user_id,
        coalesce(sum(pp.pontos), 0)::int as total_pontos,
        coalesce(sum(case when pp.acerto_exato then 1 else 0 end), 0)::int as total_acertos_exatos,
        min(p.created_at) as primeiro_palpite_em
    from palpites p
    left join pontuacoes_palpite pp
        on pp.palpite_id = p.id
    group by p.user_id
)
select
    u.id as user_id,
    u.email,
    up.full_name as nome,
    a.total_pontos,
    a.total_acertos_exatos,
    a.primeiro_palpite_em,
    row_number() over (
        order by
            a.total_pontos desc,
            a.total_acertos_exatos desc,
            a.primeiro_palpite_em asc,
            u.id asc
    ) as posicao
from agg a
join app_users u on u.id = a.user_id
left join user_profiles up on up.user_id = u.id
order by
    a.total_pontos desc,
    a.total_acertos_exatos desc,
    a.primeiro_palpite_em asc,
    u.id asc;

drop materialized view if exists mv_ranking_usuarios;

create materialized view mv_ranking_usuarios as
with agg as (
    select
        p.user_id,
        coalesce(sum(pp.pontos), 0)::int as total_pontos,
        coalesce(sum(case when pp.acerto_exato then 1 else 0 end), 0)::int as total_acertos_exatos,
        min(p.created_at) as primeiro_palpite_em
    from palpites p
    left join pontuacoes_palpite pp
        on pp.palpite_id = p.id
    group by p.user_id
)
select
    u.id as user_id,
    u.email,
    up.full_name as nome,
    a.total_pontos,
    a.total_acertos_exatos,
    a.primeiro_palpite_em,
    row_number() over (
        order by
            a.total_pontos desc,
            a.total_acertos_exatos desc,
            a.primeiro_palpite_em asc,
            u.id asc
    ) as posicao
from agg a
join app_users u on u.id = a.user_id
left join user_profiles up on up.user_id = u.id
order by
    a.total_pontos desc,
    a.total_acertos_exatos desc,
    a.primeiro_palpite_em asc,
    u.id asc;

create unique index if not exists ux_mv_ranking_usuarios_user_id
    on mv_ranking_usuarios (user_id);

create index if not exists ix_mv_ranking_usuarios_ord
    on mv_ranking_usuarios (
        total_pontos desc,
        total_acertos_exatos desc,
        primeiro_palpite_em asc
    );

create or replace function refresh_mv_ranking_usuarios()
returns void
language plpgsql
security definer
as $$
begin
    refresh materialized view concurrently mv_ranking_usuarios;
end;
$$;

RESET client_min_messages;
