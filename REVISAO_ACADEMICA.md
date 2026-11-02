# Revisão acadêmica — 02/11/2026

Revisão textual e bibliográfica: não foram alterados os scripts de análise, os dados, os parâmetros de configuração, os critérios de elegibilidade ou os gráficos. O escopo permanece em máximos de blocos/GEV e comparação continental. Não foram recuperadas análises excluídas e não foi criado ZIP.

Foram ampliados introdução, objetivo geral, objetivos específicos, referencial teórico e conclusão. A redação metodológica explicita a unidade ajustada, a magnitude original, a reamostragem circular e os limites dos diagnósticos. Foram retiradas as atribuições a outro trabalho no relatório e no README, sem substituir por uma informação não documentada.

## Referências verificadas

Existência e metadados conferidos em páginas editoriais, arquivo oficial de R News, documentação institucional e registros bibliográficos. O teste automático de citações não substitui essa conferência documental.

| Chave | Fonte de verificação | Aplicação |
|---|---|---|
| coles2001 | https://link.springer.com/book/10.1007/978-1-4471-3675-0 | estimação, diagnóstico e retorno |
| embrechts1997 | https://link.springer.com/book/10.1007/978-3-642-33483-2 | fundamentos e comportamento de cauda |
| dehaan2006 | https://link.springer.com/book/10.1007/0-387-34471-3 | convergência e domínios de atração |
| leadbetter1983 | https://link.springer.com/book/10.1007/978-1-4612-5449-2 | extremos de sequências dependentes |
| fishertippett1928 | https://doi.org/10.1017/S0305004100015681 ; registro Cambridge Core, 24(2), 180–190, 1928 | tipos limites |
| ljungbox1978 | https://academic.oup.com/biomet/article-abstract/65/2/297/236869 | autocorrelação; Biometrika 65(2), 297–303 |
| kunsch1989 | https://doi.org/10.1214/aos/1176347265 ; https://www.jstor.org/stable/i312909 ; https://cir.nii.ac.jp/crid/1362544419497266176 | reamostragem dependente; Annals of Statistics 17(3), 1217–1241 |
| stephenson2002 | https://journal.r-project.org/articles/RN-2002-015/ | evd; R News 2(2), 31–32 |
| pebesma2005 | https://journal.r-project.org/articles/RN-2005-014/ | sp; R News 5(2), 9–13 |
| usgs | https://earthquake.usgs.gov/earthquakes/search/ | catálogo |
| usgsformat | https://earthquake.usgs.gov/data/comcat/ | documentação ComCat |
| usgscatalogs | https://earthquake.usgs.gov/data/comcat/catalog/ | fontes contribuintes |
| neic | https://www.usgs.gov/programs/earthquake-hazards/national-earthquake-information-center-neic | papel do NEIC |
| naturalearth | https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-land/ | costa |
| naturalearthcountries | https://www.naturalearthdata.com/downloads/50m-cultural-vectors/ | polígonos continentais |

Novas entradas: de Haan e Ferreira (2006), Leadbetter, Lindgren e Rootzén (1983), Fisher e Tippett (1928), Ljung e Box (1978) e Künsch (1989). Citações inseridas na introdução, no referencial e na explicação da metodologia. Os links de R News foram corrigidos, e os anos não documentados de páginas USGS foram substituídos por datas de acesso. Nenhuma entrada existente precisou ser excluída: as atribuições retiradas estavam no texto, não no BibTeX.

`tests/validate_bibliography.py` confere chaves duplicadas, entradas não citadas, citações sem entrada e resolução no HTML. As validações estatísticas e a comparação dos produtos calculados antes e depois da revisão verificam a preservação dos resultados.
