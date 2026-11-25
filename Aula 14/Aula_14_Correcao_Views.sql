USE SISTEMA_VENDAS;
GO


/* =====================================================================
   EXERCICIO 01 (Basico)
   Criar vw_produtos_catalogo: nome_produto, nome_categoria, preco,
   estoque e valor_em_estoque (preco x estoque). Consultar com WHERE e
   GROUP BY.
   ===================================================================== */
CREATE OR ALTER VIEW vw_produtos_catalogo AS
SELECT pr.id_produto,
       pr.nome_produto,
       cat.nome_categoria,
       pr.preco,
       pr.estoque,
       pr.preco * pr.estoque AS valor_em_estoque   -- coluna calculada precisa de alias
FROM   PRODUTO   pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

-- Consulta simples: a view e usada como se fosse uma tabela
SELECT * FROM vw_produtos_catalogo;

-- Com WHERE: produtos com estoque baixo
SELECT nome_produto, nome_categoria, estoque
FROM   vw_produtos_catalogo
WHERE  estoque < 10;

-- Com WHERE: produtos caros (acima de 500)
SELECT nome_produto, preco
FROM   vw_produtos_catalogo
WHERE  preco > 500
ORDER  BY preco DESC;     -- ORDER BY e permitido na CONSULTA, nao no corpo da view

-- Com GROUP BY: valor total parado em estoque por categoria
SELECT nome_categoria,
       COUNT(*)                AS qtd_produtos,
       SUM(estoque)            AS total_unidades,
       SUM(valor_em_estoque)   AS valor_total_estoque
FROM   vw_produtos_catalogo
GROUP  BY nome_categoria
ORDER  BY valor_total_estoque DESC;
GO


/* =====================================================================
   EXERCICIO 02 (Basico)
   Criar vw_pedidos_completos com JOIN de PEDIDOS + CLIENTES +
   FUNCIONARIOS. Usar para: (a) listar pedidos ENTREGUE,
   (b) faturamento por UF com GROUP BY.
   ===================================================================== */
CREATE OR ALTER VIEW vw_pedidos_completos AS
SELECT p.id_pedido,
       FORMAT(p.data_pedido, 'dd/MM/yyyy') AS data,
       c.nome   AS cliente,
       c.estado AS uf,
       f.nome   AS vendedor,
       p.status,
       p.total
FROM   PEDIDO      p
JOIN   CLIENTE     c ON p.id_cliente     = c.id_cliente
JOIN   FUNCIONARIO f ON p.id_funcionario = f.id_funcionario;
GO

-- (a) Pedidos entregues
SELECT *
FROM   vw_pedidos_completos
WHERE  status = 'ENTREGUE';

-- (b) Faturamento por UF
SELECT uf,
       COUNT(*)   AS pedidos,
       SUM(total) AS faturamento
FROM   vw_pedidos_completos
GROUP  BY uf
ORDER  BY faturamento DESC;
GO


/* =====================================================================
   EXERCICIO 03 (Medio)
   View de seguranca vw_funcionarios_publico: expoe apenas id, nome e
   cargo (SEM salario). Consultar e verificar que o salario nao aparece.
   ===================================================================== */
CREATE OR ALTER VIEW vw_funcionarios_publico AS
SELECT id_funcionario,
       nome,
       cargo
FROM   FUNCIONARIO;       -- sem salario, sem cpf!
GO

-- Consulta a view: so aparecem id_funcionario, nome e cargo
SELECT * FROM vw_funcionarios_publico;

-- Verificacao: tentar buscar o salario pela view gera ERRO
-- (o EXEC + TRY/CATCH serve para mostrar a mensagem sem derrubar o script)
BEGIN TRY
    EXEC('SELECT salario FROM vw_funcionarios_publico');
END TRY
BEGIN CATCH
    PRINT 'Erro esperado: ' + ERROR_MESSAGE();   -- Invalid column name 'salario'
END CATCH;

