-- ============================================
-- SCRIPT: Criar tabela de produtos e inserir dados iniciais
-- Execute este script no Supabase SQL Editor
-- Data: 2025-11-21
-- ============================================

-- PARTE 1: Criar tabela de produtos (se não existir)
-- ============================================
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

-- PARTE 2: Habilitar RLS
-- ============================================
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- PARTE 3: Criar políticas RLS
-- ============================================
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

-- PARTE 4: Inserir produtos iniciais
-- ============================================
INSERT INTO public.produtos (nome, descricao, preco, categoria, ativo) VALUES
  ('Marmitex P', 'Marmita pequena', 15.00, 'marmitex', true),
  ('Marmitex M', 'Marmita média', 18.00, 'marmitex', true),
  ('Marmitex G', 'Marmita grande', 22.00, 'marmitex', true),
  ('Refrigerante Lata', 'Refrigerante 350ml', 5.00, 'bebida', true),
  ('Refrigerante 2L', 'Refrigerante 2 litros', 10.00, 'bebida', true),
  ('Suco Natural', 'Suco natural 500ml', 8.00, 'bebida', true),
  ('Água Mineral', 'Água mineral 500ml', 3.00, 'bebida', true),
  ('Sobremesa', 'Sobremesa do dia', 6.00, 'sobremesa', true),
  ('Adicional Proteína', 'Porção extra de proteína', 8.00, 'adicional', true),
  ('Adicional Acompanhamento', 'Porção extra de acompanhamento', 5.00, 'adicional', true)
ON CONFLICT (id) DO NOTHING;

-- PARTE 5: Criar índices
-- ============================================
CREATE INDEX IF NOT EXISTS idx_produtos_categoria ON public.produtos(categoria);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON public.produtos(ativo);

-- ============================================
-- FIM DO SCRIPT
-- ============================================
