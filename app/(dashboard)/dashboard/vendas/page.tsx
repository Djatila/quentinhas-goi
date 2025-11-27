'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Plus, Trash2, Edit, Search } from 'lucide-react'
import Link from 'next/link'
import { useToast } from '@/components/ui/Toast'
import { ConfirmModal } from '@/components/ui/ConfirmModal'

export default function VendasPage() {
    const [vendas, setVendas] = useState<any[]>([])
    const [filteredVendas, setFilteredVendas] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterType, setFilterType] = useState('all')
    const [startDate, setStartDate] = useState('')
    const [endDate, setEndDate] = useState('')
    const supabase = createClient()
    const { showToast } = useToast()
    const [deleteModal, setDeleteModal] = useState<{ isOpen: boolean; id: string | null }>({
        isOpen: false,
        id: null
    })

    async function loadVendas() {
        setLoading(true)
        const { data } = await supabase
            .from('vendas')
            .select(`
                *,
                itens_venda (
                    id,
                    quantidade,
                    preco_unitario,
                    subtotal,
                    produtos (
                        id,
                        nome
                    )
                )
            `)
            .order('data', { ascending: false })
            .limit(100)

        setVendas(data || [])
        setFilteredVendas(data || [])
        setLoading(false)
    }

    useEffect(() => {
        loadVendas()
    }, [])

    useEffect(() => {
        let filtered = [...vendas]

        if (filterType !== 'all') {
            filtered = filtered.filter(v => v.tipo === filterType)
        }

        if (startDate) {
            filtered = filtered.filter(v => new Date(v.data) >= new Date(startDate))
        }
        if (endDate) {
            filtered = filtered.filter(v => new Date(v.data) <= new Date(endDate + 'T23:59:59'))
        }

        if (searchTerm) {
            filtered = filtered.filter(v =>
                v.forma_pagamento.toLowerCase().includes(searchTerm.toLowerCase()) ||
                (v.observacoes && v.observacoes.toLowerCase().includes(searchTerm.toLowerCase()))
            )
        }

        setFilteredVendas(filtered)
    }, [searchTerm, filterType, startDate, endDate, vendas])

    async function handleDelete() {
        if (!deleteModal.id) return

        const { error } = await supabase
            .from('vendas')
            .delete()
            .eq('id', deleteModal.id)

        if (error) {
            showToast('error', 'Erro ao excluir', error.message)
        } else {
            showToast('success', 'Venda excluída!', 'A venda foi removida com sucesso.')
            loadVendas()
        }

        setDeleteModal({ isOpen: false, id: null })
    }

    const totalVendas = filteredVendas.reduce((sum, v) => sum + Number(v.total || 0), 0)

    return (
        <div className="flex flex-col gap-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold">Vendas</h1>
                    <p className="text-muted-foreground">Gerencie as entradas do restaurante</p>
                </div>
                <Link href="/dashboard/vendas/nova">
                    <Button>
                        <Plus size={16} className="mr-2" />
                        Nova Venda
                    </Button>
                </Link>
            </div>

            <Card>
                <CardContent className="pt-6">
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" size={16} />
                            <input
                                type="text"
                                placeholder="Buscar..."
                                className="w-full pl-10 pr-3 py-2 border border-input rounded-md text-sm"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <select
                            className="px-3 py-2 border border-input rounded-md text-sm"
                            value={filterType}
                            onChange={(e) => setFilterType(e.target.value)}
                        >
                            <option value="all">Todos os tipos</option>
                            <option value="local">Local</option>
                            <option value="delivery">Delivery</option>
                        </select>
                        <Input
                            type="date"
                            label=""
                            value={startDate}
                            onChange={(e) => setStartDate(e.target.value)}
                            placeholder="Data início"
                        />
                        <Input
                            type="date"
                            label=""
                            value={endDate}
                            onChange={(e) => setEndDate(e.target.value)}
                            placeholder="Data fim"
                        />
                    </div>
                </CardContent>
            </Card>

            <Card>
                <CardHeader>
                    <CardTitle>Histórico de Vendas ({filteredVendas.length} registros)</CardTitle>
                </CardHeader>
                <CardContent>
                    <div style={{ overflowX: 'auto' }}>
                        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                            <thead>
                                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                                    <th className="p-4 font-medium text-muted-foreground">Data</th>
                                    <th className="p-4 font-medium text-muted-foreground">Tipo</th>
                                    <th className="p-4 font-medium text-muted-foreground">Produtos</th>
                                    <th className="p-4 font-medium text-muted-foreground">Pagamento</th>
                                    <th className="p-4 font-medium text-muted-foreground">Valor</th>
                                    <th className="p-4 font-medium text-muted-foreground">Ações</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredVendas.map((venda) => (
                                    <tr key={venda.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                        <td className="p-4">{new Date(venda.data).toLocaleDateString()}</td>
                                        <td className="p-4">
                                            <span style={{
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '9999px',
                                                fontSize: '0.75rem',
                                                backgroundColor: venda.tipo === 'delivery' ? '#e0f2fe' : '#dcfce7',
                                                color: venda.tipo === 'delivery' ? '#0369a1' : '#15803d'
                                            }}>
                                                {venda.tipo === 'delivery' ? 'Delivery' : 'Local'}
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            {venda.itens_venda && venda.itens_venda.length > 0 ? (
                                                <div className="text-sm">
                                                    {venda.itens_venda.map((item: any, idx: number) => (
                                                        <div key={idx}>
                                                            {item.quantidade}x {item.produtos?.nome || 'Produto'}
                                                        </div>
                                                    ))}
                                                </div>
                                            ) : (
                                                <span className="text-muted-foreground text-sm">
                                                    {venda.quantidade} {venda.quantidade === 1 ? 'item' : 'itens'}
                                                </span>
                                            )}
                                        </td>
                                        <td className="p-4">{venda.forma_pagamento}</td>
                                        <td className="p-4 font-medium">R$ {Number(venda.total || venda.valor || 0).toFixed(2)}</td>
                                        <td className="p-4">
                                            <div className="flex gap-2">
                                                <Link href={`/dashboard/vendas/${venda.id}/editar`}>
                                                    <Button
                                                        variant="ghost"
                                                        className="h-8 w-8 p-0 text-blue-500 hover:text-blue-700"
                                                    >
                                                        <Edit size={16} />
                                                    </Button>
                                                </Link>
                                                <Button
                                                    variant="ghost"
                                                    className="h-8 w-8 p-0 text-red-500 hover:text-red-700"
                                                    onClick={() => setDeleteModal({ isOpen: true, id: venda.id })}
                                                >
                                                    <Trash2 size={16} />
                                                </Button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                                {filteredVendas.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="p-8 text-center text-muted-foreground">
                                            Nenhuma venda encontrada.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                            <tfoot>
                                <tr style={{ borderTop: '2px solid var(--border)', fontWeight: 'bold' }}>
                                    <td colSpan={4} className="p-4 text-right">Total:</td>
                                    <td className="p-4">R$ {totalVendas.toFixed(2)}</td>
                                    <td></td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <ConfirmModal
                isOpen={deleteModal.isOpen}
                title="Excluir Venda"
                message="Tem certeza que deseja excluir esta venda? Esta ação não pode ser desfeita."
                onConfirm={handleDelete}
                onCancel={() => setDeleteModal({ isOpen: false, id: null })}
                confirmText="Excluir"
                cancelText="Cancelar"
            />
        </div>
    )
}