-- Conferindo as colunas expostas pela view
SELECT COLUMN_NAME, DATA_TYPE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'vw_funcionarios_publico';
GO


/* =====================================================================
   EXERCICIO 04 (Medio)
   Criar vw_painel_clientes com LEFT JOIN + GROUP BY classificando como
   VIP / Regular / Inativo. Depois usar ALTER VIEW para adicionar a
   coluna 'ultimo_pedido' (MAX de data_pedido).
   ===================================================================== */

-- Passo 1: versao inicial da view
CREATE OR ALTER VIEW vw_painel_clientes AS
SELECT c.id_cliente,
       c.nome,
       c.estado,
       COUNT(p.id_pedido)       AS total_pedidos,   -- COUNT(coluna) ignora NULL: cliente sem pedido = 0
       ISNULL(SUM(p.total), 0)  AS gasto_total,
       CASE WHEN COUNT(p.id_pedido) = 0 THEN 'Inativo'
            WHEN SUM(p.total) > 1000    THEN 'VIP'
            ELSE 'Regular' END  AS perfil
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente   -- LEFT: mantem clientes sem pedido
GROUP  BY c.id_cliente, c.nome, c.estado;
GO

SELECT * FROM vw_painel_clientes ORDER BY gasto_total DESC;
GO

-- Passo 2: ALTER VIEW substitui a definicao inteira (por isso repetimos tudo)
ALTER VIEW vw_painel_clientes AS
SELECT c.id_cliente,
       c.nome,
       c.estado,
       COUNT(p.id_pedido)       AS total_pedidos,
       ISNULL(SUM(p.total), 0)  AS gasto_total,
       MAX(p.data_pedido)       AS ultimo_pedido,      -- NOVA COLUNA
       CASE WHEN COUNT(p.id_pedido) = 0 THEN 'Inativo'
            WHEN SUM(p.total) > 1000    THEN 'VIP'
            ELSE 'Regular' END  AS perfil
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
GROUP  BY c.id_cliente, c.nome, c.estado;
GO

-- Conferindo: agora a coluna ultimo_pedido existe (NULL para clientes inativos)
SELECT * FROM vw_painel_clientes ORDER BY ultimo_pedido DESC;

-- Quantos clientes em cada perfil?
SELECT perfil, COUNT(*) AS qtd_clientes
FROM   vw_painel_clientes
GROUP  BY perfil;
GO


/* =====================================================================
   EXERCICIO 05 (Avancado)
   Criar a biblioteca completa: vw_itens_detalhados (5 tabelas),
   vw_faturamento_categoria e vw_estoque_alertas. Depois criar uma
   query que faz JOIN entre duas views.
   ===================================================================== */

-- VIEW: itens detalhados (6 tabelas no FROM: ITENS + PEDIDOS + CLIENTES
--       + FUNCIONARIOS + PRODUTOS + CATEGORIAS)
CREATE OR ALTER VIEW vw_itens_detalhados AS
SELECT ip.id_pedido,
       c.nome                          AS cliente,
       f.nome                          AS vendedor,
       cat.nome_categoria,
       pr.nome_produto,
       ip.quantidade,
       ip.preco_unitario,
       ip.quantidade * ip.preco_unitario AS subtotal,
       p.status
FROM   ITEM_PEDIDO ip
JOIN   PEDIDO      p   ON ip.id_pedido      = p.id_pedido
JOIN   CLIENTE     c   ON p.id_cliente      = c.id_cliente
JOIN   FUNCIONARIO f   ON p.id_funcionario  = f.id_funcionario
JOIN   PRODUTO     pr  ON ip.id_produto     = pr.id_produto
JOIN   CATEGORIA   cat ON pr.id_categoria   = cat.id_categoria;
GO

