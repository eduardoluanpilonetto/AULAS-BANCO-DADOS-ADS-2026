/* ============================================================
   AULA 08 — BANCO DE DADOS COM SQL SERVER
   Script de Correção — Exercícios Propostos + Desafio
   Banco: SISTEMA_VENDAS
   ============================================================ */

USE SISTEMA_VENDAS;
GO

/* ============================================================
   EXERCÍCIO 01 (Básico)
   Reajuste de 12% no preço de todos os produtos da categoria
   'Roupas'. OUTPUT para ver antes/depois. Confirmar com SELECT.
   ============================================================ */

-- Antes
SELECT p.id_produto, p.nome_produto, p.preco, c.nome_categoria
FROM   PRODUTO p
JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
WHERE  c.nome_categoria = 'Roupas';

UPDATE p
SET    p.preco = p.preco * 1.12
OUTPUT DELETED.nome_produto,
       DELETED.preco  AS preco_antes,
       INSERTED.preco AS preco_depois
FROM   PRODUTO p
JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
WHERE  c.nome_categoria = 'Roupas';
GO

-- Depois (confirmação)
SELECT p.id_produto, p.nome_produto, p.preco, c.nome_categoria
FROM   PRODUTO p
JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
WHERE  c.nome_categoria = 'Roupas';


/* ============================================================
   EXERCÍCIO 02 (Básico)
   Deletar pedidos CANCELADO. Excluir primeiro os itens
   (FK!), depois os pedidos. SELECT antes de cada DELETE.
   ============================================================ */

-- Ver o que será excluído
SELECT id_pedido, status, total FROM PEDIDO WHERE status = 'CANCELADO';

SELECT ip.*
FROM   ITEM_PEDIDO ip
JOIN   PEDIDO p ON ip.id_pedido = p.id_pedido
WHERE  p.status = 'CANCELADO';

-- Passo 1: excluir os itens (FK primeiro!)
DELETE FROM ITEM_PEDIDO
OUTPUT DELETED.id_item, DELETED.id_pedido, DELETED.id_produto
WHERE  id_pedido IN (SELECT id_pedido FROM PEDIDO WHERE status = 'CANCELADO');
GO

-- Passo 2: excluir os pedidos cancelados
DELETE FROM PEDIDO
OUTPUT DELETED.id_pedido, DELETED.status
WHERE  status = 'CANCELADO';
GO

-- Confirmar (deve retornar 0 linhas)
SELECT * FROM PEDIDO WHERE status = 'CANCELADO';


/* ============================================================
   EXERCÍCIO 03 (Médio) — já demonstrado no slide, reproduzido
   aqui para o script completo de correção
   ============================================================ */
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE PEDIDO SET status = 'APROVADO' WHERE id_pedido = 4;

    UPDATE pr
    SET    pr.estoque = pr.estoque - ip.quantidade
    FROM   PRODUTO pr
    JOIN   ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
    WHERE  ip.id_pedido = 4;

    IF EXISTS (SELECT 1 FROM PRODUTO WHERE estoque < 0)
        THROW 50003, 'Estoque ficou negativo!', 1;

    COMMIT;
    PRINT 'Pedido 4 aprovado!';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ERRO: ' + ERROR_MESSAGE();
END CATCH
GO


/* ============================================================
   EXERCÍCIO 04 (Médio) — já demonstrado no slide, reproduzido
   aqui para o script completo de correção
   ============================================================ */
UPDATE p
SET    p.total = (
           SELECT SUM(ip.quantidade * ip.preco_unitario)
           FROM   ITEM_PEDIDO ip
           WHERE  ip.id_pedido = p.id_pedido
       )
FROM   PEDIDO p;
GO
SELECT id_pedido, total FROM PEDIDO ORDER BY id_pedido;


/* ============================================================
   EXERCÍCIO 05 (Avançado)
   Script de "encerramento do mês":
   1) mover pedidos ENTREGUES há mais de 30 dias para
      PEDIDOS_HISTORICO (SELECT INTO)
   2) deletar esses pedidos de PEDIDOS
   3) atualizar estatística na tabela FUNCIONARIOS
   TRY/CATCH com ROLLBACK completo.
   ============================================================ */

