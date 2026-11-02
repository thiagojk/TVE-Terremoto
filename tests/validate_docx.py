"""Validação estrutural do artefato Word publicado, sem depender do Microsoft Word."""
from pathlib import Path
from zipfile import ZipFile
import re
import xml.etree.ElementTree as ET
p=Path('docs/relatorio.docx')
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'm':'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'r':'http://schemas.openxmlformats.org/package/2006/relationships'}
with ZipFile(p) as z:
    assert z.testzip() is None
    for name in z.namelist():
        if name.endswith(('.xml','.rels')): ET.fromstring(z.read(name))
    doc=ET.fromstring(z.read('word/document.xml'))
    paragraphs=[''.join(q.itertext()) for q in doc.findall('.//w:p',ns)]
    # Visible textual runs avoid XML instruction noise when checking removed prose.
    visible=[''.join(q.itertext()) for q in doc.findall('.//w:t',ns)]
    text=' '.join(visible)
    assert not re.search(r'(?:α|alfa|alpha)[ -]?estáve|Nolan|McCulloch|stabledist|fBasics',text,re.I)
    assert 'Teoria dos Valores Extremos' in text
    assert 'United States Geological Survey' in text
    assert 'Conclusão' in text and 'Referências' in text
    assert len(doc.findall('.//w:tbl',ns))>=18,'Tabelas perderam estrutura nativa'
    assert len(doc.findall('.//m:oMath',ns))>=2,'Equações não foram preservadas em matemática nativa'
    media=[n for n in z.namelist() if n.startswith('word/media/')]
    assert len(media)>=15,'Figuras estáticas não foram incorporadas'
    # Cada figura e tabela possui legenda; a numeração deve acompanhar o HTML.
    for word,count in [('Figura',15),('Tabela',18)]:
        nums=[]
        for q in doc.findall('.//w:p',ns):
            t=''.join(e.text or '' for e in q.findall('.//w:t',ns))
            match=re.match(word+r'\s+(\d+)\b',t.strip())
            if match:nums.append(int(match.group(1)))
        assert nums==list(range(1,count+1)),(word,nums)
    rel=ET.fromstring(z.read('word/_rels/document.xml.rels'))
    external=[e.get('Target','') for e in rel if e.get('TargetMode')=='External']
    assert any('earthquake.usgs.gov/data/comcat/' in s for s in external)
    assert not any(s.endswith('.qmd') or s.startswith(('tables/','data/','figures/')) for s in external)
    assert any('thiagojk.github.io/TVE-Terremoto/mapa.html' in s for s in external)
print('Word: pacote íntegro, 15 figuras, 18 tabelas, equações nativas, legendas e referências validados.')
