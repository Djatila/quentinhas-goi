-- Script para corrigir permissões da tabela de configurações
-- Rode este script no Editor SQL do Supabase para permitir salvar a logo e dados

-- 1. Habilitar RLS na tabela configuracoes
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas antigas para limpar
DROP POLICY IF EXISTS "Permitir leitura para todos" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir atualização para autenticados" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir inserção para autenticados" ON public.configuracoes;
DROP POLICY IF EXISTS "Public read access" ON public.configuracoes;
DROP POLICY IF EXISTS "Authenticated update access" ON public.configuracoes;

-- 3. Criar política de leitura pública 
-- (Necessário para o cardápio online ver a logo e nome sem estar logado)
CREATE POLICY "Permitir leitura para todos"
ON public.configuracoes FOR SELECT
TO public
USING (true);

-- 4. Criar política de atualização para usuários autenticados
-- (Permite que você salve as alterações no painel)
CREATE POLICY "Permitir atualização para autenticados"
ON public.configuracoes FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 5. Criar política de inserção
CREATE POLICY "Permitir inserção para autenticados"
ON public.configuracoes FOR INSERT
TO authenticated
WITH CHECK (true);
