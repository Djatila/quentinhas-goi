export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
            categorias: {
                Row: {
                    id: string
                    nome: string
                    tipo: 'entrada' | 'saida'
                    created_at: string
                }
                Insert: {
                    id?: string
                    nome: string
                    tipo: 'entrada' | 'saida'
                    created_at?: string
                }
                Update: {
                    id?: string
                    nome?: string
                    tipo?: 'entrada' | 'saida'
                    created_at?: string
                }
            }
            vendas: {
                Row: {
                    id: string
                    data: string
                    tipo: 'local' | 'delivery'
                    forma_pagamento: string
                    quantidade: number
                    valor: number
                    total: number | null
                    observacoes: string | null
                    cliente_id: string | null
                    criado_por: string | null
                    created_at: string
                }
                Insert: {
                    id?: string
                    data?: string
                    tipo: 'local' | 'delivery'
                    forma_pagamento: string
                    quantidade?: number
                    valor: number
                    total?: number | null
                    observacoes?: string | null
                    cliente_id?: string | null
                    criado_por?: string | null
                    created_at?: string
                }
                Update: {
                    id?: string
                    data?: string
                    tipo?: 'local' | 'delivery'
                    forma_pagamento?: string
                    quantidade?: number
                    valor?: number
                    total?: number | null
                    observacoes?: string | null
                    cliente_id?: string | null
                    criado_por?: string | null
                    created_at?: string
                }
            }
            produtos: {
                Row: {
                    id: string
                    nome: string
                    descricao: string | null
                    preco: number
                    categoria: string | null
                    ativo: boolean
                    created_at: string
                    updated_at: string
                }
                Insert: {
                    id?: string
                    nome: string
                    descricao?: string | null
                    preco: number
                    categoria?: string | null
                    ativo?: boolean
                    created_at?: string
                    updated_at?: string
                }
                Update: {
                    id?: string
                    nome?: string
                    descricao?: string | null
                    preco?: number
                    categoria?: string | null
                    ativo?: boolean
                    created_at?: string
                    updated_at?: string
                }
            }
            itens_venda: {
                Row: {
                    id: string
                    venda_id: string
                    produto_id: string
                    quantidade: number
                    preco_unitario: number
                    subtotal: number
                    observacoes: string | null
                    created_at: string
                }
                Insert: {
                    id?: string
                    venda_id: string
                    produto_id: string
                    quantidade: number
                    preco_unitario: number
                    observacoes?: string | null
                    created_at?: string
                }
                Update: {
                    id?: string
                    venda_id?: string
                    produto_id?: string
                    quantidade?: number
                    preco_unitario?: number
                    observacoes?: string | null
                    created_at?: string
                }
            }
            clientes: {
                Row: {
                    id: string
                    nome: string
                    telefone: string
                    endereco: string | null
                    bairro: string | null
                    cidade: string | null
                    cep: string | null
                    observacoes: string | null
                    ativo: boolean
                    total_pedidos: number
                    total_gasto: number
                    ultima_compra: string | null
                    created_at: string
                    updated_at: string
                }
                Insert: {
                    id?: string
                    nome: string
                    telefone: string
                    endereco?: string | null
                    bairro?: string | null
                    cidade?: string | null
                    cep?: string | null
                    observacoes?: string | null
                    ativo?: boolean
                    total_pedidos?: number
                    total_gasto?: number
                    ultima_compra?: string | null
                    created_at?: string
                    updated_at?: string
                }
                Update: {
                    id?: string
                    nome?: string
                    telefone?: string
                    endereco?: string | null
                    bairro?: string | null
                    cidade?: string | null
                    cep?: string | null
                    observacoes?: string | null
                    ativo?: boolean
                    total_pedidos?: number
                    total_gasto?: number
                    ultima_compra?: string | null
                    created_at?: string
                    updated_at?: string
                }
            }
            despesas: {
                Row: {
                    id: string
                    data: string
                    categoria: string
                    descricao: string
                    valor: number
                    fornecedor: string | null
                    criado_por: string | null
                    created_at: string
                }
                Insert: {
                    id?: string
                    data?: string
                    categoria: string
                    descricao: string
                    valor: number
                    fornecedor?: string | null
                    criado_por?: string | null
                    created_at?: string
                }
                Update: {
                    id?: string
                    data?: string
                    categoria?: string
                    descricao?: string
                    valor?: number
                    fornecedor?: string | null
                    criado_por?: string | null
                    created_at?: string
                }
            }
            fluxo_caixa: {
                Row: {
                    id: string
                    data: string
                    entrada_total: number
                    saida_total: number
                    saldo_do_dia: number
                    saldo_acumulado: number
                    updated_at: string
                }
                Insert: {
                    id?: string
                    data: string
                    entrada_total?: number
                    saida_total?: number
                    saldo_do_dia?: number
                    saldo_acumulado?: number
                    updated_at?: string
                }
                Update: {
                    id?: string
                    data?: string
                    entrada_total?: number
                    saida_total?: number
                    saldo_do_dia?: number
                    saldo_acumulado?: number
                    updated_at?: string
                }
            }
        }
    }
}
