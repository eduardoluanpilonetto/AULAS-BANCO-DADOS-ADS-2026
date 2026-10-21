
USE SISTEMA_VENDAS;
/* =====================================================================
   EXERCICIO 01 (Basico)
   LEFT JOIN: TODOS os clientes com seus pedidos (se existirem).
   Mostrar nome, estado, id_pedido e status.
   ---------------------------------------------------------------------
   Logica: CLIENTES fica a ESQUERDA (tabela principal). Clientes sem
   pedido aparecem com NULL em id_pedido e status.
   ===================================================================== */
SELECT c.nome      AS cliente,
       c.estado,
       p.id_pedido,
       p.status
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
ORDER  BY c.nome, p.id_pedido;
GO


/* =====================================================================
   EXERCICIO 02 (Basico)
   LEFT JOIN + WHERE IS NULL para encontrar registros "orfaos":
   (a) clientes sem pedido
   (b) produtos nunca vendidos
   ---------------------------------------------------------------------
   Logica: o LEFT JOIN traz tudo da esquerda; o filtro IS NULL na chave
   da tabela da direita deixa SOMENTE quem nao encontrou par.
   ===================================================================== */

-- 02a) Clientes SEM pedido
SELECT c.id_cliente,
       c.nome,
       c.email,
       c.estado,
       c.data_cadastro
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  p.id_pedido IS NULL
ORDER  BY c.nome;
GO

-- 02b) Produtos NUNCA vendidos
--      INNER JOIN com CATEGORIAS (todo produto TEM categoria)
--      LEFT  JOIN com ITENS_PEDIDO (produto pode nunca ter sido vendido)
SELECT pr.id_produto,
       pr.nome_produto,
       pr.preco,
       pr.estoque,
       cat.nome_categoria
FROM   PRODUTO pr
INNER  JOIN CATEGORIA   cat ON pr.id_categoria = cat.id_categoria
LEFT   JOIN ITEM_PEDIDO ip  ON pr.id_produto   = ip.id_produto
WHERE  ip.id_item IS NULL
ORDER  BY cat.nome_categoria, pr.nome_produto;
GO


/* =====================================================================
   EXERCICIO 03 (Medio)
   Relatorio de desempenho: TODOS os funcionarios com total de pedidos
   (COUNT) e faturamento (SUM). Quem nao vendeu deve aparecer com 0.
   Usar LEFT JOIN + GROUP BY + ISNULL.
   ---------------------------------------------------------------------
   Logica:
   - COUNT(p.id_pedido) ignora NULL, entao retorna 0 sem precisar de ISNULL.
   - SUM(p.total) retorna NULL quando nao ha pedidos -> ISNULL(...,0).
   ===================================================================== */
SELECT f.nome                                AS vendedor,
       f.cargo,
       COUNT(p.id_pedido)                    AS total_pedidos,
       ISNULL(SUM(p.total), 0)               AS faturamento,
       ISNULL(ROUND(AVG(p.total), 2), 0)     AS ticket_medio
FROM   FUNCIONARIO f
LEFT   JOIN PEDIDO p ON f.id_funcionario = p.id_funcionario
GROUP  BY f.nome, f.cargo
ORDER  BY faturamento DESC;
GO


/* =====================================================================
   EXERCICIO 04 (Medio)
   FULL OUTER JOIN entre CLIENTES e PEDIDOS. Classificar cada linha como
   'Cliente sem compra', 'Pedido normal' ou 'Pedido orfao' (sem cliente).
   Usar CASE + IS NULL.
   ---------------------------------------------------------------------
   Logica:
   - c.id_cliente IS NULL -> existe pedido, mas nao existe cliente
   - p.id_pedido  IS NULL -> existe cliente, mas nao existe pedido
   - nenhum dos dois NULL -> par normal
   Obs.: como PEDIDOS.id_cliente e FK, na pratica nao deve haver
   "pedido orfao". O FULL JOIN serve justamente para PROVAR isso.
   ===================================================================== */
SELECT ISNULL(c.nome, '--- SEM CLIENTE ---')                  AS cliente,
       ISNULL(CAST(p.id_pedido AS VARCHAR(10)), '--- SEM PEDIDO ---') AS pedido,
       p.status,
       CASE
            WHEN c.id_cliente IS NULL THEN 'Pedido órfão'
            WHEN p.id_pedido  IS NULL THEN 'Cliente sem compra'
            ELSE                           'Pedido normal'
       END                                                   AS situacao
