import hashlib,json
from pathlib import Path
for name,digest in json.loads(Path('data/raw/checksums.json').read_text()).items():
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest()==digest,name
print('Integridade dos arquivos de entrada aprovada.')
