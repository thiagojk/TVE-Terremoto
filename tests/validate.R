source('R/funcoes.R')
d<-readRDS('data/processed/terremotos.rds');m<-readRDS('data/processed/modelos.rds')
stopifnot(nrow(d)==23232,all(d$Type=='Earthquake'),!anyNA(d$timestamp),!anyDuplicated(d$ID),identical(sort(unique(d$ano)),1965:2016))
a<-read.csv('tables/maximos_anuais.csv');stopifnot(nrow(a)==52)
expected<-aggregate(Magnitude~ano,d,max);stopifnot(all(a$Magnitude==expected$Magnitude[match(a$ano,expected$ano)]))
r<-read.csv('tables/retorno_global.csv');stopifnot(all(diff(r$magnitude)>0),all(r$inferior<=r$magnitude),all(r$superior>=r$magnitude),all(is.finite(as.matrix(r[,4:6]))))
stopifnot(all.equal(as.numeric(evd::pgev(r$magnitude,loc=m$global$fit$estimate[1],scale=m$global$fit$estimate[2],shape=m$global$fit$estimate[3])),r$probabilidade,tolerance=1e-8))
# Testes de referência geográfica documentados pelo ObsPy.
fe<-fe_load();stopifnot(all(fe_number(c(12,-60),c(48,-30),fe)==c(543,133)))
pars<-read.csv('tables/gev_global.csv');stopifnot(all(pars$bootstrap_validos/pars$bootstrap_total>.9))
pot<-read.csv('tables/gpd.csv');stopifnot(all(pot$bootstrap_validos/pot$bootstrap_total>.9))
# Checagem independente do ajuste MLE com início automático do evd.
auto<-evd::fgev(a$Magnitude);stopifnot(abs(auto$deviance-m$global$fit$deviance)<1e-4)
message('Validações estatísticas e geográficas aprovadas.')
