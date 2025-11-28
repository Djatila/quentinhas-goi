'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/utils/supabase/client'
import { ShoppingCart, Plus, Minus, X, Phone, MapPin, User, MessageSquare, CreditCard, Banknote, Clock, LogOut } from 'lucide-react'
import { ClienteIdentificationModal } from '@/components/cliente/ClienteIdentificationModal'
import { useToast } from '@/components/ui/Toast'
import styles from './page.module.css'

interface Produto {
    id: string
    nome: string
    descricao: string
    preco: number
    categoria: string
    ativo: boolean
}

interface ItemCarrinho extends Produto {
    quantidade: number
}

interface DadosCliente {
    nome: string
    telefone: string
    endereco: string
    tipo_entrega: 'retirada' | 'delivery'
    metodo_pagamento?: 'pix' | 'cartao' | 'dinheiro' | 'pagamento_posterior'
    precisa_troco: boolean
    valor_para_troco: string
    observacoes: string
}

export default function CardapioPublicoPage() {
    const supabase = createClient()
    const { showToast } = useToast()
    const [produtos, setProdutos] = useState<Produto[]>([])
    const [carrinho, setCarrinho] = useState<ItemCarrinho[]>([])
    const [categoriaFiltro, setCategoriaFiltro] = useState<string>('todas')
    const [mostrarCarrinho, setMostrarCarrinho] = useState(false)
    const [mostrarCheckout, setMostrarCheckout] = useState(false)
    const [taxaEntrega, setTaxaEntrega] = useState(0)
    const [loading, setLoading] = useState(true)
    const [enviando, setEnviando] = useState(false)
    const [pedidoConfirmado, setPedidoConfirmado] = useState<number | null>(null)
    const [modoComplemento, setModoComplemento] = useState(false)
    const [pedidoComplementoNumero, setPedidoComplementoNumero] = useState<number | null>(null)

    // Customer identification
    const [mostrarIdentificacao, setMostrarIdentificacao] = useState(false)
    const [clienteId, setClienteId] = useState<string | null>(null)
    const [tipoCliente, setTipoCliente] = useState<'credito' | 'informal' | null>(null)

    const [configuracao, setConfiguracao] = useState({
        nome_restaurante: 'Cardápio Online',
        logo_url: '',
        taxa_entrega_padrao: 0
    })

    const [dadosCliente, setDadosCliente] = useState<DadosCliente>({
        nome: '',
        telefone: '',
        endereco: '',
        tipo_entrega: 'retirada',
        metodo_pagamento: undefined,
        precisa_troco: false,
        valor_para_troco: '',
        observacoes: ''
    })

    useEffect(() => {
        loadProdutos()
        loadConfiguracao()
        checkClienteSession()
    }, [])

    async function checkClienteSession() {
        // Verificar se há sessão de cliente salva
        const savedClienteId = sessionStorage.getItem('clienteId')
        const savedTipoCliente = sessionStorage.getItem('tipoCliente') as 'credito' | 'informal' | null

        if (savedClienteId && savedTipoCliente) {
            setClienteId(savedClienteId)
            setTipoCliente(savedTipoCliente)
            await loadClienteData(savedClienteId)
        } else {
            // Verificar se há usuário autenticado (cliente crédito)
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                const { data: cliente } = await supabase
                    .from('clientes')
                    .select('id')
                    .eq('user_id', user.id)
                    .single()

                if (cliente) {
                    setClienteId(cliente.id)
                    setTipoCliente('credito')
                    sessionStorage.setItem('clienteId', cliente.id)
                    sessionStorage.setItem('tipoCliente', 'credito')
                    await loadClienteData(cliente.id)
                } else {
                    setMostrarIdentificacao(true)
                }
            } else {
                setMostrarIdentificacao(true)
            }
        }
    }

    async function loadClienteData(id: string) {
        const { data: cliente } = await supabase
            .from('clientes')
            .select('*')
            .eq('id', id)
            .single()

        if (cliente) {
            setDadosCliente(prev => ({
                ...prev,
                nome: cliente.nome || '',
                telefone: cliente.telefone || '',
                endereco: cliente.endereco || ''
            }))
        }
    }

    async function handleLogout() {
        sessionStorage.removeItem('clienteId')
        sessionStorage.removeItem('tipoCliente')
        await supabase.auth.signOut()
        setClienteId(null)
        setTipoCliente(null)
        setMostrarIdentificacao(true)
        window.location.reload()
    }

    function handleClienteIdentified(id: string, tipo: 'credito' | 'informal') {
        setClienteId(id)
        setTipoCliente(tipo)
        sessionStorage.setItem('clienteId', id)
        sessionStorage.setItem('tipoCliente', tipo)
        setMostrarIdentificacao(false)
        loadClienteData(id)
    }

    async function loadProdutos() {
        setLoading(true)
        const { data } = await supabase
            .from('produtos')
            .select('*')
            .eq('ativo', true)
            .order('categoria', { ascending: true })
            .order('nome', { ascending: true })

        if (data) {
            setProdutos(data)
        }
        setLoading(false)
    }

    async function loadConfiguracao() {
        const { data } = await supabase
            .from('configuracoes')
            .select('taxa_entrega_padrao, nome_restaurante, logo_url')
            .single()

        if (data) {
            setConfiguracao({
                nome_restaurante: data.nome_restaurante || 'Cardápio Online',
                logo_url: data.logo_url || '',
                taxa_entrega_padrao: data.taxa_entrega_padrao || 0
            })
            setTaxaEntrega(data.taxa_entrega_padrao || 0)
        }
    }

    const categorias = ['todas', ...Array.from(new Set(produtos.map(p => p.categoria)))]

    const produtosFiltrados = categoriaFiltro === 'todas'
        ? produtos
        : produtos.filter(p => p.categoria === categoriaFiltro)

    function adicionarAoCarrinho(produto: Produto) {
        const itemExistente = carrinho.find(item => item.id === produto.id)

        if (itemExistente) {
            setCarrinho(carrinho.map(item =>
                item.id === produto.id
                    ? { ...item, quantidade: item.quantidade + 1 }
                    : item
            ))
        } else {
            setCarrinho([...carrinho, { ...produto, quantidade: 1 }])
        }
        showToast('success', 'Adicionado ao carrinho', `${produto.nome} foi adicionado!`)
    }

    function alterarQuantidade(produtoId: string, delta: number) {
        setCarrinho(carrinho.map(item => {
            if (item.id === produtoId) {
                const novaQuantidade = item.quantidade + delta
                return novaQuantidade > 0 ? { ...item, quantidade: novaQuantidade } : item
            }
            return item
        }).filter(item => item.quantidade > 0))
    }

    function removerDoCarrinho(produtoId: string) {
        setCarrinho(carrinho.filter(item => item.id !== produtoId))
    }

    const subtotal = carrinho.reduce((acc, item) => acc + (item.preco * item.quantidade), 0)
    const taxaAplicada = dadosCliente.tipo_entrega === 'delivery' ? taxaEntrega : 0
    const total = subtotal + taxaAplicada

    async function finalizarPedido() {
        if (!dadosCliente.nome || !dadosCliente.telefone) {
            alert('Por favor, preencha seu nome e telefone')
            return
        }

        if (dadosCliente.tipo_entrega === 'delivery' && !dadosCliente.endereco) {
            alert('Por favor, preencha seu endereço para entrega')
            return
        }

        if (!dadosCliente.metodo_pagamento) {
            alert('Por favor, selecione a forma de pagamento')
            return
        }

        if (dadosCliente.metodo_pagamento === 'dinheiro' && dadosCliente.precisa_troco) {
            const valorParaTroco = parseFloat(dadosCliente.valor_para_troco)
            if (!dadosCliente.valor_para_troco || isNaN(valorParaTroco) || valorParaTroco < total) {
                alert('Por favor, informe um valor válido para o troco (deve ser maior ou igual ao total)')
                return
            }
        }

        if (carrinho.length === 0) {
            alert('Seu carrinho está vazio')
            return
        }

        setEnviando(true)

        const itens = carrinho.map(item => ({
            id: item.id,
            nome: item.nome,
            quantidade: item.quantidade,
            preco: item.preco,
            subtotal: item.preco * item.quantidade
        }))

        // Modo Complemento: Atualizar pedido existente
        if (modoComplemento && pedidoComplementoNumero) {
            // Buscar pedido original
            const { data: pedidoOriginal, error: fetchError } = await supabase
                .from('pedidos_online')
                .select('*')
                .eq('numero_pedido', pedidoComplementoNumero)
                .single()

            if (fetchError || !pedidoOriginal) {
                setEnviando(false)
                alert('Erro: Pedido original não encontrado')
                return
            }

            // Calcular novos totais
            const novosItens = [...pedidoOriginal.itens, ...itens]
            const novoSubtotal = pedidoOriginal.subtotal + subtotal
            const novoTotal = pedidoOriginal.total + total

            // Criar registro de complemento para histórico
            const complemento = {
                data: new Date().toISOString(),
                itens: itens,
                subtotal: subtotal,
                total: total
            }

            const historico = Array.isArray(pedidoOriginal.historico_complementos)
                ? [...pedidoOriginal.historico_complementos, complemento]
                : [complemento]

            // Atualizar pedido
            const { error: updateError } = await supabase
                .from('pedidos_online')
                .update({
                    itens: novosItens,
                    subtotal: novoSubtotal,
                    total: novoTotal,
                    historico_complementos: historico
                })
                .eq('numero_pedido', pedidoComplementoNumero)

            setEnviando(false)

            if (updateError) {
                console.error('Erro ao adicionar complemento:', updateError)
                alert('Erro ao adicionar itens. Tente novamente.')
            } else {
                // Resetar modo complemento
                setModoComplemento(false)
                setPedidoComplementoNumero(null)
                setCarrinho([])
                setMostrarCheckout(false)
                setMostrarCarrinho(false)
                setPedidoConfirmado(pedidoComplementoNumero)
            }
        } else {
            // Modo Normal: Criar novo pedido
            const { data, error } = await supabase
                .from('pedidos_online')
                .insert({
                    cliente_id: clienteId,
                    cliente_nome: dadosCliente.nome,
                    cliente_telefone: dadosCliente.telefone,
                    cliente_endereco: dadosCliente.endereco || null,
                    tipo_entrega: dadosCliente.tipo_entrega,
                    metodo_pagamento: dadosCliente.metodo_pagamento,
                    precisa_troco: dadosCliente.precisa_troco,
                    valor_para_troco: dadosCliente.precisa_troco && dadosCliente.valor_para_troco
                        ? parseFloat(dadosCliente.valor_para_troco)
                        : null,
                    itens: itens,
                    subtotal: subtotal,
                    taxa_entrega: taxaAplicada,
                    total: total,
                    observacoes: dadosCliente.observacoes || null,
                    status: 'pendente'
                })
                .select('numero_pedido')
                .single()

            setEnviando(false)

            if (error) {
                console.error('Erro ao criar pedido:', error)
                alert('Erro ao enviar pedido. Tente novamente.')
            } else if (data) {
                setPedidoConfirmado(data.numero_pedido)
                setCarrinho([])
                setMostrarCheckout(false)
                setMostrarCarrinho(false)
            }
        }
    }

    if (pedidoConfirmado && !modoComplemento) {
        return (
            <div className={styles.confirmacao}>
                <div className={styles.confirmacaoCard}>
                    <div className={styles.confirmacaoIcone}>✓</div>
                    <h1>Pedido Confirmado!</h1>

                    <div className={styles.pedidoHeader}>
                        <p className={styles.numeroPedido}>
                            Pedido <strong>#{pedidoConfirmado}</strong>
                        </p>
                        <button
                            className={styles.botaoComplemento}
                            onClick={() => {
                                setModoComplemento(true)
                                setPedidoComplementoNumero(pedidoConfirmado)
                            }}
                        >
                            + Adicionar Itens
                        </button>
                    </div>

                    <p>Seu pedido foi recebido e está sendo preparado.</p>
                    <p className={styles.textoSecundario}>
                        {dadosCliente.tipo_entrega === 'delivery'
                            ? 'Entraremos em contato em breve para confirmar a entrega.'
                            : 'Você pode retirar seu pedido em aproximadamente 30 minutos.'}
                    </p>
                    <button
                        className={styles.botaoPrimario}
                        onClick={() => {
                            setPedidoConfirmado(null)
                            setDadosCliente({
                                nome: '',
                                telefone: '',
                                endereco: '',
                                tipo_entrega: 'retirada',
                                metodo_pagamento: undefined,
                                precisa_troco: false,
                                valor_para_troco: '',
                                observacoes: ''
                            })
                        }}
                    >
                        Fazer Novo Pedido
                    </button>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.container}>
            {/* Header */}
            <header className={styles.header}>
                <div className={styles.headerContent}>
                    {configuracao.logo_url && (
                        <div className={styles.logoWrapper}>
                            <img src={configuracao.logo_url} alt="Logo" className={styles.logo} />
                        </div>
                    )}
                    <div className={styles.tituloSubtitulo}>
                        <h1 className={styles.titulo}>{configuracao.nome_restaurante}</h1>
                        <p className={styles.subtitulo}>Faça seu pedido e receba em casa ou retire no local</p>
                    </div>
                </div>

                {tipoCliente && (
                    <button
                        className={styles.botaoSair}
                        onClick={handleLogout}
                        title="Sair / Trocar Usuário"
                    >
                        <LogOut size={20} />
                    </button>
                )}

                <button
                    className={styles.botaoCarrinho}
                    onClick={() => setMostrarCarrinho(!mostrarCarrinho)}
                >
                    <ShoppingCart size={24} />
                    {carrinho.length > 0 && (
                        <span className={styles.badgeCarrinho}>{carrinho.length}</span>
                    )}
                </button>
            </header>

            {/* Banner de Modo Complemento */}
            {modoComplemento && pedidoComplementoNumero && (
                <div className={styles.bannerComplemento}>
                    <div className={styles.bannerConteudo}>
                        <p>
                            🛒 Você está adicionando itens ao <strong>Pedido #{pedidoComplementoNumero}</strong>
                        </p>
                        <button
                            className={styles.botaoCancelar}
                            onClick={() => {
                                setModoComplemento(false)
                                setPedidoComplementoNumero(null)
                                setCarrinho([])
                            }}
                        >
                            Cancelar
                        </button>
                    </div>
                </div>
            )}

            {/* Filtros de Categoria */}
            <div className={styles.filtros}>
                {categorias.map(cat => (
                    <button
                        key={cat}
                        className={`${styles.filtroBtn} ${categoriaFiltro === cat ? styles.filtroAtivo : ''}`}
                        onClick={() => setCategoriaFiltro(cat)}
                    >
                        {cat.charAt(0).toUpperCase() + cat.slice(1)}
                    </button>
                ))}
            </div>

            {/* Lista de Produtos */}
            <div className={styles.produtos}>
                {loading ? (
                    <p className={styles.loading}>Carregando cardápio...</p>
                ) : produtosFiltrados.length === 0 ? (
                    <p className={styles.vazio}>Nenhum produto disponível nesta categoria.</p>
                ) : (
                    produtosFiltrados.map(produto => (
                        <div key={produto.id} className={styles.produtoCard}>
                            <div className={styles.produtoInfo}>
                                <h3 className={styles.produtoNome}>{produto.nome}</h3>
                                {produto.descricao && (
                                    <p className={styles.produtoDescricao}>{produto.descricao}</p>
                                )}
                                <p className={styles.produtoPreco}>
                                    R$ {produto.preco.toFixed(2)}
                                </p>
                            </div>
                            <button
                                className={styles.botaoAdicionar}
                                onClick={() => adicionarAoCarrinho(produto)}
                            >
                                <Plus size={20} />
                            </button>
                        </div>
                    ))
                )}
            </div>

            {/* Carrinho Lateral */}
            {mostrarCarrinho && (
                <div className={styles.carrinhoOverlay} onClick={() => setMostrarCarrinho(false)}>
                    <div className={styles.carrinho} onClick={(e) => e.stopPropagation()}>
                        <div className={styles.carrinhoHeader}>
                            <h2>Seu Pedido</h2>
                            <button onClick={() => setMostrarCarrinho(false)}>
                                <X size={24} />
                            </button>
                        </div>

                        {carrinho.length === 0 ? (
                            <p className={styles.carrinhoVazio}>Seu carrinho está vazio</p>
                        ) : (
                            <>
                                <div className={styles.carrinhoItens}>
                                    {carrinho.map(item => (
                                        <div key={item.id} className={styles.carrinhoItem}>
                                            <div className={styles.itemInfo}>
                                                <h4>{item.nome}</h4>
                                                <p>R$ {item.preco.toFixed(2)}</p>
                                            </div>
                                            <div className={styles.itemControles}>
                                                <button onClick={() => alterarQuantidade(item.id, -1)}>
                                                    <Minus size={16} />
                                                </button>
                                                <span>{item.quantidade}</span>
                                                <button onClick={() => alterarQuantidade(item.id, 1)}>
                                                    <Plus size={16} />
                                                </button>
                                                <button
                                                    className={styles.botaoRemover}
                                                    onClick={() => removerDoCarrinho(item.id)}
                                                >
                                                    <X size={16} />
                                                </button>
                                            </div>
                                            <p className={styles.itemSubtotal}>
                                                R$ {(item.preco * item.quantidade).toFixed(2)}
                                            </p>
                                        </div>
                                    ))}
                                </div>

                                <div className={styles.carrinhoResumo}>
                                    <div className={styles.resumoLinha}>
                                        <span>Subtotal:</span>
                                        <span>R$ {subtotal.toFixed(2)}</span>
                                    </div>
                                    <button
                                        className={styles.botaoFinalizar}
                                        onClick={() => {
                                            setMostrarCarrinho(false)
                                            setMostrarCheckout(true)
                                        }}
                                    >
                                        Finalizar Pedido
                                    </button>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            )}

            {/* Modal de Checkout */}
            {mostrarCheckout && (
                <div className={styles.checkoutOverlay} onClick={() => setMostrarCheckout(false)}>
                    <div className={styles.checkout} onClick={(e) => e.stopPropagation()}>
                        <div className={styles.checkoutHeader}>
                            <h2>Finalizar Pedido</h2>
                            <button onClick={() => setMostrarCheckout(false)}>
                                <X size={24} />
                            </button>
                        </div>

                        <div className={styles.checkoutForm}>
                            <div className={styles.formGroup}>
                                <label>
                                    <User size={18} />
                                    Nome Completo *
                                </label>
                                <input
                                    type="text"
                                    value={dadosCliente.nome}
                                    onChange={(e) => setDadosCliente({ ...dadosCliente, nome: e.target.value })}
                                    placeholder="Seu nome"
                                    required
                                />
                            </div>

                            <div className={styles.formGroup}>
                                <label>
                                    <Phone size={18} />
                                    Telefone *
                                </label>
                                <input
                                    type="tel"
                                    value={dadosCliente.telefone}
                                    onChange={(e) => setDadosCliente({ ...dadosCliente, telefone: e.target.value })}
                                    placeholder="(00) 00000-0000"
                                    required
                                />
                            </div>

                            <div className={styles.formGroup}>
                                <label>Tipo de Entrega *</label>
                                <div className={styles.tipoEntregaOpcoes}>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.tipo_entrega === 'retirada' ? styles.opcaoAtiva : ''}`}
                                        onClick={() => setDadosCliente({ ...dadosCliente, tipo_entrega: 'retirada' })}
                                    >
                                        Retirada no Local
                                    </button>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.tipo_entrega === 'delivery' ? styles.opcaoAtiva : ''}`}
                                        onClick={() => setDadosCliente({ ...dadosCliente, tipo_entrega: 'delivery' })}
                                    >
                                        Delivery
                                    </button>
                                </div>
                            </div>

                            {dadosCliente.tipo_entrega === 'delivery' && (
                                <div className={styles.formGroup}>
                                    <label>
                                        <MapPin size={18} />
                                        Endereço Completo *
                                    </label>
                                    <input
                                        type="text"
                                        value={dadosCliente.endereco}
                                        onChange={(e) => setDadosCliente({ ...dadosCliente, endereco: e.target.value })}
                                        placeholder="Rua, número, bairro"
                                        required
                                    />
                                </div>
                            )}

                            <div className={styles.formGroup}>
                                <label>Forma de Pagamento *</label>
                                <div className={styles.tipoEntregaOpcoes}>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.metodo_pagamento === 'pix' ? styles.opcaoAtiva : ''}`}
                                        onClick={() => setDadosCliente({ ...dadosCliente, metodo_pagamento: 'pix', precisa_troco: false, valor_para_troco: '' })}
                                    >
                                        💳 PIX
                                    </button>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.metodo_pagamento === 'cartao' ? styles.opcaoAtiva : ''}`}
                                        onClick={() => setDadosCliente({ ...dadosCliente, metodo_pagamento: 'cartao', precisa_troco: false, valor_para_troco: '' })}
                                    >
                                        <CreditCard size={16} /> Cartão
                                    </button>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.metodo_pagamento === 'dinheiro' ? styles.opcaoAtiva : ''}`}
                                        onClick={() => setDadosCliente({ ...dadosCliente, metodo_pagamento: 'dinheiro' })}
                                    >
                                        <Banknote size={16} /> Dinheiro
                                    </button>
                                    <button
                                        className={`${styles.opcaoBtn} ${dadosCliente.metodo_pagamento === 'pagamento_posterior' ? styles.opcaoAtiva : ''} ${tipoCliente === 'informal' ? styles.opcaoDesabilitada : ''}`}
                                        onClick={() => tipoCliente === 'credito' && setDadosCliente({ ...dadosCliente, metodo_pagamento: 'pagamento_posterior', precisa_troco: false, valor_para_troco: '' })}
                                        disabled={tipoCliente === 'informal'}
                                        title={tipoCliente === 'informal' ? 'Disponível apenas para clientes crédito' : ''}
                                    >
                                        <Clock size={16} /> Pagar Depois
                                    </button>
                                </div>
                            </div>

                            {dadosCliente.metodo_pagamento === 'dinheiro' && (
                                <div className={styles.formGroup}>
                                    <label>Precisa de troco?</label>
                                    <div className={styles.tipoEntregaOpcoes}>
                                        <button
                                            className={`${styles.opcaoBtn} ${dadosCliente.precisa_troco ? styles.opcaoAtiva : ''}`}
                                            onClick={() => setDadosCliente({ ...dadosCliente, precisa_troco: true })}
                                        >
                                            Sim
                                        </button>
                                        <button
                                            className={`${styles.opcaoBtn} ${!dadosCliente.precisa_troco ? styles.opcaoAtiva : ''}`}
                                            onClick={() => setDadosCliente({ ...dadosCliente, precisa_troco: false, valor_para_troco: '' })}
                                        >
                                            Não
                                        </button>
                                    </div>
                                    {dadosCliente.precisa_troco && (
                                        <div>
                                            <label style={{ marginTop: '1rem' }}>Troco para quanto?</label>
                                            <input
                                                type="number"
                                                step="0.01"
                                                min={total}
                                                value={dadosCliente.valor_para_troco}
                                                onChange={(e) => setDadosCliente({ ...dadosCliente, valor_para_troco: e.target.value })}
                                                placeholder="Ex: 50.00"
                                            />
                                            {dadosCliente.valor_para_troco && parseFloat(dadosCliente.valor_para_troco) >= total && (
                                                <p style={{ marginTop: '0.5rem', color: '#22c55e', fontWeight: 500 }}>
                                                    Troco: R$ {(parseFloat(dadosCliente.valor_para_troco) - total).toFixed(2)}
                                                </p>
                                            )}
                                        </div>
                                    )}
                                </div>
                            )}

                            <div className={styles.formGroup}>
                                <label>
                                    <MessageSquare size={18} />
                                    Observações
                                </label>
                                <textarea
                                    value={dadosCliente.observacoes}
                                    onChange={(e) => setDadosCliente({ ...dadosCliente, observacoes: e.target.value })}
                                    placeholder="Alguma observação sobre seu pedido?"
                                    rows={3}
                                />
                            </div>

                            <div className={styles.resumoFinal}>
                                <div className={styles.resumoLinha}>
                                    <span>Subtotal:</span>
                                    <span>R$ {subtotal.toFixed(2)}</span>
                                </div>
                                {dadosCliente.tipo_entrega === 'delivery' && (
                                    <div className={styles.resumoLinha}>
                                        <span>Taxa de Entrega:</span>
                                        <span>R$ {taxaAplicada.toFixed(2)}</span>
                                    </div>
                                )}
                                <div className={`${styles.resumoLinha} ${styles.resumoTotal}`}>
                                    <span>Total:</span>
                                    <span>R$ {total.toFixed(2)}</span>
                                </div>
                            </div>

                            <button
                                className={styles.botaoConfirmar}
                                onClick={finalizarPedido}
                                disabled={enviando}
                            >
                                {enviando ? 'Enviando...' : 'Confirmar Pedido'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Modal de Identificação do Cliente */}
            <ClienteIdentificationModal
                isOpen={mostrarIdentificacao}
                onClienteIdentified={handleClienteIdentified}
            />
        </div>
    )
}
