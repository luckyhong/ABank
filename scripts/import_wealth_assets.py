"""Import only reviewed wealth assets, preserving other asset configuration edits."""
from pathlib import Path
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported/Wealth'
rows=json.loads((SOURCE/'analysis/resources.json').read_text());lookup={r['source']:r for r in rows if r.get('preview')}
recipes={
 'menu_deposit':'deposit_index_native500.png','menu_wealth':'home_finance_native500.png','menu_fund':'home_fund_native500.png','menu_metals':'precious_metal_zone_native500.png','menu_bonds':'bond_zone_native500.png','menu_insurance':'insurance_plan_native500.png','menu_securities':'securities_native500.png','menu_forex':'foreign_exchange_zone_native500.png','menu_pension':'pension_zone_native500.png','menu_all':'homepage_more_native500.png',
 'header_spare_money':'ABCFortune_CurrentDepositZone_Title_Img.png','header_steady_growth':'ABCFortune_Finance_Title_Img.png','header_income_advance':'ABCFortune_Fund_Title_Img.png','header_deposits':'ABCFortune_FixDeposit_Title_Img.png','header_bonds':'ABCFortune_Bond_Title_Img.png','hotspot':'ABCFortune_News_financial_img.png','login_background':'ABCFortune_Position_small_bg_img.png','ribbon_hot':'ABCFortune_HotSell.png','ribbon_selected':'ABCFortune_FirstSelect.png','spare_featured_background':'ABCFortune_CurrentDepositZone_SSF_bg.png','spare_keb2_background':'ABCFortune_CurrentDepositZone_KEB2_bg.png','spare_keb_background':'ABCFortune_CurrentDepositZone_KEB_bg.png'}
for name,source in [('scan','扫一扫_黑'),('service','客服_黑'),('message','消息_黑'),('search','huinong_nav_searchbar_search_black'),('microphone','huinong_nav_searchbar_voice_black')]:recipes['toolbar_'+name]=[f'Assets/{source}_Normal@{s}x.png' for s in [2,3]]
manifest=[]
for name,sources in recipes.items():
 sources=[sources] if isinstance(sources,str) else sources;asset='abc_wealth_'+name;folder='Menu' if name.startswith('menu_') else 'Toolbar' if name.startswith('toolbar_') else 'Decorations';d=DEST/folder/(asset+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for source in sources:
  r=lookup[source];m=re.search(r'@([23])x\.',source);scale=m[1] if m else '3';filename='image@'+scale+'x.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/filename)
  images.append({'idiom':'universal','scale':scale+'x','filename':filename});manifest.append({'asset':asset,'source':source,'sha256':r['sha256'],'width':r['width'],'height':r['height'],'scale':scale+'x'})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:(p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-wealth-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print('Wealth:',len(recipes),'sets',len(manifest),'images')
