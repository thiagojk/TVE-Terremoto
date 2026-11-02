# TVE-Terremoto

Teoria dos Valores Extremos aplicada à magnitude de terremotos: análise global e regional por máximos de blocos, com comparação continental. Relatório acadêmico em português, R e Quarto.

**Site:** https://thiagojk.github.io/TVE-Terremoto/

## Dados e metodologia

Registros históricos de procedência documentada **USGS/NEIC**, com catálogos e redes contribuintes do [ANSS ComCat](https://earthquake.usgs.gov/data/comcat/). A análise utiliza a cópia arquivada `data/raw/Terremoto.csv` (1965–2016), sem nova coleta direta. A documentação da coleção e os metadados de origem foram confrontados com a lista oficial de catálogos; não se comprovou equivalência integral com o serviço atual. A cadeia de distribuição e os limites dessa verificação estão em [PROVENIENCIA.md](data/raw/PROVENIENCIA.md).

O bruto (~2,4 MB) permanece inalterado. Explosões e rock burst não integram a amostra de terremotos. Datas ISO misturadas ao formato americano são tratadas explicitamente. Não são convertidas escalas de magnitude por aproximações não verificadas.

Máximos trimestrais, semestrais e anuais; GEV por máxima verossimilhança com múltiplos inícios; IC95% por 399 réplicas de bootstrap circular de blocos contíguos. Ljung–Box e ACF são diagnósticos e não critérios de seleção por maior p-valor. A classificação continental usa interseção ponto-em-polígono (sp) com países Natural Earth 1:50m e o atributo CONTINENT. Sem buffers ou costa mais próxima: pontos fora dos polígonos ficam em Áreas oceânicas/outros. A convenção da fonte atribui a Rússia à Europa e a Turquia à Ásia; não são inventadas fronteiras internas. GEV regional exige 52 anos com registros; categorias incompletas permanecem apenas descritivas, sem substituir lacunas por zero.

**Limitação central:** há dependência anual. Os retornos estacionários são resumos condicionais históricos; não são previsões operacionais nem um estudo de perigo sísmico local. Mistura de escalas, truncamento e mudanças de cobertura limitam a inferência. Consulte as tabelas e os diagnósticos antes de interpretar retornos longos.

O PDF OPME fornecido foi lido como referência de organização, não como fonte de resultados de terremotos. Ele não é redistribuído neste repositório.

## Executar localmente

Requisitos: R **4.5.2**, Quarto **1.8.27**, compilador C/C++ se instalar dependências do código-fonte. Linux pode exigir `libuv1-dev` (pacote R fs). Apenas `evd`, `jsonlite`, `sp`, `knitr`, `rmarkdown` e `renv`, com suas dependências, são necessários. Nenhum download de dados é feito durante a análise.

```sh
git clone https://github.com/thiagojk/TVE-Terremoto.git
cd TVE-Terremoto
Rscript -e 'install.packages("renv"); renv::restore(prompt=FALSE)'
quarto render
Rscript tests/validate.R
python3 tests/validate_html.py
python3 tests/validate_docx.py
quarto preview
```

`quarto render` executa o pipeline via `pre-render` e produz o HTML e o Word em `docs/`. O workflow usa explicitamente `quarto render --to all`. O botão **Baixar relatório em Word** no início do relatório HTML baixa `docs/relatorio.docx`, recriado no mesmo render. O DOCX incorpora figuras estáticas e equações nativas; o mapa interativo é disponibilizado por link. Para somente recalcular resultados: `Rscript R/run.R`. A semente fixa é 20261029. Os CSV/TXT de `tables/` e PNG de `figures/` são regenerados; esses diretórios são reservados a produtos do pipeline. O render falha se houver erro; warnings estatísticos não são indiscriminadamente ocultados. O relatório lê tabelas calculadas, evitando números fictícios.

## Estrutura

- `R/`: funções reutilizáveis e etapas de importação, descrição, GEV, continentes, mapas.
- `data/raw/`: CSV original, costa e polígonos de países Natural Earth, proveniência e checksums.
- `data/processed/`: CSV limpo e objetos R gerados pelo pipeline.
- `tables/`, `figures/`: resultados recalculados.
- `index.qmd`, `relatorio.qmd`, `reproducibilidade.qmd`: site e relatório sequencial.
- `assets/leaflet/`: Leaflet 1.9.4 e licença; o mapa não necessita de tiles externos.
- `tests/`: verificações de máximos, quantis, convergência, regiões e arquivos HTML locais.
- `templates/reference.docx`, `filters/word-links.lua`: estilo e links da versão Word.
- `renv.lock`, `renv/`: versões das dependências e ativação.
- `.github/workflows/publish.yml`: restauração, render, validação e Pages.

## Atualizar os dados

Substitua `data/raw/Terremoto.csv` e documente sua origem. Revise nomes, escalas, período de cobertura, exclusões e checksums. Os denominadores de exposição e a validação usam os 52 anos 1965–2016; uma nova cobertura exige revisão explícita desses elementos. Execute novamente todo o pipeline e releia diagnósticos e conclusões. Nunca modifique o bruto para corrigir valores silenciosamente.

## Publicar no GitHub Pages

Em Settings → Pages → Build and deployment, escolha **GitHub Actions**. O workflow é disparado por push em `main` ou manualmente por `workflow_dispatch`. O artefato publicado é exatamente `docs/`. A publicação requer permissão Pages no repositório; falha de configuração não deve ser confundida com sucesso do render. O site usa caminhos relativos, incluindo o iframe Leaflet, para funcionar no subdiretório `/TVE-Terremoto/`.

## Fontes e licenças

As referências estão em `referencias.bib`. Procedência documentada dos registros: USGS/NEIC, com redes e catálogos contribuintes; veja a nota de procedência. Costa: Natural Earth (domínio público). Leaflet: BSD-2-Clause, licença em `assets/leaflet/LICENSE`. A licença da raiz aplica-se ao código original do projeto, sem substituir as licenças das fontes incorporadas.
