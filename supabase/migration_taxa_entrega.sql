-- Migration: Adicionar campo taxa_entrega na tabela vendas
-- Data: 2025-11-21
-- Descrição: Adiciona o campo taxa_entrega para armazenar o valor da taxa de entrega em vendas delivery

-- 1. Adicionar coluna taxa_entrega na tabela vendas
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(10,2) DEFAULT 0;

-- 2. Comentário explicativo
COMMENT ON COLUMN public.vendas.taxa_entrega IS 'Valor da taxa de entrega para vendas do tipo delivery';