FROM   CLIENTE c
FULL   OUTER JOIN PEDIDO p ON c.id_cliente = p.id_cliente
ORDER  BY situacao, c.nome, p.id_pedido;
GO


/* =====================================================================
   EXERCICIO 05 (Avancado)
   Relatorio final de produtos: nome_produto, categoria, preco,
   total_unidades_vendidas, faturamento, situacao
   (Nunca vendido / Baixo / Normal / Alto giro).
   Misturar INNER JOIN (categoria) e LEFT JOIN (itens).
   Ordenar por faturamento DESC.
   ---------------------------------------------------------------------
   Logica:
   - INNER JOIN CATEGORIAS: relacao garantida pela FK.
   - LEFT  JOIN ITENS_PEDIDO: produto pode nunca ter sido vendido.
   - Criterio de giro (sugestao): 0 vendas = Nunca vendido;
     1-2 = Baixo giro; 3-5 = Normal; 6 ou mais = Alto giro.
   ===================================================================== */
SELECT pr.nome_produto,
       cat.nome_categoria                                   AS categoria,
       pr.preco,
       ISNULL(SUM(ip.quantidade), 0)                        AS total_unidades_vendidas,
       ISNULL(SUM(ip.quantidade * ip.preco_unitario), 0)    AS faturamento,
       CASE
            WHEN COUNT(ip.id_item) = 0 THEN 'Nunca vendido'
            WHEN COUNT(ip.id_item) < 3 THEN 'Baixo giro'
            WHEN COUNT(ip.id_item) < 6 THEN 'Normal'
            ELSE                            'Alto giro'
       END                                                  AS situacao
FROM   PRODUTO pr
INNER  JOIN CATEGORIA   cat ON pr.id_categoria = cat.id_categoria
LEFT   JOIN ITEM_PEDIDO ip  ON pr.id_produto   = ip.id_produto
GROUP  BY pr.nome_produto, cat.nome_categoria, pr.preco
ORDER  BY faturamento DESC;
GO


/* =====================================================================
   ============================  DESAFIO  ==============================
   Contexto: o setor de qualidade de dados e o marketing precisam de
   relatorios de auditoria e segmentacao completos, incluindo registros
   sem correspondencia (orfaos).
   ===================================================================== */


/* =====================================================================
   A1 - PAINEL DE CLIENTES
   TODOS os clientes com total de pedidos (COUNT), gasto total (SUM),
   ultimo pedido (MAX data) e situacao:
   'VIP' (> R$ 1000), 'Regular' ou 'Inativo' (sem pedido).
   ---------------------------------------------------------------------
   Atencao a ORDEM do CASE: o teste de "sem pedido" vem primeiro, pois
   SUM() e NULL para quem nunca comprou.
   ===================================================================== */
SELECT c.id_cliente,
       c.nome,
       c.estado,
       COUNT(p.id_pedido)              AS total_pedidos,
       ISNULL(SUM(p.total), 0)         AS gasto_total,
       MAX(p.data_pedido)              AS ultimo_pedido,
       CASE
            WHEN COUNT(p.id_pedido) = 0     THEN 'Inativo'
            WHEN ISNULL(SUM(p.total),0) > 1000 THEN 'VIP'
            ELSE                                 'Regular'
       END                             AS situacao
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
GROUP  BY c.id_cliente, c.nome, c.estado
ORDER  BY gasto_total DESC, c.nome;
GO


/* =====================================================================
   A2 - CATALOGO DE PRODUTOS
   TODOS os produtos com categoria, qtd vendida, faturamento, situacao
   de estoque e de giro (Nunca vendido / Baixo / Normal).
   Misturar INNER + LEFT JOIN.
   ---------------------------------------------------------------------
   - INNER JOIN CATEGORIAS  (todo produto tem categoria)
   - LEFT  JOIN FORNECEDORES (garante que o produto aparece mesmo se o
                              fornecedor nao estiver informado)
   - LEFT  JOIN ITENS_PEDIDO (produto pode nunca ter sido vendido)
   Criterios (sugestao):
   Estoque: 0 = Sem estoque | ate 10 = Estoque baixo | acima = Estoque ok
   Giro:    0 vendas = Nunca vendido | 1-2 = Baixo | 3 ou mais = Normal
   ===================================================================== */
