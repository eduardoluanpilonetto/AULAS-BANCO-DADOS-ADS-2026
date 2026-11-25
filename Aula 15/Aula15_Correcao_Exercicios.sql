
USE SISTEMA_VENDAS;
GO


/* ============================================================================
   0. PREPARAÇÃO - TABELAS DE LOG E TRIGGERS
   ========================================================================== */

-- 0.1 Tabelas de log (só criam se ainda não existirem) -----------------------
IF OBJECT_ID('dbo.LOG_PRECOS', 'U') IS NULL
    CREATE TABLE LOG_PRECOS (
        id_log         INT IDENTITY(1,1) PRIMARY KEY,
        id_produto     INT           NOT NULL,
        preco_antigo   DECIMAL(10,2) NOT NULL,
        preco_novo     DECIMAL(10,2) NOT NULL,
        data_alteracao DATETIME      NOT NULL DEFAULT GETDATE()
    );
GO

IF OBJECT_ID('dbo.LOG_CLIENTES', 'U') IS NULL
    CREATE TABLE LOG_CLIENTES (
        id_log     INT IDENTITY(1,1) PRIMARY KEY,
        id_cliente INT          NOT NULL,
        nome       VARCHAR(150) NULL,
        email      VARCHAR(150) NULL,
        acao       VARCHAR(20)  NOT NULL,
        data_log   DATETIME     NOT NULL DEFAULT GETDATE()
    );
GO

IF OBJECT_ID('dbo.LOG_STATUS_PEDIDOS', 'U') IS NULL
    CREATE TABLE LOG_STATUS_PEDIDOS (
        id_log        INT IDENTITY(1,1) PRIMARY KEY,
        id_pedido     INT         NOT NULL,
        status_antigo VARCHAR(20) NULL,
        status_novo   VARCHAR(20) NULL,
        data_log      DATETIME    NOT NULL DEFAULT GETDATE()
    );
GO


-- 0.2 Trigger: histórico de preços (usado no Exercício 3 e no Bônus P5) -----
CREATE OR ALTER TRIGGER trg_produtos_log_preco
ON PRODUTO AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(preco) RETURN;          -- só continua se a coluna preco foi tocada

    INSERT INTO LOG_PRECOS (id_produto, preco_antigo, preco_novo)
    SELECT d.id_produto, d.preco, i.preco
    FROM   deleted  d
    JOIN   inserted i ON i.id_produto = d.id_produto
    WHERE  d.preco <> i.preco;            -- só registra se o valor realmente mudou
END;
GO


-- 0.3 Trigger: log de cadastro de clientes (usado no Desafio P1) -------------
CREATE OR ALTER TRIGGER trg_clientes_log
ON CLIENTE AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LOG_CLIENTES (id_cliente, nome, email, acao)
    SELECT id_cliente, nome, email, 'INSERT'
    FROM   inserted;
END;
GO


-- 0.4 Trigger: baixa e VALIDA estoque ao inserir itens -----------------------
CREATE OR ALTER TRIGGER trg_itens_pedido_estoque
ON ITEM_PEDIDO AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Soma por produto (o mesmo produto pode vir em várias linhas do mesmo INSERT)
    -- 1) valida: se algum produto não tem estoque, desfaz tudo
    IF EXISTS (
        SELECT 1
        FROM   PRODUTO p
        JOIN  (SELECT id_produto, SUM(quantidade) AS qtd
               FROM inserted GROUP BY id_produto) i
               ON i.id_produto = p.id_produto
        WHERE  p.estoque < i.qtd
    )
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50010, 'Estoque insuficiente para um ou mais itens do pedido.', 1;
    END

    -- 2) baixa o estoque (set-based: funciona para 1 ou N linhas)
    UPDATE p
    SET    p.estoque = p.estoque - i.qtd
    FROM   PRODUTO p
    JOIN  (SELECT id_produto, SUM(quantidade) AS qtd
           FROM inserted GROUP BY id_produto) i
           ON i.id_produto = p.id_produto;
END;
GO


