/* =====================================================================
   EXERCÍCIO 01 (Básico)
   Subquery escalar no WHERE para listar produtos com preço acima da
   média geral. Mostrar também o desvio em relação à média (preco - avg)
   no SELECT.
   ===================================================================== */
SELECT nome_produto,
       preco,
       (SELECT AVG(preco) FROM PRODUTO)         AS media_geral,
       preco - (SELECT AVG(preco) FROM PRODUTO) AS desvio_media
FROM   PRODUTO
WHERE  preco > (SELECT AVG(preco) FROM PRODUTO)
ORDER  BY desvio_media DESC;

/* =====================================================================
   EXERCÍCIO 02 (Básico)
   IN com subquery para encontrar clientes que fizeram pelo menos um
   pedido com status 'ENTREGUE'. Comparar com a versão JOIN.
   ===================================================================== */

-- Versão 1: Subquery com IN
SELECT nome, estado
FROM   CLIENTE
WHERE  id_cliente IN (
           SELECT id_cliente
           FROM   PEDIDO
           WHERE  status = 'ENTREGUE'
             AND  id_cliente IS NOT NULL   -- segurança contra NULL
       )
ORDER  BY nome;

-- Versão 2: INNER JOIN (precisa de DISTINCT para evitar duplicatas)
SELECT DISTINCT c.nome, c.estado
FROM   CLIENTE c
INNER  JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  p.status = 'ENTREGUE'
ORDER  BY c.nome;

/* =====================================================================
   EXERCÍCIO 03 (Médio)
   EXISTS para encontrar pedidos que contêm pelo menos um produto da
   categoria Eletrônicos (id_categoria = 1). Mostrar id_pedido, cliente
   (nome via subquery no SELECT) e status.
   ===================================================================== */

SELECT p.id_pedido,
       (SELECT c.nome
        FROM   CLIENTE c
        WHERE  c.id_cliente = p.id_cliente) AS cliente,   -- subquery escalar no SELECT
       p.status
FROM   PEDIDO p
WHERE  EXISTS (
           SELECT 1
           FROM   ITEM_PEDIDO ip
           INNER  JOIN PRODUTO pr ON ip.id_produto = pr.id_produto
           WHERE  ip.id_pedido    = p.id_pedido           -- correlação com a query externa
             AND  pr.id_categoria = 1                     -- Eletrônicos
       )
ORDER  BY p.id_pedido;

/* =====================================================================
   EXERCÍCIO 04 (Médio)
   Subquery no FROM (derived table) para calcular o total por cliente em
   PEDIDOS, depois JOIN com CLIENTES para mostrar nome, estado, total e
   classificação (VIP / Regular / Inativo).
   ===================================================================== */
SELECT c.nome,
       c.estado,
       ISNULL(totais.gasto, 0)                  AS gasto_total,
       CASE WHEN totais.gasto IS NULL THEN 'Inativo'
            WHEN totais.gasto > 1000  THEN 'VIP'
            ELSE 'Regular'
       END                                      AS perfil
FROM   CLIENTE c
LEFT   JOIN (
           SELECT id_cliente, SUM(total) AS gasto
           FROM   PEDIDO
           WHERE  status <> 'CANCELADO'
           GROUP  BY id_cliente
       ) AS totais ON c.id_cliente = totais.id_cliente   -- alias é OBRIGATÓRIO
ORDER  BY gasto_total DESC;

/* =====================================================================
   EXERCÍCIO 05 (Avançado)
   Subquery correlacionada: para cada produto, mostrar nome, preço e se
   ele é o mais caro da sua categoria ('Destaque' ou 'Normal'). Usar
   subquery correlacionada com MAX.
   ===================================================================== */
SELECT pr.nome_produto,
       pr.preco,
       cat.nome_categoria,
       CASE WHEN pr.preco = (
                     SELECT MAX(p2.preco)
                     FROM   PRODUTO p2
                     WHERE  p2.id_categoria = pr.id_categoria   -- correlação!
                 )
            THEN 'Destaque'
            ELSE 'Normal'
       END AS situacao
FROM   PRODUTO pr
INNER  JOIN CATEGORIA cat ON pr.id_categoria = cat.id_categoria
ORDER  BY cat.nome_categoria, pr.preco DESC;

/* =====================================================================
   DESAFIO DA AULA 13
   Contexto: o CTO solicitou um sistema de análise avançada usando
   subqueries - comparações relativas, rankings e detecção de anomalias.
   ===================================================================== */

/* ---------------------------------------------------------------------
   S1 - Análise de preço relativo
   Para cada produto: preço, média da categoria e % acima/abaixo da
   média. Usar subquery escalar correlacionada.
   --------------------------------------------------------------------- */

SELECT pr.nome_produto,
       pr.preco,
       (SELECT AVG(p2.preco)
        FROM   PRODUTO p2
        WHERE  p2.id_categoria = pr.id_categoria)              AS media_categoria,
       ROUND(
           (pr.preco - (SELECT AVG(p2.preco)
                        FROM   PRODUTO p2
                        WHERE  p2.id_categoria = pr.id_categoria))
           * 100.0
           / (SELECT AVG(p2.preco)
              FROM   PRODUTO p2
              WHERE  p2.id_categoria = pr.id_categoria), 2)    AS perc_vs_media
FROM   PRODUTO pr
ORDER  BY pr.id_categoria, perc_vs_media DESC;

