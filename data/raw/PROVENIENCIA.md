# Proveniência

- `Terremoto.csv`: arquivo recebido do usuário em 29/10/2026, mantido byte a byte; coleção declarada USGS/Kaggle, Significant Earthquakes 1965–2016. Não houve nova extração no USGS.
- `land.geojson`: Natural Earth, 1:110m Land, domínio público. Cópia de https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson em 29/10/2026.
- `fe/*.asc`: índices e nomes Flinn–Engdahl, copiados de https://github.com/obspy/obspy/tree/master/obspy/geodetics/data em 29/10/2026. A consulta foi reescrita em R e conferida nos exemplos Alemanha (543) e nordeste argentino (133). A granularidade angular é a da tabela de consulta reconhecida, não uma regionalização por quadrantes inventada.
- `checksums.json`: SHA256 das entradas utilizadas. As cópias versionadas fixam os arquivos, mesmo se as URLs upstream mudarem.
