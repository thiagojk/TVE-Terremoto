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
fe_load <- function() {
  idx <- scan('data/raw/fe/quadsidx.asc',quiet=TRUE); names <- readLines('data/raw/fe/names.asc')
  quads <- c('ne','nw','se','sw'); ans <- list(names=trimws(names))
  for(i in 1:4) {
    n <- idx[((i-1)*91+1):(i*91)]
    v <- matrix(scan(paste0('data/raw/fe/',quads[i],'sect.asc'),quiet=TRUE),ncol=2,byrow=TRUE)
    ans[[quads[i]]] <- list(n=n,start=c(1,head(cumsum(n),-1)+1),v=v)
  };ans
}
fe_number <- function(lon,lat,fe) {
  lon[lon== -180] <- 180
  vapply(seq_along(lon),function(i) {
    q <- if(lat[i]>=0) if(lon[i]>=0) 'ne' else 'nw' else if(lon[i]>=0) 'se' else 'sw'
    z <- fe[[q]]; a <- floor(abs(lat[i]))+1; rows <- z$start[a]+seq_len(z$n[a])-1
    r <- z$v[rows,,drop=FALSE]; r[max(which(r[,1]<=floor(abs(lon[i])))),2]
  },numeric(1))
}
haversine <- function(lon,lat,x,y) {
  rad <- pi/180; a <- sin((lat-y)*rad/2)^2+cos(lat*rad)*cos(y*rad)*sin((lon-x)*rad/2)^2
  6371*2*asin(pmin(1,sqrt(a)))
}
# Variante simétrica das janelas Gardner–Knopoff; não é um catálogo de mainshocks validado.
decluster <- function(d,factor=1) {
  d <- d[order(-d$Magnitude,d$timestamp,d$ID),]; keep <- rep(TRUE,nrow(d)); cluster <- integer(nrow(d))
  for(i in seq_len(nrow(d))) if(keep[i]) {
    m <- d$Magnitude[i]; days <- if(m>=6.5) 10^(.032*m+2.7389) else 10^(.5409*m-.547)
    radius <- 10^(.1238*m+.983)
    cand <- which(keep & seq_len(nrow(d))>i & abs(as.numeric(difftime(d$timestamp,d$timestamp[i],units='days')))<=days*factor)
    if(length(cand)) {
      hit <- cand[haversine(d$Longitude[cand],d$Latitude[cand],d$Longitude[i],d$Latitude[i])<=radius*factor]
      keep[hit]<-FALSE;cluster[hit]<-i
    }
  }; d$cluster_removed <- !keep; d$cluster_parent <- cluster;d
}
gpd_fit <- function(x,u) evd::fpot(x,threshold=u,model='gpd',std.err=TRUE)
gpd_return <- function(f,u,lambda,T) {
 s <- f$estimate['scale']; xi<-f$estimate['shape'];a<-lambda/(-log(1-1/T))
 if(abs(xi)<1e-7) u+s*log(a) else u+s/xi*(a^xi-1)
}
