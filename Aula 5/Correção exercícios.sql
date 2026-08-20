select 
  nome_produto, 
  preco, 
  estoque 
from 
  PRODUTO 
where 
  preco BETWEEN 50 
  AND 500 
order by 
  preco asc;
select 
  top 3 p.id_pedido, 
  p.id_cliente, 
  p.status, 
  p.total 
from 
  pedido p 
where 
  status != upper('Cancelado') 
order by 
  p.total desc;
SELECT 
  nome AS [Nome Cliente], 
  email AS [E-mail] 
FROM 
  CLIENTE 
WHERE 
  estado IN ('SP', 'RJ') 
  and email is not null 
select 
  nome_produto as 'Produto', 
  preco as 'Preço', 
  preco * 0.92 as 'Preço c/ 8% de desconto', 
  preco * 1.15 as 'Preco c/ 15% de acréscimo', 
  case when preco between 100 
  and 500 then 'Médio' when preco > 500 then 'Caro' else 'Barato' end as 'Veredito' 
from 
  PRODUTO 
select 
  nome_produto, 
  preco 
from 
  produto 
order by 
  preco desc offset 0 rows fetch next 3 rows only;
select 
  nome_produto, 
  preco 
from 
  produto 
order by 
  preco desc offset 3 rows fetch next 3 rows only;
select 
  top 6 nome_produto, 
  preco 
from 
  produto 
order by 
  preco desc;
