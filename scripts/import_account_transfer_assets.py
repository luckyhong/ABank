"""Import reviewed MyAccount/Transfer artwork without changing other resource groups."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources'
lookup = {r['source']: r for r in json.loads((SOURCE/'analysis/resources.json').read_text()) if r.get('preview')}
recipes = {
    'abc_account_bank_logo': 'credit_nong_logo.png',
    'abc_account_toolbar_service': 'hp_mine_customerservice.png',
    'abc_transfer_notice_speaker': 'homepage_mine_horn.png',
    'abc_transfer_record': 'hp_mine_order_all.png',
    'abc_transfer_multiple': 'cust_manager_native500.png',
    'abc_transfer_donation': 'hospitalizing_service_native500.png',
    'abc_transfer_partner_avatar': 'comm_portrait_boy_native.png',
}
manifest = []

def save_asset(name, sources, origin):
    group = 'Account' if name.startswith('abc_account_') else 'Transfer'
    folder = ROOT/'ABank/Assets.xcassets/ABCImported'/group/'Original'/(name+'.imageset')
    folder.mkdir(parents=True, exist_ok=True)
    images = []
    for source, path, scale in sources:
        filename = f'image@{scale}x{path.suffix}'
        shutil.copyfile(path, folder/filename)
        images.append({'idiom':'universal', 'scale':f'{scale}x', 'filename':filename})
        with Image.open(path) as im: dimensions = list(im.size)
        manifest.append({'asset':name, 'source':source, 'origin':origin, 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'dimensions':dimensions, 'scale':f'{scale}x'})
    (folder/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
    for parent in (folder.parent, folder.parent.parent):
        (parent/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')

for name, source in recipes.items():
    row = lookup[source]
    match = re.search(r'@([23])x', source)
    save_asset(name, [(source, SOURCE/row['preview'], int(match[1]) if match else 3)], 'extracted_abc_ipa')

# The matching seasonal banner already existed in this repository; retain all scales.
banner = ROOT/'ABank/Assets.xcassets/my_account_credit_ad.imageset'
save_asset('abc_account_credit_banner', [(str((banner/f'my_account_credit_ad{suffix}.jpg').relative_to(ROOT)), banner/f'my_account_credit_ad{suffix}.jpg', scale) for scale,suffix in [(1,''),(2,'@2x'),(3,'@3x')]], 'existing_project_artwork')
save_asset('abc_transfer_bank_ccb_wordmark', [('https://www.ccb.com/chn/fileDir/bg_image/2020031015231379393.png', SOURCE/'external/ccb-official-logo.png', 1)], 'official_ccb_website')
(ROOT/'docs/abc-account-transfer-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(f'Imported {len(recipes)+2} assets / {len(manifest)} images')
