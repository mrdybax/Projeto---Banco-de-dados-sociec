--consulta com projeção e seleção: escolher o nome das cidades cuja UF é PR
SELECT 
	cod_municipio
FROM
	municipios
WHERE
	uf = 'PR';
	

--junção externa: escolher todos municipios e seus respectivos PIBs estaticos (de 2018), 
--inclui municipios que nao tem pib (observaçoes nula)

SELECT
	cod_municipio,
	pib
FROM
	municipios m 
LEFT JOIN
	indicadores_estaticos ie
	ON m.cod_municipio = ie.codigo_municipio;

--operaçao de conjunto: seleciona cidades cujo PIB é maior que 1000000 e une às cidades com mais de 20.000 habitantes

SELECT 
	cod_municipio
FROM
	indicadores_estaticos
WHERE
	pib > 1000000

UNION

SELECT
	cod_municipio
FROM
	indicadores_estaticos
WHERE	
	populacao > 20000;
	
	
--operaçao em group by: agrupar cidades por estado e tirar media de mortalidade infantil dos estados ao longo do ano
SELECT
	uf, 
	ano,
	AVG(txmoinf)
FROM
	municipios
LEFT JOIN
	indicadores
	USING (cod_municipio)
GROUP BY uf, ano;
	
--divisão relacional: escolher todas cidades que tiveram observaçoes em todos os anos
SELECT
	nome_municipio
FROM
	municipios
WHERE NOT EXISTS
  ((SELECT DISTINCT ano FROM indicadores)
   EXCEPT
   (SELECT ano
   FROM indicadores
   WHERE indicadores.cod_municipio = municipios.cod_municipio ))
