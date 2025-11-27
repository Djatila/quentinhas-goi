-- ============================================
-- MIGRAÇÃO: Sistema Dual de Clientes (Atualizado)
-- ============================================
-- Este script adiciona suporte para dois tipos de clientes:
-- 1. Cliente Crédito (autenticado via Supabase Auth)
-- 2. Cliente Informal (apenas nome e telefone)

-- 1. Adicionar novas colunas à tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS tipo_cliente TEXT NOT NULL DEFAULT 'informal' CHECK (tipo_cliente IN ('credito', 'informal')),
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS limite_credito NUMERIC(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS credito_utilizado NUMERIC(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'bloqueado'));

-- 2. Adicionar cliente_id em pedidos_online
ALTER TABLE public.pedidos_online
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL;

-- 3. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_clientes_tipo ON public.clientes(tipo_cliente);
CREATE INDEX IF NOT EXISTS idx_clientes_user_id ON public.clientes(user_id);
CREATE INDEX IF NOT EXISTS idx_clientes_status ON public.clientes(status);
CREATE INDEX IF NOT EXISTS idx_pedidos_online_cliente_id ON public.pedidos_online(cliente_id);

-- 4. Atualizar políticas RLS para clientes

-- Permitir clientes autenticados verem seus próprios dados
DROP POLICY IF EXISTS "Clientes podem ver próprios dados" ON public.clientes;
CREATE POLICY "Clientes podem ver próprios dados"
  ON public.clientes FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR auth.uid() IN (SELECT id FROM public.usuarios) -- Admin pode ver todos
  );

-- Permitir inserção de clientes informais (anônimos)
DROP POLICY IF EXISTS "Permitir criação de clientes informais" ON public.clientes;
CREATE POLICY "Permitir criação de clientes informais"
  ON public.clientes FOR INSERT
  TO anon, authenticated
  WITH CHECK (tipo_cliente = 'informal' OR user_id = auth.uid());

-- Clientes podem atualizar próprios dados
DROP POLICY IF EXISTS "Clientes podem atualizar próprios dados" ON public.clientes;
CREATE POLICY "Clientes podem atualizar próprios dados"
  ON public.clientes FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR auth.uid() IN (SELECT id FROM public.usuarios) -- Admin pode atualizar
  );

-- 5. Políticas RLS para pedidos (clientes podem ver seus próprios pedidos)
DROP POLICY IF EXISTS "Clientes podem ver próprios pedidos" ON public.pedidos_online;
CREATE POLICY "Clientes podem ver próprios pedidos"
  ON public.pedidos_online FOR SELECT
  TO authenticated
  USING (
    cliente_id IN (
      SELECT id FROM public.clientes WHERE user_id = auth.uid()
    )
    OR auth.uid() IN (SELECT id FROM public.usuarios) -- Admin pode ver todos
  );

-- 6. Função para atualizar estatísticas quando pedido é criado
CREATE OR REPLACE FUNCTION public.atualizar_estatisticas_cliente_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.cliente_id IS NOT NULL THEN
    UPDATE public.clientes
    SET 
      total_pedidos = total_pedidos + 1,
      total_gasto = total_gasto + NEW.total,
      ultima_compra = NEW.created_at,
      updated_at = NOW()
    WHERE id = NEW.cliente_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger para atualizar estatísticas
DROP TRIGGER IF EXISTS trigger_atualizar_estatisticas_cliente_pedido ON public.pedidos_online;
CREATE TRIGGER trigger_atualizar_estatisticas_cliente_pedido
  AFTER INSERT ON public.pedidos_online
  FOR EACH ROW
  WHEN (NEW.cliente_id IS NOT NULL)
  EXECUTE FUNCTION public.atualizar_estatisticas_cliente_pedido();

-- 8. Função RPC para verificar elegibilidade de cadastro
-- Retorna true se o telefone existe e está marcado como 'credito' (pré-aprovado)
CREATE OR REPLACE FUNCTION public.check_credit_eligibility(phone_number text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  is_eligible boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM public.clientes 
    WHERE telefone = phone_number 
    AND tipo_cliente = 'credito'
  ) INTO is_eligible;
  
  RETURN is_eligible;
END;
$$;

-- 9. Função para vincular cliente existente ao novo usuário (trigger no auth.users)
CREATE OR REPLACE FUNCTION public.handle_new_customer()
RETURNS TRIGGER AS $$
DECLARE
  customer_role TEXT;
  customer_phone TEXT;
  existing_client_id UUID;
BEGIN
  -- Verificar se é um cliente (não admin)
  customer_role := NEW.raw_user_meta_data->>'role';
  customer_phone := NEW.raw_user_meta_data->>'telefone';
  
  IF customer_role = 'cliente' THEN
    -- Tentar encontrar cliente existente pelo telefone e tipo 'credito'
    SELECT id INTO existing_client_id
    FROM public.clientes
    WHERE telefone = customer_phone
    AND tipo_cliente = 'credito'
    LIMIT 1;

    IF existing_client_id IS NOT NULL THEN
      -- Atualizar cliente existente com o user_id
      UPDATE public.clientes
      SET 
        user_id = NEW.id,
        nome = COALESCE(NEW.raw_user_meta_data->>'nome', nome), -- Atualizar nome se fornecido
        endereco = COALESCE(NEW.raw_user_meta_data->>'endereco', endereco), -- Atualizar endereço se fornecido
        updated_at = NOW()
      WHERE id = existing_client_id;
    ELSE
      -- SE NÃO ENCONTRAR:
      -- Opção A: Bloquear (Raise Exception) - Isso cancelaria o SignUp
      -- Opção B: Criar novo (mas o requisito diz que não pode)
      -- Como o frontend já deve ter validado, aqui é uma segurança extra.
      -- Vamos lançar erro para garantir a regra de negócio.
      RAISE EXCEPTION 'Cliente não autorizado para cadastro crédito. Telefone não encontrado ou não elegível.';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Trigger para vincular cliente automaticamente
DROP TRIGGER IF EXISTS on_auth_customer_created ON auth.users;
CREATE TRIGGER on_auth_customer_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_customer();

-- 11. Comentários para documentação
COMMENT ON COLUMN public.clientes.tipo_cliente IS 'Tipo de cliente: credito (autenticado) ou informal (sem login)';
COMMENT ON COLUMN public.clientes.user_id IS 'ID do usuário no auth.users (apenas para clientes crédito)';
COMMENT ON FUNCTION public.check_credit_eligibility IS 'Verifica se um telefone está pré-aprovado para cadastro crédito';

-- ============================================
-- FIM DA MIGRAÇÃO
-- ============================================
