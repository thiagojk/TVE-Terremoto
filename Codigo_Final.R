# =============================================================================
# TEORIA DOS VALORES EXTREMOS APLICADA A TERREMOTOS
# Thiago Carvalho Fernandes — Matrícula: 261102942
# =============================================================================
# Execute as seções em ordem no R ou RStudio (Ctrl+Enter / Cmd+Enter).
# No RStudio: Session > Set Working Directory > To Source File Location.
# A pasta Dados/ deve estar ao lado deste arquivo e conter Terremoto.csv,
# land.geojson e ne_50m_admin_0_countries.geojson (incluídos no ZIP de entrega).
#
# Instale os pacotes uma única vez, se necessário:
# install.packages(c("evd", "jsonlite", "sp"))
#
# Para rodar tudo de uma vez no RStudio:
# source("Codigo_Final.R", encoding = "UTF-8")
#
# As tabelas aparecem no console e ficam disponíveis no ambiente do R.
# Os gráficos aparecem no painel Plots; use as setas do painel para revê-los.
# ACF e gráficos continentais são apresentados um de cada vez para facilitar
# a leitura na tela. Não são criados arquivos, pastas ou relatórios.
# A semente, o bootstrap e os critérios GEV são os da análise final aprovada.

# 1. Preparação ----

options(warn = 1)
set.seed(20261029)

pacotes_necessarios <- c("evd", "jsonlite", "sp")
pacotes_ausentes <- pacotes_necessarios[
  !vapply(pacotes_necessarios, requireNamespace, logical(1), quietly = TRUE)
]

if (length(pacotes_ausentes)) {
  stop(
    "Instale os pacotes necessários antes de continuar: ",
    paste(pacotes_ausentes, collapse = ", ")
  )
}

arquivos_necessarios <- c(
  "Dados/Terremoto.csv",
  "Dados/land.geojson",
  "Dados/ne_50m_admin_0_countries.geojson"
)

if (!all(file.exists(arquivos_necessarios))) {
  stop(
    "Arquivo(s) ausente(s): ",
    paste(arquivos_necessarios[!file.exists(arquivos_necessarios)], collapse = ", "),
    ". Defina como diretório de trabalho a pasta que contém Dados/."
  )
}

# Fora de uma sessão gráfica, o R pode tentar criar Rplots.pdf automaticamente.
# Este teste evita essa gravação; use o RStudio ou uma sessão gráfica do R.
if (dev.cur() == 1L) {
  dispositivo <- getOption("device")
  dispositivo_de_arquivo <- identical(dispositivo, grDevices::pdf) ||
    (is.character(dispositivo) && dispositivo %in% c(
      "pdf", "postscript", "png", "jpeg", "tiff", "bmp", "svg", "cairo_pdf"
    ))

  if (!interactive() || dispositivo_de_arquivo) {
    stop("Execute este código em uma sessão gráfica do R ou no RStudio.")
  }
}

# Esta função apenas desenha no dispositivo gráfico atual, sem exportar.
mostrar_grafico <- function(titulo, codigo) {
  message("Gráfico: ", titulo)
  parametros_anteriores <- par(no.readonly = TRUE)
  on.exit(par(parametros_anteriores))

  par(
    mfrow = c(1, 1),
    mar = c(4.5, 4.5, 3, 1),
    col = "#233445",
    col.axis = "#233445",
    fg = "#233445",
    las = 1
  )

  codigo()
  invisible(NULL)
}

# 2. Funções auxiliares para GEV, bootstrap e classificação geográfica ----

# Convenção evd: xi é o parâmetro de forma. Magnitude na escala original.
# Bootstrap circular: 399 réplicas; comprimento ceil(n^(1/3)).
# Assimetria e excesso de curtose usam momentos empíricos com divisor n.
# Classificação por polígonos WGS84, sem atribuição por costa mais próxima.

