-- ============================================
-- CORREÇÃO: RLS para Produtos (Visibilidade)
-- ============================================

-- 1. Habilitar RLS
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas antigas
DROP POLICY IF EXISTS "Public read access" ON public.produtos;
DROP POLICY IF EXISTS "Produtos visíveis para todos" ON public.produtos;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.produtos;

-- 3. Criar política de SELECT abrangente
-- Permite que qualquer um (anon ou logado) veja produtos ativos
-- Permite que admins (na tabela usuarios) vejam todos os produtos
CREATE POLICY "Produtos visíveis para todos"
ON public.produtos
FOR SELECT
TO anon, authenticated
USING (
  ativo = true 
  OR 
  auth.uid() IN (SELECT id FROM public.usuarios)
);

-- 4. Garantir permissões
GRANT SELECT ON public.produtos TO anon;
GRANT SELECT ON public.produtos TO authenticated;
