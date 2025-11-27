-- Script para configurar o suporte a Logo
-- Rode este script no Editor SQL do Supabase

-- 1. Criar o bucket 'logos' se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Adicionar coluna logo_url na tabela configuracoes
ALTER TABLE public.configuracoes 
ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- 3. Remover políticas antigas para evitar duplicação (opcional, mas seguro)
DROP POLICY IF EXISTS "Logos são públicas" ON storage.objects;
DROP POLICY IF EXISTS "Gestão pode fazer upload de logos" ON storage.objects;
DROP POLICY IF EXISTS "Gestão pode atualizar logos" ON storage.objects;
DROP POLICY IF EXISTS "Gestão pode deletar logos" ON storage.objects;

-- 4. Criar Políticas de Segurança para o Storage
-- Permitir acesso público para leitura
CREATE POLICY "Logos são públicas"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'logos' );

-- Permitir upload para usuários autenticados
CREATE POLICY "Gestão pode fazer upload de logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'logos' );

-- Permitir atualização para usuários autenticados
CREATE POLICY "Gestão pode atualizar logos"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'logos' );

-- Permitir deleção para usuários autenticados
CREATE POLICY "Gestão pode deletar logos"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'logos' );
