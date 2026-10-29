# fBasics::stableFit(type='q'): estimador por quantis de McCulloch.
# A implementação calcula quantis com stabledist no padrão pm=0 (Nolan S0).
# Todos os diagnósticos abaixo passam pm=0 explicitamente; delta é localização S0.
# Não se estima uma lei estável truncada nem se substitui a GEV dos máximos.
stable_warnings <- character()
record_stable_warning <- function(w) {
  stable_warnings <<- c(stable_warnings,conditionMessage(w))
  message('Diagnóstico estável: ',conditionMessage(w))
  invokeRestart('muffleWarning')
}
x <- d$Magnitude
stable_attempt <- tryCatch(withCallingHandlers(
  fBasics::stableFit(x,type='q',doplot=FALSE),warning=record_stable_warning),
  error=function(e)e)
stable_analysis <- list(status='falha',method='Quantis de McCulloch (fBasics::stableFit, type=q)',
                        parametrizacao='Nolan S0 (pm=0)',n=length(x))
stable_par <- setNames(rep(NA_real_,4),c('alpha','beta','gamma','delta'))
if(inherits(stable_attempt,'error')) {
  stable_analysis$message <- conditionMessage(stable_attempt)
} else {
  stable_par <- stable_attempt@fit$estimate
  valid <- all(is.finite(stable_par)) && stable_par['alpha']>0 &&
    stable_par['alpha']<=2 && abs(stable_par['beta'])<=1 && stable_par['gamma']>0
  stable_analysis$status <- if(valid) 'ok' else 'falha'
  stable_analysis$message <- if(valid)
    'Estimativa por quantis obtida; sem critério iterativo de convergência.' else
    'A interpolação de quantis não produziu quatro parâmetros admissíveis.'
}
stable_analysis$parameters <- stable_par
write_table(data.frame(parametro=names(stable_par),estimativa=unname(stable_par),
  metodo=stable_analysis$method,parametrizacao=stable_analysis$parametrizacao,
  n=length(x),estado=stable_analysis$status,convergencia=stable_analysis$message), 'estavel_parametros')
if(stable_analysis$status=='ok') {
  args <- as.list(stable_par)
  stable_density <- function(q) do.call(stabledist::dstable,c(list(x=q,pm=0),args))
  stable_cdf <- function(q) do.call(stabledist::pstable,c(list(q=q,pm=0),args))
  stable_quantile <- function(p) do.call(stabledist::qstable,c(list(p=p,pm=0),args))
  diagnostic <- withCallingHandlers({
    probs <- c(.01,.05,.25,.5,.75,.9,.95,.99,.999)
    theoretical <- stable_quantile(probs)
    empirical <- unname(quantile(x,probs))
    data.frame(probabilidade=probs,empirico=empirical,estavel=theoretical)
  },warning=record_stable_warning)
  write_table(diagnostic,'estavel_quantis')
  below_cut <- withCallingHandlers(stable_cdf(min(x)),warning=record_stable_warning)
  stable_analysis$below_cut <- below_cut
  write_table(data.frame(corte=min(x),massa_abaixo_corte=below_cut,
                        beta_perto_fronteira=abs(stable_par['beta'])>=.94), 'estavel_limites')
  withCallingHandlers(fig('diagnostico_estavel',function() {
    par(mfrow=c(1,3),mar=c(4.5,4.5,3.5,1))
    hist(x,breaks=35,prob=TRUE,col='#b8ded8',xlim=c(5,max(x)),
         main='Magnitudes e densidade estável',xlab='Magnitude')
    grid <- seq(5,max(x),length.out=250)
    lines(grid,stable_density(grid),col='#d07732',lwd=2)
    abline(v=min(x),lty=3)
    plot(diagnostic$estavel,diagnostic$empirico,pch=16,col='#007f78',
         main='QQ: quantis selecionados',xlab='Quantil estável S0',ylab='Quantil empírico')
    abline(0,1,col='#d07732')
    grid <- seq(min(x),max(x),length.out=200)
    empirical_tail <- vapply(grid,function(v) mean(x>v),numeric(1))
    plot(grid,pmax(empirical_tail,1/length(x)),type='s',log='y',col='#007f78',
         main='Cauda empírica e estável',xlab='Magnitude',ylab='Probabilidade de excedência')
    lines(grid,1-stable_cdf(grid),col='#d07732',lwd=2)
    legend('topright',c('Empírica','Estável não truncada'),
           col=c('#007f78','#d07732'),lty=1,cex=.7)
  },width=1500,height=600),warning=record_stable_warning)
}
write_table(data.frame(aviso=unique(stable_warnings)),'estavel_avisos')
stable_analysis$warnings <- unique(stable_warnings)
