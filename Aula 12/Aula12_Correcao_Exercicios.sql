USE SISTEMA_VENDAS;
GO


/* =====================================================================
   PARTE 1 - EXERCICIOS PROPOSTOS
   ===================================================================== */

/* ---------------------------------------------------------------------
   EXERCICIO 01 (Basico)
   Lista unificada de todas as pessoas (clientes + funcionarios), com
   a coluna 'tipo', ordenada por tipo e nome.
   - UNION elimina duplicatas (mesmo nome + mesmo tipo)
   - A coluna 'tipo' e um valor literal que identifica a origem
   - ORDER BY usa os aliases do PRIMEIRO SELECT e vem so no final
   --------------------------------------------------------------------- */
SELECT nome, 'Cliente' AS tipo
FROM   CLIENTE
UNION
SELECT nome, 'Funcionário'
FROM   FUNCIONARIO
ORDER  BY tipo, nome;
GO

/* Variacao: incluindo a cidade (NULL para funcionarios).
   A coluna precisa existir nas duas partes - o NULL "preenche" o espaco. */
SELECT nome, 'Cliente' AS tipo, cidade
FROM   CLIENTE
UNION
SELECT nome, 'Funcionário', NULL
FROM   FUNCIONARIO
ORDER  BY tipo, nome;
GO


/* ---------------------------------------------------------------------
   EXERCICIO 02 (Basico)
   Relatorio consolidado de valores com UNION ALL:
   produtos (nome, preco, 'Produto') e funcionarios (nome, salario,
   'Funcionario'), ordenado pelo valor decrescente.
   - UNION ALL mantem tudo e nao compara linhas: e mais rapido.
     Aqui nao precisamos eliminar duplicatas (sao origens diferentes).
   - preco e salario sao numericos: tipos compativeis (regra 2).
   --------------------------------------------------------------------- */
SELECT nome_produto AS nome,
       preco        AS valor,
       'Produto'    AS tipo
FROM   PRODUTO
UNION ALL
SELECT nome,
       salario,
       'Funcionário'
FROM   FUNCIONARIO
ORDER  BY valor DESC;
GO


/* ---------------------------------------------------------------------
   EXERCICIO 03 (Medio)
   EXCEPT para encontrar (a) clientes sem pedido e (b) produtos sem
   venda. Comparar com as solucoes LEFT JOIN + IS NULL da Aula 11.
   - A EXCEPT B  traz as linhas de A que NAO estao em B (nao comutativo)
   - EXCEPT elimina duplicatas automaticamente
   --------------------------------------------------------------------- */

-- 03a) Clientes sem pedido - EXCEPT
SELECT id_cliente, nome
FROM   CLIENTE
EXCEPT
SELECT DISTINCT c.id_cliente, c.nome
FROM   CLIENTE c
INNER  JOIN PEDIDO p ON c.id_cliente = p.id_cliente;
GO

-- 03a) Clientes sem pedido - LEFT JOIN + IS NULL (Aula 11)
SELECT c.id_cliente, c.nome
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  p.id_pedido IS NULL;
GO

-- 03b) Produtos sem venda - EXCEPT
SELECT id_produto, nome_produto
FROM   PRODUTO
EXCEPT
SELECT DISTINCT pr.id_produto, pr.nome_produto
FROM   PRODUTO pr
INNER  JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto;
GO

-- 03b) Produtos sem venda - LEFT JOIN + IS NULL (Aula 11)
SELECT pr.id_produto, pr.nome_produto
FROM   PRODUTO pr
LEFT   JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
WHERE  ip.id_produto IS NULL;
GO

/* Verificacao: os resultados sao identicos?
   Se (EXCEPT) EXCEPT (LEFT JOIN) e (LEFT JOIN) EXCEPT (EXCEPT) retornarem
   vazio nos dois sentidos, os conjuntos sao iguais.
   (Ironico: usamos EXCEPT para provar que dois EXCEPTs sao equivalentes.) */

