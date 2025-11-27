'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Plus, Edit, Power, PowerOff, Search, ExternalLink } from 'lucide-react'
import Link from 'next/link'
import { useToast } from '@/components/ui/Toast'

export default function CardapioPage() {
    const [produtos, setProdutos] = useState<any[]>([])
    const [filteredProdutos, setFilteredProdutos] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterCategoria, setFilterCategoria] = useState('all')
    const [filterStatus, setFilterStatus] = useState('all')
    const supabase = createClient()
    const { showToast } = useToast()

    async function loadProdutos() {
        setLoading(true)
        const { data } = await supabase
            .from('produtos')
            .select('*')
            .order('categoria')
            .order('nome')

        setProdutos(data || [])
        setFilteredProdutos(data || [])
        setLoading(false)
    }

    useEffect(() => {
        loadProdutos()
    }, [])

    useEffect(() => {
        let filtered = [...produtos]

        if (filterCategoria !== 'all') {
            filtered = filtered.filter(p => p.categoria === filterCategoria)
        }

        if (filterStatus === 'ativo') {
            filtered = filtered.filter(p => p.ativo === true)
        } else if (filterStatus === 'inativo') {
            filtered = filtered.filter(p => p.ativo === false)
        }

        if (searchTerm) {
            filtered = filtered.filter(p =>
                p.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
                (p.descricao && p.descricao.toLowerCase().includes(searchTerm.toLowerCase()))
            )
        }

        setFilteredProdutos(filtered)
    }, [searchTerm, filterCategoria, filterStatus, produtos])

    async function toggleAtivo(id: string, currentStatus: boolean) {
        const { error } = await supabase
            .from('produtos')
            .update({ ativo: !currentStatus })
            .eq('id', id)

        if (error) {
            showToast('error', 'Erro ao atualizar', error.message)
        } else {
            showToast('success', 'Status atualizado!', `Produto ${!currentStatus ? 'ativado' : 'desativado'} com sucesso.`)
            loadProdutos()
        }
    }

    const categorias = Array.from(new Set(produtos.map(p => p.categoria).filter(Boolean)))
    const produtosAtivos = produtos.filter(p => p.ativo).length

    return (
        <div className="flex flex-col gap-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold">Cardápio Online</h1>
                    <p className="text-muted-foreground">
                        Gerencie os produtos que aparecem no cardápio online
                    </p>
                </div>
                <div className="flex gap-2">
                    <Link href="/cardapio" target="_blank">
                        <Button variant="secondary">
                            <ExternalLink size={16} className="mr-2" />
                            Ver Cardápio Online
                        </Button>
                    </Link>
                    <Link href="/dashboard/produtos/novo">
                        <Button>
                            <Plus size={16} className="mr-2" />
                            Novo Produto
                        </Button>
                    </Link>
                </div>
            </div>

            {/* Card de Estatísticas */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Card>
                    <CardContent className="pt-6">
                        <div className="text-2xl font-bold">{produtos.length}</div>
                        <p className="text-sm text-muted-foreground">Total de Produtos</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="pt-6">
                        <div className="text-2xl font-bold text-green-600">{produtosAtivos}</div>
                        <p className="text-sm text-muted-foreground">Produtos Ativos</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="pt-6">
                        <div className="text-2xl font-bold text-orange-600">{produtos.length - produtosAtivos}</div>
                        <p className="text-sm text-muted-foreground">Produtos Inativos</p>
                    </CardContent>
                </Card>
            </div>

            {/* Filtros */}
            <Card>
                <CardContent className="pt-6">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" size={16} />
                            <input
                                type="text"
                                placeholder="Buscar produto..."
                                className="w-full pl-10 pr-3 py-2 border border-input rounded-md text-sm"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <select
                            className="px-3 py-2 border border-input rounded-md text-sm"
                            value={filterCategoria}
                            onChange={(e) => setFilterCategoria(e.target.value)}
                        >
                            <option value="all">Todas as categorias</option>
                            {categorias.map(cat => (
                                <option key={cat} value={cat}>{cat}</option>
                            ))}
                        </select>
                        <select
                            className="px-3 py-2 border border-input rounded-md text-sm"
                            value={filterStatus}
                            onChange={(e) => setFilterStatus(e.target.value)}
                        >
                            <option value="all">Todos os status</option>
                            <option value="ativo">Ativos (visíveis no cardápio)</option>
                            <option value="inativo">Inativos (ocultos no cardápio)</option>
                        </select>
                    </div>
                </CardContent>
            </Card>

            {/* Tabela de Produtos */}
            <Card>
                <CardHeader>
                    <CardTitle>Produtos no Cardápio ({filteredProdutos.length} itens)</CardTitle>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <p className="text-center py-8 text-muted-foreground">Carregando produtos...</p>
                    ) : (
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                                <thead>
                                    <tr style={{ borderBottom: '1px solid var(--border)' }}>
                                        <th className="p-4 font-medium text-muted-foreground">Nome</th>
                                        <th className="p-4 font-medium text-muted-foreground">Categoria</th>
                                        <th className="p-4 font-medium text-muted-foreground">Preço</th>
                                        <th className="p-4 font-medium text-muted-foreground">Status</th>
                                        <th className="p-4 font-medium text-muted-foreground">Ações</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filteredProdutos.map((produto) => (
                                        <tr key={produto.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                            <td className="p-4">
                                                <div>
                                                    <div className="font-medium">{produto.nome}</div>
                                                    {produto.descricao && (
                                                        <div className="text-sm text-muted-foreground">{produto.descricao}</div>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <span style={{
                                                    padding: '0.25rem 0.5rem',
                                                    borderRadius: '9999px',
                                                    fontSize: '0.75rem',
                                                    backgroundColor: '#f3f4f6',
                                                    color: '#374151'
                                                }}>
                                                    {produto.categoria || 'Sem categoria'}
                                                </span>
                                            </td>
                                            <td className="p-4 font-medium">R$ {Number(produto.preco).toFixed(2)}</td>
                                            <td className="p-4">
                                                <span style={{
                                                    padding: '0.25rem 0.5rem',
                                                    borderRadius: '9999px',
                                                    fontSize: '0.75rem',
                                                    backgroundColor: produto.ativo ? '#dcfce7' : '#fee2e2',
                                                    color: produto.ativo ? '#15803d' : '#991b1b'
                                                }}>
                                                    {produto.ativo ? '✓ Visível' : '✗ Oculto'}
                                                </span>
                                            </td>
                                            <td className="p-4">
                                                <div className="flex gap-2">
                                                    <Link href={`/dashboard/produtos/${produto.id}/editar`}>
                                                        <Button
                                                            variant="ghost"
                                                            className="h-8 w-8 p-0 text-blue-500 hover:text-blue-700"
                                                        >
                                                            <Edit size={16} />
                                                        </Button>
                                                    </Link>
                                                    <Button
                                                        variant="ghost"
                                                        className={`h-8 w-8 p-0 ${produto.ativo ? 'text-orange-500 hover:text-orange-700' : 'text-green-500 hover:text-green-700'}`}
                                                        onClick={() => toggleAtivo(produto.id, produto.ativo)}
                                                        title={produto.ativo ? 'Ocultar do cardápio' : 'Mostrar no cardápio'}
                                                    >
                                                        {produto.ativo ? <PowerOff size={16} /> : <Power size={16} />}
                                                    </Button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {filteredProdutos.length === 0 && (
                                        <tr>
                                            <td colSpan={5} className="p-8 text-center text-muted-foreground">
                                                {searchTerm || filterCategoria !== 'all' || filterStatus !== 'all'
                                                    ? 'Nenhum produto encontrado com os filtros aplicados.'
                                                    : 'Nenhum produto cadastrado. Clique em "Novo Produto" para começar.'}
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Informação sobre sincronização */}
            <Card className="bg-blue-50 border-blue-200">
                <CardContent className="pt-6">
                    <div className="flex gap-3">
                        <div className="text-blue-600 text-2xl">ℹ️</div>
                        <div>
                            <h3 className="font-semibold text-blue-900 mb-1">Sincronização Automática</h3>
                            <p className="text-sm text-blue-800">
                                Produtos marcados como <strong>"Visível"</strong> aparecem automaticamente no cardápio online.
                                Produtos <strong>"Ocultos"</strong> não são exibidos para os clientes, mas permanecem salvos no sistema.
                            </p>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
