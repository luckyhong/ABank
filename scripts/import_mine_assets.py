"""Import only reviewed mine assets, preserving other asset configuration edits."""
from pathlib import Path
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported/Mine'
rows=json.loads((SOURCE/'analysis/resources.json').read_text());lookup={r['source']:r for r in rows if r.get('preview')}
def pair(name):return [f'Assets/{name}_Normal@{s}x.png' for s in [2,3]]
recipes={
 'stats_background':'hp_mine_userinfo_bg.png','finance_header_background':'hp_mine_title_bg.png','toolbar_logout':'hp_my_logout_white.png','toolbar_search':'hp_my_search_white.png','toolbar_settings':'hp_my_settings_white.png','toolbar_more':'hp_my_more_white.png',
 'profile_avatar':'comm_portrait_boy_native.png','profile_star':pair('hp_mine_userrights_star_level'),'profile_benefits':pair('hp_mine_userrights_center'),
 'amount_eye_open':'homepage_mine_eyeopen.png','amount_eye_closed':'homepage_mine_eyeclose.png',
 'branch_refresh':pair('hp_mine_nearbyoutlets_refresh_all'),'branch_open':pair('hp_mine_nearbyoutlets_opencard'),'branch_coin':pair('hp_mine_nearbyoutlets_commecoin'),'branch_replace':pair('hp_mine_nearbyoutlets_changecard'),'branch_find':pair('hp_mine_nearbyoutlets_find'),
 'security_login':'safecenter_login_setting_700_native500.png','security_transfer':'safecenter_trans_setting_700_native500.png','security_payment':'safecenter_pay_setting_700_native500.png','security_devices':'safecenter_trusted_device_1100_native500.png',
 'manager_wechat':pair('hp_mine_customermanger_wechat')}
manifest=[]
for name,sources in recipes.items():
 sources=[sources] if isinstance(sources,str) else sources;asset='abc_mine_'+name;folder='Menu' if name.startswith('menu_') else 'Toolbar' if name.startswith('toolbar_') else 'Decorations';d=DEST/folder/(asset+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for source in sources:
  r=lookup[source];m=re.search(r'@([23])x\.',source);scale=m[1] if m else '3';filename='image@'+scale+'x.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/filename)
  images.append({'idiom':'universal','scale':scale+'x','filename':filename});manifest.append({'asset':asset,'source':source,'sha256':r['sha256'],'width':r['width'],'height':r['height'],'scale':scale+'x'})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:(p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-mine-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print('Mine:',len(recipes),'sets',len(manifest),'images')