gev_fit <- function(x) {
  fits <- lapply(c(-0.2, 0, 0.2), function(s) {
    loc <- mean(x) - 0.3 * sd(x)
    sc <- sd(x)
    if (any(1 + s * (x - loc)/sc <= 0))
      return(NULL)
    tryCatch(evd::fgev(x, start = list(loc = loc, scale = sc, shape = s)), error = function(e) NULL)
  })
  fits <- Filter(function(f) !is.null(f) && f$convergence == "successful" && all(is.finite(f$estimate)),
    fits)
  if (!length(fits))
    stop("GEV: nenhum início convergiu")
  fits[[which.min(sapply(fits, function(f) f$deviance))]]
}

qgev <- function(p, f) evd::qgev(p, loc = f$estimate["loc"], scale = f$estimate["scale"],
  shape = f$estimate["shape"])

gev_boot <- function(x, B = 399) {
  out <- matrix(NA_real_, B, 9, dimnames = list(NULL, c("mu", "sigma", "xi", paste0("z",
    c(2, 5, 10, 20, 50, 100)))))
  for (b in seq_len(B)) {
    L <- ceiling(length(x)^(1/3))
    starts <- sample.int(length(x), ceiling(length(x)/L), replace = TRUE)
    idx <- unlist(lapply(starts, function(j) ((j - 1 + 0:(L - 1))%%length(x)) + 1))[seq_along(x)]
    f <- tryCatch(gev_fit(x[idx]), error = function(e) NULL)
    if (!is.null(f))
      out[b, ] <- c(f$estimate, qgev(1 - 1/c(2, 5, 10, 20, 50, 100), f))
  }
  out
}

ci <- function(x) if (sum(is.finite(x)) >= 30) quantile(x[is.finite(x)], c(0.025, 0.975)) else c(NA,
  NA)

fit_tables <- function(x, label, B = 399) {
  f <- gev_fit(x)
  b <- gev_boot(x, B)
  pars <- data.frame(modelo = label, parametro = c("mu", "sigma", "xi"), estimativa = unname(f$estimate),
    EP = unname(f$std.err), inferior = apply(b[, 1:3], 2, ci)[1, ], superior = apply(b[,
      1:3], 2, ci)[2, ], n = length(x), logLik = -f$deviance/2, AIC = f$deviance +
      6, bootstrap_validos = sum(complete.cases(b)), bootstrap_total = B)
  ret <- data.frame(modelo = label, T = c(2, 5, 10, 20, 50, 100), probabilidade = 1 -
    1/c(2, 5, 10, 20, 50, 100), magnitude = qgev(1 - 1/c(2, 5, 10, 20, 50, 100), f),
    inferior = apply(b[, 4:9], 2, ci)[1, ], superior = apply(b[, 4:9], 2, ci)[2, ])
  list(fit = f, boot = b, pars = pars, ret = ret)
}

block_max <- function(d, months = 12) {
  k <- sprintf("%04d-%02d", d$ano, ((d$mes - 1)%/%months) * months + 1)
  ans <- do.call(rbind, lapply(split(d, k), function(z) z[order(-z$Magnitude, z$timestamp,
    z$ID)[1], ]))
  ans$bloco <- rownames(ans)
  rownames(ans) <- NULL
  ans
}

shape_moments <- function(x) {
  x <- x[is.finite(x)]
  m2 <- mean((x - mean(x))^2)
  c(assimetria = mean((x - mean(x))^3)/m2^(3/2), excesso_curtose = mean((x - mean(x))^4)/m2^2 -
    3)
}

desc <- function(x) {
  x <- x[is.finite(x)]
  c(n = length(x), media = mean(x), mediana = median(x), DP = sd(x), variancia = var(x),
    min = min(x), Q1 = unname(quantile(x, 0.25)), Q3 = unname(quantile(x, 0.75)), P90 = unname(quantile(x,
      0.9)), P95 = unname(quantile(x, 0.95)), P99 = unname(quantile(x, 0.99)), P999 = unname(quantile(x,
      0.999)), max = max(x), shape_moments(x))
}

region_names <- c("África", "América do Norte", "América do Sul", "Ásia", "Europa",
  "Oceania", "Áreas oceânicas/outros")

continent_lookup <- c(Africa = "África", `North America` = "América do Norte", `South America` = "América do Sul",
  Asia = "Ásia", Europe = "Europa", Oceania = "Oceania")

geo_load <- function() jsonlite::fromJSON("Dados/ne_50m_admin_0_countries.geojson", simplifyVector = FALSE)

