USE SISTEMA_VENDAS;

--EXERCICIO 1
-- (a) Clientes cujo nome contém 'a' (minúscula ou maiúscula)
-- LIKE já é case-insensitive por padrão no SQL Server, então '%a%' já pega A e a
SELECT nome FROM CLIENTE
WHERE nome LIKE '%a%';

-- (b) Produtos que começam com 'Note' ou 'Fone'
SELECT nome_produto FROM PRODUTO
WHERE nome_produto LIKE 'Note%' OR nome_produto LIKE 'Fone%';

-- (c) Emails que terminam em '.com'
SELECT nome, email FROM CLIENTE
WHERE email LIKE '%.com';

--EXERCICIO 2
-- Produtos entre R$100 e R$1.000 (inclusive)
SELECT nome_produto, preco FROM PRODUTO
WHERE preco BETWEEN 100.00 AND 1000.00
ORDER BY preco;

-- Produtos FORA dessa faixa
SELECT nome_produto, preco FROM PRODUTO
WHERE preco NOT BETWEEN 100.00 AND 1000.00
ORDER BY preco;

-- Comparação: as duas consultas juntas devem cobrir 100% da tabela
-- (BETWEEN + NOT BETWEEN = todos os registros, sem sobreposição)

SELECT
(SELECT COUNT(*) FROM PRODUTO) AS total,
(SELECT COUNT(*) FROM PRODUTO WHERE preco BETWEEN 100.00 AND 1000.00) AS dentro_faixa,
(SELECT COUNT(*) FROM PRODUTO WHERE preco NOT BETWEEN 100.00 AND 1000.00) AS fora_faixa;

--EXERCICIO 3
SELECT nome        AS [Nome],
       email       AS [E-mail],
       estado      AS UF,
       ISNULL(telefone, 'Não informado') AS [Telefone]
FROM   CLIENTE
WHERE  estado IN ('SP', 'RJ', 'MG')
AND    email IS NOT NULL
ORDER BY estado, nome;

--EXERCICIO 4
-- Query de auditoria: total x com email x sem email
SELECT COUNT(*)                    AS total_clientes,
       COUNT(email)                AS com_email,
       COUNT(*) - COUNT(email)     AS sem_email
FROM   CLIENTE;

-- Lista de estados únicos com clientes cadastrados
SELECT DISTINCT estado
FROM   CLIENTE
ORDER BY estado;

--EXERCICIO 5
-- Versão direta
SELECT nome_produto                        AS Produto,
       preco                               AS [Preço (R$)],
       ISNULL(descricao, 'Sem descrição')  AS Descricao
FROM   PRODUTO
WHERE  nome_produto LIKE '%o%'
AND    preco BETWEEN 50 AND 500
AND    id_categoria NOT IN (3, 4)
ORDER BY preco;

-- Versão com subquery no FROM (derived table)
SELECT sub.Produto, sub.[Preço (R$)], sub.Descricao
FROM (
    SELECT nome_produto AS Produto,
           preco        AS [Preço (R$)],
           ISNULL(descricao, 'Sem descrição') AS Descricao
    FROM   PRODUTO
    WHERE  nome_produto LIKE '%o%'
    AND    preco BETWEEN 50 AND 500
    AND    id_categoria NOT IN (3, 4)
) AS sub
ORDER BY sub.[Preço (R$)];

--DESAFIO
SELECT nome, email, cidade
FROM   CLIENTE
WHERE  (nome LIKE '% %a%' OR nome LIKE '% %o%')  -- 'a' ou 'o' após o primeiro espaço (sobrenome)
AND    email IS NOT NULL;

SELECT nome_produto              AS [Produto],
       FORMAT(preco, 'C', 'pt-BR') AS [Preço],
       estoque                   AS [Em estoque]
FROM   PRODUTO
WHERE  id_categoria IN (1, 2)
AND    preco BETWEEN 150.00 AND 1000.00
ORDER BY preco;

SELECT nome                                AS [Nome],
       cidade                              AS [Cidade],
       estado                              AS UF,
       ISNULL(telefone, 'Não informado')   AS [Telefone]
FROM   CLIENTE
WHERE  email IS NULL
AND    estado NOT IN ('SP', 'RJ');

SELECT DISTINCT cidade
FROM   CLIENTE
WHERE  nome LIKE '[AEIOU]%'
ORDER BY cidade;

SELECT nome_produto                        AS [Produto],
       preco                               AS [Preço],
       ISNULL(descricao, '—')              AS [Descrição]
FROM   PRODUTO
WHERE  (nome_produto LIKE '%Pro%' OR id_categoria IN (1, 5))
AND    preco NOT BETWEEN 3000.00 AND 10000.00
ORDER BY preco;