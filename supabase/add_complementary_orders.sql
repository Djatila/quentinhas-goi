-- Adicionar coluna para histórico de complementos
ALTER TABLE pedidos_online
ADD COLUMN IF NOT EXISTS historico_complementos JSONB DEFAULT '[]'::jsonb;

-- Comentário explicativo
COMMENT ON COLUMN pedidos_online.historico_complementos IS 'Histórico de itens complementares adicionados após o pedido inicial. Formato: [{data, itens, subtotal, total}]';
