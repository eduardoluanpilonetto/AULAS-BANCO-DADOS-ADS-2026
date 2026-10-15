
USE SISTEMA_VENDAS;
GO


/* =====================================================================
   EXERCÍCIO 01 (Básico)
   Listar todos os produtos com o nome da sua categoria.
   Mostrar: nome_produto, nome_categoria, preço e estoque.
   Ordenar por categoria e depois por preço.
   ===================================================================== */
SELECT pr.nome_produto,
       cat.nome_categoria,
       pr.preco,
       pr.estoque
FROM   PRODUTO pr
INNER  JOIN CATEGORIA cat ON pr.id_categoria = cat.id_categoria
ORDER  BY cat.nome_categoria, pr.preco;
GO


/* =====================================================================
   EXERCÍCIO 02 (Básico)
   Listar os pedidos com o nome do cliente, status e total.
   Filtrar apenas pedidos 'ENTREGUE' ou 'ENVIADO'.
   Ordenar pelo total decrescente.
   ===================================================================== */
SELECT p.id_pedido,
       c.nome AS cliente,
       p.status,
       p.total
FROM   PEDIDO p
INNER  JOIN CLIENTE c ON p.id_cliente = c.id_cliente
WHERE  p.status IN ('ENTREGUE', 'ENVIADO')
ORDER  BY p.total DESC;
GO


/* =====================================================================
   EXERCÍCIO 03 (Médio)
   Relatório de itens de pedido com: id_pedido, nome do cliente,
   nome do produto, quantidade, preco_unitario e subtotal (calculado).
   Tabelas: ITENS_PEDIDO + PEDIDOS + CLIENTES + PRODUTOS
   (o enunciado diz "3 tabelas", mas lista 4 - são 4 tabelas = 3 JOINs).
   ===================================================================== */
SELECT p.id_pedido,
       c.nome                             AS cliente,
       pr.nome_produto                    AS produto,
       ip.quantidade,
       ip.preco_unitario,
       ip.quantidade * ip.preco_unitario  AS subtotal
FROM   ITEM_PEDIDO ip
INNER  JOIN PEDIDO  p  ON ip.id_pedido  = p.id_pedido
INNER  JOIN CLIENTE c  ON p.id_cliente  = c.id_cliente
INNER  JOIN PRODUTO pr ON ip.id_produto = pr.id_produto
ORDER  BY p.id_pedido, pr.nome_produto;
GO


/* =====================================================================
   EXERCÍCIO 04 (Médio)
   Faturamento por vendedor: JOIN entre PEDIDOS e FUNCIONARIOS.
   Agrupar por nome do funcionário, somar o total (excluindo
   cancelados), mostrar COUNT de pedidos e ticket médio.
   Ordenar por faturamento decrescente.
   ===================================================================== */
SELECT f.nome                  AS vendedor,
       f.cargo,
       COUNT(p.id_pedido)      AS total_pedidos,
       SUM(p.total)            AS faturamento,
       ROUND(AVG(p.total), 2)  AS ticket_medio
FROM   FUNCIONARIO f
INNER  JOIN PEDIDO p ON f.id_funcionario = p.id_funcionario
WHERE  p.status <> 'CANCELADO'          -- exclui cancelados antes de agrupar
GROUP  BY f.nome, f.cargo
ORDER  BY faturamento DESC;
GO

/* Variação (resolução do slide): CASE dentro das agregações.
   Aqui COUNT(p.id_pedido) conta TODOS os pedidos (inclusive cancelados),
   enquanto faturamento e ticket médio ignoram os cancelados.            */
SELECT f.nome AS vendedor,
       f.cargo,
       COUNT(p.id_pedido) AS total_pedidos,
       SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.total ELSE 0 END) AS faturamento,
       ROUND(AVG(CASE WHEN p.status <> 'CANCELADO' THEN p.total END), 2) AS ticket_medio
FROM   FUNCIONARIO f
INNER  JOIN PEDIDO p ON f.id_funcionario = p.id_funcionario
GROUP  BY f.nome, f.cargo
ORDER  BY faturamento DESC;
GO


