"""Confere correspondência entre citações e entradas; não substitui verificação editorial."""
from pathlib import Path
import re
bib=Path('referencias.bib').read_text()
entries=re.findall(r'@\w+\s*\{\s*([^,\s]+)',bib)
assert len(entries)==len(set(entries)),'Chaves bibliográficas duplicadas'
cited=set()
for p in Path('.').glob('*.qmd'):
    refs=re.findall(r'(?<![\w/])@([A-Za-z][A-Za-z0-9_-]*)',p.read_text())
    cited.update(k for k in refs if not k.startswith(('eq-','fig-','tbl-','sec-')))
assert cited==set(entries),{'sem_entrada':cited-set(entries),'nao_citadas':set(entries)-cited}
html=Path('docs/relatorio.html').read_text()
assert all(f'id="ref-{key}"' in html for key in cited)
assert not re.search(r'citation not found|\?\?\?\s*(?:eq|tbl|fig)',html,re.I)
print(f'{len(entries)} referências citadas, sem entradas ausentes ou não utilizadas.')