SELECT pr.id_produto,
       pr.nome_produto,
       cat.nome_categoria                                   AS categoria,
       ISNULL(fo.nome, 'Sem fornecedor')                    AS fornecedor,
       pr.preco,
       pr.estoque,
       ISNULL(SUM(ip.quantidade), 0)                        AS qtd_vendida,
       ISNULL(SUM(ip.quantidade * ip.preco_unitario), 0)    AS faturamento,
       CASE
            WHEN pr.estoque = 0   THEN 'Sem estoque'
            WHEN pr.estoque <= 10 THEN 'Estoque baixo'
            ELSE                       'Estoque ok'
       END                                                  AS situacao_estoque,
       CASE
            WHEN COUNT(ip.id_item) = 0 THEN 'Nunca vendido'
            WHEN COUNT(ip.id_item) < 3 THEN 'Baixo'
            ELSE                            'Normal'
       END                                                  AS situacao_giro
FROM   PRODUTO pr
INNER  JOIN CATEGORIA   cat ON pr.id_categoria  = cat.id_categoria
LEFT   JOIN FORNECEDOR fo  ON pr.id_fornecedor = fo.id_fornecedor
LEFT   JOIN ITEM_PEDIDO ip  ON pr.id_produto    = ip.id_produto
GROUP  BY pr.id_produto, pr.nome_produto, cat.nome_categoria,
          fo.nome, pr.preco, pr.estoque
ORDER  BY faturamento DESC, pr.nome_produto;
GO


/* =====================================================================
   A3 - RELATORIO DE VENDEDORES
   TODOS os funcionarios com pedidos entregues/cancelados (COUNT CASE),
   faturamento real e comissao de 5%. Zeros para quem nao vendeu.
   ---------------------------------------------------------------------
   Logica:
   - COUNT(CASE WHEN ... THEN 1 END): conta so as linhas que atendem a
     condicao (o CASE devolve NULL nas demais e o COUNT ignora NULL).
   - Faturamento REAL = soma apenas dos pedidos ENTREGUES
     (cancelados nao entram).
   - Comissao = 5% do faturamento real.
   ===================================================================== */
SELECT f.id_funcionario,
       f.nome                                                       AS vendedor,
       f.cargo,
       COUNT(CASE WHEN p.status = 'Entregue'  THEN 1 END)           AS pedidos_entregues,
       COUNT(CASE WHEN p.status = 'Cancelado' THEN 1 END)           AS pedidos_cancelados,
       ISNULL(SUM(CASE WHEN p.status = 'Entregue'
                       THEN p.total END), 0)                        AS faturamento_real,
       ISNULL(SUM(CASE WHEN p.status = 'Entregue'
                       THEN p.total END), 0) * 0.05                 AS comissao_5pct
FROM   FUNCIONARIO f
LEFT   JOIN PEDIDO p ON f.id_funcionario = p.id_funcionario
GROUP  BY f.id_funcionario, f.nome, f.cargo
ORDER  BY faturamento_real DESC, f.nome;
GO


/* =====================================================================
   A4 - AUDITORIA COM FULL JOIN
   Detectar pedidos sem cliente valido e clientes sem pedido.
   Classificar e CONTAR cada tipo de inconsistencia.
   ---------------------------------------------------------------------
   Parte 1: detalhe de cada inconsistencia (so as linhas problematicas).
   Parte 2: resumo com a contagem por tipo.
   ===================================================================== */

-- A4 - Parte 1: detalhamento das inconsistencias
SELECT CASE
            WHEN c.id_cliente IS NULL THEN 'Pedido órfão (sem cliente)'
            ELSE                           'Cliente sem pedido'
       END                                  AS tipo_inconsistencia,
       c.id_cliente,
       c.nome                               AS cliente,
       p.id_pedido,
       p.status,
       p.total
FROM   CLIENTE c
FULL   OUTER JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  c.id_cliente IS NULL
   OR  p.id_pedido  IS NULL
ORDER  BY tipo_inconsistencia, c.nome;
GO

