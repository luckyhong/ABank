#!/usr/bin/env python3
"""把通用界面图标（导航返回、网点电话/定位）从原包 Assets.car 导出图导入工程。

来源：artifacts/abc-resources/catalog-images/Assets（Git 忽略，本机采集）。
保留原包的 @2x/@3x，不虚构 1x；逐字节复制并校验 SHA-256，清单写入 docs/。
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources/catalog-images/Assets'
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/Common'
MANIFEST = ROOT / 'docs/abc-common-resource-manifest.json'

# 语义名: (原包资源名, 渲染方式, 用途)
MAPPING = {
    'abc_nav_back': ('UPSDK_icon_back_Normal', 'template', '全局导航返回箭头（随导航栏 tint 着色）'),
    'abc_branch_phone': ('hp_mine_nearbyoutlets_phone_Normal', 'original', '首页网点服务-拨打电话'),
    'abc_branch_location': ('hp_mine_nearbyoutlets_location_Normal', 'original', '首页网点服务-地图定位'),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if not SOURCE.is_dir():
        print(f'缺少本机资源目录：{SOURCE}', file=sys.stderr)
        return 1
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
    assets = []
    for semantic, (source, rendering, usage) in MAPPING.items():
        target = DEST / f'{semantic}.imageset'
        target.mkdir(exist_ok=True)
        images, files = [{'idiom': 'universal', 'scale': '1x'}], []
        for scale in ('2x', '3x'):
            src = SOURCE / f'{source}@{scale}.png'
            name = f'{semantic}@{scale}.png'
            data = src.read_bytes()
            (target / name).write_bytes(data)
            if sha256(target / name) != sha256(src):
                print(f'SHA-256 不一致：{name}', file=sys.stderr)
                return 1
            images.append({'idiom': 'universal', 'scale': scale, 'filename': name})
            files.append({'scale': scale, 'source': f'{source}@{scale}.png', 'sha256': sha256(src)})
        contents = {'images': images, 'info': {'author': 'xcode', 'version': 1}}
        if rendering == 'template':
            contents['properties'] = {'template-rendering-intent': 'template'}
        (target / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')
        assets.append({'semantic_name': semantic, 'usage': usage, 'rendering': rendering,
                       'imageset': str(target.relative_to(ROOT)), 'files': files})
    MANIFEST.write_text(json.dumps({'module': 'Common', 'source_root': 'artifacts/abc-resources/catalog-images/Assets',
                                    'assets': assets}, ensure_ascii=False, indent=1) + '\n')
    print(f'导入 {len(assets)} 个通用图标')
    return 0


if __name__ == '__main__':
    sys.exit(main())
