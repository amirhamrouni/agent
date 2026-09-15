"""Regenerate reviewed source pins after an intentional source change."""
from pathlib import Path
import hashlib
import re
import tempfile
from reconstruct import reconstruct
repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    reconstruct(repo, root)
    files = []
    for p in sorted(root.rglob('*')):
        rel = p.relative_to(root)
        if not p.is_file() or rel.name == 'SOURCES.json':
            continue
        if (len(rel.parts) == 1 and rel.name in {'project.godot','export_presets.cfg','RELEASE_METADATA.json','main.tscn','main.gd','main.gd.uid','main_production.tscn'}) or rel.parts[0] in {'autoload','scripts','shaders','data','assets'}:
            files.append((rel.as_posix(), hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_size))
    h = hashlib.sha256()
    for name, digest, size in files:
        h.update(f'{name}\0{digest}\0{size}\n'.encode())
    for p in (repo / '.github/workflows').glob('*.yml'):
        s = p.read_text()
        new = re.sub(r'(EXPECTED_RUNTIME_SOURCE_TREE: )[^\n]+', lambda m: m[1] + "'" + h.hexdigest() + "'", s)
        new = re.sub(r'(EXPECTED_RUNTIME_SOURCE_FILES: )[^\n]+', lambda m: m[1] + "'" + str(len(files)) + "'", new)
        if new != s:
            p.write_text(new)
    print(len(files), h.hexdigest())
