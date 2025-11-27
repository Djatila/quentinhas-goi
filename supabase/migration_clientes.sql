-- ============================================
-- SCRIPT DE ATUALIZAÇÃO: INTEGRAÇÃO DE CLIENTES
-- Execute este script no Supabase SQL Editor
-- ============================================

-- 1. Criar tabela de Clientes
CREATE TABLE IF NOT EXISTS public.clientes (
  id UUID NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  nome TEXT NOT NULL,
  telefone TEXT NOT NULL,
  endereco TEXT,
  bairro TEXT,
  cidade TEXT DEFAULT 'São Paulo',
  cep TEXT,
  observacoes TEXT,
  ativo BOOLEAN DEFAULT true,
  total_pedidos INTEGER DEFAULT 0,
  total_gasto NUMERIC(10,2) DEFAULT 0,
  ultima_compra TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Adicionar campo cliente_id na tabela vendas
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL;

-- 3. Adicionar campo total na tabela vendas (se não existir)
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS total NUMERIC(10,2) GENERATED ALWAYS AS (quantidade * valor) STORED;

-- 4. Habilitar RLS na tabela clientes
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS para clientes
DROP POLICY IF EXISTS "Clientes visíveis para autenticados" ON public.clientes;
CREATE POLICY "Clientes visíveis para autenticados"
  ON public.clientes FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Clientes inseríveis por autenticados" ON public.clientes;
CREATE POLICY "Clientes inseríveis por autenticados"
  ON public.clientes FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Clientes atualizáveis por autenticados" ON public.clientes;
CREATE POLICY "Clientes atualizáveis por autenticados"
  ON public.clientes FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Clientes deletáveis por autenticados" ON public.clientes;
CREATE POLICY "Clientes deletáveis por autenticados"
  ON public.clientes FOR DELETE
  TO authenticated
  USING (true);

-- 6. Criar função para atualizar estatísticas do cliente
CREATE OR REPLACE FUNCTION public.atualizar_estatisticas_cliente()
RETURNS TRIGGER AS $$
BEGIN
  -- Atualizar total_pedidos, total_gasto e ultima_compra
  UPDATE public.clientes
  SET 
    total_pedidos = (
      SELECT COUNT(*) 
      FROM public.vendas 
      WHERE cliente_id = NEW.cliente_id
    ),
    total_gasto = (
      SELECT COALESCE(SUM(quantidade * valor), 0) 
      FROM public.vendas 
      WHERE cliente_id = NEW.cliente_id
    ),
    ultima_compra = NEW.data,
    updated_at = NOW()
  WHERE id = NEW.cliente_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Criar trigger para atualizar estatísticas do cliente
DROP TRIGGER IF EXISTS trigger_atualizar_estatisticas_cliente ON public.vendas;
CREATE TRIGGER trigger_atualizar_estatisticas_cliente
  AFTER INSERT OR UPDATE ON public.vendas
  FOR EACH ROW
  WHEN (NEW.cliente_id IS NOT NULL)
  EXECUTE FUNCTION public.atualizar_estatisticas_cliente();

-- 8. Inserir alguns clientes de exemplo (OPCIONAL - remova se não quiser)
INSERT INTO public.clientes (nome, telefone, endereco) VALUES
  ('João Silva', '(11) 98765-4321', 'Rua das Flores, 123 - Centro - São Paulo'),
  ('Maria Santos', '(11) 91234-5678', 'Av. Paulista, 456 - Bela Vista - São Paulo'),
  ('Pedro Costa', '(11) 99876-5432', 'Rua Augusta, 789 - Consolação - São Paulo')
ON CONFLICT DO NOTHING;

-- 9. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON public.clientes(telefone);
CREATE INDEX IF NOT EXISTS idx_clientes_nome ON public.clientes(nome);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente_id ON public.vendas(cliente_id);

-- ============================================
-- FIM DO SCRIPT
-- ============================================