-- VIEW: faturamento por categoria (ignora pedidos cancelados)
CREATE OR ALTER VIEW vw_faturamento_categoria AS
SELECT cat.nome_categoria,
       COUNT(DISTINCT p.id_pedido)              AS pedidos,
       SUM(ip.quantidade)                       AS itens_vendidos,
       SUM(ip.quantidade * ip.preco_unitario)   AS faturamento,
       AVG(ip.preco_unitario)                   AS preco_medio
FROM   ITEM_PEDIDO ip
JOIN   PRODUTO     pr  ON ip.id_produto   = pr.id_produto
JOIN   CATEGORIA   cat ON pr.id_categoria = cat.id_categoria
JOIN   PEDIDO      p   ON ip.id_pedido    = p.id_pedido
WHERE  p.status <> 'CANCELADO'
GROUP  BY cat.nome_categoria;
GO

-- VIEW: estoque com alertas
CREATE OR ALTER VIEW vw_estoque_alertas AS
SELECT pr.nome_produto,
       cat.nome_categoria,
       pr.preco,
       pr.estoque,
       pr.preco * pr.estoque AS valor_parado,
       CASE WHEN pr.estoque = 0  THEN 'SEM ESTOQUE'
            WHEN pr.estoque < 10 THEN 'ESTOQUE BAIXO'
            ELSE 'NORMAL' END AS alerta
FROM   PRODUTO   pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

-- Testando cada view isoladamente
SELECT * FROM vw_itens_detalhados;
SELECT * FROM vw_faturamento_categoria ORDER BY faturamento DESC;
SELECT * FROM vw_estoque_alertas WHERE alerta <> 'NORMAL';
GO

-- JOIN ENTRE DUAS VIEWS (1): clientes VIP e quanto gastaram por categoria
-- (consulta da propria aula)
SELECT vpc.nome              AS cliente,
       vpc.perfil,
       vpc.gasto_total,
       vid.nome_categoria,
       SUM(vid.subtotal)     AS gasto_por_categoria
FROM   vw_painel_clientes   vpc          -- view 1
JOIN   vw_itens_detalhados  vid          -- view 2
       ON vpc.nome = vid.cliente
WHERE  vpc.perfil = 'VIP'
GROUP  BY vpc.nome, vpc.perfil, vpc.gasto_total, vid.nome_categoria
ORDER  BY vpc.gasto_total DESC, gasto_por_categoria DESC;
-- Obs.: o ideal seria juntar por id_cliente. Como vw_itens_detalhados nao
-- expoe o id, juntamos pelo nome (cuidado com clientes homonimos).

-- JOIN ENTRE DUAS VIEWS (2): faturamento x situacao do estoque por categoria
SELECT fc.nome_categoria,
       fc.faturamento,
       COUNT(ea.nome_produto)                                         AS produtos_cadastrados,
       SUM(CASE WHEN ea.alerta <> 'NORMAL' THEN 1 ELSE 0 END)         AS produtos_em_alerta,
       SUM(ea.valor_parado)                                           AS valor_parado_estoque
FROM   vw_faturamento_categoria fc
JOIN   vw_estoque_alertas       ea ON fc.nome_categoria = ea.nome_categoria
GROUP  BY fc.nome_categoria, fc.faturamento
ORDER  BY fc.faturamento DESC;
GO


/* =====================================================================
   DESAFIO DA AULA 14
   Camada de acesso do SISTEMA_VENDAS: nenhuma aplicacao acessa as
   tabelas diretamente, apenas as views.
   ===================================================================== */

