#!/usr/bin/env python3
"""把安全中心线性图标从原包图片导入工程。

来源：artifacts/abc-resources/images（Git 忽略，本机采集；originals/ 下同名文件为 iOS 优化格式，不可直接读取）。
原图为 96×96 单倍图，只放入 imageset 的 3x 槽位（显示 32pt），不虚构 2x；逐字节复制并校验 SHA-256，清单写入 docs/。
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources/images'
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/Security'
MANIFEST = ROOT / 'docs/abc-security-resource-manifest.json'

# 语义名: (原包文件名, 用途)
MAPPING = {
    'abc_security_center': ('safecenter_home_700_native500.png', '安全中心状态卡'),
    'abc_security_login': ('safecenter_login_setting_700_native500.png', '登录设置行'),
    'abc_security_transfer': ('safecenter_trans_setting_700_native500.png', '转账设置行'),
    'abc_security_payment': ('safecenter_pay_setting_700_native500.png', '支付设置行'),
    'abc_security_devices': ('safecenter_trusted_device_1100_native500.png', '登录设备行与设备列表'),
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
    for semantic, (source, usage) in MAPPING.items():
        src = SOURCE / source
        target = DEST / f'{semantic}.imageset'
        target.mkdir(exist_ok=True)
        name = f'{semantic}@3x.png'
        (target / name).write_bytes(src.read_bytes())
        digest = sha256(src)
        if sha256(target / name) != digest:
            print(f'SHA-256 不一致：{name}', file=sys.stderr)
            return 1
        contents = {
            'images': [
                {'idiom': 'universal', 'scale': '1x'},
                {'idiom': 'universal', 'scale': '2x'},
                {'idiom': 'universal', 'scale': '3x', 'filename': name},
            ],
            'info': {'author': 'xcode', 'version': 1},
        }
        (target / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')
        assets.append({'semantic_name': semantic, 'usage': usage, 'rendering': 'original',
                       'imageset': str(target.relative_to(ROOT)),
                       'files': [{'scale': '3x', 'source': source, 'sha256': digest}]})
        print(f'{semantic} <- {source} {digest}')
    MANIFEST.write_text(json.dumps({'module': 'Security', 'source_root': 'artifacts/abc-resources/images',
                                    'assets': assets}, ensure_ascii=False, indent=1) + '\n')
    print(f'导入 {len(assets)} 个安全中心图标')
    return 0


if __name__ == '__main__':
    sys.exit(main())