-- Cria a tabela de histórico se ainda não existir
IF OBJECT_ID('PEDIDOS_HISTORICO', 'U') IS NULL
BEGIN
    SELECT *, CAST(NULL AS DATETIME2) AS arquivado_em
    INTO   PEDIDOS_HISTORICO
    FROM   PEDIDO
    WHERE  1 = 0; -- cria só a estrutura, sem linhas
END
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1) Mover pedidos ENTREGUES há mais de 30 dias
    INSERT INTO PEDIDOS_HISTORICO
    SELECT *, GETDATE() AS arquivado_em
    FROM   PEDIDO
    WHERE  status = 'ENTREGUE'
       AND DATEDIFF(DAY, data_pedido, GETDATE()) > 30;

    -- 2) Deletar itens (FK!) e depois os pedidos movidos
    DELETE FROM ITEM_PEDIDO
    WHERE  id_pedido IN (
               SELECT id_pedido FROM PEDIDO
               WHERE  status = 'ENTREGUE'
                  AND DATEDIFF(DAY, data_pedido, GETDATE()) > 30
           );

    DELETE FROM PEDIDO
    WHERE  status = 'ENTREGUE'
       AND DATEDIFF(DAY, data_pedido, GETDATE()) > 30;

    -- 3) Atualizar estatística em FUNCIONARIOS
    --    Exemplo: contagem de pedidos processados no período,
    --    salva numa coluna auxiliar/ tabela de estatística.
    --    Ajuste os nomes de coluna conforme o modelo real usado em aula.
    IF OBJECT_ID('ESTATISTICA_FUNCIONARIOS', 'U') IS NULL
        CREATE TABLE ESTATISTICA_FUNCIONARIOS (
            id_funcionario   INT PRIMARY KEY,
            pedidos_processados INT,
            atualizado_em    DATETIME2 DEFAULT GETDATE()
        );

    MERGE ESTATISTICA_FUNCIONARIOS AS destino
    USING (
        SELECT id_funcionario, COUNT(*) AS qtd
        FROM   PEDIDOS_HISTORICO
        WHERE  arquivado_em >= CAST(GETDATE() AS DATE)
        GROUP  BY id_funcionario
    ) AS origem
    ON destino.id_funcionario = origem.id_funcionario
    WHEN MATCHED THEN
        UPDATE SET pedidos_processados = destino.pedidos_processados + origem.qtd,
                   atualizado_em = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (id_funcionario, pedidos_processados) VALUES (origem.id_funcionario, origem.qtd);

    COMMIT;
    PRINT 'Encerramento do mês concluído com sucesso!';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ERRO no encerramento: ' + ERROR_MESSAGE();
END CATCH
GO


/* ============================================================
   DESAFIO DA AULA 08 — Fechamento de Trimestre
   ============================================================ */

/* ---------- T1: Reajuste de preços por categoria ---------- */
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE p
    SET    p.preco = p.preco * 1.08
    OUTPUT DELETED.nome_produto, 'Eletrônicos' AS categoria,
           DELETED.preco AS preco_antes, INSERTED.preco AS preco_depois
    FROM   PRODUTO p
    JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
    WHERE  c.nome_categoria = 'Eletrônicos';

    UPDATE p
    SET    p.preco = p.preco * 1.05
    OUTPUT DELETED.nome_produto, 'Roupas' AS categoria,
           DELETED.preco AS preco_antes, INSERTED.preco AS preco_depois
    FROM   PRODUTO p
    JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
    WHERE  c.nome_categoria = 'Roupas';

    UPDATE p
    SET    p.preco = p.preco * 0.97
    OUTPUT DELETED.nome_produto, 'Alimentos' AS categoria,
           DELETED.preco AS preco_antes, INSERTED.preco AS preco_depois
    FROM   PRODUTO p
    JOIN   CATEGORIA c ON p.id_categoria = c.id_categoria
    WHERE  c.nome_categoria = 'Alimentos';

    COMMIT;
    PRINT 'T1: Reajustes aplicados com sucesso!';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ERRO no T1: ' + ERROR_MESSAGE();
