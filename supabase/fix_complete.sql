-- ============================================
-- SCRIPT DE CORREÇÃO COMPLETA DO BANCO DE DADOS
-- Execute este script no Supabase SQL Editor
-- Data: 2025-11-21
-- ============================================

-- PARTE 1: Corrigir tabela de clientes
-- ============================================

-- 1.1. Verificar se a tabela clientes existe, se não, criar
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1.2. Adicionar colunas de estatísticas se não existirem
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS total_pedidos INTEGER DEFAULT 0;

ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS total_gasto NUMERIC(10,2) DEFAULT 0;

ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS ultima_compra TIMESTAMP WITH TIME ZONE;

-- PARTE 2: Corrigir tabela de vendas
-- ============================================

-- 2.1. Adicionar campo cliente_id se não existir
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL;

-- 2.2. Adicionar campo taxa_entrega se não existir
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(10,2) DEFAULT 0;

-- 2.3. Remover coluna total se for GENERATED (causando problemas)
DO $$ 
BEGIN
    -- Tentar remover a coluna total se existir como GENERATED
    ALTER TABLE public.vendas DROP COLUMN IF EXISTS total;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorar erro se a coluna não existir
        NULL;
END $$;

-- 2.4. Adicionar coluna total como coluna normal (não GENERATED)
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS total NUMERIC(10,2);

-- PARTE 3: Habilitar RLS e criar políticas
-- ============================================

-- 3.1. Habilitar RLS na tabela clientes
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- 3.2. Criar políticas RLS para clientes
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

-- PARTE 4: Criar função e trigger para atualizar estatísticas
-- ============================================

-- 4.1. Criar função para atualizar estatísticas do cliente
CREATE OR REPLACE FUNCTION public.atualizar_estatisticas_cliente()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar se cliente_id não é nulo
  IF NEW.cliente_id IS NOT NULL THEN
    -- Atualizar total_pedidos, total_gasto e ultima_compra
    UPDATE public.clientes
    SET 
      total_pedidos = (
        SELECT COUNT(*) 
        FROM public.vendas 
        WHERE cliente_id = NEW.cliente_id
      ),
      total_gasto = (
        SELECT COALESCE(SUM(COALESCE(total, valor, 0)), 0) 
        FROM public.vendas 
        WHERE cliente_id = NEW.cliente_id
      ),
      ultima_compra = NEW.data,
      updated_at = NOW()
    WHERE id = NEW.cliente_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4.2. Criar trigger para atualizar estatísticas do cliente
DROP TRIGGER IF EXISTS trigger_atualizar_estatisticas_cliente ON public.vendas;
CREATE TRIGGER trigger_atualizar_estatisticas_cliente
  AFTER INSERT OR UPDATE ON public.vendas
  FOR EACH ROW
  WHEN (NEW.cliente_id IS NOT NULL)
  EXECUTE FUNCTION public.atualizar_estatisticas_cliente();

-- PARTE 5: Criar índices para melhor performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON public.clientes(telefone);
CREATE INDEX IF NOT EXISTS idx_clientes_nome ON public.clientes(nome);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente_id ON public.vendas(cliente_id);

-- PARTE 6: Comentários explicativos
-- ============================================

COMMENT ON COLUMN public.vendas.taxa_entrega IS 'Valor da taxa de entrega para vendas do tipo delivery';
COMMENT ON COLUMN public.clientes.total_pedidos IS 'Número total de pedidos do cliente';
COMMENT ON COLUMN public.clientes.total_gasto IS 'Valor total gasto pelo cliente';
COMMENT ON COLUMN public.clientes.ultima_compra IS 'Data da última compra do cliente';

-- ============================================
-- FIM DO SCRIPT
-- Todas as correções foram aplicadas!
-- ============================================
