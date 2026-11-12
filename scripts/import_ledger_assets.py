"""Import reviewed local ledger artwork with semantic names and reproducible provenance."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources'
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/Ledger'
RECIPES = {
    'mobile_recharge': 'LHPhoneRecharge.png',
    'life_payment': 'LHLifeRechrge.png',
    'interest': 'ck_interestrate_native500.png',
    'cash_withdrawal': 'huinong_hp_menu_nocardwithdraw.png',
    'cash_deposit': 'income_detail_native500.png',
    'loan_repayment': 'my_loan_overview_native500.png',
    'wealth': 'monetary_fund_native500.png',
    'other': 'income_detail_native500.png',
}
rows = {r['source']: r for r in json.loads((SOURCE / 'analysis/resources.json').read_text())}
DEST.mkdir(parents=True, exist_ok=True)
(DEST / 'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
manifest = []
for name, source in RECIPES.items():
    row = rows[source]
    asset = 'abc_ledger_' + name
    folder = DEST / (asset + '.imageset')
    folder.mkdir(parents=True, exist_ok=True)
    path = SOURCE / row['preview']
    with Image.open(path) as image:
        image.convert('RGBA').save(folder / 'icon@3x.png')
    contents = {'images': [{'idiom': 'universal', 'scale': '3x', 'filename': 'icon@3x.png'}],
                'info': {'author': 'xcode', 'version': 1}, 'properties': {'template-rendering-intent': 'original'}}
    (folder / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')
    manifest.append({'asset': asset, 'source': source, 'source_sha256': row['sha256'],
                     'preview': row['preview'], 'preview_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                     'width': row['width'], 'height': row['height'], 'scale': '3x'})
(ROOT / 'docs/abc-ledger-resource-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(f'Imported {len(manifest)} reviewed ledger imagesets')