/* =====================================================================
   EXERCÍCIO 05 (Avançado)
   Para cada categoria: faturamento total (SUM dos itens), quantidade de
   pedidos distintos e o produto mais vendido. Filtrar categorias com
   faturamento > 0.
   Estratégia: JOINs principais + CROSS APPLY com subquery (TOP 1) que
   devolve o produto mais vendido (em quantidade) de cada categoria.
   ===================================================================== */
SELECT cat.nome_categoria,
       COUNT(DISTINCT p.id_pedido)                AS pedidos_distintos,
       SUM(ip.quantidade * ip.preco_unitario)     AS faturamento,
       top1.nome_produto                          AS produto_mais_vendido,
       top1.qtd_vendida                           AS qtd_do_mais_vendido
FROM   ITEM_PEDIDO ip
INNER  JOIN PEDIDO    p   ON ip.id_pedido    = p.id_pedido
INNER  JOIN PRODUTO   pr  ON ip.id_produto   = pr.id_produto
INNER  JOIN CATEGORIA cat ON pr.id_categoria = cat.id_categoria
CROSS  APPLY (
        SELECT TOP 1
               pr2.nome_produto,
               SUM(ip2.quantidade) AS qtd_vendida
        FROM   ITEM_PEDIDO ip2
        INNER  JOIN PRODUTO pr2 ON ip2.id_produto = pr2.id_produto
        INNER  JOIN PEDIDO  p2  ON ip2.id_pedido  = p2.id_pedido
        WHERE  pr2.id_categoria = cat.id_categoria
          AND  p2.status <> 'CANCELADO'
        GROUP  BY pr2.nome_produto
        ORDER  BY SUM(ip2.quantidade) DESC
       ) top1
WHERE  p.status <> 'CANCELADO'
GROUP  BY cat.id_categoria, cat.nome_categoria, top1.nome_produto, top1.qtd_vendida
HAVING SUM(ip.quantidade * ip.preco_unitario) > 0
ORDER  BY faturamento DESC;
GO


/* =====================================================================
   ===================  DESAFIO DA AULA 10  ============================
   Relatório de desempenho para o diretor
   ===================================================================== */

/* ---------------------------------------------------------------------
   R1 - Nota fiscal digital do pedido 2
   Itens (produto, categoria, quantidade, preço, subtotal) e, no final,
   uma linha com o total do pedido.
   A coluna "ordem" garante que a linha de total fique por último.
   Obs.: UNION ALL é usado no lugar de UNION para não eliminar linhas
   idênticas (ex.: o mesmo produto lançado duas vezes no pedido).
   --------------------------------------------------------------------- */
SELECT produto, categoria, quantidade, preco_unitario, subtotal
FROM (
        -- Itens do pedido
        SELECT 1                               AS ordem,
               pr.nome_produto                 AS produto,
               cat.nome_categoria              AS categoria,
               ip.quantidade                   AS quantidade,
               ip.preco_unitario               AS preco_unitario,
               ip.quantidade * ip.preco_unitario AS subtotal
        FROM   ITEM_PEDIDO ip
        INNER  JOIN PRODUTO   pr  ON ip.id_produto   = pr.id_produto
        INNER  JOIN CATEGORIA cat ON pr.id_categoria = cat.id_categoria
        WHERE  ip.id_pedido = 2

        UNION ALL

        -- Linha de total do pedido
        SELECT 2,
               'TOTAL DO PEDIDO',
               '',
               SUM(ip.quantidade),
               CAST(NULL AS DECIMAL(10,2)),
               SUM(ip.quantidade * ip.preco_unitario)
        FROM   ITEM_PEDIDO ip
        WHERE  ip.id_pedido = 2
     ) nf
ORDER BY ordem, produto;
GO