-- Clientes: diferenca nos dois sentidos (esperado: 0 linhas em cada)
(SELECT id_cliente, nome FROM CLIENTE
 EXCEPT
 SELECT DISTINCT c.id_cliente, c.nome
 FROM CLIENTE c INNER JOIN PEDIDO p ON c.id_cliente = p.id_cliente)
EXCEPT
(SELECT c.id_cliente, c.nome
 FROM CLIENTE c LEFT JOIN PEDIDO p ON c.id_cliente = p.id_cliente
 WHERE p.id_pedido IS NULL);

(SELECT c.id_cliente, c.nome
 FROM CLIENTE c LEFT JOIN PEDIDO p ON c.id_cliente = p.id_cliente
 WHERE p.id_pedido IS NULL)
EXCEPT
(SELECT id_cliente, nome FROM CLIENTE
 EXCEPT
 SELECT DISTINCT c.id_cliente, c.nome
 FROM CLIENTE c INNER JOIN PEDIDO p ON c.id_cliente = p.id_cliente);
GO

-- Produtos: diferenca nos dois sentidos (esperado: 0 linhas em cada)
(SELECT id_produto, nome_produto FROM PRODUTO
 EXCEPT
 SELECT DISTINCT pr.id_produto, pr.nome_produto
 FROM PRODUTO pr INNER JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto)
EXCEPT
(SELECT pr.id_produto, pr.nome_produto
 FROM PRODUTO pr LEFT JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
 WHERE ip.id_produto IS NULL);

(SELECT pr.id_produto, pr.nome_produto
 FROM PRODUTO pr LEFT JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
 WHERE ip.id_produto IS NULL)
EXCEPT
(SELECT id_produto, nome_produto FROM PRODUTO
 EXCEPT
 SELECT DISTINCT pr.id_produto, pr.nome_produto
 FROM PRODUTO pr INNER JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto);
GO

/* Bonus - terceiro caminho: NOT EXISTS (mais performatico em grandes volumes) */
SELECT c.id_cliente, c.nome
FROM   CLIENTE c
WHERE  NOT EXISTS (SELECT 1 FROM PEDIDO p WHERE p.id_cliente = c.id_cliente);

SELECT pr.id_produto, pr.nome_produto
FROM   PRODUTO pr
WHERE  NOT EXISTS (SELECT 1 FROM ITEM_PEDIDO ip WHERE ip.id_produto = pr.id_produto);
GO

/* Conclusao do exercicio 03:
   - Os tres caminhos respondem a mesma pergunta e devem trazer as mesmas linhas.
   - EXCEPT  : mais legivel, mas exige as mesmas colunas dos dois lados.
   - LEFT JOIN + IS NULL : mais flexivel (permite trazer colunas extras),
                           mas cuidado com duplicatas em JOIN 1:N.
   - NOT EXISTS : melhor desempenho em tabelas grandes. */


/* ---------------------------------------------------------------------
   EXERCICIO 04 (Medio)
   (a) INTERSECT: categorias que tem produtos cadastrados E ao menos uma venda.
   (b) EXCEPT   : categorias com produtos mas SEM venda.
   --------------------------------------------------------------------- */

-- 04a) Categorias COM produtos E COM vendas
SELECT id_categoria
FROM   PRODUTO
INTERSECT
SELECT pr.id_categoria
FROM   PRODUTO pr
INNER  JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto;
GO

-- 04b) Categorias COM produtos MAS SEM venda
SELECT id_categoria
FROM   PRODUTO
EXCEPT
SELECT pr.id_categoria
FROM   PRODUTO pr
INNER  JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto;
GO

/* Versao legivel: trazendo tambem o nome da categoria */
SELECT ca.id_categoria, ca.nome_categoria, 'Com venda' AS situacao
FROM   CATEGORIA ca
WHERE  ca.id_categoria IN (SELECT id_categoria FROM PRODUTO
                           INTERSECT
                           SELECT pr.id_categoria
                           FROM   PRODUTO pr
                           INNER  JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto)
