# Convenção evd: xi é shape; dados em magnitude original, não log-transformada.
write_table <- function(x, name) write.csv(x, file.path('tables', paste0(name,'.csv')), row.names=FALSE, na='')
gev_fit <- function(x) {
  fits <- lapply(c(-.2,0,.2), function(s) { loc<-mean(x)-.3*sd(x); sc<-sd(x); if(any(1+s*(x-loc)/sc<=0)) return(NULL); tryCatch(evd::fgev(x, start=list(loc=loc,scale=sc,shape=s)), error=function(e) NULL) })
  fits <- Filter(function(f) !is.null(f) && f$convergence == 'successful' && all(is.finite(f$estimate)), fits)
  if (!length(fits)) stop('GEV: nenhum início convergiu')
  fits[[which.min(sapply(fits, function(f) f$deviance))]]
}
qgev <- function(p, f) evd::qgev(p,loc=f$estimate['loc'],scale=f$estimate['scale'],shape=f$estimate['shape'])
gev_boot <- function(x, B=399) {
  out <- matrix(NA_real_,B,9,dimnames=list(NULL,c('mu','sigma','xi',paste0('z',c(2,5,10,20,50,100)))))
  for(b in seq_len(B)) {
    L <- ceiling(length(x)^(1/3)); starts <- sample.int(length(x),ceiling(length(x)/L),replace=TRUE); idx <- unlist(lapply(starts,function(j)((j-1+0:(L-1))%%length(x))+1))[seq_along(x)]; f <- tryCatch(gev_fit(x[idx]),error=function(e) NULL)
    if(!is.null(f)) out[b,] <- c(f$estimate,qgev(1-1/c(2,5,10,20,50,100),f))
  }
  out
}
ci <- function(x) if(sum(is.finite(x))>=30) quantile(x[is.finite(x)],c(.025,.975)) else c(NA,NA)
fit_tables <- function(x,label, B=399) {
  f <- gev_fit(x); b <- gev_boot(x,B)
  pars <- data.frame(modelo=label,parametro=c('mu','sigma','xi'),estimativa=unname(f$estimate),EP=unname(f$std.err),inferior=apply(b[,1:3],2,ci)[1,],superior=apply(b[,1:3],2,ci)[2,],n=length(x),logLik=-f$deviance/2,AIC=f$deviance+6,bootstrap_validos=sum(complete.cases(b)),bootstrap_total=B)
  ret <- data.frame(modelo=label,T=c(2,5,10,20,50,100),probabilidade=1-1/c(2,5,10,20,50,100),magnitude=qgev(1-1/c(2,5,10,20,50,100),f),inferior=apply(b[,4:9],2,ci)[1,],superior=apply(b[,4:9],2,ci)[2,])
  list(fit=f,boot=b,pars=pars,ret=ret)
}
fig <- function(name, code, width=1100,height=720) {
  png(file.path('figures',paste0(name,'.png')),width=width,height=height,res=125)
  par(mar=c(4.5,4.5,3,1),col='#233445',col.axis='#233445',fg='#233445',las=1)
  code(); dev.off()
}
block_max <- function(d,months=12) {
  k <- sprintf('%04d-%02d',d$ano,((d$mes-1)%/%months)*months+1)
  ans <- do.call(rbind,lapply(split(d,k),function(z) z[order(-z$Magnitude,z$timestamp,z$ID)[1],]))
  ans$bloco <- rownames(ans); rownames(ans)<-NULL; ans
}
# Momentos centrais empíricos (divisor n), sem correção de viés.
shape_moments <- function(x) {
  x <- x[is.finite(x)]
  m2 <- mean((x-mean(x))^2)
  c(assimetria=mean((x-mean(x))^3)/m2^(3/2),
    excesso_curtose=mean((x-mean(x))^4)/m2^2-3)
}
desc <- function(x) {
  x <- x[is.finite(x)]
  c(n=length(x), media=mean(x), mediana=median(x), DP=sd(x), variancia=var(x),
    min=min(x), Q1=unname(quantile(x,.25)), Q3=unname(quantile(x,.75)),
    P90=unname(quantile(x,.9)), P95=unname(quantile(x,.95)),
    P99=unname(quantile(x,.99)), P999=unname(quantile(x,.999)), max=max(x),
    shape_moments(x))
}
region_names <- c('África','América do Norte','América do Sul','Ásia','Europa',
                  'Oceania','Áreas oceânicas/outros')
continent_lookup <- c('Africa'='África','North America'='América do Norte',
                      'South America'='América do Sul','Asia'='Ásia',
                      'Europe'='Europa','Oceania'='Oceania')
geo_load <- function() jsonlite::fromJSON('data/raw/ne_50m_admin_0_countries.geojson',
                                         simplifyVector=FALSE)
geo_polygons <- function(feature) {
  if(feature$geometry$type=='Polygon') list(feature$geometry$coordinates)
  else feature$geometry$coordinates
}
# Point-in-polygon em coordenadas WGS84; sem buffers, snapping ou costa mais próxima.
classify_continents <- function(lon,lat,geo) {
  hits <- vector('list',length(lon))
  for(j in seq_along(geo$features)) {
    f <- geo$features[[j]]
    for(poly in geo_polygons(f)) {
      ring <- do.call(rbind,lapply(poly[[1]],unlist))
      k <- which(lon>=min(ring[,1]) & lon<=max(ring[,1]) &
                 lat>=min(ring[,2]) & lat<=max(ring[,2]))
      if(!length(k)) next
      inside <- sp::point.in.polygon(lon[k],lat[k],ring[,1],ring[,2])>0
      if(length(poly)>1) for(h in poly[-1]) {
        hole <- do.call(rbind,lapply(h,unlist))
        inside <- inside & sp::point.in.polygon(lon[k],lat[k],hole[,1],hole[,2])==0
      }
      for(i in k[inside]) hits[[i]] <- union(hits[[i]],j)
    }
  }
  country <- vapply(hits,function(h) paste(sort(unique(vapply(h,function(j)
    geo$features[[j]]$properties$ADMIN,character(1)))),collapse='; '),character(1))
  labels <- lapply(hits,function(h) unique(na.omit(unname(continent_lookup[
    vapply(h,function(j) geo$features[[j]]$properties$CONTINENT,character(1))]))))
  region <- vapply(labels,function(h) if(length(h)==1) h else tail(region_names,1),character(1))
  reason <- vapply(seq_along(hits),function(i) {
    if(!length(hits[[i]])) 'Fora dos polígonos'
    else if(length(labels[[i]])==1) 'Polígono continental'
    else if(length(labels[[i]])>1) 'Fronteira continental ambígua'
    else 'Polígono fora dos seis continentes'
  },character(1))
  data.frame(regiao=region,pais_poligono=country,criterio_geografico=reason)
}
