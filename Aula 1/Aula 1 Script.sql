create database SISTEMA_VENDAS;
use SISTEMA_VENDAS;
create table CATEGORIA(
	id_categoria int identity(1,1) not null,
	nome_categoria varchar(100) not null,
	descricao varchar(100) null,
	ativo bit not null default 1,
	constraint PK_CATEGORIA primary key (id_categoria)
)
create table CLIENTE(
	id_cliente int identity(1,1) not null,
	nome varchar(150) not null,
	email varchar(200) null,
	telefone char(11) null,
	cidade varchar(100) null,
	estado char(2) null,
	data_cadastro datetime2 not null default getdate(),
	constraint PK_CLIENTE primary key (id_cliente)
)
create table PRODUTO(
	id_produto int identity(1,1) not null,
	nome_produto varchar(200) not null,
	descricao varchar(500) null,
	preco decimal(10,2) not null,
	estoque int not null default 0,
	id_categoria int not null,
	constraint PK_PRODUTO primary key (id_produto),
	constraint FK_PROD_CAT foreign key (id_categoria) references CATEGORIA(id_categoria)
)
create table FUNCIONARIO(
	id_funcionario int identity(1,1) not null,
	nome varchar(150) not null,
	cargo varchar(100) null,
	salario decimal(10,2) not null,
	data_admissao date not null default getdate(),
	ativo bit not null default 1,
	constraint PK_FUNCIONARIO primary key (id_funcionario)
)
create table PEDIDO(
	id_pedido int identity(1,1) not null,
	id_cliente int not null,
	id_funcionario int not null,
	data_pedido datetime2 not null default getdate(),
	status varchar(20) not null default 'PENDENTE',
	total decimal(12,2) null,
	constraint PK_PEDIDO primary key (id_pedido),
	constraint FK_PED_CLI foreign key (id_cliente) references CLIENTE(id_cliente),
	constraint FK_PED_FUNCIONARIO foreign key (id_funcionario) references FUNCIONARIO(id_funcionario)
)

create table ITEM_PEDIDO(
	id_item int identity(1,1) not null,
	id_pedido int not null,
	id_produto int not null,
	quantidade int not null default 1,
	preco_unitario decimal(10,2) not null,
	constraint FK_ITEM_P1 foreign key (id_pedido) references PEDIDO(id_pedido),
	constraint FK_ITEM_P2 foreign key (id_produto) references PRODUTO(id_produto)
)

-- 1. Listar todas as tabelas do banco
SELECT 
	TABLE_NAME, 
	TABLE_TYPE
FROM   
	INFORMATION_SCHEMA.TABLES
WHERE  
	TABLE_TYPE = 'BASE TABLE'
ORDER  BY 
	TABLE_NAME;

-- 2. Ver colunas de uma tabela específica
SELECT 
	COLUMN_NAME, 
	DATA_TYPE, 
	IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH, 
	COLUMN_DEFAULT
FROM   
INFORMATION_SCHEMA.COLUMNS
WHERE  
	TABLE_NAME = 'CLIENTE'
ORDER  BY 
	ORDINAL_POSITION;
	
-- 3. Ver constraints (PKs e FKs) definidas
SELECT 
	tc.CONSTRAINT_NAME,
	tc.CONSTRAINT_TYPE,
    tc.TABLE_NAME, 
	kcu.COLUMN_NAME
FROM   
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
	JOIN   INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
       ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
ORDER  BY
	tc.TABLE_NAME, tc.CONSTRAINT_TYPE;