-- ============================================
-- MIGRAÇÃO: Suporte a Logo e Personalização
-- ============================================

-- 1. Adicionar coluna logo_url na tabela configuracoes
ALTER TABLE public.configuracoes 
ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- 2. Criar bucket de storage para logos (se não existir)
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Políticas de Segurança para o Storage (Logos)

-- Permitir acesso público para leitura (para exibir no cardápio)
CREATE POLICY "Logos são públicas"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'logos' );

-- Permitir upload apenas para usuários autenticados (gestão)
CREATE POLICY "Gestão pode fazer upload de logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'logos' );

-- Permitir atualização apenas para usuários autenticados
CREATE POLICY "Gestão pode atualizar logos"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'logos' );

-- Permitir deleção apenas para usuários autenticados
CREATE POLICY "Gestão pode deletar logos"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'logos' );
