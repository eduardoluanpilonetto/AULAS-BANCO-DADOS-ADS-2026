/* =====================================================================
   EXERCÍCIO 01 (Básico)
   Contar clientes por estado, mostrar apenas estados com mais de
   1 cliente e ordenar pelo total de clientes decrescente.
   ===================================================================== */
SELECT estado,
       COUNT(*) AS total_clientes
FROM   CLIENTE
GROUP  BY estado
HAVING COUNT(*) > 1                 -- filtra GRUPOS (depois do GROUP BY)
ORDER  BY total_clientes DESC;      -- ORDER BY pode usar o alias do SELECT
GO


/* =====================================================================
   EXERCÍCIO 02 (Básico)
   Por categoria de produto: quantidade de produtos, preço mínimo,
   máximo e médio e total de estoque. Ordenar pelo preço médio desc.
   ===================================================================== */
SELECT id_categoria,
       COUNT(*)           AS qtd_produtos,
       MIN(preco)         AS preco_min,
       MAX(preco)         AS preco_max,
       AVG(preco)         AS preco_medio,
       SUM(estoque)       AS estoque_total
FROM   PRODUTO
GROUP  BY id_categoria
ORDER  BY preco_medio DESC;
GO

-- Variação: mostrando o NOME da categoria (exige JOIN - tema da Aula 10)
SELECT c.nome_categoria,
       COUNT(*)           AS qtd_produtos,
       MIN(p.preco)       AS preco_min,
       MAX(p.preco)       AS preco_max,
       AVG(p.preco)       AS preco_medio,
       SUM(p.estoque)     AS estoque_total
FROM   PRODUTO p
JOIN   CATEGORIA c ON c.id_categoria = p.id_categoria
GROUP  BY c.id_categoria, c.nome_categoria
ORDER  BY preco_medio DESC;
GO


/* =====================================================================
   EXERCÍCIO 03 (Médio)
   Faturamento por mês: GROUP BY com YEAR e MONTH, COUNT de pedidos,
   SUM e AVG do total. Excluir cancelados com WHERE e mostrar apenas
   meses com faturamento > R$ 100.
   ===================================================================== */
SELECT YEAR(data_pedido)   AS ano,
       MONTH(data_pedido)  AS mes,
       COUNT(*)            AS total_pedidos,
       SUM(total)          AS faturamento,
       ROUND(AVG(total),2) AS ticket_medio
FROM   PEDIDO
WHERE  status <> 'CANCELADO'                       -- filtra linhas ANTES do GROUP BY
GROUP  BY YEAR(data_pedido), MONTH(data_pedido)
HAVING SUM(total) > 100                            -- filtra grupos DEPOIS do GROUP BY
ORDER  BY ano, mes;
GO


/* =====================================================================
   EXERCÍCIO 04 (Médio)
   'Clientes fiéis': mais de 1 pedido não cancelado. Mostrar id_cliente,
   total de pedidos, soma gasta e média por pedido. Ordenar pela soma
   gasta (desc).
   ===================================================================== */
SELECT p.id_cliente,
       COUNT(*)             AS total_pedidos,
       SUM(p.total)         AS soma_gasta,
       ROUND(AVG(p.total),2) AS media_pedido
FROM   PEDIDO p
WHERE  p.status <> 'CANCELADO'
GROUP  BY p.id_cliente
HAVING COUNT(*) > 1
ORDER  BY soma_gasta DESC;
GO

-- Variação: incluindo o nome do cliente (JOIN necessário)
SELECT c.id_cliente,
       c.nome,
       COUNT(*)              AS total_pedidos,
       SUM(p.total)          AS soma_gasta,
       ROUND(AVG(p.total),2) AS media_pedido
FROM   PEDIDO p
JOIN   CLIENTE c ON c.id_cliente = p.id_cliente
WHERE  p.status <> 'CANCELADO'
GROUP  BY c.id_cliente, c.nome      -- id_cliente evita juntar homônimos
HAVING COUNT(*) > 1
ORDER  BY soma_gasta DESC;
GO


/* =====================================================================
   EXERCÍCIO 05 (Avançado)
   ROLLUP para relatório de clientes por estado com subtotal por estado
   e total geral. GROUPING() para trocar o NULL da linha de total por
   'TOTAL GERAL'. Depois, ROW_NUMBER para numerar cada cliente dentro
   do seu estado.
   ===================================================================== */

