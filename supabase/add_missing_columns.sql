-- ============================================
-- SCRIPT SIMPLIFICADO: Adicionar colunas faltantes
-- Execute este script no Supabase SQL Editor
-- Data: 2025-11-21
-- ============================================

-- Adicionar coluna updated_at na tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Adicionar coluna created_at na tabela clientes (se não existir)
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Adicionar coluna total_pedidos na tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS total_pedidos INTEGER DEFAULT 0;

-- Adicionar coluna total_gasto na tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS total_gasto NUMERIC(10,2) DEFAULT 0;

-- Adicionar coluna ultima_compra na tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS ultima_compra TIMESTAMP WITH TIME ZONE;

-- Adicionar coluna taxa_entrega na tabela vendas
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(10,2) DEFAULT 0;

-- Adicionar coluna cliente_id na tabela vendas
ALTER TABLE public.vendas 
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL;

-- ============================================
-- FIM DO SCRIPT
-- ============================================
