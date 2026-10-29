blocks <- lapply(c(3,6,12),function(m) block_max(d,m));names(blocks)<-c('Trimestral','Semestral','Anual')
models <- lapply(names(blocks),function(n) fit_tables(blocks[[n]]$Magnitude,n));names(models)<-names(blocks)
a <- blocks$Anual;global<-models$Anual
write_table(a,'maximos_anuais');write_table(do.call(rbind,lapply(models,`[[`,'pars')),'parametros_blocos');write_table(do.call(rbind,lapply(models,`[[`,'ret')),'retorno_blocos')
bs <- do.call(rbind,lapply(seq_along(blocks),function(i){x<-blocks[[i]]$Magnitude;p<-models[[i]]$pars[3,];data.frame(bloco=names(blocks)[i],meses=c(3,6,12)[i],blocos_esperados=52*c(4,2,1)[i],maximos=length(x),vazios=52*c(4,2,1)[i]-length(x),media=mean(x),DP=sd(x),min=min(x),max=max(x),lag=10,Ljung_Box=Box.test(x,lag=10,type='Ljung-Box')$p.value,xi=p$estimativa,inf=p$inferior,sup=p$superior)}))
write_table(bs,'comparacao_blocos')
write_table(global$pars,'gev_global');write_table(global$ret,'retorno_global')
write_table(data.frame(magnitude=c(7,7.5,8,8.5,9),probabilidade=1-evd::pgev(c(7,7.5,8,8.5,9),loc=global$fit$estimate[1],scale=global$fit$estimate[2],shape=global$fit$estimate[3])),'probabilidades')
fig('maximos',function() plot(a$ano,a$Magnitude,type='b',pch=16,col='#007f78',main='Máximos anuais globais',xlab='Ano',ylab='Magnitude máxima'))
fig('acf',function(){par(mfrow=c(3,1));for(n in names(blocks)) acf(blocks[[n]]$Magnitude,main=paste('ACF:',n),lag.max=15)},height=1000)
fig('diagnostico_gev',function(){par(mfrow=c(2,2));x<-sort(a$Magnitude);p<-ppoints(length(x));plot(qgev(p,global$fit),x,main='QQ: GEV anual',xlab='Quantis ajustados',ylab='Quantis observados');abline(0,1,col='#d07732');plot(p,evd::pgev(x,loc=global$fit$estimate[1],scale=global$fit$estimate[2],shape=global$fit$estimate[3]),main='PP: GEV anual',xlab='Probabilidade empírica',ylab='Probabilidade ajustada');abline(0,1,col='#d07732');hist(x,prob=TRUE,breaks=10,col='#b8ded8',main='Densidade anual',xlab='Magnitude');xx<-seq(min(x)-.1,max(x)+.3,length.out=300);lines(xx,evd::dgev(xx,loc=global$fit$estimate[1],scale=global$fit$estimate[2],shape=global$fit$estimate[3]),col='#007f78',lwd=2);r<-global$ret;plot(r$T,r$magnitude,log='x',type='b',ylim=range(r[,4:6]),main='Níveis de retorno e IC95%',xlab='Período (anos)',ylab='Magnitude');arrows(r$T,r$inferior,r$T,r$superior,angle=90,code=3,length=.04,col='#007f78')})
# Tendência exploratória e comparação aninhada com localização linear centralizada.
t <- (a$ano-mean(a$ano))/sd(a$ano)
fns <- evd::fgev(a$Magnitude,nsloc=data.frame(trend=t))
write_table(data.frame(modelo=c('Estacionária','Localização linear'),logLik=c(-global$fit$deviance/2,-fns$deviance/2),AIC=c(global$fit$deviance+6,fns$deviance+8),LRT_p=c(NA,pchisq(max(0,global$fit$deviance-fns$deviance),1,lower.tail=FALSE))),'tendencia')

write_table(data.frame(parametro=names(fns$estimate),estimativa=unname(fns$estimate),EP=unname(fns$std.err),inferior=unname(fns$estimate-1.96*fns$std.err),superior=unname(fns$estimate+1.96*fns$std.err)),'gev_tendencia')

resid_pit<-evd::pgev(a$Magnitude,loc=fns$estimate['loc']+fns$estimate['loctrend']*t,scale=fns$estimate['scale'],shape=fns$estimate['shape'])
write_table(data.frame(serie=c('Máximos anuais','PIT após localização linear'),Ljung_Box=c(Box.test(a$Magnitude,lag=10,type='Ljung-Box')$p.value,Box.test(resid_pit,lag=10,type='Ljung-Box')$p.value)),'dependencia_tendencia')