/* ---------------------------------------------------------------------
   R2 - Ranking de clientes (TOP 5 por gasto total)
   Nome, estado, total de pedidos (não cancelados), gasto total e
   ticket médio.  JOIN CLIENTES + PEDIDOS + GROUP BY.
   --------------------------------------------------------------------- */
SELECT TOP 5
       c.nome,
       c.estado,
       COUNT(p.id_pedido)      AS total_pedidos,
       SUM(p.total)            AS gasto_total,
       ROUND(AVG(p.total), 2)  AS ticket_medio
FROM   CLIENTE c
INNER  JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  p.status <> 'CANCELADO'
GROUP  BY c.id_cliente, c.nome, c.estado
ORDER  BY gasto_total DESC;
GO


/* ---------------------------------------------------------------------
   R3 - Mix de produtos vendidos (4 tabelas)
   Nome, categoria, quantidade total vendida e faturamento.
   O INNER JOIN já garante apenas produtos com pelo menos 1 venda.
   Tabelas: ITENS_PEDIDO + PRODUTOS + CATEGORIAS + PEDIDOS
   --------------------------------------------------------------------- */
SELECT pr.nome_produto,
       cat.nome_categoria,
       SUM(ip.quantidade)                      AS qtd_vendida,
       SUM(ip.quantidade * ip.preco_unitario)  AS faturamento
FROM   ITEM_PEDIDO ip
INNER  JOIN PRODUTO   pr  ON ip.id_produto   = pr.id_produto
INNER  JOIN CATEGORIA cat ON pr.id_categoria = cat.id_categoria
INNER  JOIN PEDIDO    p   ON ip.id_pedido    = p.id_pedido
WHERE  p.status <> 'CANCELADO'
GROUP  BY pr.id_produto, pr.nome_produto, cat.nome_categoria
ORDER  BY faturamento DESC;
GO


/* ---------------------------------------------------------------------
   R4 - Painel do vendedor
   Pedidos entregues / enviados / pendentes / cancelados (COUNT + CASE)
   e faturamento real (sem cancelados).  JOIN FUNCIONARIOS + PEDIDOS.
   Ajuste os textos de status se o seu banco usar valores diferentes
   (ex.: 'PENDENTE' ou 'PROCESSANDO').
   --------------------------------------------------------------------- */
SELECT f.nome  AS vendedor,
       f.cargo,
       COUNT(CASE WHEN p.status = 'ENTREGUE'  THEN 1 END) AS entregues,
       COUNT(CASE WHEN p.status = 'ENVIADO'   THEN 1 END) AS enviados,
       COUNT(CASE WHEN p.status = 'PENDENTE'  THEN 1 END) AS pendentes,
       COUNT(CASE WHEN p.status = 'CANCELADO' THEN 1 END) AS cancelados,
       SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.total ELSE 0 END) AS faturamento_real
FROM   FUNCIONARIO f
INNER  JOIN PEDIDO p ON f.id_funcionario = p.id_funcionario
GROUP  BY f.id_funcionario, f.nome, f.cargo
ORDER  BY faturamento_real DESC;
GO


/* ---------------------------------------------------------------------
   R5 - BÔNUS: relatório cruzado (estado do cliente x categoria)
   Faturamento total usando as 6 tabelas (5 JOINs).
   --------------------------------------------------------------------- */
SELECT c.estado,
       cat.nome_categoria,
       SUM(ip.quantidade * ip.preco_unitario) AS faturamento
FROM   ITEM_PEDIDO ip
INNER  JOIN PEDIDO      p   ON ip.id_pedido      = p.id_pedido
INNER  JOIN CLIENTE     c   ON p.id_cliente      = c.id_cliente
INNER  JOIN FUNCIONARIO f   ON p.id_funcionario  = f.id_funcionario
INNER  JOIN PRODUTO     pr  ON ip.id_produto     = pr.id_produto
INNER  JOIN CATEGORIA   cat ON pr.id_categoria   = cat.id_categoria
WHERE  p.status <> 'CANCELADO'
GROUP  BY c.estado, cat.nome_categoria
ORDER  BY c.estado, faturamento DESC;
GO
