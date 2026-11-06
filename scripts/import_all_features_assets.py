#!/usr/bin/env python3
"""从工程内已导入的 Loose 素材生成“全部功能”编辑角标的语义 imageset。

不依赖 artifacts/ 原包目录。工程内 Loose 图片是导入时转换过的 PNG，与原包字节不同；
因此校验复制结果与工程内来源图逐字节一致，并在清单中同时记录原包哈希与工程内文件哈希。
"""
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOOSE = ROOT / 'ABank/Assets.xcassets/ABCImported/Loose/Main'
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/AllFeatures'
GAP_ASSETS = ROOT / 'docs/abc-feature-gap-assets.json'
MANIFEST = ROOT / 'docs/abc-all-features-resource-manifest.json'

MAPPING = {
    'abc_allmenus_add': ('hp_allmenus_icon_add.png', 'abc_resource_hp_allmenus_icon_add_b8a98a9e1ab8'),
    'abc_allmenus_delete': ('hp_allmenus_icon_delete.png', 'abc_resource_hp_allmenus_icon_delete_c7006f39f5d4'),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    gap = json.loads(GAP_ASSETS.read_text())
    rows = gap if isinstance(gap, list) else gap.get('assets', gap.get('candidates', []))
    by_source = {row['source']: row for row in rows}

    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}) + '\n')

    manifest = []
    for semantic, (source, loose_name) in MAPPING.items():
        source_set = LOOSE / f'{loose_name}.imageset'
        expected = by_source[source]['source_sha256']
        target_set = DEST / f'{semantic}.imageset'
        if target_set.exists():
            shutil.rmtree(target_set)
        shutil.copytree(source_set, target_set)
        image = target_set / 'image.png'
        actual = sha256(image)
        source_hash = sha256(source_set / 'image.png')
        if actual != source_hash:
            print(f'SHA-256 mismatch for {semantic}: {actual} != {source_hash}', file=sys.stderr)
            return 1
        manifest.append({
            'semantic_name': semantic,
            'source': source,
            'source_sha256': expected,
            'imported_sha256': actual,
            'dimensions': by_source[source].get('dimensions', [45, 45]),
            'copied_from': str(source_set.relative_to(ROOT)),
            'imageset': str(target_set.relative_to(ROOT)),
            'scale': '1x（原包仅提供 1x，不虚构 2x/3x）',
            'rendering': 'original',
        })
        print(target_set.relative_to(ROOT))

    MANIFEST.write_text(json.dumps({'module': 'AllFeatures', 'assets': manifest}, ensure_ascii=False, indent=2) + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
