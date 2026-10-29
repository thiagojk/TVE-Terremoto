source('R/funcoes.R')
d <- readRDS('data/processed/terremotos.rds'); m <- readRDS('data/processed/modelos.rds')
stopifnot(nrow(d)==23232,all(d$Type=='Earthquake'),!anyNA(d$timestamp),
          !anyDuplicated(d$ID),identical(sort(unique(d$ano)),1965:2016))
a <- read.csv('tables/maximos_anuais.csv');stopifnot(nrow(a)==52)
expected <- aggregate(Magnitude~ano,d,max)
stopifnot(all(a$Magnitude==expected$Magnitude[match(a$ano,expected$ano)]))
r <- read.csv('tables/retorno_global.csv')
stopifnot(identical(r$T,c(2L,5L,10L,20L,50L,100L)),all(diff(r$magnitude)>0),
          all(r$inferior<=r$magnitude),all(r$superior>=r$magnitude),
          all(is.finite(as.matrix(r[,4:6]))))
stopifnot(all.equal(as.numeric(evd::pgev(r$magnitude,loc=m$global$fit$estimate[1],
  scale=m$global$fit$estimate[2],shape=m$global$fit$estimate[3])),r$probabilidade,tolerance=1e-8))
pars <- read.csv('tables/gev_global.csv')
stopifnot(all(pars$bootstrap_validos/pars$bootstrap_total>.9))
auto <- evd::fgev(a$Magnitude)
stopifnot(abs(auto$deviance-m$global$fit$deviance)<1e-4)
# Momentos empíricos: referência simétrica conhecida, excesso de curtose explicitado.
stopifnot(all.equal(unname(shape_moments(c(-1,0,1))),c(0,-1.5)))
# Pontos de referência continentais e ponto em oceano aberto; sem costa mais próxima.
geo <- geo_load()
g <- classify_continents(c(31.2,-99.13,-46.63,139.7,-.1,151.2,-140,107,35),
                         c(30,19.43,-23.55,35.7,51.5,-33.8,-40,52,39),geo)
stopifnot(identical(g$regiao,c(region_names[c(1,2,3,4,5,6,7)],'Europa','Ásia')))
# Anéis internos e pontos no contorno externo.
fake <- list(features=list(list(properties=list(ADMIN='Teste',CONTINENT='Africa'),
 geometry=list(type='Polygon',coordinates=list(
   list(c(0,0),c(10,0),c(10,10),c(0,10),c(0,0)),
   list(c(4,4),c(6,4),c(6,6),c(4,6),c(4,4)))))))
stopifnot(identical(classify_continents(c(1,5,0),c(1,5,1),fake)$regiao,
                    c('África','Áreas oceânicas/outros','África')))
coverage <- read.csv('tables/cobertura_regional.csv')
series <- read.csv('tables/maximos_regionais.csv')
stopifnot(sum(coverage$eventos)==nrow(d),setequal(coverage$regiao,region_names),
          all(coverage$anos+coverage$anos_vazios==52),nrow(series)==52*length(region_names),
          !any(series$Magnitude==0,na.rm=TRUE))
for(n in region_names) {
  actual <- series[series$regiao==n,]
  stopifnot(sum(!is.na(actual$Magnitude))==coverage$anos[coverage$regiao==n])
  z <- d[d$regiao==n,]
  if(nrow(z)) {
    ex <- aggregate(Magnitude~ano,z,max)
    stopifnot(all(actual$Magnitude[match(ex$ano,actual$ano)]==ex$Magnitude))
  }
}
for(n in names(m$regional)) {
  stopifnot(coverage$anos_vazios[coverage$regiao==n]==0)
  stopifnot(m$regional[[n]]$fit$convergence=='successful')
}
s <- m$stable
stopifnot(s$n==nrow(d),s$parametrizacao=='Nolan S0 (pm=0)')
if(s$status=='ok') {
  stopifnot(all(is.finite(s$parameters)),s$parameters['alpha']>0,
            s$parameters['alpha']<=2,abs(s$parameters['beta'])<=1,s$parameters['gamma']>0)
  q <- read.csv('tables/estavel_quantis.csv')
  p <- do.call(stabledist::pstable,c(list(q=q$estavel,pm=0),as.list(s$parameters)))
  stopifnot(max(abs(p-q$probabilidade))<1e-5)
}
stopifnot(!any(c('pot','pot_boot','threshold','chosen')%in%names(m)))
message('Validações estatísticas, continentais e da parametrização estável aprovadas.')
