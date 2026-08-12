--EXERCÍCIO 1
select
*
from
CLIENTE
WHERE
estado in ('SP', 'RJ', 'MG')

select
*
from
CLIENTE
WHERE
estado = 'SP' or
estado = 'RJ' or 
estado = 'MG'

--EXERCÍCIO 2
select
nome,
'cliente' as tipo,
cidade
from
CLIENTE
union 
select
nome,
'funcionario' as tipo,
null cidade
from
FUNCIONARIO

--EXERCÍCIO 3
select 
id_cliente, 
nome 
from
CLIENTE
except
select 
C.id_cliente, 
C.nome 
from 
PEDIDO as P
join CLIENTE as C on C.id_cliente = P.id_cliente

select
C.id_cliente, 
C.nome 
from
CLIENTE as C
where
not exists (
	select
	p.id_pedido
	from
	PEDIDO P 
	where
	P.id_cliente = C.id_cliente
)

--EXERCÍCIO 4
select
C.id_categoria,
C.nome_categoria
from
PRODUTO P
join CATEGORIA C on C.id_categoria = P.id_categoria
INTERSECT
select 
C.id_categoria,
C.nome_categoria
from
PRODUTO P
join CATEGORIA C on C.id_categoria = P.id_categoria
join ITEM_PEDIDO IP on IP.id_produto = P.id_produto

--EXERCÍCIO 5
select
C.id_cliente as id,
'Cliente' as Tipo,
C.nome as nomezinho,
C.data_cadastro as datacadastro
from
CLIENTE C
union all
select
F.id_funcionario as id,
'Funcionário' as Tipo,
F.nome as nomezinho,
F.data_admissao as datacadastro
from
FUNCIONARIO as F
order by datacadastro asc