END CATCH
GO


/* ---------- T2: Recalcular totais + marcar REVISÃO ---------- */
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE p
    SET    p.total = (
               SELECT SUM(ip.quantidade * ip.preco_unitario)
               FROM   ITEM_PEDIDO ip
               WHERE  ip.id_pedido = p.id_pedido
           )
    FROM   PEDIDO p;

    UPDATE PEDIDO
    SET    status = 'REVISÃO'
    WHERE  total IS NULL;

    COMMIT;
    PRINT 'T2: Totais recalculados; pedidos sem itens marcados como REVISÃO!';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ERRO no T2: ' + ERROR_MESSAGE();
END CATCH
GO


/* ---------- T3: Processar pendentes (aprovar ou suspender) ----------
   Cada pedido é tratado em sua PRÓPRIA transação, para que um
   ROLLBACK afete apenas aquele pedido — não os demais. */
DECLARE @id_pedido INT;

DECLARE cursor_pendentes CURSOR FOR
    SELECT id_pedido
    FROM   PEDIDO
    WHERE  status = 'PENDENTE'
       AND DATEDIFF(DAY, data_pedido, GETDATE()) > 7;

OPEN cursor_pendentes;
FETCH NEXT FROM cursor_pendentes INTO @id_pedido;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE pr
        SET    pr.estoque = pr.estoque - ip.quantidade
        FROM   PRODUTO pr
        JOIN   ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
        WHERE  ip.id_pedido = @id_pedido;

        IF EXISTS (SELECT 1 FROM PRODUTO WHERE estoque < 0)
            THROW 50003, 'Estoque insuficiente', 1;

        UPDATE PEDIDO SET status = 'APROVADO' WHERE id_pedido = @id_pedido;

        COMMIT;
        PRINT 'Pedido ' + CAST(@id_pedido AS VARCHAR) + ' aprovado.';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        UPDATE PEDIDO SET status = 'SUSPENSO' WHERE id_pedido = @id_pedido;
        PRINT 'Pedido ' + CAST(@id_pedido AS VARCHAR) + ' suspenso: ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM cursor_pendentes INTO @id_pedido;
END

CLOSE cursor_pendentes;
DEALLOCATE cursor_pendentes;
GO


/* ---------- T4: Arquivar cancelados ---------- */
IF OBJECT_ID('PEDIDOS_ARQUIVO', 'U') IS NULL
BEGIN
    SELECT *, CAST(NULL AS DATETIME2) AS data_arquivamento
    INTO   PEDIDOS_ARQUIVO
    FROM   PEDIDO
    WHERE  1 = 0;
END
GO

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO PEDIDOS_ARQUIVO
    SELECT *, GETDATE() AS data_arquivamento
    FROM   PEDIDO
    WHERE  status = 'CANCELADO';

    DELETE FROM ITEM_PEDIDO
    WHERE  id_pedido IN (SELECT id_pedido FROM PEDIDO WHERE status = 'CANCELADO');

    DELETE FROM PEDIDO
    WHERE  status = 'CANCELADO';

    COMMIT;
    PRINT 'T4: Cancelados arquivados e removidos com sucesso!';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'ERRO no T4: ' + ERROR_MESSAGE();
END CATCH
GO


/* ---------- T5 (BÔNUS): sp_fechar_trimestre ----------
   Encapsula T1 + T2 + T3 + T4 numa única transação master,
   com log de cada etapa em LOG_FECHAMENTO. */
