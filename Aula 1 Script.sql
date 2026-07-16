create database SISTEMA_VENDAS;
use SISTEMA_VENDAS;
create table CATEGORIAS(
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
	constraint FK_PROD_CAT foreign key (id_categoria) references CATEGORIAS(id_categoria)
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