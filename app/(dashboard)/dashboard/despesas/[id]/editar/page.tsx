'use client'

import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { createClient } from '@/utils/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

export default function EditarDespesaPage() {
    const router = useRouter()
    const params = useParams()
    const id = params.id as string
    const supabase = createClient()
    const [loading, setLoading] = useState(false)
    const [loadingData, setLoadingData] = useState(true)
    const [categorias, setCategorias] = useState<{ id: string, nome: string }[]>([])

    const [formData, setFormData] = useState({
        categoria: '',
        descricao: '',
        valor: '',
        fornecedor: ''
    })

    useEffect(() => {
        async function loadData() {
            // Carregar categorias
            const { data: cats } = await supabase
                .from('categorias')
                .select('id, nome')
                .eq('tipo', 'saida')

            if (cats) {
                setCategorias(cats)
            }

            // Carregar despesa
            const { data, error } = await supabase
                .from('despesas')
                .select('*')
                .eq('id', id)
                .single()

            if (error) {
                alert('Erro ao carregar despesa: ' + error.message)
                router.push('/dashboard/despesas')
                return
            }

            if (data) {
                setFormData({
                    categoria: data.categoria,
                    descricao: data.descricao,
                    valor: String(data.valor || 0),
                    fornecedor: data.fornecedor || ''
                })
            }

            setLoadingData(false)
        }

        loadData()
    }, [id])

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        const { error } = await supabase
            .from('despesas')
            .update({
                categoria: formData.categoria,
                descricao: formData.descricao,
                valor: Number(formData.valor),
                fornecedor: formData.fornecedor || null,
            })
            .eq('id', id)

        if (error) {
            alert('Erro ao atualizar despesa: ' + error.message)
            setLoading(false)
        } else {
            router.push('/dashboard/despesas')
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
                <Link href="/dashboard/despesas">
                    <Button variant="ghost">
                        <ArrowLeft size={20} />
                    </Button>
                </Link>
                <h1 className="text-2xl font-bold">Editar Despesa</h1>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Atualizar Despesa</CardTitle>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium">Categoria</label>
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
                                {loading ? 'Salvando...' : 'Atualizar Despesa'}
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
