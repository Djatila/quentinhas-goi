-- ============================================
-- SCRIPT FINAL: Corrigir TODAS as tabelas
-- Execute este script no Supabase SQL Editor
-- Data: 2025-11-21
-- ============================================

-- PARTE 1: Corrigir tabela CLIENTES
-- ============================================
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS total_pedidos INTEGER DEFAULT 0;
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS total_gasto NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS ultima_compra TIMESTAMP WITH TIME ZONE;

-- PARTE 2: Corrigir tabela VENDAS
-- ============================================
ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL;

-- Remover coluna total se for GENERATED e recriar como normal
DO $$ 
BEGIN
    ALTER TABLE public.vendas DROP COLUMN IF EXISTS total;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS total NUMERIC(10,2);

-- PARTE 3: Corrigir tabela ITENS_VENDA
-- ============================================

-- Remover coluna subtotal se for GENERATED
DO $$ 
BEGIN
    ALTER TABLE public.itens_venda DROP COLUMN IF EXISTS subtotal;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Adicionar colunas necessárias
ALTER TABLE public.itens_venda ADD COLUMN IF NOT EXISTS subtotal NUMERIC(10,2);
ALTER TABLE public.itens_venda ADD COLUMN IF NOT EXISTS observacoes TEXT;

-- PARTE 4: Atualizar valores de subtotal existentes
-- ============================================
UPDATE public.itens_venda 
SET subtotal = quantidade * preco_unitario 
WHERE subtotal IS NULL;

-- PARTE 5: Criar função para calcular subtotal automaticamente
-- ============================================
CREATE OR REPLACE FUNCTION public.calcular_subtotal_item()
RETURNS TRIGGER AS $$
BEGIN
  NEW.subtotal = NEW.quantidade * NEW.preco_unitario;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calcular_subtotal_item ON public.itens_venda;
CREATE TRIGGER trigger_calcular_subtotal_item
  BEFORE INSERT OR UPDATE ON public.itens_venda
  FOR EACH ROW
  EXECUTE FUNCTION public.calcular_subtotal_item();

-- PARTE 6: Criar função para atualizar total da venda
-- ============================================
CREATE OR REPLACE FUNCTION public.atualizar_total_venda()
RETURNS TRIGGER AS $$
DECLARE
  venda_id_alvo UUID;
  novo_total NUMERIC(10,2);
  taxa_entrega_valor NUMERIC(10,2);
BEGIN
  -- Determinar qual venda foi afetada
  IF (TG_OP = 'DELETE') THEN
    venda_id_alvo := OLD.venda_id;
  ELSE
    venda_id_alvo := NEW.venda_id;
  END IF;

  -- Calcular novo total somando todos os itens da venda
  SELECT COALESCE(SUM(subtotal), 0)
  INTO novo_total
  FROM public.itens_venda
  WHERE venda_id = venda_id_alvo;

  -- Buscar taxa de entrega
  SELECT COALESCE(taxa_entrega, 0)
  INTO taxa_entrega_valor
  FROM public.vendas
  WHERE id = venda_id_alvo;

  -- Atualizar o campo total na tabela vendas (produtos + taxa de entrega)
  UPDATE public.vendas
  SET total = novo_total + taxa_entrega_valor
  WHERE id = venda_id_alvo;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_total_venda ON public.itens_venda;
CREATE TRIGGER trigger_atualizar_total_venda
  AFTER INSERT OR UPDATE OR DELETE ON public.itens_venda
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_total_venda();

-- PARTE 7: Criar função para atualizar estatísticas do cliente
-- ============================================
CREATE OR REPLACE FUNCTION public.atualizar_estatisticas_cliente()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.cliente_id IS NOT NULL THEN
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

DROP TRIGGER IF EXISTS trigger_atualizar_estatisticas_cliente ON public.vendas;
CREATE TRIGGER trigger_atualizar_estatisticas_cliente
  AFTER INSERT OR UPDATE ON public.vendas
  FOR EACH ROW
  WHEN (NEW.cliente_id IS NOT NULL)
  EXECUTE FUNCTION public.atualizar_estatisticas_cliente();

-- ============================================
-- FIM DO SCRIPT - Tudo corrigido!
-- ============================================
