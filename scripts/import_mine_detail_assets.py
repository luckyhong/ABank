"""Import only reviewed life assets, preserving other asset configuration edits."""
from pathlib import Path
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported/MineDetails'
rows=json.loads((SOURCE/'analysis/resources.json').read_text());lookup={r['source']:r for r in rows if r.get('preview')}
def pair(name):return [f'Assets/{name}_Normal@{s}x.png' for s in [2,3]]
recipes={
 'amount_eye_open':'LHEyeOpenIcon.png','amount_eye_closed':'LHEyeCloseicon.png',
 'info':'ABCFortune_Star_TipIcon.png','wealth_checkup':'wealth_test_native500.png',
 'toolbar_service':pair('客服_黑'),'toolbar_search':pair('huinong_nav_searchbar_search_black')}
manifest=[]
for name,sources in recipes.items():
 sources=[sources] if isinstance(sources,str) else sources;asset='abc_mine_detail_'+name;folder='Menu' if name.startswith('menu_') else 'Toolbar' if name.startswith('toolbar_') else 'Decorations';d=DEST/folder/(asset+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for source in sources:
  r=lookup[source];m=re.search(r'@([23])x\.',source);scale=m[1] if m else '3';filename='image@'+scale+'x.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/filename)
  images.append({'idiom':'universal','scale':scale+'x','filename':filename});manifest.append({'asset':asset,'source':source,'sha256':r['sha256'],'width':r['width'],'height':r['height'],'scale':scale+'x'})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:(p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-mine-detail-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print('Mine details:',len(recipes),'sets',len(manifest),'images')
