from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit,unquote
import re
class Links(HTMLParser):
    def __init__(self): super().__init__();self.links=[];self.ids=set()
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.add(a['id'])
        if tag in ('a','img','script','link','iframe'):
            ref=a.get('href',a.get('src',''))
            if ref:self.links.append(ref)
root=Path('docs');errors=[];parsed={}
for p in root.rglob('*.html'):
    h=Links();text=p.read_text();h.feed(text);parsed[p]=h
    assert 'citation not found' not in text.lower(),p
    if p.parent==root:
        assert not re.search(r'\b(?:POT|GPD)\b|Flinn|Gardner|ObsPy|declustering|thresholds',text),p
for p,h in parsed.items():
    for ref in h.links:
        u=urlsplit(ref)
        if u.scheme or u.netloc:continue
        target=p.parent/unquote(u.path) if u.path else p
        if not target.exists():errors.append((str(p),ref))
        elif u.fragment and target in parsed and unquote(u.fragment) not in parsed[target].ids:
            errors.append((str(p),ref))
assert not errors,errors
assert len(list((root/'figures').glob('*.png')))>=14
assert not any((root/'figures').glob('*gpd*'))
assert not (root/'tables/thresholds.csv').exists()
assert 'L.circleMarker' in (root/'mapa.html').read_text()
assert 'Região continental:' in (root/'mapa.html').read_text()
print('HTML, âncoras, figuras, mapa e remoção de resultados antigos validados.')
