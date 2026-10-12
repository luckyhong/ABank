"""Import decoded local ABC media; no network or account data is used."""
from pathlib import Path
import json,re,hashlib,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported'
rows=json.loads((SOURCE/'analysis/resources.json').read_text())
by_source={r['source']:r for r in rows if r.get('preview')}
# Explicit, reviewed mappings for the first page. Library aliases stay discoverable in the manifest.
home={
 'abc_home_account':['myaccount_kk.png'],
 'abc_home_transfer':['transfer_new_kk.png'],
 'abc_home_income':['income_detail_kk.png'],
 'abc_home_scan':['bar_code_kk.png'],
 'abc_home_credit':['credit_home_native500.png'],
 'abc_home_pension_community':['pension_native500.png'],
 'abc_home_inclusive':['GD_eloanapp_native500.png'],
 'abc_home_deposit':['deposit_native500.png'],
 'abc_home_wealth':['home_finance_native500.png'],
 'abc_home_loan':['my_loan_overview_native500.png'],
 'abc_home_payment':['Assets/home_life_menu_recharge_Normal@2x.png','Assets/home_life_menu_recharge_Normal@3x.png'],
 'abc_home_activity':['pop_activity_webview_native500.png'],
 'abc_home_city':['city_zone_native500.png'],
 'abc_home_all':['homepage_more_native500.png'],
 'abc_home_branch_open':['Assets/图标_我要开卡_Normal@2x.png','Assets/图标_我要开卡_Normal@3x.png'],
 'abc_home_branch_coin':['Assets/图标_纪念币_Normal@2x.png','Assets/图标_纪念币_Normal@3x.png'],
 'abc_home_branch_replace':['Assets/图标_同号换卡_Normal@2x.png','Assets/图标_同号换卡_Normal@3x.png'],
 'abc_home_branch_logo':['Assets/图标_农行logo_Normal@2x.png','Assets/图标_农行logo_Normal@3x.png'],
 'abc_home_branch_refresh':['Assets/图标_网点服务刷新_标题_Normal@2x.png','Assets/图标_网点服务刷新_标题_Normal@3x.png'],
}
for name,source in [('gift','抽奖_白'),('version','版本_白'),('service','客服_白'),('message','消息_白'),('search','huinong_nav_searchbar_search_white'),('mic','huinong_nav_searchbar_voice_white')]:
 home['abc_home_'+name]=[f'Assets/{source}_Normal@{scale}x.png' for scale in [2,3]]

for name, source in [('home', 'main'), ('wealth', 'invest'), ('life', 'mall'), ('news', 'news'), ('mine', 'my')]:
 for state, suffix in [('normal', ''), ('selected', '_s')]:
  home[f'abc_tab_{name}_{state}'] = [f'{source}_native_600{suffix}@{scale}x.png' for scale in [2, 3]]

def scale(r):
 m=re.search(r'@([123])x(?:_\d+)?\.',r['source'])
 if m:return m[1]+'x'
 # The 96px native500 menus and colored shortcuts were shipped for 3x phones.
 if len(Path(r['source']).parts)==1 and (r['source'].endswith('native500.png') or r['source'].endswith('_kk.png')):return '3x'
 return '1x'

def save_set(name,rs,folder):
 d=DEST/folder/(name+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for i,r in enumerate(rs):
  # GIF frame zero is explicitly rasterized for UIImage; original animation stays in local extraction.
  f='image'+('' if len(rs)==1 else '@'+scale(r))+'.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/f)
  images.append({'idiom':'universal','filename':f,'scale':scale(r)})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
 return str(d.relative_to(ROOT))
manifest=[];sha_to_asset={};home_map={}
for name,sources in home.items():
 rs=[by_source[s] for s in sources];path=save_set(name,rs,'TabBar' if name.startswith('abc_tab_') else 'Home');home_map[name]=sources
 for r in rs:sha_to_asset.setdefault(r['sha256'],(name,path))
for r in rows:
 if not r.get('preview'):continue
 key=r['sha256']
 if key not in sha_to_asset:
  slug=re.sub('[^A-Za-z0-9_]+','_',Path(r['source']).stem).strip('_')[:48] or 'image'
  name='abc_resource_'+slug+'_'+key[:12]
  folder=('Catalog' if r['kind']=='catalog-image' else 'Loose')+('/Main' if r['scope']=='main-app' else '/Bundles')
  sha_to_asset[key]=(name,save_set(name,[r],folder))
 name,path=sha_to_asset[key]
 manifest.append({'source':r['source'],'source_kind':r['kind'],'source_sha256':key,'asset_name':name,'imageset':path,'source_width':r['width'],'source_height':r['height'],'scale':scale(r),'animation_policy':'first-frame' if r['source'].lower().endswith('.gif') else None})
used_paths={str(DEST/folder/(name+'.imageset')) for name in home for folder in ['TabBar' if name.startswith('abc_tab_') else 'Home']}
used_paths.update(str(ROOT/path) for _,path in sha_to_asset.values())
for existing in DEST.rglob('abc_resource_*.imageset'):
 if str(existing) not in used_paths:shutil.rmtree(existing)
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:
 (p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-resource-manifest.json').write_text(json.dumps({'app_version':'11.3.0','build':'11.3.1','home':home_map,'resources':manifest,'excluded':['yw_1222.jpg (strict decode failed)','PackedImage / MultiSized catalog records without an exported image']},ensure_ascii=False,indent=2)+'\n')
print('Imported',len(manifest),'source images into',len(list(DEST.rglob('*.imageset'))),'image sets; Home',len(home))
