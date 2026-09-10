-- ============================================================
-- AULA 07 — Funções SQL (SISTEMA_VENDAS)
-- CORREÇÃO — UMA QUERY POR EXERCÍCIO
-- ============================================================

USE SISTEMA_VENDAS;
GO

-- ============================================================
-- EXERCÍCIO 01 (Básico)
-- Painel de KPIs: total de clientes, pedidos, faturamento total
-- (excluindo cancelados), ticket médio, produto mais caro e mais barato.
-- ============================================================
SELECT
    COUNT(DISTINCT c.id_cliente)                              AS total_clientes,
    COUNT(p.id_pedido)                                        AS total_pedidos,
    SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.total ELSE 0 END) AS faturamento,
    ROUND(AVG(CASE WHEN p.status <> 'CANCELADO' THEN p.total END), 2) AS ticket_medio,
    MIN(pr.preco_min)                                         AS produto_mais_barato,
    MAX(pr.preco_max)                                         AS produto_mais_caro
FROM CLIENTE c
LEFT JOIN PEDIDO p ON c.id_cliente = p.id_cliente
CROSS JOIN (SELECT MIN(preco) AS preco_min, MAX(preco) AS preco_max FROM PRODUTO) pr;


-- ============================================================
-- EXERCÍCIO 02 (Básico)
-- Relatório de clientes: primeiro nome, nome em maiúsculas
-- e label 'CIDADE/UF' em um único campo.
-- ============================================================
SELECT
    nome,
    SUBSTRING(nome, 1, ISNULL(NULLIF(CHARINDEX(' ', nome), 0) - 1, LEN(nome))) AS primeiro_nome,
    UPPER(nome)                     AS nome_maiusculo,
    CONCAT(cidade, '/', estado)     AS cidade_uf
FROM CLIENTE
ORDER BY nome;


-- ============================================================
-- EXERCÍCIO 03 (Médio)
-- Dias desde o pedido, previsão de entrega (+7 dias) e situação
-- (ATRASADO/OK) usando DATEDIFF, DATEADD e CASE.
-- ============================================================
SELECT
    id_pedido,
    FORMAT(data_pedido, 'dd/MM/yyyy')                         AS pedido_em,
    FORMAT(DATEADD(DAY, 7, data_pedido), 'dd/MM/yyyy')        AS previsao_entrega,
    DATEDIFF(DAY, data_pedido, GETDATE())                     AS dias_decorridos,
    CASE
        WHEN DATEADD(DAY, 7, data_pedido) < GETDATE()
             AND status NOT IN ('ENTREGUE', 'CANCELADO') THEN 'ATRASADO'
        ELSE 'OK'
    END                                                        AS situacao
FROM PEDIDO
ORDER BY dias_decorridos DESC;


-- ============================================================
-- EXERCÍCIO 04 (Médio)
-- Comissões: agrupar pedidos por funcionário, somar faturamento,
-- calcular 5% de comissão (ROUND 2), tratando quem não vendeu com ISNULL.
-- ============================================================
SELECT
    f.nome                                                    AS vendedor,
    ISNULL(SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.total END), 0) AS faturamento,
    ROUND(ISNULL(SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.total END), 0) * 0.05, 2) AS comissao_5pct
FROM FUNCIONARIO f
LEFT JOIN PEDIDO p ON p.id_funcionario = f.id_funcionario
GROUP BY f.nome
ORDER BY faturamento DESC;


-- ============================================================
-- EXERCÍCIO 05 (Avançado)
-- Relatório de produtos: nome em UPPER, preço em formato moeda,
-- valor em estoque, classificação por estoque e previsão de reposição.
-- ============================================================
SELECT
    UPPER(nome_produto)                            AS produto,
    FORMAT(preco, 'C', 'pt-BR')                     AS preco_formatado,
    FORMAT(preco * estoque, 'C', 'pt-BR')           AS valor_em_estoque,
    CASE
        WHEN estoque = 0               THEN 'Sem Estoque'
        WHEN estoque < 10              THEN 'Baixo'
        WHEN estoque BETWEEN 10 AND 50 THEN 'Normal'
        ELSE 'Alto'
    END                                              AS classificacao_estoque,
    100 / NULLIF(estoque, 0)                        AS indice_reposicao
FROM PRODUTO
ORDER BY estoque ASC;