-- A4 - Parte 2: resumo (contagem por tipo, incluindo os registros normais)
SELECT CASE
            WHEN c.id_cliente IS NULL THEN 'Pedido órfão (sem cliente)'
            WHEN p.id_pedido  IS NULL THEN 'Cliente sem pedido'
            ELSE                           'Registro OK'
       END                                  AS tipo,
       COUNT(*)                             AS quantidade
FROM   CLIENTE c
FULL   OUTER JOIN PEDIDO p ON c.id_cliente = p.id_cliente
GROUP  BY CASE
               WHEN c.id_cliente IS NULL THEN 'Pedido órfão (sem cliente)'
               WHEN p.id_pedido  IS NULL THEN 'Cliente sem pedido'
               ELSE                           'Registro OK'
          END
ORDER  BY quantidade DESC;
GO


/* =====================================================================
   A5 - BONUS: ANALISE DE COHORT SIMPLES
   Para cada mes de cadastro dos clientes (YEAR + MONTH de data_cadastro):
   quantos clientes se cadastraram, quantos fizeram pedido e qual o
   gasto medio. LEFT JOIN + GROUP BY.
   ---------------------------------------------------------------------
   Logica:
   - COUNT(DISTINCT c.id_cliente): clientes cadastrados no mes.
     (DISTINCT e necessario: o JOIN 1:N repete o cliente por pedido.)
   - COUNT(DISTINCT p.id_cliente): clientes do mes que compraram
     (NULL e ignorado pelo COUNT).
   - Gasto medio por pedido  = AVG(p.total)
   - Gasto medio por cliente = SUM(p.total) / clientes cadastrados
   ===================================================================== */
SELECT YEAR(c.data_cadastro)                                        AS ano,
       MONTH(c.data_cadastro)                                       AS mes,
       COUNT(DISTINCT c.id_cliente)                                 AS clientes_cadastrados,
       COUNT(DISTINCT p.id_cliente)                                 AS clientes_com_pedido,
       COUNT(p.id_pedido)                                           AS total_pedidos,
       ISNULL(ROUND(AVG(p.total), 2), 0)                            AS gasto_medio_por_pedido,
       ISNULL(ROUND(SUM(p.total) * 1.0
                    / COUNT(DISTINCT c.id_cliente), 2), 0)          AS gasto_medio_por_cliente
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
GROUP  BY YEAR(c.data_cadastro), MONTH(c.data_cadastro)
ORDER  BY ano, mes;
GO


/* =====================================================================
   EXTRA - SELF JOIN (conteudo do slide "SELF JOIN - Exemplos Praticos")
   Hierarquia funcionario -> gerente.
   ---------------------------------------------------------------------
   ATENCAO: o slide original tem uma inconsistencia. A tabela de exemplo
   mostra Maria = id 1 (gerente), mas o UPDATE do slide usa
   "gerente_id = 2 WHERE id_funcionario IN (1,3,4)". Abaixo, o script
   corrigido considerando Maria = 1, Joao = 2, Pedro = 3 e Lucia = 4.
   Ajuste os ids conforme os dados reais da sua tabela FUNCIONARIOS.
   ===================================================================== */

-- 1) Criar a coluna e a FK autorreferenciada (executar apenas UMA vez)
-- ALTER TABLE FUNCIONARIOS ADD gerente_id INT NULL;
-- GO
-- ALTER TABLE FUNCIONARIOS
--     ADD CONSTRAINT FK_FUNC_GERENTE
--     FOREIGN KEY (gerente_id) REFERENCES FUNCIONARIOS(id_funcionario);
-- GO

-- 2) Definir a hierarquia: Joao (2), Pedro (3) e Lucia (4) reportam a Maria (1)
-- UPDATE FUNCIONARIOS SET gerente_id = 1 WHERE id_funcionario IN (2, 3, 4);
-- GO

-- 3) SELF JOIN: funcionario e seu gerente
--    LEFT JOIN para a propria Maria (sem gerente) nao sumir do resultado.
-- SELECT f.nome                          AS funcionario,
--        f.cargo,
--        ISNULL(g.nome, 'É o gerente!')  AS gerente
-- FROM   FUNCIONARIOS f
-- LEFT   JOIN FUNCIONARIOS g ON f.gerente_id = g.id_funcionario
-- ORDER  BY g.nome, f.nome;
-- GO