/* ---------------------------------------------------------------------
   V1 - vw_dashboard_geral: metricas globais em UMA linha
   (total de clientes, produtos, pedidos ativos, faturamento,
    ticket medio e produto mais caro)
   Cada metrica e uma subquery escalar; sem FROM externo = 1 linha so.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_dashboard_geral AS
SELECT
    (SELECT COUNT(*) FROM CLIENTE)                                      AS total_clientes,
    (SELECT COUNT(*) FROM PRODUTO)                                      AS total_produtos,
    (SELECT COUNT(*) FROM PEDIDO WHERE status <> 'CANCELADO')           AS pedidos_ativos,
    (SELECT ISNULL(SUM(total), 0) FROM PEDIDO WHERE status <> 'CANCELADO') AS faturamento,
    (SELECT ISNULL(AVG(total), 0) FROM PEDIDO WHERE status <> 'CANCELADO') AS ticket_medio,
    (SELECT TOP 1 nome_produto FROM PRODUTO ORDER BY preco DESC)        AS produto_mais_caro;
GO

SELECT * FROM vw_dashboard_geral;
GO


/* ---------------------------------------------------------------------
   V2 - vw_relatorio_mensal: faturamento por mes (YEAR + MONTH), pedidos,
   ticket medio e variacao % em relacao ao mes anterior (LAG).
   - A CTE agrupa por mes; o LAG enxerga a linha do mes anterior.
   - NULLIF evita divisao por zero.
   - Sem ORDER BY no corpo da view: quem consulta ordena.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_relatorio_mensal AS
WITH mensal AS (
    SELECT YEAR(p.data_pedido)   AS ano,
           MONTH(p.data_pedido)  AS mes,
           COUNT(*)              AS pedidos,
           SUM(p.total)          AS faturamento,
           AVG(p.total)          AS ticket_medio
    FROM   PEDIDO p
    WHERE  p.status <> 'CANCELADO'
    GROUP  BY YEAR(p.data_pedido), MONTH(p.data_pedido)
)
SELECT ano,
       mes,
       pedidos,
       faturamento,
       ticket_medio,
       LAG(faturamento) OVER (ORDER BY ano, mes) AS faturamento_mes_anterior,
       CAST(
         (faturamento - LAG(faturamento) OVER (ORDER BY ano, mes)) * 100.0
         / NULLIF(LAG(faturamento) OVER (ORDER BY ano, mes), 0)
       AS DECIMAL(10,2))                         AS variacao_pct
FROM   mensal;
GO

SELECT * FROM vw_relatorio_mensal ORDER BY ano, mes;
GO


/* ---------------------------------------------------------------------
   V3 - vw_auditoria_completa: FULL JOIN entre CLIENTES e PEDIDOS
   classificando cada registro:
     - 'Cliente sem compra' -> existe cliente, mas nao existe pedido
     - 'Pedido orfao'       -> existe pedido, mas nao existe cliente
     - 'OK'                 -> cliente e pedido existem
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_auditoria_completa AS
SELECT c.id_cliente,
       c.nome       AS cliente,
       p.id_pedido,
       p.id_cliente AS id_cliente_no_pedido,
       p.total,
       CASE WHEN p.id_pedido  IS NULL THEN N'Cliente sem compra'
            WHEN c.id_cliente IS NULL THEN N'Pedido órfão'
            ELSE 'OK' END AS situacao
FROM   CLIENTE c
FULL   JOIN PEDIDO p ON c.id_cliente = p.id_cliente;
GO

SELECT * FROM vw_auditoria_completa WHERE situacao <> 'OK';

SELECT situacao, COUNT(*) AS qtd
FROM   vw_auditoria_completa
GROUP  BY situacao;
GO


/* ---------------------------------------------------------------------
   V4 - vw_catalogo_seguro: view de seguranca. Oculta o preco de custo
   e mostra apenas preco de venda, categoria e disponibilidade.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_catalogo_seguro AS
SELECT pr.id_produto,
       pr.nome_produto,
       pr.preco                AS preco_venda,       -- preco_custo NAO e exposto
       cat.nome_categoria,
       CASE WHEN pr.estoque > 0 THEN N'Disponível'
            ELSE N'Indisponível' END AS disponibilidade
FROM   PRODUTO   pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

SELECT * FROM vw_catalogo_seguro;

-- Verificacao: a coluna de custo nao existe na view (erro esperado)
BEGIN TRY
    EXEC('SELECT preco_custo FROM vw_catalogo_seguro');
END TRY
BEGIN CATCH
    PRINT 'Erro esperado: ' + ERROR_MESSAGE();
END CATCH;

/* A aplicacao recebe permissao apenas na view:
   GRANT SELECT ON vw_catalogo_seguro TO [app_catalogo];
   DENY  SELECT ON PRODUTOS           TO [app_catalogo];
*/
GO


