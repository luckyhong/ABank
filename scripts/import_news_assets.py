"""Import only reviewed news assets, preserving other asset configuration edits."""
from pathlib import Path
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'artifacts/abc-resources'
DEST=ROOT/'ABank/Assets.xcassets/ABCImported/News'
rows=json.loads((SOURCE/'analysis/resources.json').read_text());lookup={r['source']:r for r in rows if r.get('preview')}
def pair(name):return [f'Assets/{name}_Normal@{s}x.png' for s in [2,3]]
recipes={
 'hero_finance_background':pair('ABCInformationHeadPlaceImg'),'header_flash':pair('ABCInformationFlash'),'header_videos':pair('ABCInformationVideo'),'header_ranking':pair('ABCInformationHotList'),'header_topic':pair('ABCInformationTopic'),
 'rank_first':pair('ABCInformationHotList1'),'rank_second':pair('ABCInformationHotList2'),'rank_third':pair('ABCInformationHotList3'),'badge_hot':pair('ABCInformationListhot'),'badge_new':pair('ABCInformationListnew'),
 'category_edit':pair('ABCInformationTagEdit'),'topic_hot':pair('ABCNoFollowWatchHot'),'tag_topic':pair('ABCInformationTagTopic'),'tag_video':pair('ABCInformationTagVideo'),
 'placeholder_article':pair('ABCFollowNormalPlaceImg'),'placeholder_photo':pair('ABCFollowPhotoPlaceImg'),'placeholder_video':pair('ABCInformationVideoPlaceImg'),'placeholder_video_horizontal':pair('ABCFollowVideoHorizonPlaceImg'),
 'toolbar_scan':pair('扫一扫_黑'),'toolbar_service':pair('客服_黑'),'toolbar_message':pair('消息_黑'),'toolbar_search':pair('huinong_nav_searchbar_search_black'),'toolbar_microphone':pair('huinong_nav_searchbar_voice_black')}
manifest=[]
for name,sources in recipes.items():
 sources=[sources] if isinstance(sources,str) else sources;asset='abc_news_'+name;folder='Menu' if name.startswith('menu_') else 'Toolbar' if name.startswith('toolbar_') else 'Decorations';d=DEST/folder/(asset+'.imageset');d.mkdir(parents=True,exist_ok=True);images=[]
 for source in sources:
  r=lookup[source];m=re.search(r'@([23])x\.',source);scale=m[1] if m else '3';filename='image@'+scale+'x.png'
  with Image.open(SOURCE/r['preview']) as im:im.convert('RGBA').save(d/filename)
  images.append({'idiom':'universal','scale':scale+'x','filename':filename});manifest.append({'asset':asset,'source':source,'sha256':r['sha256'],'width':r['width'],'height':r['height'],'scale':scale+'x'})
 (d/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
for p in [DEST,*[p for p in DEST.rglob('*') if p.is_dir() and not p.name.endswith('.imageset')]]:(p/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-news-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');print('News:',len(recipes),'sets',len(manifest),'images')