-- 0.5 Trigger: recalcula o total do pedido ----------------------------------
CREATE OR ALTER TRIGGER trg_itens_pedido_total
ON ITEM_PEDIDO AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET    p.total = ISNULL(t.soma, 0)
    FROM   PEDIDO p
    LEFT JOIN (SELECT id_pedido, SUM(quantidade * preco_unitario) AS soma
               FROM ITEM_PEDIDO GROUP BY id_pedido) t
           ON t.id_pedido = p.id_pedido
    WHERE  p.id_pedido IN (SELECT id_pedido FROM inserted
                           UNION
                           SELECT id_pedido FROM deleted);
END;
GO


-- 0.6 Trigger: restaura estoque quando o pedido é CANCELADO -----------------
CREATE OR ALTER TRIGGER trg_pedidos_restaura_estoque
ON PEDIDO AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(status) RETURN;

    UPDATE p
    SET    p.estoque = p.estoque + x.qtd
    FROM   PRODUTO p
    JOIN  (SELECT ip.id_produto, SUM(ip.quantidade) AS qtd
           FROM   ITEM_PEDIDO ip
           JOIN   inserted i ON i.id_pedido = ip.id_pedido
           JOIN   deleted  d ON d.id_pedido = ip.id_pedido
           WHERE  i.status = 'CANCELADO'      -- agora está cancelado...
             AND  d.status <> 'CANCELADO'     -- ...e antes não estava (evita devolver 2x)
           GROUP BY ip.id_produto) x
           ON x.id_produto = p.id_produto;
END;
GO


-- 0.7 Trigger: auditoria de mudança de status -------------------------------
CREATE OR ALTER TRIGGER trg_pedidos_log_status
ON PEDIDO AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(status) RETURN;

    INSERT INTO LOG_STATUS_PEDIDOS (id_pedido, status_antigo, status_novo)
    SELECT d.id_pedido, d.status, i.status
    FROM   deleted  d
    JOIN   inserted i ON i.id_pedido = d.id_pedido
    WHERE  ISNULL(d.status, '') <> ISNULL(i.status, '');
END;
GO


/* ============================================================================
   1. EXERCÍCIOS
   ========================================================================== */

