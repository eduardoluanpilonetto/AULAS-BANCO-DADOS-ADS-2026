select
*
from
CLIENTE

SELECT 
nome,
email, 
cidade,
estado
FROM   CLIENTE;

SELECT nome           AS [Nome do Cliente],
       cidade         AS Cidade,
       estado         AS UF,
       data_cadastro  AS [Membro desde]
FROM   CLIENTE;

SELECT nome_produto,
       preco,
       estoque,
       preco * estoque AS valor_em_estoque,
       preco * 0.90 AS preco_com_desconto_10pct
FROM   PRODUTO;

SELECT TOP 3 
nome_produto, 
preco 
FROM 
PRODUTO
ORDER BY 
preco DESC

SELECT 
nome, 
email, 
cidade 
FROM 
CLIENTE
WHERE  
estado = 'SP';

sELECT
nome_produto, 
preco, 
estoque
FROM   
PRODUTO
WHERE
preco > 500.00;


SELECT
id_pedido,
id_cliente, 
status, 
total
FROM   
PEDIDO 
WHERE 
status != 'CANCELADO';

SELECT 
nome_produto,
preco 
FROM 
PRODUTO
WHERE  
preco BETWEEN 50.00 AND 300.00
ORDER BY 
preco;

SELECT 
id_pedido, 
status, 
total 
FROM 
PEDIDO
WHERE  
total > (SELECT AVG(total) FROM PEDIDO);

SELECT 
id_cliente, 
nome 
FROM 
CLIENTE
WHERE  
id_cliente BETWEEN 3 AND 6;

SELECT 
id_pedido,
data_pedido, 
total 
FROM 
PEDIDO
WHERE  
data_pedido BETWEEN '2026-01-01' AND '2026-12-31'

SELECT 
nome, 
cidade, 
estado
FROM CLIENTE
WHERE 
estado = 'SP' AND 
cidade = 'São Paulo';

SELECT 
nome,
estado
FROM CLIENTE
WHERE  
estado = 'SP' OR
estado = 'RJ';

SELECT 
nome,
estado
FROM 
CLIENTE 
WHERE  
estado IN ('SP','RJ');

SELECT
id_categoria,
nome_produto,
preco 
FROM PRODUTO
WHERE  
NOT id_categoria = 1; 


sELECT 
nome_produto,
preco, 
id_categoria 
FROM 
PRODUTO
WHERE  
(id_categoria = 2 OR id_categoria = 5)  
AND    preco < 200.00;

SELECT 
nome, 
estado 
FROM CLIENTE
WHERE  (
estado = 'SP' OR estado = 'RJ')
AND
NOT email IS NULL; 

SELECT DISTINCT estado FROM CLIENTE ORDER BY estado;-- Quais categorias têm produtos cadastrados?
SELECT DISTINCT id_categoria FROM PRODUTO;-- DISTINCT em múltiplas colunas (combinação única)
SELECT DISTINCT estado, cidade FROM CLIENTE ORDER BY estado, cidade;-- COUNT com DISTINCT: quantos estados distintos?
SELECT 
COUNT(DISTINCT estado) AS total_estados 
FROM 
CLIENTE;

 SELECT 
 nome          AS 'Nome Completo',
email         AS 'E-mail',
cidade        AS Cidade,
estado        AS UF
FROM   
CLIENTE AS c   -- alias de tabela (útil em JOINs!)
WHERE  c.estado <> 'DF';-- Alias de tabela (forma curta, sem AS)

SELECT 
p.nome_produto,
p.preco
FROM   
PRODUTO p   -- a

SELECT nome_produto, preco FROM PRODUTO
ORDER  BY preco DESC;-- Ordenação por múltiplas colunas
SELECT nome, estado, cidade FROM CLIENTE
ORDER  BY estado ASC, cidade ASC, nome ASC;-- Ordenar por alias (definido no SELECT)
SELECT nome_produto, preco * estoque AS valor_total
FROM   PRODUTO
ORDER  BY valor_total DESC;  -- alias funciona no ORDER BY!-- Ordenar por posição da coluna (evite — pouco legível)
SELECT nome_produto, preco FROM PRODUTO
ORDER  BY 2 DESC;  -- 2 = segunda coluna = preco-- NULL: vão por último no ASC, primeiro no DESC (padrão SQL Server)
SELECT nome, email FROM CLIENTE ORDER BY email ASC;-- Clientes sem email aparecem no final-- TOP com ORDER BY: os 3 pedidos de maior valor
SELECT TOP 3 id_pedido, total, status FROM PEDIDO
ORDER  BY total DESC;