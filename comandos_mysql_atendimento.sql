select * from users.associados where nome like '%clebio%';

select * from users.associados where cpf like '%33092723899%';

select * from users.associados where telefone like '%9839%';

-- id joao pedro = 3599 / id carlos = 3923 / id téo = 4174 / id aquiles = 3156

insert into users.transacoes_mk (valor, tipo, id_cliente) values (183, 'credito', 3923);

select
  montadoras.nome montadora,
  senhas.chassis chassi,
  consultas.data data
    from registros.consultas_senhas_helpkey consultas
    inner join senhas.chassis senhas on consultas.id_senha = senhas.id
    inner join senhas.montadoras montadoras on senhas.id_montadora = montadoras.id
      where consultas.cobrada is true;

select * from users.transacoes_mk;

select * from senhas.chassis where chassis like '%KNA%';

select
  clientes.nome as cliente,
  transacoes.valor as valor_em_mk,
  senhas.chassis as chassi,
  transacoes.data
    from users.transacoes_mk as transacoes
    inner join users.associados as clientes on transacoes.id_cliente = clientes.id
    inner join senhas.chassis as senhas on transacoes.id_senha = senhas.id
      where clientes.id > 1
      and transacoes.tipo = 'debito'
      and senhas.id_montadora = 2;
      select sum(case when tipo = 'credito' then valor when tipo = 'debito' then -valor end) total from (select * from users.transacoes_mk where
	id_cliente = 3923
    
) todas;