counts <- sort(table(d$regiao),decreasing=TRUE);chosen <- names(counts)[1:4]
regional <- list();coverage<-list()
for(n in chosen) {
  z<-d[d$regiao==n,];b<-block_max(z);coverage[[n]]<-data.frame(regiao=n,eventos=nrow(z),anos=nrow(b),anos_vazios=52-nrow(b))
  if(nrow(b)>=30 && nrow(b)==52) regional[[n]]<-fit_tables(b$Magnitude,n)
}
write_table(do.call(rbind,coverage),'cobertura_regional')
write_table(do.call(rbind,lapply(regional,`[[`,'pars')),'gev_regional')
write_table(do.call(rbind,lapply(regional,`[[`,'ret')),'retorno_regional')
fig('regional',function(){par(mfrow=c(2,2));pp<-do.call(rbind,lapply(regional,function(z) z$pars[3,]));plot(pp$estimativa,seq_len(nrow(pp)),xlim=range(pp[,5:6]),yaxt='n',xlab='xi e IC95%',ylab='',main='Forma por região');axis(2,seq_len(nrow(pp)),abbreviate(pp$modelo,14),cex.axis=.65);segments(pp$inferior,seq_len(nrow(pp)),pp$superior,seq_len(nrow(pp)));abline(v=0,lty=2);cols<-hcl.colors(4,'Dark 3');plot(NA,xlim=c(1965,2016),ylim=c(5.5,9.5),xlab='Ano',ylab='Magnitude',main='Máximos anuais regionais');for(i in seq_along(chosen)){b<-block_max(d[d$regiao==chosen[i],]);lines(b$ano,b$Magnitude,col=cols[i])};boxplot(lapply(chosen,function(n)block_max(d[d$regiao==n,])$Magnitude),names=abbreviate(chosen,10),ylab='Magnitude',main='Distribuição dos máximos',col=cols,cex.axis=.65);plot(NA,xlim=c(2,100),ylim=range(do.call(rbind,lapply(regional,`[[`,'ret'))[,4:6]),log='x',xlab='Anos',ylab='Magnitude',main='Retorno regional e IC95%');for(i in seq_along(regional)){r<-regional[[i]]$ret;lines(r$T,r$magnitude,col=cols[i]);lines(r$T,r$inferior,col=cols[i],lty=3);lines(r$T,r$superior,col=cols[i],lty=3)}})
