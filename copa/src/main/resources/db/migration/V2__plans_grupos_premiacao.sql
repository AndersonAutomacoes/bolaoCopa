SET client_min_messages TO WARNING;

ALTER TABLE app_users ADD COLUMN IF NOT EXISTS plan_tier varchar(20) NOT NULL DEFAULT 'BRONZE';
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS plan_valid_until timestamp with time zone;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS plan_source varchar(30) DEFAULT 'MANUAL';

DO $$
BEGIN
    ALTER TABLE app_users ADD CONSTRAINT ck_app_users_plan_tier CHECK (plan_tier IN ('BRONZE', 'PRATA', 'OURO'));
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS plan_orders (
    id bigserial primary key,
    user_id bigint not null,
    requested_tier varchar(20) not null,
    amount_cents bigint not null,
    status varchar(20) not null,
    external_ref varchar(255),
    notes text,
    created_at timestamp with time zone not null default now(),
    constraint fk_plan_orders_user foreign key (user_id) references app_users(id) on delete cascade,
    constraint ck_plan_orders_tier check (requested_tier in ('PRATA', 'OURO')),
    constraint ck_plan_orders_status check (status in ('PENDENTE', 'PAGO', 'CANCELADO'))
);

CREATE INDEX IF NOT EXISTS ix_plan_orders_user_id ON plan_orders (user_id);

CREATE TABLE IF NOT EXISTS bolao_grupos (
    id bigserial primary key,
    owner_user_id bigint not null,
    nome varchar(120) not null,
    codigo_convite varchar(32) not null unique,
    created_at timestamp with time zone not null default now(),
    constraint fk_bolao_grupos_owner foreign key (owner_user_id) references app_users(id) on delete cascade
);

CREATE INDEX IF NOT EXISTS ix_bolao_grupos_owner ON bolao_grupos (owner_user_id);

CREATE TABLE IF NOT EXISTS bolao_grupo_membros (
    bolao_id bigint not null,
    user_id bigint not null,
    joined_at timestamp with time zone not null default now(),
    primary key (bolao_id, user_id),
    constraint fk_bgm_bolao foreign key (bolao_id) references bolao_grupos(id) on delete cascade,
    constraint fk_bgm_user foreign key (user_id) references app_users(id) on delete cascade
);

CREATE INDEX IF NOT EXISTS ix_bolao_grupo_membros_user ON bolao_grupo_membros (user_id);

CREATE TABLE IF NOT EXISTS premiacao_regras (
    id bigserial primary key,
    owner_user_id bigint not null,
    nome varchar(120) not null,
    escopo varchar(20) not null,
    jogo_id bigint,
    qtd_premiados integer not null,
    valor_total_centavos bigint not null,
    created_at timestamp with time zone not null default now(),
    constraint fk_premiacao_owner foreign key (owner_user_id) references app_users(id) on delete cascade,
    constraint fk_premiacao_jogo foreign key (jogo_id) references jogos(id) on delete set null,
    constraint ck_premiacao_escopo check (escopo in ('CAMPEONATO', 'JOGO')),
    constraint ck_premiacao_qtd check (qtd_premiados > 0),
    constraint ck_premiacao_valor check (valor_total_centavos >= 0)
);

CREATE INDEX IF NOT EXISTS ix_premiacao_regras_owner ON premiacao_regras (owner_user_id);

CREATE TABLE IF NOT EXISTS premiacao_pagamentos (
    id bigserial primary key,
    regra_id bigint not null,
    user_id bigint not null,
    posicao_ranking integer not null,
    status varchar(20) not null,
    observacao text,
    updated_at timestamp with time zone not null default now(),
    constraint fk_pp_regra foreign key (regra_id) references premiacao_regras(id) on delete cascade,
    constraint fk_pp_user foreign key (user_id) references app_users(id) on delete cascade,
    constraint ck_pp_status check (status in ('PENDENTE', 'PAGO', 'CANCELADO'))
);

CREATE INDEX IF NOT EXISTS ix_premiacao_pag_regra ON premiacao_pagamentos (regra_id);

RESET client_min_messages;
