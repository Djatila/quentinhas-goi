-- ============================================
-- MIGRAÇÃO: Sistema de Pedidos Online
-- ============================================

-- 1. Criar tabela de pedidos online
CREATE TABLE IF NOT EXISTS public.pedidos_online (
  id UUID NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  numero_pedido SERIAL UNIQUE,
  cliente_nome TEXT NOT NULL,
  cliente_telefone TEXT NOT NULL,
  cliente_endereco TEXT,
  tipo_entrega TEXT NOT NULL CHECK (tipo_entrega IN ('retirada', 'delivery')),
  itens JSONB NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL,
  taxa_entrega NUMERIC(10,2) DEFAULT 0,
  total NUMERIC(10,2) NOT NULL,
  observacoes TEXT,
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'confirmado', 'preparando', 'pronto', 'entregue', 'cancelado')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_pedidos_online_status ON public.pedidos_online(status);
CREATE INDEX IF NOT EXISTS idx_pedidos_online_created_at ON public.pedidos_online(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pedidos_online_telefone ON public.pedidos_online(cliente_telefone);

-- 3. Habilitar RLS
ALTER TABLE public.pedidos_online ENABLE ROW LEVEL SECURITY;

-- 4. Políticas RLS

-- Permitir que qualquer pessoa (anônima ou autenticada) insira pedidos
DROP POLICY IF EXISTS "Permitir inserção pública de pedidos" ON public.pedidos_online;
CREATE POLICY "Permitir inserção pública de pedidos"
  ON public.pedidos_online FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Permitir que qualquer pessoa veja pedidos (para acompanhamento por número)
DROP POLICY IF EXISTS "Permitir visualização pública de pedidos" ON public.pedidos_online;
CREATE POLICY "Permitir visualização pública de pedidos"
  ON public.pedidos_online FOR SELECT
  TO anon, authenticated
  USING (true);

-- Apenas usuários autenticados (gestão) podem atualizar pedidos
DROP POLICY IF EXISTS "Gestão pode atualizar pedidos" ON public.pedidos_online;
CREATE POLICY "Gestão pode atualizar pedidos"
  ON public.pedidos_online FOR UPDATE
  TO authenticated
  USING (true);

-- Apenas usuários autenticados (gestão) podem deletar pedidos
DROP POLICY IF EXISTS "Gestão pode deletar pedidos" ON public.pedidos_online;
CREATE POLICY "Gestão pode deletar pedidos"
  ON public.pedidos_online FOR DELETE
  TO authenticated
  USING (true);

-- 5. Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.atualizar_updated_at_pedido()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS trigger_atualizar_updated_at_pedido ON public.pedidos_online;
CREATE TRIGGER trigger_atualizar_updated_at_pedido
  BEFORE UPDATE ON public.pedidos_online
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_updated_at_pedido();

-- 7. Habilitar Realtime para a tabela (para atualizações em tempo real)
ALTER PUBLICATION supabase_realtime ADD TABLE public.pedidos_online;

-- ============================================
-- FIM DA MIGRAÇÃO
-- ============================================

-- Para testar, você pode inserir um pedido de exemplo:
/*
INSERT INTO public.pedidos_online (
  cliente_nome,
  cliente_telefone,
  cliente_endereco,
  tipo_entrega,
  itens,
  subtotal,
  taxa_entrega,
  total,
  observacoes
) VALUES (
  'João Silva',
  '(11) 98765-4321',
  'Rua das Flores, 123',
  'delivery',
  '[{"id": "uuid-produto", "nome": "Marmitex M", "quantidade": 2, "preco": 18.00}]'::jsonb,
  36.00,
  5.00,
  41.00,
  'Sem cebola'
);
*/
