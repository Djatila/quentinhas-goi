'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ArrowLeft, Plus, Check, X } from 'lucide-react'
import Link from 'next/link'

export default function NovaDespesaPage() {
    const router = useRouter()
    const supabase = createClient()
    const [loading, setLoading] = useState(false)
    const [categorias, setCategorias] = useState<{ id: string, nome: string }[]>([])
    const [showNovaCategoria, setShowNovaCategoria] = useState(false)
    const [novaCategoriaNome, setNovaCategoriaNome] = useState('')
    const [salvandoCategoria, setSalvandoCategoria] = useState(false)

    const [formData, setFormData] = useState({
        categoria: '',
        descricao: '',
        valor: '',
        fornecedor: ''
    })

    useEffect(() => {
        loadCategorias()
    }, [])

    async function loadCategorias() {
        const { data } = await supabase
            .from('categorias')
            .select('id, nome')
            .eq('tipo', 'saida')
            .order('nome')

        if (data) {
            setCategorias(data)
            if (data.length > 0 && !formData.categoria) {
                setFormData(prev => ({ ...prev, categoria: data[0].nome }))
            }
        }
    }

    async function salvarNovaCategoria() {
        if (!novaCategoriaNome.trim()) {
            alert('Por favor, insira um nome para a categoria')
            return
        }

        setSalvandoCategoria(true)

        const { data, error } = await supabase
            .from('categorias')
            .insert({
                nome: novaCategoriaNome.trim(),
                tipo: 'saida'
            })
            .select()

        if (error) {
            alert('Erro ao criar categoria: ' + error.message)
            setSalvandoCategoria(false)
        } else {
            // Recarregar categorias
            await loadCategorias()
            // Selecionar a nova categoria
            setFormData(prev => ({ ...prev, categoria: novaCategoriaNome.trim() }))
            // Limpar e fechar o formulário de nova categoria
            setNovaCategoriaNome('')
            setShowNovaCategoria(false)
            setSalvandoCategoria(false)
        }
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        const { data: { user } } = await supabase.auth.getUser()

        const { error } = await supabase.from('despesas').insert({
            categoria: formData.categoria,
            descricao: formData.descricao,
            valor: Number(formData.valor),
            fornecedor: formData.fornecedor || null,
            criado_por: user?.id,
            data: new Date().toISOString()
        })

        if (error) {
            alert('Erro ao salvar despesa: ' + error.message)
            setLoading(false)
        } else {
            router.push('/dashboard/despesas')
            router.refresh()
        }
    }

    return (
        <div className="flex flex-col gap-6 max-w-2xl mx-auto">
            <div className="flex items-center gap-4">
                <Link href="/dashboard/despesas">
                    <Button variant="ghost">
                        <ArrowLeft size={20} />
                    </Button>
                </Link>
                <h1 className="text-2xl font-bold">Nova Despesa</h1>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Registrar Despesa</CardTitle>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="flex flex-col gap-2">
                                <div className="flex items-center justify-between">
                                    <label className="text-sm font-medium">Categoria</label>
                                    <button
                                        type="button"
                                        onClick={() => setShowNovaCategoria(!showNovaCategoria)}
                                        className="text-xs text-blue-600 hover:text-blue-700 flex items-center gap-1"
                                    >
                                        {showNovaCategoria ? (
                                            <>
                                                <X size={14} />
                                                Cancelar
                                            </>
                                        ) : (
                                            <>
                                                <Plus size={14} />
                                                Nova Categoria
                                            </>
                                        )}
                                    </button>
                                </div>

                                {showNovaCategoria ? (
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                                            placeholder="Nome da nova categoria"
                                            value={novaCategoriaNome}
                                            onChange={(e) => setNovaCategoriaNome(e.target.value)}
                                            onKeyDown={(e) => {
                                                if (e.key === 'Enter') {
                                                    e.preventDefault()
                                                    salvarNovaCategoria()
                                                }
                                            }}
                                        />
                                        <Button
                                            type="button"
                                            onClick={salvarNovaCategoria}
                                            disabled={salvandoCategoria || !novaCategoriaNome.trim()}
                                            className="px-3"
                                        >
                                            <Check size={16} />
                                        </Button>
                                    </div>
                                ) : (
                                    <select
                                        className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                                        value={formData.categoria}
                                        onChange={(e) => setFormData({ ...formData, categoria: e.target.value })}
                                        required
                                    >
                                        <option value="" disabled>Selecione...</option>
                                        {categorias.map(cat => (
                                            <option key={cat.id} value={cat.nome}>{cat.nome}</option>
                                        ))}
                                    </select>
                                )}
                            </div>

                            <Input
                                label="Valor (R$)"
                                type="number"
                                step="0.01"
                                min="0"
                                placeholder="0.00"
                                value={formData.valor}
                                onChange={(e) => setFormData({ ...formData, valor: e.target.value })}
                                required
                            />
                        </div>

                        <Input
                            label="Descrição"
                            placeholder="Ex: Compra de arroz"
                            value={formData.descricao}
                            onChange={(e) => setFormData({ ...formData, descricao: e.target.value })}
                            required
                        />

                        <Input
                            label="Fornecedor (Opcional)"
                            placeholder="Ex: Atacadão"
                            value={formData.fornecedor}
                            onChange={(e) => setFormData({ ...formData, fornecedor: e.target.value })}
                        />

                        <div className="flex justify-end gap-4 mt-4">
                            <Link href="/dashboard/despesas">
                                <Button type="button" variant="secondary">Cancelar</Button>
                            </Link>
                            <Button type="submit" variant="destructive" disabled={loading}>
                                {loading ? 'Salvando...' : 'Salvar Despesa'}
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
