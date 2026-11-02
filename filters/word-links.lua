-- Arquivos suplementares são links absolutos no Word, que pode ser aberto fora do site.
-- Caminhos HTML continuam relativos para a publicação no subdiretório do Pages.
function Link(link)
  if FORMAT ~= 'docx' then return nil end
  local target = link.target
  if target:match('^#') or target:match('^%a[%w+.-]*:') or target:match('^//') then
    return nil
  end
  target = target:gsub('%.qmd', '.html'):gsub('^%./', '')
  link.target = 'https://thiagojk.github.io/TVE-Terremoto/' .. target
  return link
end

-- Tabelas largas recebem fonte menor e larguras proporcionais ao conteúdo no Word.
-- Valores e colunas permanecem intactos; o HTML conserva sua apresentação original.
function Table(tab)
  if FORMAT ~= 'docx' or #tab.colspecs < 7 then return nil end
  local weights = {}
  for i = 1, #tab.colspecs do weights[i] = 3 end
  local function measure(rows)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        local s = pandoc.utils.stringify(cell.contents)
        local n = utf8.len(s) or #s
        local pad = s:match('^[-+%d%.]+$') and 2 or 1
        weights[i] = math.max(weights[i], math.min(n + pad, i == 1 and 24 or 12))
      end
    end
  end
  measure(tab.head.rows)
  for _, body in ipairs(tab.bodies) do measure(body.head); measure(body.body) end
  measure(tab.foot.rows)
  local sum = 0
  for _, n in ipairs(weights) do sum = sum + n end
  for i, spec in ipairs(tab.colspecs) do tab.colspecs[i] = {spec[1], weights[i] / sum} end
  local function small(p)
    p.content = {pandoc.Span(p.content, pandoc.Attr('', {}, {['custom-style']='Table Text'}))}
    return p
  end
  return tab:walk({Plain=small, Para=small})
end
