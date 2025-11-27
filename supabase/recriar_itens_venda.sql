-- ============================================
-- CORREÇÃO FINAL: Verificar e corrigir itens_venda
-- Execute este script no Supabase SQL Editor
-- ============================================

-- 1. Verificar a estrutura atual da tabela itens_venda
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    is_generated
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'itens_venda'
ORDER BY ordinal_position;

-- 2. DELETAR a tabela itens_venda e recriar do zero
DROP TABLE IF EXISTS public.itens_venda CASCADE;

-- 3. Recriar tabela itens_venda SEM coluna GENERATED
CREATE TABLE public.itens_venda (
  id UUID NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  venda_id UUID NOT NULL REFERENCES public.vendas(id) ON DELETE CASCADE,
  produto_id UUID NOT NULL REFERENCES public.produtos(id) ON DELETE RESTRICT,
  quantidade INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unitario NUMERIC(10,2) NOT NULL CHECK (preco_unitario >= 0),
  subtotal NUMERIC(10,2),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Habilitar RLS
ALTER TABLE public.itens_venda ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS
DROP POLICY IF EXISTS "Itens de venda visíveis para autenticados" ON public.itens_venda;
CREATE POLICY "Itens de venda visíveis para autenticados"
  ON public.itens_venda FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Itens de venda inseríveis por autenticados" ON public.itens_venda;
CREATE POLICY "Itens de venda inseríveis por autenticados"
  ON public.itens_venda FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Itens de venda atualizáveis por autenticados" ON public.itens_venda;
CREATE POLICY "Itens de venda atualizáveis por autenticados"
  ON public.itens_venda FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Itens de venda deletáveis por autenticados" ON public.itens_venda;
CREATE POLICY "Itens de venda deletáveis por autenticados"
  ON public.itens_venda FOR DELETE
  TO authenticated
  USING (true);

-- 6. Criar trigger para calcular subtotal automaticamente
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

-- 7. Criar trigger para atualizar total da venda
CREATE OR REPLACE FUNCTION public.atualizar_total_venda()
RETURNS TRIGGER AS $$
DECLARE
  venda_id_alvo UUID;
  novo_total NUMERIC(10,2);
  taxa_entrega_valor NUMERIC(10,2);
BEGIN
  IF (TG_OP = 'DELETE') THEN
    venda_id_alvo := OLD.venda_id;
  ELSE
    venda_id_alvo := NEW.venda_id;
  END IF;

  SELECT COALESCE(SUM(subtotal), 0)
  INTO novo_total
  FROM public.itens_venda
  WHERE venda_id = venda_id_alvo;

  SELECT COALESCE(taxa_entrega, 0)
  INTO taxa_entrega_valor
  FROM public.vendas
  WHERE id = venda_id_alvo;

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

-- 8. Criar índices
CREATE INDEX IF NOT EXISTS idx_itens_venda_venda_id ON public.itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_venda_produto_id ON public.itens_venda(produto_id);

-- ============================================
-- FIM - Tabela itens_venda recriada!
-- ============================================
