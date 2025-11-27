'use client'

import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

export default function EditarVendaPage() {
    const router = useRouter()
    const params = useParams()
    const id = params.id as string
    const supabase = createClient()
    const [loading, setLoading] = useState(false)
    const [loadingData, setLoadingData] = useState(true)

    const [formData, setFormData] = useState({
        tipo: 'local',
        forma_pagamento: 'dinheiro',
        quantidade: 1,
        valor: '',
        observacoes: '',
        taxa_entrega: 0
    })

    useEffect(() => {
        async function loadVenda() {
            const { data, error } = await supabase
                .from('vendas')
                .select('*')
                .eq('id', id)
                .single()

            if (error) {
                alert('Erro ao carregar venda: ' + error.message)
                router.push('/dashboard/vendas')
                return
            }

            if (data) {
                setFormData({
                    tipo: data.tipo,
                    forma_pagamento: data.forma_pagamento,
                    quantidade: data.quantidade,
                    valor: String(data.total || 0),
                    observacoes: data.observacoes || '',
                    taxa_entrega: data.taxa_entrega || 0
                })
            }

            setLoadingData(false)
        }

        loadVenda()
    }, [id])

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        const { error } = await supabase
            .from('vendas')
            .update({
                tipo: formData.tipo as 'local' | 'delivery',
                forma_pagamento: formData.forma_pagamento,
                quantidade: Number(formData.quantidade),
                total: Number(formData.valor),
                observacoes: formData.observacoes,
                taxa_entrega: formData.tipo === 'delivery' ? formData.taxa_entrega : 0,
            })
            .eq('id', id)

        if (error) {
            alert('Erro ao atualizar venda: ' + error.message)
            setLoading(false)
        } else {
            router.push('/dashboard/vendas')
            router.refresh()
        }
    }

    if (loadingData) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <p>Carregando...</p>
            </div>
        )
    }

    return (
        <div className="flex flex-col gap-6 max-w-2xl mx-auto">
            <div className="flex items-center gap-4">
                <Link href="/dashboard/vendas">
                    <Button variant="ghost">
                        <ArrowLeft size={20} />
                    </Button>
                </Link>
                <h1 className="text-2xl font-bold">Editar Venda</h1>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Atualizar Venda</CardTitle>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium">Tipo</label>
                                <select
                                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                                    value={formData.tipo}
                                    onChange={(e) => setFormData({ ...formData, tipo: e.target.value })}
                                >
                                    <option value="local">Consumo Local</option>
                                    <option value="delivery">Delivery</option>
                                </select>
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium">Pagamento</label>
                                <select
                                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                                    value={formData.forma_pagamento}
                                    onChange={(e) => setFormData({ ...formData, forma_pagamento: e.target.value })}
                                >
                                    <option value="dinheiro">Dinheiro</option>
                                    <option value="pix">PIX</option>
                                    <option value="cartao_credito">Cartão de Crédito</option>
                                    <option value="cartao_debito">Cartão de Débito</option>
                                </select>
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <Input
                                label="Quantidade"
                                type="number"
                                min="1"
                                value={formData.quantidade}
                                onChange={(e) => setFormData({ ...formData, quantidade: Number(e.target.value) })}
                                required
                            />
                            <Input
                                label="Valor Total (R$)"
                                type="number"
                                step="0.01"
                                min="0"
                                placeholder="0.00"
                                value={formData.valor}
                                onChange={(e) => setFormData({ ...formData, valor: e.target.value })}
                                required
                            />
                        </div>

                        {/* Campo Taxa de Entrega - Apenas para Delivery */}
                        {formData.tipo === 'delivery' && (
                            <Input
                                label="Taxa de Entrega (R$)"
                                type="number"
                                step="0.01"
                                min="0"
                                placeholder="0.00"
                                value={formData.taxa_entrega}
                                onChange={(e) => setFormData({ ...formData, taxa_entrega: Number(e.target.value) })}
                            />
                        )}

                        <div className="flex flex-col gap-2">
                            <label className="text-sm font-medium">Observações</label>
                            <textarea
                                className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                value={formData.observacoes}
                                onChange={(e) => setFormData({ ...formData, observacoes: e.target.value })}
                                placeholder="Detalhes do pedido..."
                            />
                        </div>

                        <div className="flex justify-end gap-4 mt-4">
                            <Link href="/dashboard/vendas">
                                <Button type="button" variant="secondary">Cancelar</Button>
                            </Link>
                            <Button type="submit" disabled={loading}>
                                {loading ? 'Salvando...' : 'Atualizar Venda'}
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
