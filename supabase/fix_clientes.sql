-- ============================================
-- SCRIPT DE CORREÇÃO: Adicionar colunas faltantes
-- Execute este script no Supabase SQL Editor
-- ============================================

-- Adicionar coluna observacoes se não existir
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS observacoes TEXT;

-- ============================================
-- FIM DO SCRIPT
-- ============================================
