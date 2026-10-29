land<-jsonlite::fromJSON('data/raw/land.geojson',simplifyVector=FALSE)
world <- function(title) {
 plot(NA,xlim=c(-180,180),ylim=c(-90,90),xlab='Longitude',ylab='Latitude',main=title,asp=NA)
 for(f in land$features) {
   polys<-if(f$geometry$type=='Polygon')list(f$geometry$coordinates)else f$geometry$coordinates
   for(poly in polys) {xy<-do.call(rbind,lapply(poly[[1]],unlist));polygon(xy[,1],xy[,2],col='#e5e9ec',border='#a2afb7',lwd=.3)}
 }
}
fig('mapa_global',function(){world('Catálogo de terremotos — USGS/Kaggle');points(d$Longitude,d$Latitude,pch=16,cex=.15+(d$Magnitude-5.5)*.18,col=adjustcolor('#007f78',.18))},height=630)
fig('mapa_extremos',function(){world('Eventos com magnitude ≥ 8 (limiar descritivo)');z<-d[d$Magnitude>=8,];points(z$Longitude,z$Latitude,pch=21,cex=.5+(z$Magnitude-7)*.7,bg='#d07732',col='white')},height=630)
fig('mapa_maximos',function(){world('Localização dos máximos anuais');points(a$Longitude,a$Latitude,pch=21,cex=.7+(a$Magnitude-7)*.6,bg='#007f78',col='white')},height=630)
g<-expand.grid(lon=-179.5:179.5,lat=-89.5:89.5);g$id<-fe_number(g$lon,g$lat,fe)
ids<-match(chosen,fe$names);region_grid<-matrix(match(g$id,ids),360,180)
cols<-hcl.colors(4,'Dark 3')
fig('mapa_regioes',function(){world('Quatro regiões Flinn–Engdahl selecionadas');image(-179.5:179.5,-89.5:89.5,region_grid,col=adjustcolor(cols,.4),breaks=seq(.5,4.5,1),add=TRUE);for(i in 1:4){z<-matrix(as.integer(g$id==ids[i]),360,180);contour(-179.5:179.5,-89.5:89.5,z,levels=.5,drawlabels=FALSE,add=TRUE,col=cols[i],lwd=1.2)};sel<-d$regiao%in%chosen;points(d$Longitude[sel],d$Latitude[sel],pch=16,cex=.1+(d$Magnitude[sel]-5.5)*.12,col=cols[match(d$regiao[sel],chosen)]);legend('bottomleft',chosen,pch=16,col=cols,cex=.65,bg='white')},height=690)
# Leaflet JS local, sem tiles remotos: costa e pontos incorporados ao HTML.
z<-d[d$Magnitude>=7,];events<-data.frame(lat=z$Latitude,lon=z$Longitude,m=z$Magnitude,popup=paste0('Data: ',z$timestamp,' UTC<br>Magnitude: ',z$Magnitude,' (',z$`Magnitude Type`,')<br>Profundidade: ',z$Depth,' km<br>Latitude: ',z$Latitude,'<br>Longitude: ',z$Longitude,'<br>Região FE: ',z$regiao))
html<-paste0('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Mapa interativo de terremotos</title><link rel="stylesheet" href="assets/leaflet/leaflet.css"><style>body{margin:0;font:15px sans-serif}#map{height:85vh;background:#edf3f7}p{padding:0 16px}</style></head><body><p>Terremotos com magnitude ≥ 7 · clique nos pontos · costa Natural Earth · dados USGS/Kaggle</p><div id="map"></div><script src="assets/leaflet/leaflet.js"></script><script>const map=L.map("map",{preferCanvas:true}).setView([5,0],2);L.geoJSON(',paste(readLines('data/raw/land.geojson'),collapse=''),',{style:{color:"#a2afb7",weight:1,fillColor:"#dce5e8",fillOpacity:1}}).addTo(map);const events=',jsonlite::toJSON(events,auto_unbox=TRUE),';events.forEach(e=>L.circleMarker([e.lat,e.lon],{radius:3+(e.m-7)*3,color:"#007f78",weight:1,fillOpacity:.6}).bindPopup(e.popup).addTo(map));</script></body></html>')
writeLines(html,'mapa.html',useBytes=TRUE)