UNION ALL
SELECT ca.id_categoria, ca.nome_categoria, 'Com produtos, sem venda'
FROM   CATEGORIA ca
WHERE  ca.id_categoria IN (SELECT id_categoria FROM PRODUTO
                           EXCEPT
                           SELECT pr.id_categoria
                           FROM   PRODUTO pr
                           INNER  JOIN ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto)
ORDER  BY situacao, nome_categoria;
GO


/* ---------------------------------------------------------------------
   EXERCICIO 05 (Avancado)
   Relatorio de auditoria ("painel de saude do banco") com UNION ALL:
   para cada tabela principal mostrar nome, total de registros e uma
   metrica relevante.
   - COUNT(coluna) ignora NULLs; COUNT(*) conta todas as linhas
   - NULL na primeira parte e resolvido pelo tipo das demais partes;
     CAST evita surpresas de tipo (regra 2)
   --------------------------------------------------------------------- */
SELECT 'CLIENTES'                    AS tabela,
       COUNT(*)                      AS registros,
       COUNT(email)                  AS registros_validos,   -- clientes com e-mail
       CAST(NULL AS DECIMAL(18,2))   AS metrica_valor
FROM   CLIENTE
UNION ALL
SELECT 'PRODUTOS',
       COUNT(*),
       COUNT(id_categoria),                                  -- produtos com categoria
       SUM(preco * estoque)                                  -- valor total em estoque
FROM   PRODUTO
UNION ALL
SELECT 'PEDIDOS',
       COUNT(*),
       COUNT(CASE WHEN status <> 'CANCELADO' THEN 1 END),    -- pedidos nao cancelados
       SUM(CASE WHEN status <> 'CANCELADO' THEN total ELSE 0 END)  -- faturamento valido
FROM   PEDIDO;
GO


/* =====================================================================
   PARTE 2 - DESAFIO DA AULA 12
   "Dashboard de Inteligencia de Negocios" do SISTEMA_VENDAS
   ===================================================================== */

/* ---------------------------------------------------------------------
   D1 - LISTA VIP
   Clientes que compraram mais de 1 vez (INTERSECT entre meses) E que
   gastaram acima da media (subquery). Mostrar nome, total gasto e
   classificacao.
   - INTERSECT: quem comprou em janeiro E em algum outro mes (recorrente)
   - Media: media do gasto total por cliente (so clientes com pedidos,
     ignorando pedidos cancelados)
   - Classificacao: Ouro (>= 2x a media) ou Prata (acima da media)
   --------------------------------------------------------------------- */
DECLARE @media_gasto DECIMAL(18,2) =
(
    SELECT AVG(g.gasto)
    FROM  (SELECT SUM(total) AS gasto
           FROM   PEDIDO
           WHERE  status <> 'CANCELADO'
           GROUP  BY id_cliente) AS g
);

SELECT c.nome,
       SUM(p.total) AS total_gasto,
       CASE WHEN SUM(p.total) >= 2 * @media_gasto THEN 'VIP Ouro'
            ELSE 'VIP Prata'
       END          AS classificacao
FROM   CLIENTE c
INNER  JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE  p.status <> 'CANCELADO'
  AND  c.id_cliente IN (SELECT id_cliente FROM PEDIDO WHERE MONTH(data_pedido) = 1
                        INTERSECT
                        SELECT id_cliente FROM PEDIDO WHERE MONTH(data_pedido) <> 1)
GROUP  BY c.id_cliente, c.nome
HAVING SUM(p.total) > @media_gasto
ORDER  BY total_gasto DESC;
GO

/* Alternativa mais geral (sem depender de janeiro): qualquer cliente com
   mais de 1 pedido. Aqui o INTERSECT nao e necessario - basta HAVING. */
-- SELECT id_cliente FROM PEDIDOS GROUP BY id_cliente HAVING COUNT(*) > 1;