geo_polygons <- function(feature) {
  if (feature$geometry$type == "Polygon")
    list(feature$geometry$coordinates)
  else feature$geometry$coordinates
}

classify_continents <- function(lon, lat, geo) {
  hits <- vector("list", length(lon))
  for (j in seq_along(geo$features)) {
    f <- geo$features[[j]]
    for (poly in geo_polygons(f)) {
      ring <- do.call(rbind, lapply(poly[[1]], unlist))
      k <- which(lon >= min(ring[, 1]) & lon <= max(ring[, 1]) & lat >= min(ring[,
        2]) & lat <= max(ring[, 2]))
      if (!length(k))
        next
      inside <- sp::point.in.polygon(lon[k], lat[k], ring[, 1], ring[, 2]) > 0
      if (length(poly) > 1)
        for (h in poly[-1]) {
         hole <- do.call(rbind, lapply(h, unlist))
         inside <- inside & sp::point.in.polygon(lon[k], lat[k], hole[, 1], hole[,
          2]) == 0
        }
      for (i in k[inside]) hits[[i]] <- union(hits[[i]], j)
    }
  }
  country <- vapply(hits, function(h) paste(sort(unique(vapply(h, function(j) geo$features[[j]]$properties$ADMIN,
    character(1)))), collapse = "; "), character(1))
  labels <- lapply(hits, function(h) unique(na.omit(unname(continent_lookup[vapply(h,
    function(j) geo$features[[j]]$properties$CONTINENT, character(1))]))))
  region <- vapply(labels, function(h) if (length(h) == 1)
    h
  else tail(region_names, 1), character(1))
  reason <- vapply(seq_along(hits), function(i) {
    if (!length(hits[[i]]))
      "Fora dos polígonos"
    else if (length(labels[[i]]) == 1)
      "Polígono continental"
    else if (length(labels[[i]]) > 1)
      "Fronteira continental ambígua"
    else "Polígono fora dos seis continentes"
  }, character(1))
  data.frame(regiao = region, pais_poligono = country, criterio_geografico = reason)
}

# 3. Importação, tratamento e auditoria dos dados ----

raw <- read.csv("Dados/Terremoto.csv", check.names = FALSE, na.strings = c("", "NA"), stringsAsFactors = FALSE)

stopifnot(all(c("Date", "Time", "Latitude", "Longitude", "Magnitude", "Depth", "Magnitude Type",
  "ID", "Type") %in% names(raw)))

auditoria_colunas <- data.frame(coluna = names(raw), classe = sapply(raw, class), ausentes = sapply(raw,
  function(x) sum(is.na(x))))

cat("\nauditoria colunas:\n")

print(auditoria_colunas)

raw$timestamp <- as.POSIXct(paste(raw$Date, raw$Time), format = "%m/%d/%Y %H:%M:%S", tz = "UTC")

iso <- grepl("T", raw$Date, fixed = TRUE)