-- 05.a) ROLLUP + GROUPING(): quantidade de clientes por estado + total geral
SELECT CASE WHEN GROUPING(estado) = 1 THEN 'TOTAL GERAL'
            ELSE ISNULL(estado, 'Sem estado')
       END          AS estado_label,
       COUNT(*)     AS qtd_clientes
FROM   CLIENTE
GROUP  BY ROLLUP(estado)
ORDER  BY GROUPING(estado), estado;      -- total geral sempre na última linha
GO

-- 05.b) ROW_NUMBER: numerando cada cliente dentro do seu estado
SELECT ISNULL(estado, 'Sem estado')                          AS estado,
       ROW_NUMBER() OVER (PARTITION BY estado ORDER BY nome) AS nr_no_estado,
       nome
FROM   CLIENTE
ORDER  BY estado, nr_no_estado;
GO

-- 05.c) Tudo junto: cada cliente numerado + subtotal por estado + total geral
--       (a Window Function é aplicada fora do CTE, depois do ROLLUP)
WITH rollup_clientes AS (
    SELECT estado,
           id_cliente,
           MAX(nome)            AS nome,
           COUNT(*)             AS qtd,
           GROUPING(estado)     AS g_estado,
           GROUPING(id_cliente) AS g_cliente
    FROM   CLIENTE
    GROUP  BY ROLLUP(estado, id_cliente)
)
SELECT CASE WHEN g_estado = 1 THEN 'TOTAL GERAL'
            ELSE ISNULL(estado, 'Sem estado')
       END AS estado,
       CASE WHEN g_estado  = 1 THEN NULL
            WHEN g_cliente = 1 THEN '--- Subtotal do estado ---'
            ELSE nome
       END AS cliente,
       CASE WHEN g_cliente = 0
            THEN ROW_NUMBER() OVER (PARTITION BY g_estado, estado, g_cliente
                                    ORDER BY nome, id_cliente)
       END AS nr_no_estado,
       qtd
FROM   rollup_clientes
ORDER  BY g_estado, estado, g_cliente, nome;
GO


/* =====================================================================
   DESAFIO DA AULA 09 - DASHBOARD ANALÍTICO DO SISTEMA_VENDAS
   Cada query gera um 'card' de métricas.
   ===================================================================== */

/* ---------------------------------------------------------------------
   C1 - Ranking de produtos: nome, preço, estoque, valor_em_estoque e
        posição por valor (RANK), agrupado por categoria com subtotal
        por categoria (ROLLUP).
   --------------------------------------------------------------------- */
WITH agrupado AS (
    SELECT c.nome_categoria,
           p.id_produto,
           MAX(p.nome_produto)       AS nome_produto,
           MAX(p.preco)              AS preco,
           SUM(p.estoque)            AS estoque,
           SUM(p.preco * p.estoque)  AS valor_em_estoque,
           GROUPING(c.nome_categoria) AS g_cat,
           GROUPING(p.id_produto)     AS g_prod
    FROM   PRODUTO p
    JOIN   CATEGORIA c ON c.id_categoria = p.id_categoria
    GROUP  BY ROLLUP(c.nome_categoria, p.id_produto)
)
SELECT CASE WHEN g_cat = 1 THEN 'TOTAL GERAL' ELSE nome_categoria END AS categoria,
       CASE WHEN g_cat  = 1 THEN NULL
            WHEN g_prod = 1 THEN '--- Subtotal da categoria ---'
            ELSE nome_produto
       END                                   AS produto,
       CASE WHEN g_prod = 0 THEN preco END   AS preco,
       estoque,
       valor_em_estoque,
       CASE WHEN g_prod = 0
            THEN RANK() OVER (PARTITION BY g_cat, nome_categoria, g_prod
                              ORDER BY valor_em_estoque DESC)
       END                                   AS posicao_na_categoria
FROM   agrupado
ORDER  BY g_cat, nome_categoria, g_prod, valor_em_estoque DESC;
GO

-- C1 (variação simples): ranking GERAL de todos os produtos por valor em estoque
SELECT nome_produto,
       preco,
       estoque,
       preco * estoque                                  AS valor_em_estoque,
       RANK() OVER (ORDER BY preco * estoque DESC)      AS posicao_geral
FROM   PRODUTO
ORDER  BY posicao_geral;
GO


/* ---------------------------------------------------------------------
   C2 - Performance de vendedores: nome, pedidos entregues (COUNT CASE),
        faturamento (SUM CASE), ticket médio e comissão de 5%.
        Apenas quem tem faturamento > 0 (HAVING).
   --------------------------------------------------------------------- */
