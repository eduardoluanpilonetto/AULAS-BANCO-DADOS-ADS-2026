USE SISTEMA_VENDAS;
GO

-- Adicionar colunas cep e complemento
ALTER TABLE CLIENTE ADD cep CHAR(8) NULL;
ALTER TABLE CLIENTE ADD complemento VARCHAR(100) NULL;

-- Adicionar CHECK para validar tamanho da sigla do estado (2 caracteres)
ALTER TABLE CLIENTE
ADD CONSTRAINT CK_CLI_ESTADO CHECK (LEN(estado) = 2);
GO

-- 1. Criar a tabela FORNECEDORES
CREATE TABLE FORNECEDOR (
    id_fornecedor INT IDENTITY(1,1) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cnpj CHAR(14) NULL,
    email VARCHAR(200) NULL,
    ativo BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT PK_FORNECEDOR PRIMARY KEY (id_fornecedor),
    CONSTRAINT UQ_FORN_CNPJ UNIQUE (cnpj)
);
GO

-- 2. Adicionar id_fornecedor e a FK na tabela PRODUTOS
ALTER TABLE PRODUTO ADD id_fornecedor INT NULL;

ALTER TABLE PRODUTO 
ADD CONSTRAINT FK_PROD_FORN FOREIGN KEY (id_fornecedor) 
REFERENCES FORNECEDOR(id_fornecedor) 
ON DELETE SET NULL;
GO

ALTER TABLE PEDIDO 
ADD CONSTRAINT CK_PED_DATA CHECK (data_pedido <= GETDATE());

-- Teste de inserção com data futura (deve falhar e retornar erro de CHECK constraint)
INSERT INTO PEDIDO (id_cliente, id_funcionario, data_pedido, status)
VALUES (1, 1, '2099-12-31', 'PENDENTE');

IF OBJECT_ID('ITEM_PEDIDO', 'U') IS NOT NULL DROP TABLE ITEM_PEDIDO;
IF OBJECT_ID('PEDIDO', 'U') IS NOT NULL DROP TABLE PEDIDO;
IF OBJECT_ID('PRODUTO', 'U') IS NOT NULL DROP TABLE PRODUTO;
IF OBJECT_ID('FORNECEDOR', 'U') IS NOT NULL DROP TABLE FORNECEDOR;
IF OBJECT_ID('CATEGORIA', 'U') IS NOT NULL DROP TABLE CATEGORIA;
IF OBJECT_ID('CLIENTE', 'U') IS NOT NULL DROP TABLE CLIENTE;
IF OBJECT_ID('FUNCIONARIO', 'U') IS NOT NULL DROP TABLE FUNCIONARIO;
GO

PRINT 'Banco de dados resetado com sucesso!';

-- Adicionar coluna calculada persistida
ALTER TABLE ITENS_PEDIDO
ADD subtotal AS (quantidade * preco_unitario) PERSISTED;
GO

-- Query para verificar o estado da coluna calculada
SELECT 
    name AS nome_coluna, 
    is_computed, 
    is_persisted
FROM sys.columns
WHERE object_id = OBJECT_ID('ITEM_PEDIDO') 
  AND name = 'subtotal';
GO