/* =====================================================================
   V5 - BONUS: SCRIPT DE DEPLOY COMPLETO
   Todas as views da aula com CREATE OR ALTER, na ORDEM CORRETA:
   primeiro as views que dependem so de tabelas, depois as que dependem
   de outras views (nenhuma view desta aula depende de outra view, mas
   mantemos a ordem: basicas -> complexas -> seguranca -> desafio).
   Pode ser executado quantas vezes quiser (idempotente).
   ===================================================================== */
PRINT '=== DEPLOY DA CAMADA DE VIEWS - SISTEMA_VENDAS ===';
GO

USE SISTEMA_VENDAS;
GO

/* ---------- 1. VIEWS BASICAS ---------- */

-- vw_produtos_catalogo: produtos com categoria e valor em estoque
CREATE OR ALTER VIEW vw_produtos_catalogo AS
SELECT pr.id_produto, pr.nome_produto, cat.nome_categoria,
       pr.preco, pr.estoque,
       pr.preco * pr.estoque AS valor_em_estoque
FROM   PRODUTO pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

-- vw_pedidos_completos: pedidos com cliente, vendedor e previsao de entrega
-- (versao final, apos o ALTER VIEW da aula)
CREATE OR ALTER VIEW vw_pedidos_completos AS
SELECT p.id_pedido,
       FORMAT(p.data_pedido, 'dd/MM/yyyy HH:mm') AS data_hora,
       c.nome   AS cliente,
       c.estado AS uf,
       f.nome   AS vendedor,
       f.cargo,
       p.status,
       p.total,
       DATEADD(DAY, 7, p.data_pedido) AS previsao_entrega
FROM   PEDIDO p
JOIN   CLIENTE c     ON p.id_cliente     = c.id_cliente
JOIN   FUNCIONARIO f ON p.id_funcionario = f.id_funcionario;
GO

/* ---------- 2. VIEWS COMPLEXAS ---------- */

-- vw_itens_detalhados: relatorio de itens (JOIN de 6 tabelas)
CREATE OR ALTER VIEW vw_itens_detalhados AS
SELECT ip.id_pedido, c.nome AS cliente, f.nome AS vendedor,
       cat.nome_categoria, pr.nome_produto,
       ip.quantidade, ip.preco_unitario,
       ip.quantidade * ip.preco_unitario AS subtotal,
       p.status
FROM   ITEM_PEDIDO ip
JOIN   PEDIDO      p   ON ip.id_pedido     = p.id_pedido
JOIN   CLIENTE     c   ON p.id_cliente     = c.id_cliente
JOIN   FUNCIONARIO f   ON p.id_funcionario = f.id_funcionario
JOIN   PRODUTO     pr  ON ip.id_produto    = pr.id_produto
JOIN   CATEGORIA   cat ON pr.id_categoria  = cat.id_categoria;
GO

-- vw_painel_clientes: classificacao VIP / Regular / Inativo
CREATE OR ALTER VIEW vw_painel_clientes AS
SELECT c.id_cliente, c.nome, c.estado,
       COUNT(p.id_pedido)      AS total_pedidos,
       ISNULL(SUM(p.total), 0) AS gasto_total,
       MAX(p.data_pedido)      AS ultimo_pedido,
       CASE WHEN COUNT(p.id_pedido) = 0 THEN 'Inativo'
            WHEN SUM(p.total) > 1000    THEN 'VIP'
            ELSE 'Regular' END AS perfil
