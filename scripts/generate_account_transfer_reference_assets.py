"""Rebuild screenshot-only transfer artwork on a 32pt grid at 2x and 3x."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/Transfer/Reference'
GRAY, GREEN, GOLD = '#606460', '#2cbea2', '#eab645'
FONT = '/System/Library/Fonts/STHeiti Light.ttc'
manifest = []

def artwork(name, paint, size=(32, 32)):
    asset_name = 'abc_account_' + name.removeprefix('account_') if name.startswith('account_') else 'abc_transfer_' + name
    group = ROOT / 'ABank/Assets.xcassets/ABCImported/Account/Reference' if name.startswith('account_') else DEST
    group.mkdir(parents=True, exist_ok=True)
    (group/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
    folder = group / (asset_name + '.imageset')
    folder.mkdir(parents=True, exist_ok=True)
    im = Image.new('RGBA', (size[0]*12, size[1]*12))
    d = ImageDraw.Draw(im)
    def line(points, color=GRAY, width=1.4):
        d.line([(round(x*12), round(y*12)) for x,y in points], fill=color, width=round(width*12), joint='curve')
    def box(rect, color=GRAY, width=1.4, radius=0, fill=None):
        d.rounded_rectangle(tuple(round(v*12) for v in rect), radius=round(radius*12), outline=color, width=round(width*12), fill=fill)
    def ellipse(rect, color=GRAY, width=1.4, fill=None):
        d.ellipse(tuple(round(v*12) for v in rect), outline=color, width=round(width*12), fill=fill)
    def arc(rect, start, end, color=GRAY, width=1.4):
        d.arc(tuple(round(v*12) for v in rect), start, end, fill=color, width=round(width*12))
    def text(x,y,value,color=GREEN,sz=10):
        d.text((x*12,y*12),value,font=ImageFont.truetype(FONT,round(sz*12)),fill=color,anchor='mm')
    overlay = paint(d,line,box,ellipse,arc,text)
    if overlay is not None:
        im.alpha_composite(overlay)
    images=[]
    for scale in (2,3):
        filename=f'image@{scale}x.png'
        im.resize((size[0]*scale,size[1]*scale),Image.Resampling.LANCZOS).save(folder/filename)
        images.append({'idiom':'universal','scale':f'{scale}x','filename':filename})
    (folder/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'template-rendering-intent':'original'}},indent=2)+'\n')
    manifest.append({'asset':asset_name,'origin':'reconstructed_from_user_screenshots','logicalSize':list(size),'scales':['2x','3x'],'generator':'scripts/generate_account_transfer_reference_assets.py'})

def primary_cards(d,l,b,e,a,t):
    b((3,5,25,20),color='white',width=1,radius=.5)
    l([(25,10),(29,10),(29,25),(7,25),(7,20)],'white',1)
    l([(3,10),(25,10)],'white',1)

def primary_phone(d,l,b,e,a,t):
    b((3,3,15,29),color='white',width=1,radius=1)
    l([(6,6),(12,6)],'white',1);e((8,25,10,27),color='white',width=1)
    b((15,9,29,25),color='white',width=1,radius=1);t(22,17,'¥','white',14)

def repay(d,l,b,e,a,t):
    l([(4,25),(3,25),(3,5),(27,5),(27,17)])
    l([(3,11),(27,11)])
    l([(21,26),(28,26),(25,23)],GREEN)

def schedule(d,l,b,e,a,t):
    a((3,3,27,28),30,330);t(14,15,'¥',GRAY,18)
    e((21,20,31,30),GREEN,1.2,fill='white');l([(26,22),(26,25),(29,25)],GREEN,1.1)

def other_bank(d,l,b,e,a,t):
    a((3,3,28,29),25,330);t(14,15,'¥',GRAY,18)
    l([(27,23),(22,23),(22,27),(29,27),(29,30),(25,30)],GREEN,1.4)
    l([(24,20),(21,23),(24,25)],GREEN,1.4)

def crossborder(d,l,b,e,a,t):
    a((2,2,30,30),10,170);a((2,2,30,30),190,350)
    l([(1,12),(2,5),(9,3)]);l([(23,29),(29,27),(31,20)])
    l([(7,22),(24,15),(25,12),(16,15),(10,9),(8,10),(12,18),(7,20),(7,22)],'#ef939b',1.2)

def mobile_collection(d,l,b,e,a,t):
    l([(22,30),(5,30),(5,3),(26,3),(26,18)])
    l([(9,7),(22,7)],GRAY,1);t(16,16,'¥',GRAY,16)
    e((21,21,31,31),GREEN,1.2);t(26,26,'✓',GREEN,8)

def cancel(d,l,b,e,a,t):
    l([(27,16),(27,5),(3,5),(3,27),(17,27)])
    l([(7,10),(23,10)],GRAY,1.2);l([(7,14),(20,14)],GRAY,1.2)
    l([(23,20),(20,23),(23,26)],GREEN);l([(21,23),(28,23),(29,27),(24,29)],GREEN)

def settings(d,l,b,e,a,t):
    points=[]
    for i in range(32):
        angle=math.pi*2*i/32
        radius=14 if i%4 in (0,3) else 11
        points.append((16+math.cos(angle)*radius,16+math.sin(angle)*radius))
    l(points+[points[0]],GRAY,1.3);e((10,10,22,22),GREEN,1.4)

def alias(d,l,b,e,a,t):
    l([(27,17),(27,29),(3,29),(3,5),(17,5)],GREEN)
    l([(12,20),(29,3)],GREEN,1.6)

def statement(d,l,b,e,a,t):
    l([(26,16),(26,3),(4,3),(4,29),(14,29)])
    l([(8,8),(21,8)],GRAY,1.2);l([(8,13),(17,13)],GRAY,1.2)
    e((15,17,31,32),GRAY,1.3,fill='white');t(23,25,'导',GRAY,9)

def header_background(d,l,b,e,a,t):
    d.rectangle((0,0,375*12,112*12),fill='#08b79c')
    for x in (50,175,300):
        l([(x-75,-30),(x+25,140)],'#0ab99f',24)

for name,paint in [('primary_account',primary_cards),('primary_phone',primary_phone),('repay',repay),('schedule',schedule),('other_bank',other_bank),('crossborder',crossborder),('mobile_collection',mobile_collection),('cancel',cancel),('settings',settings),('account_alias',alias),('account_statement',statement)]:artwork(name,paint)
artwork('primary_background',header_background,(375,112))
(DEST/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-account-transfer-reference-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(f'Reconstructed {len(manifest)} assets')
