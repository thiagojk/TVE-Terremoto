from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit,unquote
class Links(HTMLParser):
    def __init__(self): super().__init__();self.links=[];self.ids=set()
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.add(a['id'])
        if tag in ('a','img','script','link','iframe'):
            ref=a.get('href',a.get('src',''))
            if ref:self.links.append(ref)
root=Path('docs');errors=[]
for p in root.rglob('*.html'):
    h=Links();text=p.read_text();h.feed(text)
    assert 'citation not found' not in text.lower(),p
    for ref in h.links:
        u=urlsplit(ref)
        if u.scheme or u.netloc or not u.path:continue
        target=p.parent/unquote(u.path)
        if not target.exists():errors.append((str(p),ref))
assert not errors,errors
assert len(list((root/'figures').glob('*.png')))>=12
assert 'L.circleMarker' in (root/'mapa.html').read_text()
print('HTML, figuras, referências locais e assets Leaflet validados.')
