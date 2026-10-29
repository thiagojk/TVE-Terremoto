raw <- read.csv('data/raw/Terremoto.csv',check.names=FALSE,na.strings=c('','NA'),stringsAsFactors=FALSE)
stopifnot(all(c('Date','Time','Latitude','Longitude','Magnitude','Depth','Magnitude Type','ID','Type') %in% names(raw)))
write_table(data.frame(coluna=names(raw),classe=sapply(raw,class),ausentes=sapply(raw,function(x)sum(is.na(x)))),'auditoria_colunas')
raw$timestamp <- as.POSIXct(paste(raw$Date,raw$Time),format='%m/%d/%Y %H:%M:%S',tz='UTC')
iso <- grepl('T',raw$Date,fixed=TRUE)
raw$timestamp[iso] <- as.POSIXct(raw$Date[iso],format='%Y-%m-%dT%H:%M:%OS',tz='UTC')
invalid <- is.na(raw$timestamp)|!is.finite(raw$Magnitude)|abs(raw$Latitude)>90|abs(raw$Longitude)>180|!is.finite(raw$Depth)
write_table(data.frame(metrica=c('Registros brutos','Datas ISO','IDs duplicados','Linhas duplicadas','Inválidos essenciais','Profundidades negativas','Eventos não sísmicos'),valor=c(nrow(raw),sum(iso),sum(duplicated(raw$ID)),sum(duplicated(raw[,1:21])),sum(invalid),sum(raw$Depth<0,na.rm=TRUE),sum(raw$Type!='Earthquake'))),'auditoria')
write_table(raw[invalid | raw$Type!='Earthquake',],'exclusoes')
d <- raw[!invalid & raw$Type=='Earthquake' & !duplicated(raw$ID),]
d$data <- as.Date(d$timestamp,tz='UTC');d$ano<-as.integer(format(d$data,'%Y'));d$mes<-as.integer(format(d$data,'%m'))
d$semestre<-(d$mes-1)%/%6+1;d$trimestre<-(d$mes-1)%/%3+1;d$decada<-d$ano%/%10*10
fe <- fe_load();d$fe_id <- fe_number(d$Longitude,d$Latitude,fe);d$regiao <- fe$names[d$fe_id]
write.csv(d,'data/processed/terremotos.csv',row.names=FALSE)
saveRDS(d,'data/processed/terremotos.rds')
