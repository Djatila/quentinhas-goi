-- ============================================
-- SCRIPT: Adicionar campo cargo_usuario
-- ============================================

-- Adicionar coluna cargo_usuario à tabela configuracoes
ALTER TABLE public.configuracoes 
ADD COLUMN IF NOT EXISTS cargo_usuario TEXT DEFAULT 'Atendente';

-- Atualizar registros existentes que não têm valor
UPDATE public.configuracoes 
SET cargo_usuario = 'Atendente' 
WHERE cargo_usuario IS NULL;
