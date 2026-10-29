options(warn=1)
set.seed(20261029)
for(p in c('evd','jsonlite')) if(!requireNamespace(p,quietly=TRUE))stop('Dependência ausente: ',p)
for(p in c('data/processed','tables','figures'))dir.create(p,recursive=TRUE,showWarnings=FALSE)
source('R/funcoes.R')
for(s in c('01_importacao','02_descritiva','03_blocos_gev','04_regional','05_pot','06_mapas','07_sensibilidade')){
 message('Executando ',s);source(paste0('R/',s,'.R'))
}