FROM   CLIENTE c
LEFT   JOIN PEDIDO p ON c.id_cliente = p.id_cliente
GROUP  BY c.id_cliente, c.nome, c.estado;
GO

-- vw_faturamento_categoria: dashboard de faturamento por categoria
CREATE OR ALTER VIEW vw_faturamento_categoria AS
SELECT cat.nome_categoria,
       COUNT(DISTINCT p.id_pedido)            AS pedidos,
       SUM(ip.quantidade)                     AS itens_vendidos,
       SUM(ip.quantidade * ip.preco_unitario) AS faturamento,
       AVG(ip.preco_unitario)                 AS preco_medio
FROM   ITEM_PEDIDO ip
JOIN   PRODUTO   pr  ON ip.id_produto   = pr.id_produto
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria
JOIN   PEDIDO    p   ON ip.id_pedido    = p.id_pedido
WHERE  p.status <> 'CANCELADO'
GROUP  BY cat.nome_categoria;
GO

-- vw_estoque_alertas: estoque com alerta (sem estoque / baixo / normal)
CREATE OR ALTER VIEW vw_estoque_alertas AS
SELECT pr.nome_produto, cat.nome_categoria, pr.preco, pr.estoque,
       pr.preco * pr.estoque AS valor_parado,
       CASE WHEN pr.estoque = 0  THEN 'SEM ESTOQUE'
            WHEN pr.estoque < 10 THEN 'ESTOQUE BAIXO'
            ELSE 'NORMAL' END AS alerta
FROM   PRODUTO pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

/* ---------- 3. VIEWS DE SEGURANCA ---------- */

-- vw_funcionarios_publico: seguranca por COLUNA (sem salario/cpf)
CREATE OR ALTER VIEW vw_funcionarios_publico AS
SELECT id_funcionario, nome, cargo
FROM   FUNCIONARIO;
GO

-- vw_clientes_sp: seguranca por LINHA (apenas clientes de SP)
CREATE OR ALTER VIEW vw_clientes_sp AS
SELECT id_cliente, nome, email, cidade
FROM   CLIENTE
WHERE  estado = 'SP';
GO

-- vw_catalogo_seguro: oculta preco de custo e mostra disponibilidade
CREATE OR ALTER VIEW vw_catalogo_seguro AS
SELECT pr.id_produto, pr.nome_produto,
       pr.preco AS preco_venda,
       cat.nome_categoria,
       CASE WHEN pr.estoque > 0 THEN N'Disponível'
            ELSE N'Indisponível' END AS disponibilidade
FROM   PRODUTO pr
JOIN   CATEGORIA cat ON pr.id_categoria = cat.id_categoria;
GO

/* ---------- 4. VIEWS DO DESAFIO (camada de acesso) ---------- */

-- vw_dashboard_geral: metricas globais em uma unica linha
CREATE OR ALTER VIEW vw_dashboard_geral AS
SELECT
    (SELECT COUNT(*) FROM CLIENTE)                                         AS total_clientes,
    (SELECT COUNT(*) FROM PRODUTO)                                         AS total_produtos,
    (SELECT COUNT(*) FROM PEDIDO WHERE status <> 'CANCELADO')              AS pedidos_ativos,
    (SELECT ISNULL(SUM(total), 0) FROM PEDIDO WHERE status <> 'CANCELADO') AS faturamento,
    (SELECT ISNULL(AVG(total), 0) FROM PEDIDO WHERE status <> 'CANCELADO') AS ticket_medio,
    (SELECT TOP 1 nome_produto FROM PRODUTO ORDER BY preco DESC)           AS produto_mais_caro;
GO

