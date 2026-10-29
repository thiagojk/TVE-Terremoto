# TVE-Terremoto

Teoria dos Valores Extremos aplicada à magnitude de terremotos: análise global e regional por máximos de blocos, com comparação continental e análise α-estável exploratória. Relatório acadêmico em português, R e Quarto.

**Site:** https://thiagojk.github.io/TVE-Terremoto/

## Dados e metodologia

CSV fornecido pelo usuário, correspondente à coleção [Significant Earthquakes, 1965–2016](https://www.kaggle.com/datasets/usgs/earthquake-database), USGS/Kaggle. O bruto (~2,4 MB) permanece inalterado. Explosões e rock burst não integram a amostra de terremotos. Datas ISO misturadas ao formato americano são tratadas explicitamente. Não são convertidas escalas de magnitude por aproximações não verificadas.

Máximos trimestrais, semestrais e anuais; GEV por máxima verossimilhança com múltiplos inícios; IC95% por 399 réplicas de bootstrap circular de blocos contíguos. Ljung–Box e ACF são diagnósticos e não critérios de seleção por maior p-valor. A classificação continental usa interseção ponto-em-polígono (sp) com países Natural Earth 1:50m e o atributo CONTINENT. Sem buffers ou costa mais próxima: pontos fora dos polígonos ficam em Áreas oceânicas/outros. A convenção da fonte atribui a Rússia à Europa e a Turquia à Ásia; não são inventadas fronteiras internas. GEV regional exige 52 anos com registros; categorias incompletas permanecem apenas descritivas, sem substituir lacunas por zero. A tentativa α-estável usa fBasics::stableFit(type="q"), estimador de quantis de McCulloch, em Nolan S0/pm=0; não é uma estimação iterativa e não modela o corte inferior.

**Limitação central:** há dependência anual e evidência favorável à localização linear no tempo. Os retornos estacionários são resumos condicionais históricos; não são previsões operacionais nem um estudo de perigo sísmico local. Mistura de escalas, truncamento e mudanças de cobertura limitam a inferência. Consulte as tabelas e os diagnósticos antes de interpretar retornos longos.

O PDF OPME fornecido foi lido como referência de organização, não como fonte de resultados de terremotos. Ele não é redistribuído neste repositório.

## Executar localmente

Requisitos: R **4.5.2**, Quarto **1.8.27**, compilador C/C++ se instalar dependências do código-fonte. Linux pode exigir `libuv1-dev` (pacote R fs). Apenas `evd`, `jsonlite`, `sp`, `fBasics`, `stabledist`, `knitr`, `rmarkdown` e `renv`, com suas dependências, são necessários. Nenhum download de dados é feito durante a análise.

```sh
git clone https://github.com/thiagojk/TVE-Terremoto.git
cd TVE-Terremoto
Rscript -e 'install.packages("renv"); renv::restore(prompt=FALSE)'
quarto render
Rscript tests/validate.R
python3 tests/validate_html.py
quarto preview
```

`quarto render` executa o pipeline via `pre-render` e produz `docs/`. Para somente recalcular resultados: `Rscript R/run.R`. A semente fixa é 20261029. Os CSV/TXT de `tables/` e PNG de `figures/` são regenerados; esses diretórios são reservados a produtos do pipeline. O render falha se houver erro; warnings estatísticos não são indiscriminadamente ocultados. O relatório lê tabelas calculadas, evitando números fictícios.

## Estrutura

- `R/`: funções reutilizáveis e etapas de importação, descrição, GEV, continentes, distribuição estável, mapas e sensibilidade.
- `data/raw/`: CSV original, costa e polígonos de países Natural Earth, proveniência e checksums.
- `data/processed/`: CSV limpo e objetos R gerados pelo pipeline.
- `tables/`, `figures/`: resultados recalculados.
- `index.qmd`, `relatorio.qmd`, `reproducibilidade.qmd`: site e relatório sequencial.
- `assets/leaflet/`: Leaflet 1.9.4 e licença; o mapa não necessita de tiles externos.
- `tests/`: verificações de máximos, quantis, convergência, regiões e arquivos HTML locais.
- `renv.lock`, `renv/`: versões das dependências e ativação.
- `.github/workflows/publish.yml`: restauração, render, validação e Pages.

## Atualizar os dados

Substitua `data/raw/Terremoto.csv` e documente sua origem. Revise nomes, escalas, período de cobertura, exclusões e checksums. Os denominadores de exposição e a validação usam os 52 anos 1965–2016; uma nova cobertura exige revisão explícita desses elementos. Execute novamente todo o pipeline e releia diagnósticos e conclusões. Nunca modifique o bruto para corrigir valores silenciosamente.

## Publicar no GitHub Pages

Em Settings → Pages → Build and deployment, escolha **GitHub Actions**. O workflow é disparado por push em `main` ou manualmente por `workflow_dispatch`. O artefato publicado é exatamente `docs/`. A publicação requer permissão Pages no repositório; falha de configuração não deve ser confundida com sucesso do render. O site usa caminhos relativos, incluindo o iframe Leaflet, para funcionar no subdiretório `/TVE-Terremoto/`.

## Fontes e licenças

As referências estão em `referencias.bib`. Dados: USGS/Kaggle. Costa: Natural Earth (domínio público). Leaflet: BSD-2-Clause, licença em `assets/leaflet/LICENSE`. A licença da raiz aplica-se ao código original do projeto, sem substituir as licenças das fontes incorporadas.
