"""Import only reviewed life assets, preserving other asset configuration edits."""
from pathlib import Path
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported/Life'
rows=json.loads((SOURCE/'analysis/resources.json').read_text());lookup={r['source']:r for r in rows if r.get('preview')}
def pair(name):return [f'Assets/{name}_Normal@{s}x.png' for s in [2,3]]
recipes={
 'menu_payment':pair('home_life_menu_recharge'),'menu_mobile':pair('home_life_menu_phoneRecharge'),'menu_government':pair('home_life_menu_people'),'menu_social':pair('home_life_menu_social'),'menu_beans':pair('home_life_menu_xiaodou'),'menu_campus':pair('home_life_menu_school'),'menu_cafeteria':pair('home_life_menu_cafeteria'),'menu_party':'party_dues_webview_native500.png','menu_car':'car_zone_native500.png','menu_market':pair('home_life_menu_shop'),
 'menu_hospital':'hospitalizing_service_native500.png','menu_provident':'XM_AccmFund_native500.png','menu_transport':'nb_etc_bus_native500.png','menu_points':'credit_pointmall_webview_native500.png','menu_all':'homepage_more_native500.png',
 'toolbar_orders':pair('订单_黑'),'toolbar_coupons':pair('卡券_黑'),'toolbar_location':pair('定位_黑'),'toolbar_search':pair('huinong_nav_searchbar_search_black'),'toolbar_microphone':pair('huinong_nav_searchbar_voice_black'),
 'activity_beans':pair('home_life_xiaodou'),'activity_rural':pair('home_life_xiangcun'),'activity_offers':pair('home_life_youhui'),'banner_payment':pair('home_life_topAd_first'),'banner_events':pair('home_life_topAd_second'),'promo_food':pair('home_life_meishi')}
manifest=[]
for name,sources in recipes.items():
 sources=[sources] if isinstance(sources,str) else sources;asset='abc_life_'+name;folder='Menu' if name.startswith('menu_') else 'Toolbar' if name.startswith('toolbar_') else 'Decorations';d=DEST/folder/(asset+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for source in sources:
  r=lookup[source];m=re.search(r'@([23])x\.',source);scale=m[1] if m else '3';filename='image@'+scale+'x.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/filename)
  images.append({'idiom':'universal','scale':scale+'x','filename':filename});manifest.append({'asset':asset,'source':source,'sha256':r['sha256'],'width':r['width'],'height':r['height'],'scale':scale+'x'})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:(p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-life-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print('Life:',len(recipes),'sets',len(manifest),'images')