-- perc_vs_media > 0  => produto ACIMA da média da categoria
-- perc_vs_media < 0  => produto ABAIXO da média da categoria
GO

/* ---------------------------------------------------------------------
   S2 - Clientes VIP dinâmico
   Usando subquery no FROM + JOIN, identificar clientes com gasto > 150%
   da média geral. Mostrar nome, gasto e percentual acima da média.
   --------------------------------------------------------------------- */
SELECT c.nome,
       t.gasto_total,
       m.media_geral,
       ROUND((t.gasto_total / m.media_geral - 1) * 100, 2) AS perc_acima_media
FROM   CLIENTE c
INNER  JOIN (
           SELECT id_cliente, SUM(total) AS gasto_total
           FROM   PEDIDO
           WHERE  status <> 'CANCELADO'
           GROUP  BY id_cliente
       ) AS t ON c.id_cliente = t.id_cliente
CROSS  JOIN (
           SELECT AVG(gasto) AS media_geral          -- média do gasto por cliente
           FROM  (
                     SELECT SUM(total) AS gasto
                     FROM   PEDIDO
                     WHERE  status <> 'CANCELADO'
                     GROUP  BY id_cliente
                 ) AS g
       ) AS m
WHERE  t.gasto_total > 1.5 * m.media_geral           -- > 150% da média
ORDER  BY t.gasto_total DESC;

/* ---------------------------------------------------------------------
   S3 - Anomalias de pedidos
   Usando EXISTS, encontrar pedidos ENTREGUES cujo total registrado
   diverge do total calculado pelos itens (diferença > R$ 1).
   --------------------------------------------------------------------- */
SELECT p.id_pedido,
       p.total AS total_registrado,
       (SELECT SUM(ip.quantidade * ip.preco_unitario)
        FROM   ITEM_PEDIDO ip
        WHERE  ip.id_pedido = p.id_pedido) AS total_calculado
FROM   PEDIDO p
WHERE  p.status = 'ENTREGUE'
  AND  EXISTS (
           SELECT 1
           FROM   ITEM_PEDIDO ip
           WHERE  ip.id_pedido = p.id_pedido
           GROUP  BY ip.id_pedido
           HAVING ABS(p.total - SUM(ip.quantidade * ip.preco_unitario)) > 1
       )
ORDER  BY p.id_pedido;

/* ---------------------------------------------------------------------
   S4 - Ranking por categoria
   Usando subquery no FROM com ROW_NUMBER(), mostrar os 2 produtos mais
   caros de cada categoria com seu ranking.
   --------------------------------------------------------------------- */

SELECT cat.nome_categoria,
       ranked.nome_produto,
       ranked.preco,
       ranked.rn AS ranking
FROM  (
           SELECT id_categoria,
                  nome_produto,
                  preco,
                  ROW_NUMBER() OVER (PARTITION BY id_categoria
                                     ORDER BY preco DESC) AS rn
           FROM   PRODUTO
      ) AS ranked
INNER  JOIN CATEGORIA cat ON ranked.id_categoria = cat.id_categoria
WHERE  ranked.rn <= 2
ORDER  BY cat.nome_categoria, ranked.rn;

/* ---------------------------------------------------------------------
   S5 - BÔNUS
   Reescrever S1 de 3 formas:
   (a) subquery correlacionada, (b) derived table no FROM,
   (c) LEFT JOIN + GROUP BY. Comparar a legibilidade.
   --------------------------------------------------------------------- */
-- (a) Subquery correlacionada (executa a subquery 1x por produto)
SELECT pr.nome_produto,
       pr.preco,
       (SELECT AVG(p2.preco)
        FROM   PRODUTO p2
        WHERE  p2.id_categoria = pr.id_categoria) AS media_categoria,
       ROUND((pr.preco - (SELECT AVG(p2.preco)
                          FROM   PRODUTO p2
                          WHERE  p2.id_categoria = pr.id_categoria))
             * 100.0
             / (SELECT AVG(p2.preco)
                FROM   PRODUTO p2
                WHERE  p2.id_categoria = pr.id_categoria), 2) AS perc_vs_media
FROM   PRODUTO pr
ORDER  BY pr.id_categoria, perc_vs_media DESC;

-- (b) Derived table no FROM (média calculada 1x por categoria)
SELECT pr.nome_produto,
       pr.preco,
       m.media_categoria,
       ROUND((pr.preco - m.media_categoria) * 100.0 / m.media_categoria, 2) AS perc_vs_media
FROM   PRODUTO pr
INNER  JOIN (
           SELECT id_categoria, AVG(preco) AS media_categoria
           FROM   PRODUTO
           GROUP  BY id_categoria
       ) AS m ON pr.id_categoria = m.id_categoria
ORDER  BY pr.id_categoria, perc_vs_media DESC;

-- (c) LEFT JOIN + GROUP BY (agrupa e calcula a média na mesma query)
SELECT pr.nome_produto,
       pr.preco,
       AVG(outros.preco) AS media_categoria,
       ROUND((pr.preco - AVG(outros.preco)) * 100.0 / AVG(outros.preco), 2) AS perc_vs_media
FROM   PRODUTO pr
LEFT   JOIN PRODUTO outros ON outros.id_categoria = pr.id_categoria
GROUP  BY pr.id_produto, pr.nome_produto, pr.preco, pr.id_categoria
ORDER  BY pr.id_categoria, perc_vs_media DESC;

