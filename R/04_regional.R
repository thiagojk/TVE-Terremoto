# Mesma regra de elegibilidade para todas as categorias, antes de comparar ajustes.
# Ausência de evento no catálogo não é magnitude zero nem prova de ausência física.
regional <- list(); coverage <- list(); regional_max <- list(); regional_desc <- list()
for(n in region_names) {
  z <- d[d$regiao==n,]
  b <- if(nrow(z)) block_max(z) else NULL
  series <- merge(data.frame(ano=1965:2016),
                  if(is.null(b)) data.frame(ano=integer(),Magnitude=double()) else
                    b[,c('ano','Magnitude')],by='ano',all.x=TRUE,sort=TRUE)
  series$regiao <- n
  regional_max[[n]] <- series
  observed <- sum(is.finite(series$Magnitude))
  eligible <- observed>=30 && observed==52
  reason <- if(eligible) 'Cobertura completa; ajuste elegível' else
    'Sem GEV: anos sem registros ou menos de 30 máximos'
  if(eligible) {
    result <- tryCatch(fit_tables(series$Magnitude,n),error=function(e)e)
    if(inherits(result,'error')) reason <- paste('Sem GEV:',conditionMessage(result))
    else regional[[n]] <- result
  }
  coverage[[n]] <- data.frame(regiao=n,eventos=nrow(z),anos=observed,
                              anos_vazios=52-observed,ajuste=reason)
  if(observed) regional_desc[[n]] <- data.frame(regiao=n,t(desc(series$Magnitude)))
}
write_table(do.call(rbind,coverage),'cobertura_regional')
write_table(do.call(rbind,regional_max),'maximos_regionais')
write_table(do.call(rbind,regional_desc),'descritiva_regional')
write_table(do.call(rbind,lapply(regional,`[[`,'pars')),'gev_regional')
write_table(do.call(rbind,lapply(regional,`[[`,'ret')),'retorno_regional')
regional_acf <- do.call(rbind,lapply(names(regional),function(n) {
  x <- regional_max[[n]]$Magnitude
  data.frame(regiao=n,Ljung_Box=Box.test(x,lag=10,type='Ljung-Box')$p.value)
}))
write_table(regional_acf,'dependencia_regional')
cols <- setNames(c(hcl.colors(6,'Dark 3'),'#7d8a94'),region_names)
fig('regional_series',function() {
  par(mfrow=c(4,2),mar=c(3.2,4,3,1))
  for(n in region_names) {
    x <- regional_max[[n]]
    plot(x$ano,x$Magnitude,type='b',pch=16,cex=.45,col=cols[n],
         xlim=c(1965,2016),ylim=range(d$Magnitude),main=n,
         xlab='Ano',ylab='Máximo anual')
  }
  plot.new();text(.5,.6,'Anos sem registros: lacunas, não zeros',cex=.9)
},height=1350)
fig('regional_distribuicoes',function() {
  par(mar=c(8,4,3,1))
  boxplot(lapply(regional_max,`[[`,'Magnitude'),names=region_names,las=2,
          col=cols,cex.axis=.75,ylab='Magnitude máxima anual',
          main='Distribuição dos máximos anuais observados')
})
fig('regional_xi',function() {
  pp <- do.call(rbind,lapply(regional,function(z) z$pars[3,]))
  par(mar=c(4.5,11,3,1))
  plot(pp$estimativa,seq_len(nrow(pp)),xlim=range(pp[,5:6]),yaxt='n',
       pch=16,col=cols[pp$modelo],xlab='xi e IC95% bootstrap',ylab='',
       main='Forma da GEV por região com cobertura completa')
  axis(2,seq_len(nrow(pp)),pp$modelo,las=1,cex.axis=.8)
  segments(pp$inferior,seq_len(nrow(pp)),pp$superior,seq_len(nrow(pp)),
           col=cols[pp$modelo],lwd=2)
  abline(v=0,lty=2,col='#a0a0a0')
})
fig('regional_retornos',function() {
  par(mfrow=c(ceiling(length(regional)/2),2),mar=c(4,4,3,1))
  for(n in names(regional)) {
    r <- regional[[n]]$ret
    plot(r$T,r$magnitude,log='x',type='b',pch=16,col=cols[n],
         ylim=range(r[,4:6]),main=n,xlab='Período de retorno (anos)',ylab='Magnitude')
    lines(r$T,r$inferior,col=cols[n],lty=3)
    lines(r$T,r$superior,col=cols[n],lty=3)
  }
},height=1050)
fig('regional_curvas',function() {
  ret <- do.call(rbind,lapply(regional,`[[`,'ret'))
  plot(NA,xlim=c(2,100),ylim=range(ret$magnitude),log='x',
       xlab='Período de retorno (anos)',ylab='Magnitude',
       main='Curvas de retorno: categorias com 52 máximos')
  for(n in names(regional)) {
    r <- regional[[n]]$ret;lines(r$T,r$magnitude,col=cols[n],lwd=2)
  }
  legend('topleft',names(regional),col=cols[names(regional)],lty=1,cex=.8,bg='white')
})
