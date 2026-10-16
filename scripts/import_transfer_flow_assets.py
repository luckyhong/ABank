"""Map reviewed package artwork for M1. Does not modify existing resource groups."""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'artifacts/abc-resources'
lookup = {row['source']: row for row in json.loads((SOURCE/'analysis/resources.json').read_text())}
recipes = {'abc_transfer_result_success': ['CWABCResource.bundle/cwSuccess@2x.png', 'CWABCResource.bundle/cwSuccess@3x.png']}
manifest = []
for name, sources in recipes.items():
    folder = ROOT/'ABank/Assets.xcassets/ABCImported/Transfer/Flow'/(name+'.imageset')
    folder.mkdir(parents=True, exist_ok=True)
    images = []
    for source in sources:
        scale = '2x' if '@2x' in source else '3x'
        path = SOURCE/lookup[source]['preview']
        filename = 'image@'+scale+'.png'
        shutil.copyfile(path, folder/filename)
        images.append({'idiom': 'universal', 'scale': scale, 'filename': filename})
        with Image.open(path) as image: dimensions = list(image.size)
        manifest.append({'asset': name, 'source': source, 'origin': 'extracted_abc_ipa',
                         'source_sha256': lookup[source]['sha256'], 'imported_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                         'scale': scale, 'dimensions': dimensions,
                         'usage': 'local reconstructed result page; original transfer screen use unverified'})
    (folder/'Contents.json').write_text(json.dumps({'images': images, 'info': {'author': 'xcode', 'version': 1}, 'properties': {'template-rendering-intent': 'original'}}, indent=2)+'\n')
(folder.parent/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
(ROOT/'docs/abc-transfer-flow-resource-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
print('Imported M1 result artwork with original 2x/3x scales')
