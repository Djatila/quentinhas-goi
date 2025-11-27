-- ============================================
-- CORREÇÃO COMPLETA: Todas as políticas RLS
-- Execute este script no Supabase SQL Editor
-- ============================================

-- ============================================
-- PRODUTOS
-- ============================================
DROP POLICY IF EXISTS "Produtos visíveis para autenticados" ON public.produtos;
DROP POLICY IF EXISTS "Produtos inseríveis por autenticados" ON public.produtos;
DROP POLICY IF EXISTS "Produtos atualizáveis por autenticados" ON public.produtos;
DROP POLICY IF EXISTS "Produtos deletáveis por autenticados" ON public.produtos;

CREATE POLICY "Produtos visíveis para autenticados"
  ON public.produtos FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Produtos inseríveis por autenticados"
  ON public.produtos FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Produtos atualizáveis por autenticados"
  ON public.produtos FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Produtos deletáveis por autenticados"
  ON public.produtos FOR DELETE USING (auth.uid() IS NOT NULL);

-- ============================================
-- ITENS_VENDA
-- ============================================
DROP POLICY IF EXISTS "Itens de venda visíveis para autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda inseríveis por autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda atualizáveis por autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda deletáveis por autenticados" ON public.itens_venda;

CREATE POLICY "Itens de venda visíveis para autenticados"
  ON public.itens_venda FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda inseríveis por autenticados"
  ON public.itens_venda FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda atualizáveis por autenticados"
  ON public.itens_venda FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda deletáveis por autenticados"
  ON public.itens_venda FOR DELETE USING (auth.uid() IS NOT NULL);

-- ============================================
-- VENDAS
-- ============================================
DROP POLICY IF EXISTS "Vendas visíveis para autenticados" ON public.vendas;
DROP POLICY IF EXISTS "Vendas criáveis por autenticados" ON public.vendas;
DROP POLICY IF EXISTS "Vendas editáveis por quem criou" ON public.vendas;
DROP POLICY IF EXISTS "Vendas deletáveis por quem criou" ON public.vendas;

CREATE POLICY "Vendas visíveis para autenticados"
  ON public.vendas FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Vendas criáveis por autenticados"
  ON public.vendas FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Vendas editáveis por quem criou"
  ON public.vendas FOR UPDATE USING (auth.uid() = criado_por);

CREATE POLICY "Vendas deletáveis por quem criou"
  ON public.vendas FOR DELETE USING (auth.uid() = criado_por);

-- ============================================
-- CLIENTES
-- ============================================
DROP POLICY IF EXISTS "Clientes visíveis para autenticados" ON public.clientes;
DROP POLICY IF EXISTS "Clientes inseríveis por autenticados" ON public.clientes;
DROP POLICY IF EXISTS "Clientes atualizáveis por autenticados" ON public.clientes;
DROP POLICY IF EXISTS "Clientes deletáveis por autenticados" ON public.clientes;

CREATE POLICY "Clientes visíveis para autenticados"
  ON public.clientes FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Clientes inseríveis por autenticados"
  ON public.clientes FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Clientes atualizáveis por autenticados"
  ON public.clientes FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Clientes deletáveis por autenticados"
  ON public.clientes FOR DELETE USING (auth.uid() IS NOT NULL);

-- ============================================
-- DESPESAS
-- ============================================
DROP POLICY IF EXISTS "Despesas visíveis para autenticados" ON public.despesas;
DROP POLICY IF EXISTS "Despesas criáveis por autenticados" ON public.despesas;
DROP POLICY IF EXISTS "Despesas editáveis por quem criou" ON public.despesas;
DROP POLICY IF EXISTS "Despesas deletáveis por quem criou" ON public.despesas;

CREATE POLICY "Despesas visíveis para autenticados"
  ON public.despesas FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Despesas criáveis por autenticados"
  ON public.despesas FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Despesas editáveis por quem criou"
  ON public.despesas FOR UPDATE USING (auth.uid() = criado_por);

CREATE POLICY "Despesas deletáveis por quem criou"
  ON public.despesas FOR DELETE USING (auth.uid() = criado_por);

-- ============================================
-- CATEGORIAS
-- ============================================
DROP POLICY IF EXISTS "Categorias visíveis para todos autenticados" ON public.categorias;
DROP POLICY IF EXISTS "Categorias editáveis por autenticados" ON public.categorias;

CREATE POLICY "Categorias visíveis para todos autenticados"
  ON public.categorias FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Categorias editáveis por autenticados"
  ON public.categorias FOR ALL USING (auth.uid() IS NOT NULL);

-- ============================================
-- FLUXO_CAIXA
-- ============================================
DROP POLICY IF EXISTS "Fluxo visível para autenticados" ON public.fluxo_caixa;

CREATE POLICY "Fluxo visível para autenticados"
  ON public.fluxo_caixa FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================
-- USUÁRIOS
-- ============================================
DROP POLICY IF EXISTS "Usuários veem todos perfis" ON public.usuarios;
DROP POLICY IF EXISTS "Usuários editam próprio perfil" ON public.usuarios;

CREATE POLICY "Usuários veem todos perfis"
  ON public.usuarios FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuários editam próprio perfil"
  ON public.usuarios FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- FIM - Todas as políticas RLS corrigidas!
-- ============================================
