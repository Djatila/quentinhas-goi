-- ============================================
-- SCRIPT DE DIAGNÓSTICO E CORREÇÃO
-- Execute este script no Supabase SQL Editor
-- ============================================

-- 1. Verificar se a tabela produtos existe e tem dados
SELECT COUNT(*) as total_produtos FROM public.produtos;

-- 2. Listar todos os produtos
SELECT id, nome, preco, categoria, ativo FROM public.produtos;

-- 3. Verificar a estrutura da tabela itens_venda
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'itens_venda'
ORDER BY ordinal_position;

-- 4. Verificar foreign keys
SELECT
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='itens_venda';

-- ============================================
-- CORREÇÃO: Deletar e recriar foreign key se necessário
-- ============================================

-- Remover foreign key antiga se existir
ALTER TABLE public.itens_venda 
DROP CONSTRAINT IF EXISTS itens_venda_produto_id_fkey;

-- Criar foreign key correta
ALTER TABLE public.itens_venda
ADD CONSTRAINT itens_venda_produto_id_fkey 
FOREIGN KEY (produto_id) 
REFERENCES public.produtos(id) 
ON DELETE RESTRICT;

-- ============================================
-- INSERIR PRODUTOS NOVAMENTE (forçar inserção)
-- ============================================

-- Deletar produtos existentes (CUIDADO: só faça isso se não tiver vendas)
-- DELETE FROM public.produtos;

-- Inserir produtos (desta vez sem ON CONFLICT)
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
  ('Adicional Acompanhamento', 'Porção extra de acompanhamento', 5.00, 'adicional', true);

-- Verificar novamente quantos produtos foram inseridos
SELECT COUNT(*) as total_produtos_apos_insercao FROM public.produtos;

-- Listar produtos inseridos
SELECT id, nome, preco FROM public.produtos ORDER BY categoria, nome;

-- ============================================
-- FIM DO SCRIPT
-- ============================================
