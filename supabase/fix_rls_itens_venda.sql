-- ============================================
-- CORREÇÃO: Políticas RLS para itens_venda
-- Execute este script no Supabase SQL Editor
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "Itens de venda visíveis para autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda inseríveis por autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda atualizáveis por autenticados" ON public.itens_venda;
DROP POLICY IF EXISTS "Itens de venda deletáveis por autenticados" ON public.itens_venda;

-- Criar políticas corretas (sem usar auth.role())
CREATE POLICY "Itens de venda visíveis para autenticados"
  ON public.itens_venda 
  FOR SELECT 
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda inseríveis por autenticados"
  ON public.itens_venda 
  FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda atualizáveis por autenticados"
  ON public.itens_venda 
  FOR UPDATE 
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Itens de venda deletáveis por autenticados"
  ON public.itens_venda 
  FOR DELETE 
  USING (auth.uid() IS NOT NULL);

-- ============================================
-- FIM - Políticas RLS corrigidas!
-- ============================================
