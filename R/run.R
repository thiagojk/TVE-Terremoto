options(warn=1)
set.seed(20261029)
for(p in c('evd','jsonlite','sp')) if(!requireNamespace(p,quietly=TRUE))stop('Dependência ausente: ',p)
for(p in c('data/processed','tables','figures'))dir.create(p,recursive=TRUE,showWarnings=FALSE)
# Produtos destes diretórios pertencem ao pipeline; limpar evita publicar análises removidas.
for(p in c('tables','figures')) unlink(list.files(p,pattern='\\.(csv|txt|png)$',full.names=TRUE))
source('R/funcoes.R')
for(s in c('01_importacao','02_descritiva','03_blocos_gev','04_regional','06_mapas')){
 message('Executando ',s);source(paste0('R/',s,'.R'))
}

writeLines(capture.output(sessionInfo()),'tables/sessionInfo.txt')
saveRDS(list(global=global,regional=regional,blocks=models,region_names=region_names),'data/processed/modelos.rds')
