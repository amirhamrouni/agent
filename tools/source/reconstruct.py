"""Reconstruct the same layered source used by Android CI into a fresh directory."""
import json
from pathlib import Path
import argparse

def reconstruct(repo, out):
    if out.exists() and any(out.iterdir()):
        raise SystemExit('Output must be empty: ' + str(out))
    out.mkdir(parents=True, exist_ok=True)
    for folder in ('raw_source_packs', 'source_overlay_packs'):
        chunks = {}
        for pack in sorted((repo / folder).glob('*.jsonl')):
            for raw in pack.read_text().splitlines():
                if not raw.strip():
                    continue
                row = json.loads(raw)
                rel = Path(row['path'])
                if rel.is_absolute() or '..' in rel.parts:
                    raise SystemExit('UNSAFE_PATH:' + str(rel))
                idx = int(row.get('index', 0))
                if idx in chunks.setdefault(rel, {}):
                    raise SystemExit('DUPLICATE_CHUNK:' + str(rel))
                chunks[rel][idx] = row['content']
        for rel, parts in chunks.items():
            if sorted(parts) != list(range(len(parts))):
                raise SystemExit('NON_CONTIGUOUS:' + str(rel))
            target = out / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(''.join(parts[i] for i in sorted(parts)))
    for src in (repo / 'source_overlay').rglob('*'):
        if src.is_symlink():
            raise SystemExit('SYMLINK_INPUT:' + str(src))
        if src.is_file():
            target = out / src.relative_to(repo / 'source_overlay')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(src.read_bytes())
    print('RECONSTRUCT_PASS', sum(p.is_file() for p in out.rglob('*')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    reconstruct(Path(__file__).resolve().parents[2], args.output.resolve())
