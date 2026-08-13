--EXERCÍCIO 1
insert into CLIENTE (nome, email, telefone, cidade, estado) values
('Kaun', 'kauan@email.com', '1099999999', 'Piratuba', 'SC'),
('Andressa', 'andressa@email.com', '2199999999', 'Concórdia', 'SC'),
('Gabriel', 'ococha@email.com', '3499999999', 'Arabutã', 'SC')
select SCOPE_IDENTITY()

--EXERCÍCIO 2
insert into PRODUTO (nome_produto, id_categoria, id_fornecedor, preco, estoque) values
('Livro Técnico', 6, 1, 54, 10),
('Smartwatch', 1, 1, 700, 3)

--Exercício 3
-- Exercício 3

INSERT INTO PEDIDO (id_cliente, id_funcionario, status, data_pedido)
VALUES (4, 1, 'CONCLUIDO', dateadd(minute, -5, getdate()));

DECLARE @idpedido INT = SCOPE_IDENTITY();
PRINT @idpedido
INSERT INTO ITEM_PEDIDO 
    (id_pedido, id_produto, quantidade, preco_unitario)
SELECT TOP 2
    @idpedido,
    id_produto,
    1,
    preco
FROM PRODUTO;

--EXERCÍCIO 4
SELECT PRODUTO.*,
       GETDATE() AS data_backup
INTO   PRODUTOS_ELETRONICOS  -- tabela criada automaticamente!
FROM   PRODUTO
WHERE
id_categoria = 1;
GO
SELECT * FROM PRODUTOS_ELETRONICOS
SELECT * FROM PRODUTO

--EXERCÍCIO 5
begin tran
begin try 
    INSERT INTO PEDIDO (id_cliente, id_funcionario, status, data_pedido)
    VALUES (3, 1, 'CONCLUIDO', dateadd(minute, -5, getdate()));

    DECLARE @idpedido INT = SCOPE_IDENTITY();

    INSERT INTO ITEM_PEDIDO 
    (id_pedido, id_produto, quantidade, preco_unitario)
    SELECT TOP 3
    @idpedido,
    id_produto,
    1,
    preco
    FROM PRODUTO;

    UPDATE
    PEDIDO
    SET 
    total = (select sum(preco_unitario) from ITEM_PEDIDO where id_pedido = @idpedido)
    where
    id_pedido = @idpedido

    commit tran
end try
begin catch 
    rollback tran
end catch