/* ----------------------------------------------------------------------------
   EXERCÍCIO 1 (Básico)
   SP que recebe @id_categoria e lista nome, preço e estoque dos produtos.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_listar_produtos_por_categoria
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT nome_produto, preco, estoque
    FROM   PRODUTO
    WHERE  id_categoria = @id_categoria
    ORDER BY nome_produto;
END;
GO

-- Testes com categorias diferentes:
EXEC usp_listar_produtos_por_categoria @id_categoria = 1;
EXEC usp_listar_produtos_por_categoria @id_categoria = 2;
EXEC usp_listar_produtos_por_categoria @id_categoria = 999;   -- inexistente: volta vazio
GO


/* ----------------------------------------------------------------------------
   EXERCÍCIO 2 (Básico)
   SP que busca clientes pelo nome (LIKE) e devolve o total via OUTPUT.
   Detalhe: @@ROWCOUNT deve ser lido LOGO após o SELECT (qualquer outro
   comando zera o valor). SET NOCOUNT ON não afeta o @@ROWCOUNT.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_buscar_cliente
    @nome              VARCHAR(150),
    @total_encontrados INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id_cliente, nome, email, cidade, estado
    FROM   CLIENTE
    WHERE  nome LIKE '%' + @nome + '%'
    ORDER BY nome;

    SET @total_encontrados = @@ROWCOUNT;   -- linhas retornadas pelo SELECT acima
END;
GO

DECLARE @qtd INT;
EXEC usp_buscar_cliente @nome = 'Silva', @total_encontrados = @qtd OUTPUT;
PRINT 'Encontrados: ' + CAST(@qtd AS VARCHAR(10));
GO


/* ----------------------------------------------------------------------------
   EXERCÍCIO 3 (Médio)
   SP que reajusta o preço de um produto e devolve o novo preço via OUTPUT.
   + TRIGGER de histórico (trg_produtos_log_preco, criado na seção 0):
     a SP NÃO grava o log; o trigger faz isso sozinho.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_atualizar_preco
    @id_produto INT,
    @percentual DECIMAL(5,2),
    @novo_preco DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação: o produto existe?
    IF NOT EXISTS (SELECT 1 FROM PRODUTO WHERE id_produto = @id_produto)
    BEGIN
        PRINT 'Produto não encontrado!';
        SET @novo_preco = -1;
        RETURN;                             -- sai da SP
    END

    UPDATE PRODUTO
    SET    preco = ROUND(preco * (1 + @percentual / 100), 2)
    WHERE  id_produto = @id_produto;        -- aqui o trigger dispara sozinho

    SELECT @novo_preco = preco
    FROM   PRODUTO
    WHERE  id_produto = @id_produto;

    PRINT 'Novo preço: R$ ' + CAST(@novo_preco AS VARCHAR(20));
END;
GO

DECLARE @preco_novo DECIMAL(10,2);
EXEC usp_atualizar_preco @id_produto = 1, @percentual = 10, @novo_preco = @preco_novo OUTPUT;
SELECT @preco_novo AS preco_atualizado;

-- O histórico foi gerado pelo trigger:
SELECT TOP 5 * FROM LOG_PRECOS ORDER BY id_log DESC;

-- Produto inexistente (deve devolver -1):
EXEC usp_atualizar_preco @id_produto = 9999, @percentual = 10, @novo_preco = @preco_novo OUTPUT;
SELECT @preco_novo AS deve_ser_menos_1;
GO


/* ----------------------------------------------------------------------------
   EXERCÍCIO 4 (Médio)
   Relatório do vendedor: nome, total de pedidos, faturamento (sem cancelados),
   ticket médio e classificação.
   Regra adotada (o enunciado só define "Top" > R$ 5.000):
       faturamento > 5000   -> 'Top'
       faturamento >= 1000  -> 'Regular'
       caso contrário       -> 'Iniciante'
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_relatorio_vendedor
    @id_funcionario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @nome          VARCHAR(150);
    DECLARE @total_pedidos INT;
    DECLARE @faturamento   DECIMAL(12,2);
    DECLARE @ticket_medio  DECIMAL(12,2);
    DECLARE @classificacao VARCHAR(20);

    SELECT @nome = nome
    FROM   FUNCIONARIO
    WHERE  id_funcionario = @id_funcionario;

    IF @nome IS NULL
    BEGIN
        PRINT 'Funcionário não encontrado.';
        RETURN;
    END

    SELECT @total_pedidos = COUNT(*),
           @faturamento   = ISNULL(SUM(total), 0),
           @ticket_medio  = ISNULL(AVG(total), 0)
    FROM   PEDIDO
    WHERE  id_funcionario = @id_funcionario
      AND  status <> 'CANCELADO';

    IF @faturamento > 5000
        SET @classificacao = 'Top';
    ELSE IF @faturamento >= 1000
        SET @classificacao = 'Regular';
    ELSE
        SET @classificacao = 'Iniciante';

    SELECT @nome          AS vendedor,
           @total_pedidos AS total_pedidos,
           @faturamento   AS faturamento,
           @ticket_medio  AS ticket_medio,
           @classificacao AS classificacao;
END;
GO

EXEC usp_relatorio_vendedor @id_funcionario = 1;
EXEC usp_relatorio_vendedor @id_funcionario = 2;
EXEC usp_relatorio_vendedor @id_funcionario = 9999;   -- inexistente
GO


/* ----------------------------------------------------------------------------
   EXERCÍCIO 5 (Avançado)
   Venda com 2 produtos (SP + triggers).
   A SP: valida produtos e estoque, abre transação, cria pedido + itens,
         devolve o id via OUTPUT.
   Os TRIGGERS (seção 0): baixam o estoque e recalculam o total.
   Por isso a SP NÃO faz UPDATE de estoque nem calcula o total.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_processar_venda_completa
    @id_cliente     INT,
    @id_funcionario INT,
    @produto1       INT,
    @qtd1           INT,
    @produto2       INT,
    @qtd2           INT,
    @id_pedido_out  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @id_pedido_out = NULL;

    DECLARE @preco1   DECIMAL(10,2), @estoque1 INT;
    DECLARE @preco2   DECIMAL(10,2), @estoque2 INT;

    BEGIN TRY
        -- 1) Validações (antes de abrir a transação)
        IF @qtd1 <= 0 OR @qtd2 <= 0
            THROW 50001, 'Quantidade deve ser maior que zero.', 1;

        SELECT @preco1 = preco, @estoque1 = estoque FROM PRODUTO WHERE id_produto = @produto1;
        SELECT @preco2 = preco, @estoque2 = estoque FROM PRODUTO WHERE id_produto = @produto2;

        IF @preco1 IS NULL OR @preco2 IS NULL
            THROW 50002, 'Produto não encontrado.', 1;

        -- Se for o mesmo produto nos dois parâmetros, soma as quantidades
        IF @produto1 = @produto2 AND @estoque1 < (@qtd1 + @qtd2)
            THROW 50003, 'Estoque insuficiente.', 1;

        IF @estoque1 < @qtd1 OR @estoque2 < @qtd2
            THROW 50003, 'Estoque insuficiente.', 1;

        -- 2) Transação
        BEGIN TRANSACTION;

        INSERT INTO PEDIDO (id_cliente, id_funcionario, status, total)
        VALUES (@id_cliente, @id_funcionario, 'APROVADO', 0);   -- total: o trigger recalcula

        SET @id_pedido_out = SCOPE_IDENTITY();                  -- nunca @@IDENTITY

        INSERT INTO ITEM_PEDIDO (id_pedido, id_produto, quantidade, preco_unitario)
        VALUES (@id_pedido_out, @produto1, @qtd1, @preco1),
               (@id_pedido_out, @produto2, @qtd2, @preco2);     -- dispara estoque + total

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @id_pedido_out = -1;
        THROW;                               -- relança o erro para a aplicação
    END CATCH;
END;
GO

-- Teste 1: venda válida
DECLARE @id INT;
EXEC usp_processar_venda_completa
     @id_cliente = 1, @id_funcionario = 1,
     @produto1 = 1, @qtd1 = 1,
     @produto2 = 2, @qtd2 = 2,
     @id_pedido_out = @id OUTPUT;
SELECT @id AS pedido_criado;
SELECT * FROM PEDIDO   WHERE id_pedido = @id;   -- total calculado pelo trigger
SELECT * FROM ITEM_PEDIDO WHERE id_pedido = @id;
SELECT id_produto, estoque FROM PRODUTO WHERE id_produto IN (1, 2);   -- estoque baixou
GO

-- Teste 2: estoque insuficiente (deve falhar e não criar nada)
BEGIN TRY
    DECLARE @id2 INT;
    EXEC usp_processar_venda_completa
         @id_cliente = 1, @id_funcionario = 1,
         @produto1 = 1, @qtd1 = 999999,
         @produto2 = 2, @qtd2 = 1,
         @id_pedido_out = @id2 OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'ERRO: ' + ERROR_MESSAGE();
END CATCH;
GO


/* ============================================================================
   2. DESAFIO - "API DO BANCO" DO SISTEMA_VENDAS
   As aplicações chamam apenas estas SPs, nunca as tabelas diretamente.
   ========================================================================== */