/* ---------------------------------------------------------------------
   D2 - CATALOGO INATIVO
   Produtos nunca vendidos (EXCEPT), por categoria, com preco, estoque
   e valor parado em estoque (preco x estoque). Ordenar pelo valor parado.
   --------------------------------------------------------------------- */
SELECT ca.nome_categoria,
       pr.nome_produto,
       pr.preco,
       pr.estoque,
       pr.preco * pr.estoque AS valor_parado
FROM   PRODUTO pr
INNER  JOIN CATEGORIA ca ON pr.id_categoria = ca.id_categoria
WHERE  pr.id_produto IN (SELECT id_produto FROM PRODUTO
                         EXCEPT
                         SELECT DISTINCT id_produto FROM ITEM_PEDIDO)
ORDER  BY valor_parado DESC;
GO


/* ---------------------------------------------------------------------
   D3 - RELATORIO DE COBERTURA POR ESTADO
   Com UNION ALL: clientes ativos (com pedido), inativos (sem pedido) e
   percentual de conversao por estado.
   - Cada cliente entra UMA vez como 'Ativo' OU 'Inativo' (conjuntos
     disjuntos), por isso UNION ALL e seguro e mais rapido que UNION.
   - Depois, agregacao condicional (CASE dentro do SUM) transforma as
     linhas em colunas.
   - Conversao % = ativos / total de clientes do estado x 100
   --------------------------------------------------------------------- */
WITH situacao_clientes AS
(
    SELECT c.estado, c.id_cliente, 'Ativo' AS situacao
    FROM   CLIENTE c
    WHERE  EXISTS (SELECT 1 FROM PEDIDO p WHERE p.id_cliente = c.id_cliente)
    UNION ALL
    SELECT c.estado, c.id_cliente, 'Inativo'
    FROM   CLIENTE c
    WHERE  NOT EXISTS (SELECT 1 FROM PEDIDO p WHERE p.id_cliente = c.id_cliente)
)
SELECT estado,
       SUM(CASE WHEN situacao = 'Ativo'   THEN 1 ELSE 0 END) AS clientes_ativos,
       SUM(CASE WHEN situacao = 'Inativo' THEN 1 ELSE 0 END) AS clientes_inativos,
       COUNT(*)                                              AS total_clientes,
       CAST(100.0 * SUM(CASE WHEN situacao = 'Ativo' THEN 1 ELSE 0 END)
            / COUNT(*) AS DECIMAL(5,2))                      AS pct_conversao
FROM   situacao_clientes
GROUP  BY estado
ORDER  BY estado;
GO


/* ---------------------------------------------------------------------
   D4 - AUDITORIA FINANCEIRA
   Comparar totais de PEDIDOS (campo total registrado) vs ITENS_PEDIDO
   (total calculado) com UNION ALL e identificar divergencias com EXCEPT.
   --------------------------------------------------------------------- */

-- D4.1) Visao geral: as duas somas lado a lado (UNION ALL)
SELECT 'PEDIDOS (total registrado)' AS origem,
       COUNT(*)                     AS qtd_pedidos,
       SUM(total)                   AS soma
FROM   PEDIDO
UNION ALL
SELECT 'ITENS_PEDIDO (total calculado)',
       COUNT(DISTINCT id_pedido),
       SUM(quantidade * preco_unitario)
FROM   ITEM_PEDIDO;
-- Se as somas divergirem => inconsistencia de dados!
GO

-- D4.2) Quais pedidos divergem? (EXCEPT)
--       Pedidos cujo (id, total registrado) NAO bate com (id, total calculado)
SELECT id_pedido, total
FROM   PEDIDO
EXCEPT
SELECT id_pedido, SUM(quantidade * preco_unitario)
FROM   ITEM_PEDIDO
GROUP  BY id_pedido;
GO

-- D4.3) Sentido inverso: totais calculados que nao existem nos pedidos
--       (EXCEPT nao e comutativo: A EXCEPT B <> B EXCEPT A)
SELECT id_pedido, SUM(quantidade * preco_unitario) AS total_calculado
FROM   ITEM_PEDIDO
GROUP  BY id_pedido
EXCEPT
SELECT id_pedido, total
FROM   PEDIDO;
GO

