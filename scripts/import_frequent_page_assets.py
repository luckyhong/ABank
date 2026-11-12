"""Import reviewed, local high-frequency service icons; never downloads or deletes artwork."""
from pathlib import Path
import json
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources'
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/Services'
recipes = {'abc_statement_monthly':'month_bills_native500.png', 'abc_statement_receipt':'receiptinitact_webview_native500.png',
           'abc_ledger_credit_repayment':'credit_trans_repay_native500.png', 'abc_ledger_fund':'home_fund_native500.png', 'abc_home_bill_banner':'ABCHPAdImage.png',
           'abc_home_beans_banner':'LHMengCengbanner.png', 'abc_home_life_banner':'huinong_hp_recommend.png'}
lookup = {r['source']:r for r in json.loads((SOURCE/'analysis/resources.json').read_text())}
DEST.mkdir(parents=True,exist_ok=True); (DEST/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
manifest = []
for asset,source in recipes.items():
    row=lookup[source];folder=DEST/(asset+'.imageset');folder.mkdir(exist_ok=True)
    with Image.open(SOURCE/row['preview']) as im: im.convert('RGBA').save(folder/'icon@3x.png')
    (folder/'Contents.json').write_text(json.dumps({'images':[{'idiom':'universal','scale':'3x','filename':'icon@3x.png'}], 'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
    manifest.append({'asset':asset,'source':source,'sha256':row['sha256'],'width':row['width'],'height':row['height'],'scale':'3x'})
(ROOT/'docs/abc-frequent-page-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Imported',len(recipes),'reviewed service icons')
