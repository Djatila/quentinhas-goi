-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Tabela de Categorias
create table public.categorias (
  id uuid not null default uuid_generate_v4() primary key,
  nome text not null,
  tipo text not null check (tipo in ('entrada', 'saida')),
  created_at timestamp with time zone default now()
);

-- Tabela de Usuários (Perfil público ligado ao Auth)
create table public.usuarios (
  id uuid references auth.users on delete cascade not null primary key,
  nome text,
  email text,
  created_at timestamp with time zone default now()
);

-- Tabela de Vendas
create table public.vendas (
  id uuid not null default uuid_generate_v4() primary key,
  data timestamp with time zone not null default now(),
  tipo text not null check (tipo in ('local', 'delivery')),
  forma_pagamento text not null,
  quantidade integer not null default 1,
  valor numeric(10,2) not null,
  observacoes text,
  criado_por uuid references public.usuarios(id),
  created_at timestamp with time zone default now()
);

-- Tabela de Despesas
create table public.despesas (
  id uuid not null default uuid_generate_v4() primary key,
  data timestamp with time zone not null default now(),
  categoria text not null, -- Pode ser FK se quiser estrito, mas texto facilita
  descricao text not null,
  valor numeric(10,2) not null,
  fornecedor text,
  criado_por uuid references public.usuarios(id),
  created_at timestamp with time zone default now()
);

-- Tabela de Fluxo de Caixa (Diário)
create table public.fluxo_caixa (
  id uuid not null default uuid_generate_v4() primary key,
  data date not null unique,
  entrada_total numeric(10,2) default 0,
  saida_total numeric(10,2) default 0,
  saldo_do_dia numeric(10,2) default 0,
  saldo_acumulado numeric(10,2) default 0,
  updated_at timestamp with time zone default now()
);

-- RLS (Row Level Security)
alter table public.categorias enable row level security;
alter table public.usuarios enable row level security;
alter table public.vendas enable row level security;
alter table public.despesas enable row level security;
alter table public.fluxo_caixa enable row level security;

-- Policies
-- Categorias: Leitura pública (autenticada), Escrita apenas admin (ou todo mundo autenticado por enquanto)
create policy "Categorias visíveis para todos autenticados" on public.categorias
  for select using (auth.role() = 'authenticated');

create policy "Categorias editáveis por autenticados" on public.categorias
  for all using (auth.role() = 'authenticated');

-- Usuários: Ver e editar o próprio perfil
create policy "Usuários veem todos perfis" on public.usuarios
  for select using (auth.role() = 'authenticated');

create policy "Usuários editam próprio perfil" on public.usuarios
  for update using (auth.uid() = id);

-- Vendas: Apenas autenticados podem ver e criar
create policy "Vendas visíveis para autenticados" on public.vendas
  for select using (auth.role() = 'authenticated');

create policy "Vendas criáveis por autenticados" on public.vendas
  for insert with check (auth.role() = 'authenticated');

create policy "Vendas editáveis por quem criou" on public.vendas
  for update using (auth.uid() = criado_por);

create policy "Vendas deletáveis por quem criou" on public.vendas
  for delete using (auth.uid() = criado_por);

-- Despesas: Mesma lógica de vendas
create policy "Despesas visíveis para autenticados" on public.despesas
  for select using (auth.role() = 'authenticated');

create policy "Despesas criáveis por autenticados" on public.despesas
  for insert with check (auth.role() = 'authenticated');

create policy "Despesas editáveis por quem criou" on public.despesas
  for update using (auth.uid() = criado_por);

create policy "Despesas deletáveis por quem criou" on public.despesas
  for delete using (auth.uid() = criado_por);

-- Fluxo de Caixa: Leitura para todos autenticados
create policy "Fluxo visível para autenticados" on public.fluxo_caixa
  for select using (auth.role() = 'authenticated');

-- Trigger para criar perfil de usuário ao se cadastrar
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.usuarios (id, email, nome)
  values (new.id, new.email, new.raw_user_meta_data->>'nome');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger para atualizar Fluxo de Caixa (Simplificado)
-- Nota: Para um sistema real robusto, recalcular tudo ou usar incrementos é melhor.
-- Aqui faremos uma função que recalcula o dia quando houver insert/update/delete em vendas ou despesas.

create or replace function public.update_fluxo_caixa()
returns trigger as $$
declare
  data_movimento date;
begin
  if (TG_OP = 'DELETE') then
    data_movimento := OLD.data::date;
  else
    data_movimento := NEW.data::date;
  end if;

  -- Upsert no fluxo de caixa para o dia
  insert into public.fluxo_caixa (data) values (data_movimento) on conflict (data) do nothing;

  -- Recalcular totais do dia
  update public.fluxo_caixa
  set 
    entrada_total = (select coalesce(sum(valor), 0) from public.vendas where data::date = data_movimento),
    saida_total = (select coalesce(sum(valor), 0) from public.despesas where data::date = data_movimento),
    saldo_do_dia = (select coalesce(sum(valor), 0) from public.vendas where data::date = data_movimento) - (select coalesce(sum(valor), 0) from public.despesas where data::date = data_movimento)
  where data = data_movimento;

  return null;
end;
$$ language plpgsql security definer;

create trigger on_venda_change
  after insert or update or delete on public.vendas
  for each row execute procedure public.update_fluxo_caixa();

create trigger on_despesa_change
  after insert or update or delete on public.despesas
  for each row execute procedure public.update_fluxo_caixa();

-- Seeds
insert into public.categorias (nome, tipo) values
('Ingredientes', 'saida'),
('Gás', 'saida'),
('Embalagens', 'saida'),
('Entregadores', 'saida'),
('Manutenção', 'saida'),
('Venda Local', 'entrada'),
('Venda Delivery', 'entrada');
