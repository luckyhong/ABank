"""Reconstruct screenshot-only Mine artwork; never claim these are extracted originals.

Coordinates use a 32pt grid, supersampled to produce matching 2x/3x resources.
The seven user-supplied reference screenshots (2026-10-16) are the visual source.
"""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'ABank/Assets.xcassets/ABCImported/MineDetails/Reference'
GRAY, GREEN, GOLD = '#606460', '#2cbea2', '#eab645'
FONT = '/System/Library/Fonts/STHeiti Light.ttc'
manifest = []

def artwork(name, paint, size=(32, 32)):
    folder = DEST / ('abc_mine_detail_' + name + '.imageset')
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
    manifest.append({'asset':'abc_mine_detail_'+name,'origin':'reconstructed_from_user_screenshots','logicalSize':list(size),'scales':['2x','3x'],'generator':'scripts/generate_mine_reference_assets.py'})

def task(d,l,b,e,a,t):
    l([(4,9),(16,3),(28,9),(16,15),(4,9),(4,24),(16,30),(16,15)])
    l([(28,9),(28,15)])
    for y in (19,23,27):l([(21,y),(30,y)],GREEN)

def document(d,l,b,e,a,t,renew=False):
    l([(13,30),(6,30),(6,3),(26,3),(26,17)])
    t(16,11,'续' if renew else '申',sz=10)
    l([(10,22),(15,22)]);l([(10,26),(14,26)])
    if renew:
        e((19,21,30,32));l([(24.5,23),(24.5,26.5),(27,26.5)],GRAY,1)
        a((17,19,31,33),210,300,GRAY,1);l([(29,18),(30,21),(27,21)],GRAY,1)
    else:
        e((18,19,27,28),GREEN);l([(26,27),(30,31)],GREEN)

def certificate(d,l,b,e,a,t):
    b((6,5,27,30),radius=1);b((12,3,21,7),radius=1,fill='white')
    l([(10,12),(23,12)]);l([(10,17),(20,17)]);l([(10,22),(15,22)])
    e((19,21,30,32),fill='white');l([(22,26),(24,28),(28,24)],GREEN,1.2)

def payment(d,l,b,e,a,t):
    b((3,7,28,30),radius=2)
    d.rectangle((11*12,5*12,21*12,12*12),fill=(255,255,255,255))
    l([(16,14),(16,3)],GREEN,1.6);l([(13,6),(16,3),(19,6)],GREEN,1.6)
    t(16,22,'付',GRAY,13)

def person(d,l,b,e,a,t,salary=False):
    e((10,2,23,16),width=1.5);a((4,15,29,39),180,355,width=1.5)
    d.rectangle((20*12,20*12,32*12,32*12),fill=(255,255,255,255))
    if salary:t(25,25,'¥',GOLD,15)
    else:
        l([(3,24),(12,24)],GREEN);l([(10,22),(12,24),(10,26)],GREEN)
        l([(10,29),(1,29)],GREEN);l([(3,27),(1,29),(3,31)],GREEN)

def own_transfer(d,l,b,e,a,t):
    e((3,3,29,29));t(16,17,'¥','#37afd0',18)
    l([(5,10),(8,7),(11,10)],GRAY,1);l([(21,23),(24,26),(27,23)],GRAY,1)

def prepay(d,l,b,e,a,t):
    a((4,3,28,27),180,360);l([(4,27),(28,27)]);t(16,16,'¥',GRAY,18)

def usage(d,l,b,e,a,t):
    l([(26,18),(26,28),(4,28),(4,6),(15,6)])
    l([(13,19),(28,4)]);l([(9,12),(14,12)]);l([(9,23),(20,23)])

def checkup(d,l,b,e,a,t):
    a((2,3,29,30),35,325,GRAY,1.2);l([(4,17),(9,17),(12,11),(17,23),(21,15),(26,15)],GRAY,1.2)

def info(d,l,b,e,a,t):
    e((3,3,29,29),width=1.4)
    t(16,17,'i',GRAY,22)

def photo(d,l,b,e,a,t):
    b((2,5,30,27),radius=2);e((8,9,13,14),width=1.3);l([(3,23),(12,16),(20,21),(26,15),(30,17)])

for n,p in [('loan_tasks',task),('loan_progress',document),('loan_renewal',lambda *args:document(*args,renew=True)),('loan_certificate',certificate),('transaction_payment',payment),('transaction_salary',lambda *args:person(*args,salary=True)),('transaction_transfer',person),('transaction_own_transfer',own_transfer),('loan_prepay',prepay),('loan_usage',usage),('wealth_checkup_reference',checkup),('toolbar_photo',photo),('info_reference',info)]:artwork(n,p)

# Pale sweeping bands observed in the reference, rebuilt without baked-in text.
def background(d,l,b,e,a,t,asset=False):
    w,h=375*12,(220 if asset else 132)*12
    for y in range(h):
        f=y/h
        c=(round(250-3*f),round(237-5*f),round(215-7*f),255) if asset else (255,round(244-3*f),round(221-5*f),255)
        if asset:
            fade = max(0, min(1, (f - .55) / .45))
            c = tuple(round(c[i] * (1-fade) + (245,246,248)[i] * fade) for i in range(3)) + (255,)
        d.line([(0,y),(w,y)],fill=c)
    overlay=Image.new('RGBA',(w,h));od=ImageDraw.Draw(overlay)
    od.ellipse((-180*12,-200*12,480*12,80*12),fill=(255,255,255,55))
    od.ellipse((80*12,-180*12,680*12,55*12),fill=(255,255,255,40))
    return overlay
artwork('asset_background',lambda *args:background(*args,asset=True),(375,220))
artwork('flow_background',background,(375,132))
(DEST/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-mine-reference-resource-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(f'Reconstructed {len(manifest)} reference assets')
