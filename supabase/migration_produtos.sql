-- ============================================
-- SCRIPT DE ATUALIZAÇÃO: SISTEMA DE PRODUTOS
-- Execute este script no Supabase SQL Editor
-- ============================================

-- 1. Criar tabela de Produtos
CREATE TABLE IF NOT EXISTS public.produtos (
  id UUID NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  nome TEXT NOT NULL,
  descricao TEXT,
  preco NUMERIC(10,2) NOT NULL CHECK (preco >= 0),
  categoria TEXT,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar tabela de Itens de Venda
CREATE TABLE IF NOT EXISTS public.itens_venda (
  id UUID NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  venda_id UUID NOT NULL REFERENCES public.vendas(id) ON DELETE CASCADE,
  produto_id UUID NOT NULL REFERENCES public.produtos(id) ON DELETE RESTRICT,
  quantidade INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unitario NUMERIC(10,2) NOT NULL CHECK (preco_unitario >= 0),
  subtotal NUMERIC(10,2) GENERATED ALWAYS AS (quantidade * preco_unitario) STORED,
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Habilitar RLS nas novas tabelas
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itens_venda ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS para produtos
DROP POLICY IF EXISTS "Produtos visíveis para autenticados" ON public.produtos;
CREATE POLICY "Produtos visíveis para autenticados"
  ON public.produtos FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Produtos inseríveis por autenticados" ON public.produtos;
CREATE POLICY "Produtos inseríveis por autenticados"
  ON public.produtos FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Produtos atualizáveis por autenticados" ON public.produtos;
CREATE POLICY "Produtos atualizáveis por autenticados"
  ON public.produtos FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Produtos deletáveis por autenticados" ON public.produtos;
CREATE POLICY "Produtos deletáveis por autenticados"
  ON public.produtos FOR DELETE
  TO authenticated
  USING (true);

-- 5. Criar políticas RLS para itens_venda
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

-- 6. Criar função para atualizar updated_at em produtos
CREATE OR REPLACE FUNCTION public.atualizar_updated_at_produto()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_updated_at_produto ON public.produtos;
CREATE TRIGGER trigger_atualizar_updated_at_produto
  BEFORE UPDATE ON public.produtos
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at_produto();

-- 7. Criar função para atualizar total da venda quando itens são modificados
CREATE OR REPLACE FUNCTION public.atualizar_total_venda()
RETURNS TRIGGER AS $$
DECLARE
  venda_id_alvo UUID;
  novo_total NUMERIC(10,2);
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

  -- Atualizar o campo total na tabela vendas
  -- Nota: Se a coluna 'total' não existir, ela será criada como nullable
  UPDATE public.vendas
  SET total = novo_total
  WHERE id = venda_id_alvo;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_total_venda ON public.itens_venda;
CREATE TRIGGER trigger_atualizar_total_venda
  AFTER INSERT OR UPDATE OR DELETE ON public.itens_venda
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_total_venda();

-- 8. Garantir que a coluna 'total' existe na tabela vendas
-- (Já foi criada em migration_clientes.sql, mas vamos garantir)
DO $$
BEGIN
  -- Remover a coluna total se for GENERATED (da migration anterior)
  BEGIN
    ALTER TABLE public.vendas DROP COLUMN IF EXISTS total;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  
  -- Adicionar coluna total como nullable (será calculada pelos itens)
  ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS total NUMERIC(10,2);
END $$;

-- 9. Inserir produtos iniciais
INSERT INTO public.produtos (nome, descricao, preco, categoria) VALUES
  ('Marmitex P', 'Marmita pequena', 15.00, 'marmitex'),
  ('Marmitex M', 'Marmita média', 18.00, 'marmitex'),
  ('Marmitex G', 'Marmita grande', 22.00, 'marmitex'),
  ('Refrigerante Lata', 'Refrigerante 350ml', 5.00, 'bebida'),
  ('Refrigerante 2L', 'Refrigerante 2 litros', 10.00, 'bebida'),
  ('Suco Natural', 'Suco natural 500ml', 8.00, 'bebida'),
  ('Água Mineral', 'Água mineral 500ml', 3.00, 'bebida'),
  ('Sobremesa', 'Sobremesa do dia', 6.00, 'sobremesa'),
  ('Adicional Proteína', 'Porção extra de proteína', 8.00, 'adicional'),
  ('Adicional Acompanhamento', 'Porção extra de acompanhamento', 5.00, 'adicional')
ON CONFLICT DO NOTHING;

-- 10. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_produtos_categoria ON public.produtos(categoria);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON public.produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_itens_venda_venda_id ON public.itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_venda_produto_id ON public.itens_venda(produto_id);

-- ============================================
-- FIM DO SCRIPT
-- ============================================
