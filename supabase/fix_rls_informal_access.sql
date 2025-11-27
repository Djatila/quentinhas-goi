-- ============================================
-- CORREÇÃO: RLS para Acesso Rápido (Clientes Informais)
-- ============================================

-- 1. Habilitar RLS (garantia)
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas antigas que podem estar conflitando
DROP POLICY IF EXISTS "Permitir criação de clientes informais" ON public.clientes;
DROP POLICY IF EXISTS "Clientes podem ver próprios dados" ON public.clientes;
DROP POLICY IF EXISTS "Clientes podem atualizar próprios dados" ON public.clientes;
DROP POLICY IF EXISTS "Anon can insert informal clients" ON public.clientes;
DROP POLICY IF EXISTS "Anon can select informal clients" ON public.clientes;
DROP POLICY IF EXISTS "Public read access" ON public.clientes;
DROP POLICY IF EXISTS "Public insert access" ON public.clientes;

-- 3. Criar política de INSERT (Permitir criar cliente informal ou autenticado)
CREATE POLICY "Permitir Insert Clientes"
ON public.clientes
FOR INSERT
TO anon, authenticated
WITH CHECK (
  -- Permite se for informal OU se for o próprio usuário autenticado
  tipo_cliente = 'informal' 
  OR 
  user_id = auth.uid()
);

-- 4. Criar política de SELECT (Necessário para retornar o ID após inserir)
-- ATENÇÃO: Isso permite que clientes informais sejam lidos. 
-- Em um ambiente estrito, usaríamos SECURITY DEFINER, mas para este caso resolve o erro.
CREATE POLICY "Permitir Select Clientes"
ON public.clientes
FOR SELECT
TO anon, authenticated
USING (
  tipo_cliente = 'informal' 
  OR 
  user_id = auth.uid()
);

-- 5. Criar política de UPDATE (Apenas para usuários autenticados atualizarem seus dados)
CREATE POLICY "Permitir Update Próprios Dados"
ON public.clientes
FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- 6. Garantir permissões de GRANT para a role anon e authenticated
GRANT SELECT, INSERT, UPDATE ON public.clientes TO anon;
GRANT SELECT, INSERT, UPDATE ON public.clientes TO authenticated;
-- GRANT USAGE, SELECT ON SEQUENCE clientes_id_seq TO anon, authenticated; -- Removido pois usa UUID
