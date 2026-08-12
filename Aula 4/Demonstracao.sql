USE SISTEMA_VENDAS
INSERT INTO CATEGORIA (nome_categoria, descricao, ativo)
VALUES
    ('Eletrônicos',  'Smartphones, notebooks, tablets e acessórios',  1),
    ('Roupas',       'Vestuário masculino, feminino e infantil',       1),
    ('Alimentos',    'Produtos alimentícios e bebidas variadas',       1),
    ('Móveis',       'Móveis para casa e escritório',                  1),
    ('Esportes',     'Equipamentos e artigos esportivos',              1),
    ('Livros',       'Livros técnicos, didáticos e literatura',        1);


SELECT id_categoria, nome_categoria, ativo
FROM   CATEGORIA
ORDER  BY id_categoria;

-- ===================================================-- CLIENTES: 8 registros variados (diferentes estados)-- ===================================================
INSERT INTO CLIENTE (nome, email, telefone, cidade, estado)
VALUES
    ('Ana Silva',       'ana.silva@email.com',    '11999001001', 'São Paulo',      'SP'),
    ('Bruno Santos',    'bruno@email.com',        '21999002002', 'Rio de Janeiro', 'RJ'),
    ('Carla Oliveira',  'carla@email.com',        '31999003003', 'Belo Horizonte', 'MG'),
    ('Diego Ferreira',  'diego@email.com',        '41999004004', 'Curitiba',       'PR'),
    ('Eva Costa',       'eva@email.com',          '51999005005', 'Porto Alegre',   'RS'),
    ('Felipe Lima',     'felipe@email.com',       '11999006006', 'São Paulo',      'SP'),
    ('Gabriela Rocha',  'gabi@email.com',         '21999007007', 'Rio de Janeiro', 'RJ'),
    ('Henrique Dias',   NULL,                     '61999008008', 'Brasília',       'DF');

-- Verificar: Henrique tem email NULL (campo opcional)-- data_cadastro foi preenchida automaticamente pelo DEFAULT GETDATE()
SELECT id_cliente, nome, email, estado,
       CONVERT(DATE, data_cadastro) AS cadastrado_em
FROM   CLIENTE ORDER BY id_cliente;

INSERT INTO FUNCIONARIO (nome, cargo, salario)
VALUES
    ('João Vendedor',   'Vendedor',         2800.00),
    ('Maria Gerente',   'Gerente',          5500.00),
    ('Pedro Estoque',   'Estoquista',       2200.00),
    ('Lucia Caixa',     'Operador Cx',      2000.00);

INSERT INTO PRODUTO (nome_produto, preco, estoque, id_categoria)
VALUES
    ('iPhone 15 Pro',      6999.99,  15, 1),  -- Eletrônicos
    ('Notebook Dell i7',   3499.00,   8, 1),  -- Eletrônicos
    ('Fone Bluetooth JBL',  199.90,  50, 1),  -- Eletrônicos
    ('Camisa Polo Pq',       89.90, 100, 2),  -- Roupas
    ('Calça Jeans 42',      149.90,  60, 2),  -- Roupas
    ('Arroz Integral 5kg',   28.90, 200, 3),  -- Alimentos
    ('Café Gourmet 500g',    42.50, 150, 3),  -- Alimentos
    ('Sofá 3 Lugares',     1890.00,   5, 4),  -- Móveis
    ('Bicicleta 21v',       890.00,  12, 5),  -- Esportes
    ('Tênis Running Pro',   299.90,  35, 5);  -- Esportes

 INSERT INTO PEDIDO (id_cliente, id_funcionario, status, total)
VALUES
    (1, 1, 'ENTREGUE',  479.80),  -- Ana comprou com João
    (2, 1, 'ENVIADO',  7199.89),  -- Bruno comprou com João
    (3, 2, 'APROVADO',  268.70),  -- Carla comprou com Maria
    (1, 3, 'PENDENTE',   42.50),  -- Ana comprou com Pedro
    (5, 1, 'CANCELADO',  89.90),  -- Eva cancelou
    (6, 2, 'ENTREGUE', 1890.00);  -- Felipe comprou com Maria

    INSERT INTO ITEM_PEDIDO (id_pedido, id_produto, quantidade, preco_unitario)
VALUES
    (2, 4,  2,  89.90),  -- Pedido 1: 2x Camisa Polo  = 179.80
    (2, 10, 1, 299.90),  -- Pedido 1: 1x Tênis Running = 299.90
    (3, 1,  1, 6999.99), -- Pedido 2: 1x iPhone 15    = 6999.99
    (3, 3,  1,  199.90), -- Pedido 2: 1x Fone BT      = 199.90
    (4, 5,  1,  149.90), -- Pedido 3: 1x Calça Jeans  = 149.90
    (4, 6,  2,   28.90), -- Pedido 3: 2x Arroz        = 57.80
    (4, 7,  1,   42.50), -- Pedido 3: 1x Café         = 42.50
    (5, 7,  1,   42.50), -- Pedido 4: 1x Café         = 42.50
    (6, 4,  1,   89.90), -- Pedido 5: 1x Camisa (canc)= 89.90
    (7, 8,  1, 1890.00); -- Pedido 6: 1x Sofá         = 1890.00


    

 SELECT 'CATEGORIAS'   AS tabela, COUNT(*) AS registros FROM CATEGORIA
UNION ALL
SELECT 'CLIENTES',              COUNT(*)             FROM CLIENTE
UNION ALL
SELECT 'FUNCIONARIOS',          COUNT(*)             FROM FUNCIONARIO
UNION ALL
SELECT 'PRODUTOS',              COUNT(*)             FROM PRODUTO
UNION ALL
SELECT 'PEDIDOS',               COUNT(*)             FROM PEDIDO
UNION ALL
SELECT 'ITENS_PEDIDO',          COUNT(*)             FROM ITEM_PEDIDO;

DECLARE @id_pedido INT;
INSERT INTO PEDIDO (id_cliente, id_funcionario, status, total)
VALUES (4, 1, 'PENDENTE', 0.00);
SET @id_pedido =  SCOPE_IDENTITY();
PRINT 'Novo pedido criado com ID: ' + CAST(@id_pedido AS VARCHAR(1000));-- Inserir o pedido
INSERT INTO ITEM_PEDIDO (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (@id_pedido, 9, 1, 890.00),   -- Bicicleta 21v
       (@id_pedido, 5, 2, 149.90);   -- 2x Calça Jeans
GO-- Capturar o ID gerado


INSERT INTO CLIENTE (nome, cidade, estado)
OUTPUT INSERTED.id_cliente, INSERTED.nome, INSERTED.data_cadastro
VALUES ('Isabela Nunes', 'Fortaleza', 'CE');

CREATE TABLE CAMPANHA_SP (
    id_campanha INT IDENTITY(1,1) PRIMARY KEY,
    nome        VARCHAR(150),
    email       VARCHAR(200),
    importado_em DATETIME2 DEFAULT GETDATE()
);
GO-- Passo 2: INSERT...SELECT para popular a tabela
INSERT INTO CAMPANHA_SP (nome, email)
SELECT nome, email FROM CLIENTE
WHERE  estado = 'SP' AND email IS NOT NULL;
GO-- ===== SELECT INTO: criar + inserir em um comando! =-- Não precisa criar a tabela antes
SELECT nome, email, cidade, estado,
       GETDATE() AS data_backup
INTO   CLIENTES_BACKUP_2025  -- tabela criada automaticamente!
FROM   CLIENTE;
GO


SELECT * FROM CLIENTES_BACKUP_2025