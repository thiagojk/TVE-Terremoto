# Proveniência e verificação documental

## Registros sísmicos

`Terremoto.csv` é a cópia arquivada usada neste estudo. Foi incorporada ao projeto em 29/10/2026 e permanece byte a byte inalterada. Não foi baixada diretamente de um serviço USGS durante esta análise. O hash SHA256 está em `checksums.json`.

A investigação documental de 02/11/2026 reuniu as seguintes evidências:

1. A documentação da coleção **Significant Earthquakes, 1965–2016**, no endereço de distribuição https://www.kaggle.com/datasets/usgs/earthquake-database (conta identificada como US Geological Survey), descreve a compilação do NEIC e os campos data, hora, localização, profundidade, magnitude e origem, com seleção histórica por magnitude reportada ≥ 5,5. Kaggle é o intermediário de distribuição desta coleção, não a instituição produtora das observações sísmicas.
2. A página oficial do **USGS/NEIC** confirma sua função de reunir e disponibilizar informação sísmica mundial: https://www.usgs.gov/programs/earthquake-hazards/national-earthquake-information-center-neic .
3. A documentação oficial **ANSS ComCat** informa que o serviço reúne catálogos históricos e redes contribuintes, e não apenas medições exclusivas do USGS: https://earthquake.usgs.gov/data/comcat/ . A lista https://earthquake.usgs.gov/data/comcat/catalog/ identifica, entre outros, `US` como USGS National Earthquake Information Center/PDE, `ISCGEM` como ISC-GEM Main Catalog e `ISCGEMSUP` como catálogo suplementar.
4. O CSV contém `ID`, `Source`, `Location Source` e `Magnitude Source`, com códigos compatíveis com essas fontes documentadas. O pipeline conserva os campos e gera `tables/fontes_eventos.csv` para auditoria. A primeira linha tem ID `ISCGEM860706`; o arquivo também contém registros com prefixos `US` e fontes de outras redes. Esses metadados corroboram a origem documentada da coleção, mas não são, isoladamente, uma certificação de identidade com o ComCat atual.

**Conclusão e limite da confirmação:** a procedência documentada da compilação é USGS/NEIC, com registros de catálogos e redes contribuintes. O projeto analisa uma cópia histórica redistribuída, sem registrar uma nova coleta. Não se dispõe da URL da consulta original, do instante de extração ou de um manifesto oficial que certifique todos os registros do arquivo. Não foi feita uma conferência integral com o serviço atual; revisões posteriores de eventos podem produzir diferenças. Assim, não se afirma que este CSV seja uma exportação oficial atual, nem um inventário completo de toda a sismicidade de 1965–2016. A expressão “Significant Earthquakes” é o título da coleção; não foi demonstrado que seus critérios coincidam com o indicador operacional de significância do USGS.

A referência científica primária é o USGS/ANSS ComCat e sua documentação; o endereço de distribuição acima é preservado aqui para rastreabilidade, sem substituir a fonte científica.

## Geografia

- `land.geojson`: Natural Earth, 1:110m Land, domínio público. Cópia de https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson em 29/10/2026.
- `ne_50m_admin_0_countries.geojson`: Natural Earth, Admin 0 – Countries 1:50m, domínio público, WGS84. Cópia de https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson em 29/10/2026. Classificação pelo atributo CONTINENT após teste ponto-em-polígono, respeitando buracos e multipolígonos. A convenção de países transcontinentais é preservada (Rússia: Europa; Turquia: Ásia). América Central e Caribe integram North America. Nenhum buffer, aproximação pela costa ou preenchimento de regiões oceânicas. Pontos sem correspondência, em categorias continentais não incluídas ou com fronteiras continentais ambíguas ficam em Áreas oceânicas/outros. Escala generalizada: não usar como delimitação geológica ou costeira de precisão.

`checksums.json` registra SHA256 das entradas. As cópias versionadas fixam os arquivos, mesmo se as URLs upstream mudarem.
