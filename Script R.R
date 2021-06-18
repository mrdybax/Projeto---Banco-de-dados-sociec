library(RPostgres)
library(tidyverse)
library(dplyr)
library(readxl)
library(scales)

df_Estados <- read_excel ("C:/Program Files/RStudio/excel/Estados.xlsx",1)
df_Municipios <- read_excel ("C:/Program Files/RStudio/excel/Municipios.xlsx",1)
df_Indicadores <- read_excel ("C:/Program Files/RStudio/excel/Indicadores.xlsx",1)
df_Indicadores_Estaticos <- read_excel ("C:/Program Files/RStudio/excel/Indicadores_Estaticos.xlsx",1)
df_Legenda_indicadores <- read_excel ("C:/Program Files/RStudio/excel/legenda_indicadores.xlsx",1)

con <- dbConnect(Postgres(),
                  user = "postgres",
                  password = "xxxxxx",
                  host = "localhost",
                  port = 5432,
                  dbname = "postgres")

dbWriteTable(con, "estados", df_Estados, append = FALSE, overwrite=TRUE)
bWriteTable(con, "municipios", df_Municipios, append = FALSE, overwrite=TRUE )
dbWriteTable(con, "indicadores", df_Indicadores, append = FALSE, overwrite=TRUE )
dbWriteTable(con, "indicadores_estaticos", df_Indicadores_Estaticos, append = FALSE, overwrite=TRUE )
dbWriteTable(con, "legenda_indicadores", df_Legenda_indicadores, append = FALSE, overwrite=TRUE )


consulta <- as_tibble(dbGetQuery(con, 
                                 'SELECT "Cod_Municipio"  
                                 FROM municipios 
                                 WHERE CAST("UF" AS INTEGER) = 41 '))

junção <- as_tibble(dbGetQuery(con, 
                              'SELECT m."Nome_Municipio", "PIB"
                              FROM municipios m 
                              LEFT JOIN indicadores_estaticos ie ON 
                             CAST(m."Cod_Municipio" AS INTEGER) = ie."Codigo_Municipio"'))

união <- as_tibble(dbGetQuery(con,
                              'SELECT "Codigo_Municipio"
                              FROM indicadores_estaticos
                              WHERE "PIB" > 1000000
                              
                              UNION
                              
                              SELECT "Codigo_Municipio" 
                              FROM indicadores_estaticos
                              WHERE "POPULACAO" > 20000;'))


group <- as_tibble(dbGetQuery(con,
                              'SELECT
                              e."NOME_UF", "Ano", AVG("TXMOINF")
                              FROM
                              municipios m
                              LEFT JOIN estados e ON e."UF" = CAST(M."UF" AS INTEGER)
                              LEFT JOIN indicadores i
                              ON CAST(m."Cod_Municipio" AS INTEGER) = i."Cod_Municipio"
                              GROUP BY e."NOME_UF", "Ano"'))

relacional <- as_tibble(dbGetQuery(con,
                              'SELECT
                              	"Nome_Municipio"
                              FROM
                              	municipios
                              WHERE NOT EXISTS
                                ((SELECT DISTINCT "Ano" FROM indicadores)
                                 EXCEPT
                                 (SELECT "Ano"
                                 FROM indicadores
                                 WHERE indicadores."Cod_Municipio" = CAST(municipios."Cod_Municipio" AS INTEGER)))'))



  df0_5 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 0, 5000)) %>% summarise (contagem = n_distinct(Codigo_Municipio))
  df5_10 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 5000, 10000)) %>% summarise (contagem = n_distinct(Codigo_Municipio))
  df10_50 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 10000, 50000)) %>% summarise (contagem = n_distinct(Codigo_Municipio))
  df50_100 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 50000, 100000)) %>% summarise ( contagem = n_distinct(Codigo_Municipio))
  df100_1000 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 100000, 1000000)) %>% summarise (contagem = n_distinct(Codigo_Municipio))
  df1000_1500 <-filter(df_Indicadores_Estaticos, between(as.integer(POPULACAO), 1000000, 15000000)) %>% summarise( contagem = n_distinct(Codigo_Municipio))
  pop <- c("0-5", "5-10", "10-50", "50-100", "100- 1000", "1000-15000")
  
  p_df <- data.frame(pop)
  data <- rbind.data.frame (df0_5,df5_10, df10_50, df50_100, df100_1000, df1000_1500)
  data <- cbind.data.frame (data, p_df )
  
  
  graficobar <- ggplot(data = data) +
    geom_bar(stat = "identity",position = position_dodge(), mapping = aes(x = factor(pop, level = c("0-5", "5-10", "10-50", "50-100", "100- 1000", "1000-15000")), y = contagem, fill = contagem)) + 
    labs(x = "Intervalo de população", y = "Quantidade") +
    theme_bw() +
    ggtitle("Quantidade de municipios por intervalo de população, por mil")
  graficobar
  
  df_linha <-filter(df_Indicadores_Estaticos, between(as.integer(PIB), 10439694, 91957092))
  
  graficolinha <- ggplot(data = df_linha) + 
    geom_line(mapping = aes(x = POPULACAO, y = PIB, colour = PIB)) +
    geom_point(mapping = aes(x = POPULACAO, y = PIB, colour = PIB, ), size = 3) +
    geom_smooth(mapping = aes(x = POPULACAO, y = PIB ),method = "lm")
    scale_y_continuous(n.breaks = 10, labels = comma) +
    scale_x_continuous(n.breaks = 10, labels = comma) +
    labs(x = "Populacao", y = "PIB") +
    theme_bw() +
    ggtitle("Relação entre PIB e População das 100 maiores cidades do Brasil*")
  #(Excluindo São Paulo, Rio de Janeiro e Brasilia)"  
  graficolinha
  
  graficopoint <- ggplot(data = df_Indicadores) + 
    geom_point(mapping = aes(x = TXMOHOMI, y = TXMOSUI, colour = TXMOSUI, ), size = 3) +
    scale_y_continuous(n.breaks = 10, labels = comma) +
    scale_x_continuous(n.breaks = 10, labels = comma) +
    labs(x = "Taxa de Homicidio", y = "Taxa de Suicidio") +
    theme_bw() +
    ggtitle("Relação entre Taxa de Homicidio e Taxa de Suicidio no Brasil")
  graficopoint
  
  df_Indicadores
  
  groupplot <- ggplot(group) + geom_col(mapping=(aes(x=NOME_UF, y=avg, fill=NOME_UF)))
  
  