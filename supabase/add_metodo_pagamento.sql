-- ============================================
-- MIGRAÇÃO: Adicionar Método de Pagamento e Troco
-- ============================================

-- 1. Adicionar coluna metodo_pagamento à tabela pedidos_online
ALTER TABLE public.pedidos_online 
ADD COLUMN IF NOT EXISTS metodo_pagamento TEXT 
CHECK (metodo_pagamento IN ('pix', 'cartao', 'dinheiro', 'pagamento_posterior'));

-- 2. Adicionar colunas para troco (apenas para pagamento em dinheiro)
ALTER TABLE public.pedidos_online 
ADD COLUMN IF NOT EXISTS precisa_troco BOOLEAN DEFAULT false;

ALTER TABLE public.pedidos_online 
ADD COLUMN IF NOT EXISTS valor_para_troco NUMERIC(10,2);

-- 3. Criar índice para melhor performance nas consultas por método de pagamento
CREATE INDEX IF NOT EXISTS idx_pedidos_online_metodo_pagamento 
ON public.pedidos_online(metodo_pagamento);

-- 4. Adicionar comentários descritivos nas colunas
COMMENT ON COLUMN public.pedidos_online.metodo_pagamento IS 
'Método de pagamento: pix, cartao, dinheiro, pagamento_posterior';

COMMENT ON COLUMN public.pedidos_online.precisa_troco IS 
'Indica se o cliente precisa de troco (apenas para pagamento em dinheiro)';

COMMENT ON COLUMN public.pedidos_online.valor_para_troco IS 
'Valor que o cliente vai pagar (para calcular o troco)';

-- ============================================
-- FIM DA MIGRAÇÃO
-- ============================================

-- Para testar, você pode atualizar um pedido existente:
/*
UPDATE public.pedidos_online 
SET metodo_pagamento = 'dinheiro',
    precisa_troco = true,
    valor_para_troco = 50.00
WHERE id = 'seu-uuid-aqui';
*/