CREATE OR ALTER PROCEDURE sp_fechar_trimestre
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('LOG_FECHAMENTO', 'U') IS NULL
        CREATE TABLE LOG_FECHAMENTO (
            id           INT IDENTITY PRIMARY KEY,
            etapa        VARCHAR(50),
            status       VARCHAR(20),
            mensagem     VARCHAR(500),
            executado_em DATETIME2 DEFAULT GETDATE()
        );

    BEGIN TRY
        BEGIN TRANSACTION trans_master;

        -- T1: Reajuste de preços
        UPDATE p SET p.preco = p.preco * 1.08
        FROM   PRODUTO p JOIN CATEGORIA c ON p.id_categoria = c.id_categoria
        WHERE  c.nome_categoria = 'Eletrônicos';

        UPDATE p SET p.preco = p.preco * 1.05
        FROM   PRODUTO p JOIN CATEGORIA c ON p.id_categoria = c.id_categoria
        WHERE  c.nome_categoria = 'Roupas';

        UPDATE p SET p.preco = p.preco * 0.97
        FROM   PRODUTO p JOIN CATEGORIA c ON p.id_categoria = c.id_categoria
        WHERE  c.nome_categoria = 'Alimentos';

        INSERT INTO LOG_FECHAMENTO (etapa, status, mensagem)
        VALUES ('T1 - Reajuste', 'OK', 'Preços atualizados por categoria');

        -- T2: Recalcular totais
        UPDATE p
        SET    p.total = (SELECT SUM(ip.quantidade * ip.preco_unitario)
                           FROM   ITEM_PEDIDO ip
                           WHERE  ip.id_pedido = p.id_pedido)
        FROM   PEDIDO p;

        UPDATE PEDIDO SET status = 'REVISÃO' WHERE total IS NULL;

        INSERT INTO LOG_FECHAMENTO (etapa, status, mensagem)
        VALUES ('T2 - Totais', 'OK', 'Totais recalculados');

        -- T3: Aprovar pendentes com estoque suficiente / suspender os demais
        UPDATE pr
        SET    pr.estoque = pr.estoque - ip.quantidade
        FROM   PRODUTO pr
        JOIN   ITEM_PEDIDO ip ON pr.id_produto = ip.id_produto
        JOIN   PEDIDO pe ON ip.id_pedido = pe.id_pedido
        WHERE  pe.status = 'PENDENTE'
           AND DATEDIFF(DAY, pe.data_pedido, GETDATE()) > 7;

        UPDATE PEDIDO
        SET    status = CASE
                             WHEN EXISTS (SELECT 1 FROM PRODUTO WHERE estoque < 0)
                             THEN 'SUSPENSO'
                             ELSE 'APROVADO'
                         END
        WHERE  status = 'PENDENTE'
           AND DATEDIFF(DAY, data_pedido, GETDATE()) > 7;

        INSERT INTO LOG_FECHAMENTO (etapa, status, mensagem)
        VALUES ('T3 - Pendentes', 'OK', 'Pedidos pendentes processados');

        -- T4: Arquivar cancelados
        IF OBJECT_ID('PEDIDOS_ARQUIVO', 'U') IS NULL
            SELECT *, CAST(NULL AS DATETIME2) AS data_arquivamento
            INTO   PEDIDO_ARQUIVO FROM PEDIDO WHERE 1 = 0;

        INSERT INTO PEDIDOS_ARQUIVO
        SELECT *, GETDATE() FROM PEDIDO WHERE status = 'CANCELADO';

        DELETE FROM ITEM_PEDIDO
        WHERE  id_pedido IN (SELECT id_pedido FROM PEDIDO WHERE status = 'CANCELADO');

        DELETE FROM PEDIDO WHERE status = 'CANCELADO';

        INSERT INTO LOG_FECHAMENTO (etapa, status, mensagem)
        VALUES ('T4 - Arquivamento', 'OK', 'Pedidos cancelados arquivados');

        COMMIT TRANSACTION trans_master;
        PRINT 'Fechamento do trimestre concluído com sucesso!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION trans_master;
        INSERT INTO LOG_FECHAMENTO (etapa, status, mensagem)
        VALUES ('ERRO GERAL', 'FALHA', ERROR_MESSAGE());
        PRINT 'ERRO no fechamento: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Para executar:
-- EXEC sp_fechar_trimestre;
-- SELECT * FROM LOG_FECHAMENTO ORDER BY executado_em DESC;