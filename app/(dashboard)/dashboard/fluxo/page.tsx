import { createClient } from '@/utils/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'

async function getFluxoCaixa() {
    const supabase = createClient()
    const { data } = await supabase
        .from('fluxo_caixa')
        .select('*')
        .order('data', { ascending: false })
        .limit(30)

    return data || []
}

export default async function FluxoCaixaPage() {
    const fluxo = await getFluxoCaixa()

    return (
        <div className="flex flex-col gap-6">
            <div>
                <h1 className="text-2xl font-bold">Fluxo de Caixa</h1>
                <p className="text-muted-foreground">Acompanhamento diário de entradas e saídas</p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Movimentação Diária (Últimos 30 dias)</CardTitle>
                </CardHeader>
                <CardContent>
                    <div style={{ overflowX: 'auto' }}>
                        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                            <thead>
                                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                                    <th className="p-4 font-medium text-muted-foreground">Data</th>
                                    <th className="p-4 font-medium text-muted-foreground text-green-600">Entradas</th>
                                    <th className="p-4 font-medium text-muted-foreground text-red-600">Saídas</th>
                                    <th className="p-4 font-medium text-muted-foreground">Saldo do Dia</th>
                                    {/* <th className="p-4 font-medium text-muted-foreground">Acumulado</th> */}
                                </tr>
                            </thead>
                            <tbody>
                                {fluxo.map((item) => (
                                    <tr key={item.id} style={{ borderBottom: '1px solid var(--border)' }}>
                                        <td className="p-4">{new Date(item.data).toLocaleDateString()}</td>
                                        <td className="p-4 text-green-600">R$ {item.entrada_total.toFixed(2)}</td>
                                        <td className="p-4 text-red-600">R$ {item.saida_total.toFixed(2)}</td>
                                        <td className="p-4 font-bold" style={{ color: item.saldo_do_dia >= 0 ? 'var(--primary)' : 'var(--destructive)' }}>
                                            R$ {item.saldo_do_dia.toFixed(2)}
                                        </td>
                                        {/* <td className="p-4">R$ {item.saldo_acumulado.toFixed(2)}</td> */}
                                    </tr>
                                ))}
                                {fluxo.length === 0 && (
                                    <tr>
                                        <td colSpan={4} className="p-8 text-center text-muted-foreground">
                                            Nenhum registro de fluxo encontrado.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