raw$timestamp[iso] <- as.POSIXct(raw$Date[iso], format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")

invalid <- is.na(raw$timestamp) | !is.finite(raw$Magnitude) | abs(raw$Latitude) > 90 |
  abs(raw$Longitude) > 180 | !is.finite(raw$Depth)

auditoria <- data.frame(metrica = c("Registros brutos", "Datas ISO", "IDs duplicados",
  "Linhas duplicadas", "Inválidos essenciais", "Profundidades negativas", "Eventos não sísmicos"),
  valor = c(nrow(raw), sum(iso), sum(duplicated(raw$ID)), sum(duplicated(raw[, 1:21])),
    sum(invalid), sum(raw$Depth < 0, na.rm = TRUE), sum(raw$Type != "Earthquake")))

cat("\nauditoria:\n")

print(auditoria)

exclusoes <- raw[invalid | raw$Type != "Earthquake", ]

cat("\nexclusoes:\n")

print(exclusoes)

fontes_eventos <- as.data.frame(table(raw$Source, useNA = "ifany"))

cat("\nfontes eventos:\n")

print(fontes_eventos)

d <- raw[!invalid & raw$Type == "Earthquake" & !duplicated(raw$ID), ]

d$data <- as.Date(d$timestamp, tz = "UTC")

d$ano <- as.integer(format(d$data, "%Y"))

d$mes <- as.integer(format(d$data, "%m"))

d$semestre <- (d$mes - 1)%/%6 + 1

d$trimestre <- (d$mes - 1)%/%3 + 1

d$decada <- d$ano%/%10 * 10

geo <- geo_load()

d <- cbind(d, classify_continents(d$Longitude, d$Latitude, geo))

auditoria_geografica <- as.data.frame(table(d$regiao, d$criterio_geografico))

cat("\nauditoria geografica:\n")

print(auditoria_geografica)

# 4. Análise descritiva e gráficos exploratórios ----

descritiva <- data.frame(medida = names(desc(d$Magnitude)), Magnitude = desc(d$Magnitude),
  Depth = desc(d$Depth))

cat("\ndescritiva:\n")

print(descritiva)

tipos_evento <- as.data.frame(table(raw$Type, useNA = "ifany"))

cat("\ntipos evento:\n")

print(tipos_evento)

tipos_magnitude <- as.data.frame(table(d$`Magnitude Type`, useNA = "ifany"))

cat("\ntipos magnitude:\n")

print(tipos_magnitude)

tipos_por_ano <- as.data.frame(table(d$ano, d$`Magnitude Type`, useNA = "ifany"))

cat("\ntipos por ano:\n")

print(tipos_por_ano)

eventos_ano <- as.data.frame(table(d$ano))

cat("\neventos ano:\n")

print(eventos_ano)

maiores <- head(d[order(-d$Magnitude, d$timestamp), c("data", "Magnitude", "Depth", "Latitude",
  "Longitude", "Magnitude Type", "ID", "regiao")], 20)

cat("\nmaiores:\n")

print(maiores)

mostrar_grafico("exploratoria", function() {
  par(mfrow = c(2, 2))
  hist(d$Magnitude, breaks = 35, prob = TRUE, col = "#b8ded8", main = "Distribuição da magnitude",
    xlab = "Magnitude")
  lines(density(d$Magnitude), col = "#007f78", lwd = 2)
  boxplot(d$Magnitude, horizontal = TRUE, main = "Dispersão da magnitude", xlab = "Magnitude",
    col = "#b8ded8")
  hist(d$Depth, breaks = 45, col = "#b8ded8", main = "Profundidade", xlab = "Profundidade (km)")
  plot(d$Depth, d$Magnitude, pch = 16, cex = 0.25, col = adjustcolor("#007f78", 0.15),
    main = "Magnitude e profundidade", xlab = "Profundidade (km)", ylab = "Magnitude")
})

mostrar_grafico("temporal", function() {
  par(mfrow = c(2, 1))
  plot(table(d$ano), type = "h", main = "Terremotos catalogados por ano", xlab = "Ano",
    ylab = "Eventos")
  plot(d$data, d$Magnitude, pch = 16, cex = 0.3, col = adjustcolor("#007f78", 0.2), main = "Magnitude ao longo do tempo",
    xlab = "Data", ylab = "Magnitude")
})

mostrar_grafico("escalas", function() {
  mat <- table(d$`Magnitude Type`, d$ano)
  barplot(prop.table(mat, 2), space = 0, col = hcl.colors(nrow(mat), "Spectral"), border = NA,
    xlab = "Ano", ylab = "Proporção", main = "Composição das escalas de magnitude")
  legend("topright", rownames(mat), fill = hcl.colors(nrow(mat), "Spectral"), cex = 0.65,
    ncol = 3)
})

# 5. Máximos de blocos, ACF, GEV e níveis de retorno ----

blocks <- lapply(c(3, 6, 12), function(m) block_max(d, m))

names(blocks) <- c("Trimestral", "Semestral", "Anual")

models <- lapply(names(blocks), function(n) fit_tables(blocks[[n]]$Magnitude, n))

names(models) <- names(blocks)

a <- blocks$Anual

global <- models$Anual

maximos_anuais <- a

cat("\nmaximos anuais:\n")

print(maximos_anuais)

parametros_blocos <- do.call(rbind, lapply(models, `[[`, "pars"))

cat("\nparametros blocos:\n")

print(parametros_blocos)

retorno_blocos <- do.call(rbind, lapply(models, `[[`, "ret"))

cat("\nretorno blocos:\n")

print(retorno_blocos)

bs <- do.call(rbind, lapply(seq_along(blocks), function(i) {
  x <- blocks[[i]]$Magnitude
  p <- models[[i]]$pars[3, ]
  data.frame(bloco = names(blocks)[i], meses = c(3, 6, 12)[i], blocos_esperados = 52 *
    c(4, 2, 1)[i], maximos = length(x), vazios = 52 * c(4, 2, 1)[i] - length(x), media = mean(x),
    DP = sd(x), min = min(x), max = max(x), lag = 10, Ljung_Box = Box.test(x, lag = 10,
      type = "Ljung-Box")$p.value, xi = p$estimativa, inf = p$inferior, sup = p$superior)
}))

comparacao_blocos <- bs

cat("\ncomparacao blocos:\n")

print(comparacao_blocos)

gev_global <- global$pars

cat("\ngev global:\n")

print(gev_global)

retorno_global <- global$ret

cat("\nretorno global:\n")

print(retorno_global)

probabilidades <- data.frame(magnitude = c(7, 7.5, 8, 8.5, 9), probabilidade = 1 - evd::pgev(c(7,
  7.5, 8, 8.5, 9), loc = global$fit$estimate[1], scale = global$fit$estimate[2], shape = global$fit$estimate[3]))

cat("\nprobabilidades:\n")

print(probabilidades)

mostrar_grafico("maximos", function() plot(a$ano, a$Magnitude, type = "b", pch = 16, col = "#007f78",
  main = "Máximos anuais globais", xlab = "Ano", ylab = "Magnitude máxima"))

acf_table <- do.call(rbind, lapply(names(blocks), function(n) {
  x <- blocks[[n]]$Magnitude
  corr <- as.numeric(acf(x, lag.max = 15, plot = FALSE)$acf)[-1]
  data.frame(bloco = n, lag = seq_along(corr), acf = corr, banda = 1.96/sqrt(length(x)),
    fora_banda = abs(corr) > 1.96/sqrt(length(x)))
}))

acf_maximos <- acf_table

cat("\nacf maximos:\n")

print(acf_maximos)

mostrar_grafico("acf", function() {
  # Uma ACF por gráfico; resultados anteriores ficam no histórico de Plots.
  for (n in names(blocks)) acf(blocks[[n]]$Magnitude, main = paste("ACF:", n), lag.max = 15)
})

mostrar_grafico("diagnostico_gev", function() {
  par(mfrow = c(2, 2))
  x <- sort(a$Magnitude)
  p <- ppoints(length(x))
  plot(qgev(p, global$fit), x, main = "QQ: GEV anual", xlab = "Quantis ajustados", ylab = "Quantis observados")
  abline(0, 1, col = "#d07732")
  plot(p, evd::pgev(x, loc = global$fit$estimate[1], scale = global$fit$estimate[2],
    shape = global$fit$estimate[3]), main = "PP: GEV anual", xlab = "Probabilidade empírica",
    ylab = "Probabilidade ajustada")
  abline(0, 1, col = "#d07732")
  hist(x, prob = TRUE, breaks = 10, col = "#b8ded8", main = "Densidade anual", xlab = "Magnitude")
  xx <- seq(min(x) - 0.1, max(x) + 0.3, length.out = 300)
  lines(xx, evd::dgev(xx, loc = global$fit$estimate[1], scale = global$fit$estimate[2],
    shape = global$fit$estimate[3]), col = "#007f78", lwd = 2)
  r <- global$ret
  plot(r$T, r$magnitude, log = "x", type = "b", ylim = range(r[, 4:6]), main = "Níveis de retorno e IC95%",
    xlab = "Período (anos)", ylab = "Magnitude")
  arrows(r$T, r$inferior, r$T, r$superior, angle = 90, code = 3, length = 0.04, col = "#007f78")
})

# 6. Comparação continental ----

# Elegibilidade: pelo menos 30 máximos e cobertura dos 52 anos.
# Anos sem registros são NA; não são substituídos por magnitude zero.

regional <- list()

coverage <- list()

regional_max <- list()

regional_desc <- list()

for (n in region_names) {
  z <- d[d$regiao == n, ]
  b <- if (nrow(z))
    block_max(z)
  else NULL
  series <- merge(data.frame(ano = 1965:2016), if (is.null(b))
    data.frame(ano = integer(), Magnitude = double())
  else b[, c("ano", "Magnitude")], by = "ano", all.x = TRUE, sort = TRUE)
  series$regiao <- n
  regional_max[[n]] <- series
  observed <- sum(is.finite(series$Magnitude))
  eligible <- observed >= 30 && observed == 52
  reason <- if (eligible)
    "Cobertura completa; ajuste elegível"
  else "Sem GEV: anos sem registros ou menos de 30 máximos"
  if (eligible) {
    result <- tryCatch(fit_tables(series$Magnitude, n), error = function(e) e)
    if (inherits(result, "error"))
      reason <- paste("Sem GEV:", conditionMessage(result))
    else regional[[n]] <- result
  }
  coverage[[n]] <- data.frame(regiao = n, eventos = nrow(z), anos = observed, anos_vazios = 52 -
    observed, ajuste = reason)
  if (observed)
    regional_desc[[n]] <- data.frame(regiao = n, t(desc(series$Magnitude)))
}

cobertura_regional <- do.call(rbind, coverage)

cat("\ncobertura regional:\n")

print(cobertura_regional)

maximos_regionais <- do.call(rbind, regional_max)

cat("\nmaximos regionais:\n")

print(maximos_regionais)

descritiva_regional <- do.call(rbind, regional_desc)

cat("\ndescritiva regional:\n")

print(descritiva_regional)

gev_regional <- do.call(rbind, lapply(regional, `[[`, "pars"))

cat("\ngev regional:\n")

print(gev_regional)

retorno_regional <- do.call(rbind, lapply(regional, `[[`, "ret"))

cat("\nretorno regional:\n")

print(retorno_regional)

regional_acf <- do.call(rbind, lapply(names(regional), function(n) {
  x <- regional_max[[n]]$Magnitude
  data.frame(regiao = n, Ljung_Box = Box.test(x, lag = 10, type = "Ljung-Box")$p.value)
}))

dependencia_regional <- regional_acf

cat("\ndependencia regional:\n")

print(dependencia_regional)

cols <- setNames(c(hcl.colors(6, "Dark 3"), "#7d8a94"), region_names)

mostrar_grafico("regional_series", function() {
  par(mar = c(4.5, 4.5, 3, 1))
  for (n in region_names) {
    x <- regional_max[[n]]
    plot(x$ano, x$Magnitude, type = "b", pch = 16, cex = 0.45, col = cols[n], xlim = c(1965,
      2016), ylim = range(d$Magnitude), main = n, xlab = "Ano", ylab = "Máximo anual")
  }
  message("Anos sem registros são lacunas (NA), não magnitudes iguais a zero.")
})

mostrar_grafico("regional_distribuicoes", function() {
  par(mar = c(8, 4, 3, 1))
  boxplot(lapply(regional_max, `[[`, "Magnitude"), names = region_names, las = 2, col = cols,
    cex.axis = 0.75, ylab = "Magnitude máxima anual", main = "Distribuição dos máximos anuais observados")
})

mostrar_grafico("regional_xi", function() {
  pp <- do.call(rbind, lapply(regional, function(z) z$pars[3, ]))
  par(mar = c(4.5, 11, 3, 1))
  plot(pp$estimativa, seq_len(nrow(pp)), xlim = range(pp[, 5:6]), yaxt = "n", pch = 16,
    col = cols[pp$modelo], xlab = "xi e IC95% bootstrap", ylab = "", main = "Forma da GEV por região com cobertura completa")
  axis(2, seq_len(nrow(pp)), pp$modelo, las = 1, cex.axis = 0.8)
  segments(pp$inferior, seq_len(nrow(pp)), pp$superior, seq_len(nrow(pp)), col = cols[pp$modelo],
    lwd = 2)
  abline(v = 0, lty = 2, col = "#a0a0a0")
})

mostrar_grafico("regional_retornos", function() {
  par(mar = c(4, 4, 3, 1))
  for (n in names(regional)) {
    r <- regional[[n]]$ret
    plot(r$T, r$magnitude, log = "x", type = "b", pch = 16, col = cols[n], ylim = range(r[,
      4:6]), main = n, xlab = "Período de retorno (anos)", ylab = "Magnitude")
    lines(r$T, r$inferior, col = cols[n], lty = 3)
    lines(r$T, r$superior, col = cols[n], lty = 3)
  }
})

mostrar_grafico("regional_curvas", function() {
  ret <- do.call(rbind, lapply(regional, `[[`, "ret"))
  plot(NA, xlim = c(2, 100), ylim = range(ret$magnitude), log = "x", xlab = "Período de retorno (anos)",
    ylab = "Magnitude", main = "Curvas de retorno: categorias com 52 máximos")
  for (n in names(regional)) {
    r <- regional[[n]]$ret
    lines(r$T, r$magnitude, col = cols[n], lwd = 2)
  }
  legend("topleft", names(regional), col = cols[names(regional)], lty = 1, cex = 0.8,
    bg = "white")
})

# 7. Mapas no painel de gráficos ----

land <- jsonlite::fromJSON("Dados/land.geojson", simplifyVector = FALSE)

world <- function(title) {
  plot(NA, xlim = c(-180, 180), ylim = c(-90, 90), xlab = "Longitude", ylab = "Latitude",
    main = title, asp = NA)
  for (f in land$features) {
    polys <- if (f$geometry$type == "Polygon")
      list(f$geometry$coordinates)
    else f$geometry$coordinates
    for (poly in polys) {
      xy <- do.call(rbind, lapply(poly[[1]], unlist))
      polygon(xy[, 1], xy[, 2], col = "#e5e9ec", border = "#a2afb7", lwd = 0.3)
    }
  }
}

mostrar_grafico("mapa_global", function() {
  world("Terremotos — fonte documentada: USGS/NEIC")
  points(d$Longitude, d$Latitude, pch = 16, cex = 0.15 + (d$Magnitude - 5.5) * 0.18,
    col = adjustcolor("#007f78", 0.18))
})

mostrar_grafico("mapa_extremos", function() {
  world("Eventos com magnitude ≥ 8 (limiar descritivo)")
  z <- d[d$Magnitude >= 8, ]
  points(z$Longitude, z$Latitude, pch = 21, cex = 0.5 + (z$Magnitude - 7) * 0.7, bg = "#d07732",
    col = "white")
})

mostrar_grafico("mapa_maximos", function() {
  world("Localização dos máximos anuais")
  points(a$Longitude, a$Latitude, pch = 21, cex = 0.7 + (a$Magnitude - 7) * 0.6, bg = "#007f78",
    col = "white")
})

mostrar_grafico("mapa_regioes", function() {
  world("Classificação continental: polígonos Natural Earth 1:50m")
  for (f in geo$features) {
    region <- unname(continent_lookup[f$properties$CONTINENT])
    color <- if (is.na(region))
      "#e5e9ec"
    else adjustcolor(cols[region], 0.35)
    for (poly in geo_polygons(f)) {
      xy <- do.call(rbind, lapply(poly[[1]], unlist))
      polygon(xy[, 1], xy[, 2], col = color, border = "#a2afb7", lwd = 0.3)
    }
  }
  points(d$Longitude, d$Latitude, pch = 16, cex = 0.1 + (d$Magnitude - 5.5) * 0.12, col = adjustcolor(cols[d$regiao],
    0.35))
  legend("bottomleft", region_names, pch = 16, col = cols, cex = 0.65, bg = "white")
})

# 8. Consulta dos resultados em memória ----

# Os objetos abaixo podem ser abertos também pelo painel Environment do RStudio:
# d: terremotos tratados; blocks: máximos por período; models: ajustes por período;
# global: ajuste GEV anual global; regional: ajustes GEV continentais elegíveis;
# gev_global e retorno_global: tabelas globais;
# gev_regional e retorno_regional: tabelas continentais.
# O bootstrap pode levar alguns minutos, dependendo do computador.

message("Análise concluída. Tabelas no console e gráficos no painel Plots.")