-- vw_relatorio_mensal: faturamento mensal com variacao % (LAG)
CREATE OR ALTER VIEW vw_relatorio_mensal AS
WITH mensal AS (
    SELECT YEAR(p.data_pedido) AS ano, MONTH(p.data_pedido) AS mes,
           COUNT(*) AS pedidos, SUM(p.total) AS faturamento, AVG(p.total) AS ticket_medio
    FROM   PEDIDO p
    WHERE  p.status <> 'CANCELADO'
    GROUP  BY YEAR(p.data_pedido), MONTH(p.data_pedido)
)
SELECT ano, mes, pedidos, faturamento, ticket_medio,
       LAG(faturamento) OVER (ORDER BY ano, mes) AS faturamento_mes_anterior,
       CAST((faturamento - LAG(faturamento) OVER (ORDER BY ano, mes)) * 100.0
            / NULLIF(LAG(faturamento) OVER (ORDER BY ano, mes), 0) AS DECIMAL(10,2)) AS variacao_pct
FROM   mensal;
GO

-- vw_auditoria_completa: FULL JOIN clientes x pedidos com classificacao
CREATE OR ALTER VIEW vw_auditoria_completa AS
SELECT c.id_cliente, c.nome AS cliente,
       p.id_pedido, p.id_cliente AS id_cliente_no_pedido, p.total,
       CASE WHEN p.id_pedido  IS NULL THEN N'Cliente sem compra'
            WHEN c.id_cliente IS NULL THEN N'Pedido órfão'
            ELSE 'OK' END AS situacao
FROM   CLIENTE c
FULL   JOIN PEDIDO p ON c.id_cliente = p.id_cliente;
GO

/* ---------- 5. CONFERENCIA DO DEPLOY ---------- */
-- Lista todas as views criadas no banco
SELECT TABLE_SCHEMA AS schema_name,
       TABLE_NAME   AS view_name
FROM   INFORMATION_SCHEMA.VIEWS
ORDER  BY TABLE_NAME;
GO

PRINT '=== DEPLOY CONCLUIDO ===';
GO


/* =====================================================================
   EXTRAS DA AULA - Inspecionando e removendo views
   ===================================================================== */

-- Ver a definicao (codigo) de uma view
EXEC sp_helptext 'vw_pedidos_completos';

SELECT DEFINITION
FROM   INFORMATION_SCHEMA.VIEWS
WHERE  TABLE_NAME = 'vw_pedidos_completos';

-- Ver as colunas de uma view
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'vw_pedidos_completos';
GO

/* LIMPEZA (rodar so se quiser remover tudo - DROP VIEW nao apaga dados!)

IF OBJECT_ID('vw_itens_detalhados',      'V') IS NOT NULL DROP VIEW vw_itens_detalhados;
IF OBJECT_ID('vw_pedidos_completos',     'V') IS NOT NULL DROP VIEW vw_pedidos_completos;
IF OBJECT_ID('vw_produtos_catalogo',     'V') IS NOT NULL DROP VIEW vw_produtos_catalogo;
IF OBJECT_ID('vw_painel_clientes',       'V') IS NOT NULL DROP VIEW vw_painel_clientes;
IF OBJECT_ID('vw_faturamento_categoria', 'V') IS NOT NULL DROP VIEW vw_faturamento_categoria;
IF OBJECT_ID('vw_estoque_alertas',       'V') IS NOT NULL DROP VIEW vw_estoque_alertas;
IF OBJECT_ID('vw_funcionarios_publico',  'V') IS NOT NULL DROP VIEW vw_funcionarios_publico;
IF OBJECT_ID('vw_clientes_sp',           'V') IS NOT NULL DROP VIEW vw_clientes_sp;
IF OBJECT_ID('vw_catalogo_seguro',       'V') IS NOT NULL DROP VIEW vw_catalogo_seguro;
IF OBJECT_ID('vw_dashboard_geral',       'V') IS NOT NULL DROP VIEW vw_dashboard_geral;
IF OBJECT_ID('vw_relatorio_mensal',      'V') IS NOT NULL DROP VIEW vw_relatorio_mensal;
IF OBJECT_ID('vw_auditoria_completa',    'V') IS NOT NULL DROP VIEW vw_auditoria_completa;
GO
*/