SELECT f.nome                                              AS vendedor,
       COUNT(CASE WHEN p.status = 'ENTREGUE' THEN 1 END)   AS pedidos_entregues,
       SUM(CASE WHEN p.status <> 'CANCELADO'
                THEN p.total ELSE 0 END)                   AS faturamento,
       ROUND(AVG(CASE WHEN p.status <> 'CANCELADO'
                      THEN p.total END), 2)                AS ticket_medio,
       ROUND(SUM(CASE WHEN p.status <> 'CANCELADO'
                      THEN p.total ELSE 0 END) * 0.05, 2)  AS comissao_5pct
FROM   FUNCIONARIO f
LEFT   JOIN PEDIDO p ON p.id_funcionario = f.id_funcionario
GROUP  BY f.id_funcionario, f.nome
HAVING SUM(CASE WHEN p.status <> 'CANCELADO'
                THEN p.total ELSE 0 END) > 0               -- só quem vendeu algo
ORDER  BY faturamento DESC;
GO


/* ---------------------------------------------------------------------
   C3 - Análise de clientes por UF: estado, total de clientes, clientes
        com email (COUNT(email)), % com email (CAST) e total gasto pelos
        clientes daquele estado (subquery). Ordenar por total de clientes.
   --------------------------------------------------------------------- */
SELECT c.estado,
       COUNT(*)                                             AS total_clientes,
       COUNT(c.email)                                       AS clientes_com_email,  -- COUNT(coluna) ignora NULL
       CAST(COUNT(c.email) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS pct_com_email,
       ISNULL((SELECT SUM(p.total)
               FROM   PEDIDO p
               JOIN   CLIENTE c2 ON c2.id_cliente = p.id_cliente
               WHERE  c2.estado = c.estado
                 AND  p.status <> 'CANCELADO'), 0)          AS total_gasto
FROM   CLIENTE c
GROUP  BY c.estado
ORDER  BY total_clientes DESC;
GO


/* ---------------------------------------------------------------------
   C4 - Evolução mensal: ano, mês (DATENAME), pedidos, faturamento e
        variação em relação ao mês anterior (LAG). Apenas pedidos não
        cancelados.
   --------------------------------------------------------------------- */
-- SET LANGUAGE Portuguese;   -- descomente para nomes de mês em português

WITH mensal AS (
    SELECT YEAR(data_pedido)  AS ano,
           MONTH(data_pedido) AS mes_num,
           COUNT(*)           AS pedidos,
           SUM(total)         AS faturamento
    FROM   PEDIDO
    WHERE  status <> 'CANCELADO'
    GROUP  BY YEAR(data_pedido), MONTH(data_pedido)
)
SELECT ano,
       DATENAME(MONTH, DATEFROMPARTS(ano, mes_num, 1)) AS mes,
       pedidos,
       faturamento,
       faturamento - LAG(faturamento) OVER (ORDER BY ano, mes_num) AS variacao_rs,
       CAST((faturamento - LAG(faturamento) OVER (ORDER BY ano, mes_num)) * 100.0
            / NULLIF(LAG(faturamento) OVER (ORDER BY ano, mes_num), 0)
            AS DECIMAL(10,2))                                      AS variacao_pct
FROM   mensal
ORDER  BY ano, mes_num;
GO


/* ---------------------------------------------------------------------
   C5 - BÔNUS: TOP 3 produtos mais vendidos (quantidade total em
        ITEM_PEDIDO) com DENSE_RANK, incluindo nome do produto e categoria.
   --------------------------------------------------------------------- */
WITH vendidos AS (
    SELECT p.id_produto,
           p.nome_produto,
           c.nome_categoria,
           SUM(i.quantidade)                                AS qtd_total,
           DENSE_RANK() OVER (ORDER BY SUM(i.quantidade) DESC) AS posicao
    FROM   ITEM_PEDIDO i
    JOIN   PRODUTO   p ON p.id_produto   = i.id_produto
    JOIN   CATEGORIA c ON c.id_categoria = p.id_categoria
    GROUP  BY p.id_produto, p.nome_produto, c.nome_categoria
)
SELECT posicao,
       nome_produto,
       nome_categoria,
       qtd_total
FROM   vendidos
WHERE  posicao <= 3                -- DENSE_RANK: empates ficam na mesma posição
ORDER  BY posicao, nome_produto;
GO

-- Obs.: para desconsiderar itens de pedidos cancelados, acrescente
--   JOIN PEDIDO ped ON ped.id_pedido = i.id_pedido
--   WHERE ped.status <> 'CANCELADO'
-- dentro do CTE "vendidos", antes do GROUP BY.
