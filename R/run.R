options(warn=1)
set.seed(20261029)
for(p in c('evd','jsonlite','sp','fBasics','stabledist')) if(!requireNamespace(p,quietly=TRUE))stop('Dependência ausente: ',p)
for(p in c('data/processed','tables','figures'))dir.create(p,recursive=TRUE,showWarnings=FALSE)
# Produtos destes diretórios pertencem ao pipeline; limpar evita publicar análises removidas.
for(p in c('tables','figures')) unlink(list.files(p,pattern='\\.(csv|txt|png)$',full.names=TRUE))
source('R/funcoes.R')
for(s in c('01_importacao','02_descritiva','03_blocos_gev','04_regional','05_estavel','06_mapas','07_sensibilidade')){
 message('Executando ',s);source(paste0('R/',s,'.R'))
}