/* ----------------------------------------------------------------------------
   P1 - usp_cadastrar_cliente
   Valida e-mail único (IF EXISTS), insere e devolve o id via OUTPUT.
   O log vem do trigger trg_clientes_log (seção 0).
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_cadastrar_cliente
    @nome       VARCHAR(150),
    @email      VARCHAR(150),
    @cidade     VARCHAR(100),
    @estado     CHAR(2),
    @id_cliente_out INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @id_cliente_out = NULL;

    BEGIN TRY
        IF @nome IS NULL OR LTRIM(RTRIM(@nome)) = ''
            THROW 50101, 'Nome é obrigatório.', 1;

        IF @email IS NULL OR @email NOT LIKE '%_@_%._%'
            THROW 50102, 'E-mail inválido.', 1;

        IF EXISTS (SELECT 1 FROM CLIENTE WHERE email = @email)
            THROW 50103, 'E-mail já cadastrado.', 1;

        BEGIN TRANSACTION;

        INSERT INTO CLIENTE (nome, email, cidade, estado)
        VALUES (@nome, @email, @cidade, @estado);   -- data_cadastro: DEFAULT da tabela

        SET @id_cliente_out = SCOPE_IDENTITY();

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @id_cliente_out = -1;
        PRINT 'ERRO: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

DECLARE @novo INT;
EXEC usp_cadastrar_cliente
     @nome = 'Maria Teste', @email = 'maria.teste@email.com',
     @cidade = 'Concórdia', @estado = 'SC',
     @id_cliente_out = @novo OUTPUT;
SELECT @novo AS id_gerado;

-- Repetindo o mesmo e-mail: deve devolver -1
EXEC usp_cadastrar_cliente
     @nome = 'Maria Teste', @email = 'maria.teste@email.com',
     @cidade = 'Concórdia', @estado = 'SC',
     @id_cliente_out = @novo OUTPUT;
SELECT @novo AS deve_ser_menos_1;

SELECT TOP 5 * FROM LOG_CLIENTES ORDER BY id_log DESC;   -- log criado pelo trigger
GO


/* ----------------------------------------------------------------------------
   P2 - usp_registrar_pedido
   Até 3 produtos (os parâmetros 2 e 3 são opcionais: NULL = não usado).
   Valida cada produto/estoque, cria pedido + itens em transação e devolve
   id_pedido e total. Estoque e total ficam por conta dos triggers.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_registrar_pedido
    @id_cliente     INT,
    @id_funcionario INT,
    @prod1 INT,        @qtd1 INT,
    @prod2 INT = NULL, @qtd2 INT = NULL,
    @prod3 INT = NULL, @qtd3 INT = NULL,
    @id_pedido_out  INT           OUTPUT,
    @total_out      DECIMAL(12,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @id_pedido_out = NULL;
    SET @total_out     = NULL;

    -- Junta os parâmetros numa tabela, ignorando os que vieram NULL.
    -- GROUP BY soma quantidades caso o mesmo produto seja repetido.
    DECLARE @itens TABLE (id_produto INT PRIMARY KEY, qtd INT NOT NULL);

    BEGIN TRY
        INSERT INTO @itens (id_produto, qtd)
        SELECT id_produto, SUM(qtd)
        FROM  (SELECT @prod1 AS id_produto, @qtd1 AS qtd
               UNION ALL SELECT @prod2, @qtd2
               UNION ALL SELECT @prod3, @qtd3) t
        WHERE  id_produto IS NOT NULL
        GROUP BY id_produto;

        -- Validações
        IF NOT EXISTS (SELECT 1 FROM CLIENTE WHERE id_cliente = @id_cliente)
            THROW 50201, 'Cliente não encontrado.', 1;

        IF NOT EXISTS (SELECT 1 FROM FUNCIONARIO WHERE id_funcionario = @id_funcionario)
            THROW 50202, 'Funcionário não encontrado.', 1;

        IF EXISTS (SELECT 1 FROM @itens WHERE qtd IS NULL OR qtd <= 0)
            THROW 50203, 'Quantidade inválida (deve ser maior que zero).', 1;

        IF EXISTS (SELECT 1 FROM @itens i
                   LEFT JOIN PRODUTO p ON p.id_produto = i.id_produto
                   WHERE p.id_produto IS NULL)
            THROW 50204, 'Algum produto não foi encontrado.', 1;

        IF EXISTS (SELECT 1 FROM @itens i
                   JOIN PRODUTO p ON p.id_produto = i.id_produto
                   WHERE p.estoque < i.qtd)
            THROW 50205, 'Estoque insuficiente para algum produto.', 1;

        -- Transação
        BEGIN TRANSACTION;

        INSERT INTO PEDIDO (id_cliente, id_funcionario, status, total)
        VALUES (@id_cliente, @id_funcionario, 'PENDENTE', 0);

        SET @id_pedido_out = SCOPE_IDENTITY();

        INSERT INTO ITEM_PEDIDO (id_pedido, id_produto, quantidade, preco_unitario)
        SELECT @id_pedido_out, i.id_produto, i.qtd, p.preco
        FROM   @itens i
        JOIN   PRODUTO p ON p.id_produto = i.id_produto;   -- 1 INSERT = triggers 1x

        COMMIT;

        -- O total foi recalculado pelo trigger
        SELECT @total_out = total FROM PEDIDO WHERE id_pedido = @id_pedido_out;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @id_pedido_out = -1;
        SET @total_out     = 0;
        THROW;
    END CATCH;
END;
GO

DECLARE @ped INT, @tot DECIMAL(12,2);
EXEC usp_registrar_pedido
     @id_cliente = 1, @id_funcionario = 1,
     @prod1 = 1, @qtd1 = 1,
     @prod2 = 2, @qtd2 = 1,
     @prod3 = 3, @qtd3 = 2,
     @id_pedido_out = @ped OUTPUT, @total_out = @tot OUTPUT;
SELECT @ped AS id_pedido, @tot AS total;

-- Só 1 produto (os demais usam o padrão NULL):
EXEC usp_registrar_pedido
     @id_cliente = 1, @id_funcionario = 1,
     @prod1 = 1, @qtd1 = 1,
     @id_pedido_out = @ped OUTPUT, @total_out = @tot OUTPUT;
SELECT @ped AS id_pedido, @tot AS total;
GO


/* ----------------------------------------------------------------------------
   P3 - usp_cancelar_pedido
   Valida (existe? não está ENTREGUE? já cancelado?) e só atualiza o status.
   Quem RESTAURA O ESTOQUE é o trigger trg_pedidos_restaura_estoque.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_cancelar_pedido
    @id_pedido INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status_atual VARCHAR(20);

    BEGIN TRY
        SELECT @status_atual = status FROM PEDIDO WHERE id_pedido = @id_pedido;

        IF @status_atual IS NULL
            THROW 50301, 'Pedido não encontrado.', 1;

        IF @status_atual = 'ENTREGUE'
            THROW 50302, 'Pedido já entregue: não pode ser cancelado.', 1;

        IF @status_atual = 'CANCELADO'
            THROW 50303, 'Pedido já está cancelado.', 1;

        BEGIN TRANSACTION;

        UPDATE PEDIDO
        SET    status = 'CANCELADO'
        WHERE  id_pedido = @id_pedido;      -- trigger devolve o estoque + grava log

        COMMIT;

        PRINT 'Pedido #' + CAST(@id_pedido AS VARCHAR(10)) + ' cancelado. Estoque restaurado.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'ERRO: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- Teste (use um id de pedido PENDENTE/APROVADO que exista):
-- SELECT id_produto, estoque FROM PRODUTOS WHERE id_produto IN (1,2,3);   -- antes
EXEC usp_cancelar_pedido @id_pedido = 1;
-- SELECT id_produto, estoque FROM PRODUTOS WHERE id_produto IN (1,2,3);   -- depois
EXEC usp_cancelar_pedido @id_pedido = 1;      -- 2ª vez: "já está cancelado"
EXEC usp_cancelar_pedido @id_pedido = 9999;   -- inexistente
SELECT TOP 5 * FROM LOG_STATUS_PEDIDOS ORDER BY id_log DESC;
GO


/* ----------------------------------------------------------------------------
   P4 - usp_dashboard_executivo
   Sem parâmetros. Devolve 3 conjuntos de resultados:
     (1) KPIs gerais  (2) Top 3 produtos vendidos  (3) Faturamento por mês
   Cancelados ficam de fora dos cálculos.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_dashboard_executivo
AS
BEGIN
    SET NOCOUNT ON;

    -- (1) KPIs gerais
    SELECT COUNT(*)                          AS total_pedidos,
           ISNULL(SUM(total), 0)             AS faturamento,
           ISNULL(AVG(total), 0)             AS ticket_medio,
           COUNT(DISTINCT id_cliente)        AS clientes_ativos
    FROM   PEDIDO
    WHERE  status <> 'CANCELADO';

    -- (2) Top 3 produtos mais vendidos (por quantidade)
    SELECT TOP 3
           pr.nome_produto                   AS produto,
           SUM(ip.quantidade)                AS qtd_vendida,
           SUM(ip.quantidade * ip.preco_unitario) AS receita
    FROM   ITEM_PEDIDO ip
    JOIN   PEDIDO  pe ON pe.id_pedido  = ip.id_pedido
    JOIN   PRODUTO pr ON pr.id_produto = ip.id_produto
    WHERE  pe.status <> 'CANCELADO'
    GROUP BY pr.nome_produto
    ORDER BY qtd_vendida DESC;

    -- (3) Faturamento por mês
    SELECT YEAR(data_pedido)                 AS ano,
           MONTH(data_pedido)                AS mes,
           COUNT(*)                          AS pedidos,
           SUM(total)                        AS faturamento
    FROM   PEDIDO
    WHERE  status <> 'CANCELADO'
    GROUP BY YEAR(data_pedido), MONTH(data_pedido)
    ORDER BY ano, mes;
END;
GO

EXEC usp_dashboard_executivo;
GO


/* ----------------------------------------------------------------------------
   P5 (BÔNUS) - usp_reajuste_categoria
   Reajusta TODOS os produtos de uma categoria com UM único UPDATE (set-based,
   preferível ao WHILE). A cláusula OUTPUT ... INTO captura o que mudou e monta
   o log devolvido nos parâmetros de saída.
   Obs.: como PRODUTOS tem trigger, o OUTPUT precisa ser "OUTPUT ... INTO tabela"
   (OUTPUT solto para o cliente não é permitido em tabela com trigger).
   O histórico em LOG_PRECOS é gravado automaticamente pelo trigger.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE usp_reajuste_categoria
    @id_categoria   INT,
    @percentual     DECIMAL(5,2),
    @qtd_reajustados INT           OUTPUT,
    @log_out        VARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @qtd_reajustados = 0;

    DECLARE @alterados TABLE (
        id_produto   INT,
        preco_antigo DECIMAL(10,2),
        preco_novo   DECIMAL(10,2)
    );

    BEGIN TRY
        IF @percentual IS NULL OR @percentual <= -100
            THROW 50501, 'Percentual inválido.', 1;

        IF NOT EXISTS (SELECT 1 FROM PRODUTO WHERE id_categoria = @id_categoria)
            THROW 50502, 'Categoria sem produtos (ou inexistente).', 1;

        BEGIN TRANSACTION;

        UPDATE PRODUTO
        SET    preco = ROUND(preco * (1 + @percentual / 100), 2)
        OUTPUT inserted.id_produto, deleted.preco, inserted.preco
        INTO   @alterados (id_produto, preco_antigo, preco_novo)
        WHERE  id_categoria = @id_categoria;

        SET @qtd_reajustados = @@ROWCOUNT;

        COMMIT;

        SET @log_out = 'Categoria ' + CAST(@id_categoria AS VARCHAR(10))
                     + ': ' + CAST(@qtd_reajustados AS VARCHAR(10))
                     + ' produto(s) reajustado(s) em '
                     + CAST(@percentual AS VARCHAR(10)) + '%.';

        -- Detalhe do que mudou (resultado para a aplicação)
        SELECT a.id_produto, p.nome_produto, a.preco_antigo, a.preco_novo
        FROM   @alterados a
        JOIN   PRODUTO p ON p.id_produto = a.id_produto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @qtd_reajustados = -1;
        SET @log_out = 'ERRO: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

DECLARE @qtd INT, @log VARCHAR(500);
EXEC usp_reajuste_categoria
     @id_categoria = 1, @percentual = 5,
     @qtd_reajustados = @qtd OUTPUT, @log_out = @log OUTPUT;
PRINT @log;
SELECT TOP 10 * FROM LOG_PRECOS ORDER BY id_log DESC;   -- um registro por produto
GO


/* ============================================================================
   CONFERÊNCIA FINAL
   ========================================================================== */
SELECT name, type_desc, modify_date FROM sys.procedures ORDER BY name;
SELECT name, parent_class_desc, is_disabled FROM sys.triggers ORDER BY name;
GO