-- D4.4) Detalhe das divergencias: registrado x calculado x diferenca
SELECT p.id_pedido,
       p.total                         AS total_registrado,
       ISNULL(i.total_calculado, 0)    AS total_calculado,
       p.total - ISNULL(i.total_calculado, 0) AS diferenca
FROM   PEDIDO p
LEFT   JOIN (SELECT id_pedido, SUM(quantidade * preco_unitario) AS total_calculado
             FROM   ITEM_PEDIDO
             GROUP  BY id_pedido) i ON p.id_pedido = i.id_pedido
WHERE  p.id_pedido IN (SELECT id_pedido FROM
                          (SELECT id_pedido, total FROM PEDIDO
                           EXCEPT
                           SELECT id_pedido, SUM(quantidade * preco_unitario)
                           FROM   ITEM_PEDIDO
                           GROUP  BY id_pedido) AS divergentes)
ORDER  BY p.id_pedido;
GO
/* Obs.: se o seu banco aplica desconto ou frete no pedido, o total
   registrado pode legitimamente diferir da soma dos itens. */


/* ---------------------------------------------------------------------
   D5 - BONUS: EXTRATO CRONOLOGICO
   UNION ALL unindo pedidos de clientes E alteracoes de estoque,
   ordenados por data.
   O banco nao possui historico de estoque, entao criamos uma tabela de
   movimentacao e simulamos algumas alteracoes.
   --------------------------------------------------------------------- */

-- 1) Tabela de movimentacao de estoque (so para o bonus)
IF OBJECT_ID('MOVIMENTACAO_ESTOQUE', 'U') IS NOT NULL
    DROP TABLE MOVIMENTACAO_ESTOQUE;

CREATE TABLE MOVIMENTACAO_ESTOQUE
(
    id_movimento    INT IDENTITY(1,1) PRIMARY KEY,
    id_produto      INT           NOT NULL,
    data_movimento  DATE          NOT NULL,
    tipo            VARCHAR(20)   NOT NULL,   -- ENTRADA / AJUSTE
    quantidade      INT           NOT NULL
);
GO

-- 2) Simulacao: movimentos distribuidos a partir da data do 1o pedido
DECLARE @base DATE = (SELECT MIN(CAST(data_pedido AS DATE)) FROM PEDIDOS);

INSERT INTO MOVIMENTACAO_ESTOQUE (id_produto, data_movimento, tipo, quantidade)
SELECT x.id_produto,
       DATEADD(DAY, x.rn * 10, @base),
       CASE WHEN x.rn % 2 = 1 THEN 'ENTRADA' ELSE 'AJUSTE' END,
       5 * x.rn
FROM  (SELECT TOP 4 id_produto,
              ROW_NUMBER() OVER (ORDER BY id_produto) AS rn
       FROM   PRODUTO
       ORDER  BY id_produto) AS x;
GO

-- 3) Extrato unificado: pedidos + movimentos de estoque
SELECT CAST(p.data_pedido AS DATE)                 AS data_evento,
       'Pedido'                                    AS tipo_evento,
       CONCAT('Pedido #', p.id_pedido, ' - ', c.nome) AS descricao,
       CAST(p.total AS DECIMAL(18,2))              AS valor
FROM   PEDIDO p
INNER  JOIN CLIENTE c ON p.id_cliente = c.id_cliente
UNION ALL
SELECT m.data_movimento,
       'Estoque',
       CONCAT(m.tipo, ' de ', m.quantidade, ' un. - ', pr.nome_produto),
       CAST(m.quantidade * pr.preco AS DECIMAL(18,2))
FROM   MOVIMENTACAO_ESTOQUE m
INNER  JOIN PRODUTO pr ON m.id_produto = pr.id_produto
ORDER  BY data_evento, tipo_evento;
GO
