from pathlib import Path
from PIL import Image, ImageChops, ImageFilter
import math

ROOT = Path('art_review/jet/lot2')
RAW = ROOT / 'raw'
PREVIEW = ROOT / '_preview'
for folder in (RAW, PREVIEW): folder.mkdir(parents=True, exist_ok=True)
GEN = Path(r'C:\Users\<user>\.codex\generated_images\01a1fd59-14c0-7ad3-93a4-94dd6f3c0b6e')
sources = {
    'icons': RAW/'icons_generated.png',
    'beam': RAW/'beam_generated.png',
    'node': RAW/'node_generated.png',
    'missile': RAW/'missile_generated.png',
    'warn': RAW/'warn_generated.png',
}

def keyed(im, key):
    im=im.convert('RGB'); out=Image.new('RGBA', im.size); src=im.load(); dst=out.load()
    kr,kg,kb=key
    for y in range(im.height):
        for x in range(im.width):
            r,g,b=src[x,y]; d=math.sqrt((r-kr)**2+(g-kg)**2+(b-kb)**2)
            a=max(0,min(255,round((d-35)*255/25)))
            if key == (0,255,0) and g>r+24 and g>b+24 and d<55: a=0
            if key == (255,0,255) and r>g+24 and b>g+24 and d<55: a=0
            # Remove key spill only in partially transparent edge pixels.
            if 0<a<255:
                if key == (0,255,0): r=min(r, max(g,b)); b=min(b,max(g,r))
                else: r=min(r,max(g,b)); b=min(b,max(g,r))
            dst[x,y]=(r,g,b,a)
    return out

def fit_alpha(src, size, pad=5):
    a=src.getchannel('A'); bbox=a.point(lambda p:255 if p>16 else 0).getbbox()
    crop=src.crop(bbox); crop.thumbnail((size[0]-2*pad,size[1]-2*pad),Image.Resampling.LANCZOS)
    out=Image.new('RGBA',size,(0,0,0,0)); out.alpha_composite(crop,((size[0]-crop.width)//2,(size[1]-crop.height)//2))
    return out

def recenter_alpha(im):
    bb=im.getchannel('A').point(lambda p:255 if p>8 else 0).getbbox()
    cut=im.crop(bb); out=Image.new('RGBA',im.size,(0,0,0,0)); out.alpha_composite(cut,((im.width-cut.width)//2,(im.height-cut.height)//2)); return out

def scrub_key(im,key):
    p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y]
            if a and math.dist((r,g,b),key)<6: p[x,y]=(r,g,b,0)
    return im

def panel_sheet(src, count, key, frame_size, stem, pad=5, inset=0):
    im=Image.open(src).convert('RGB'); fw=im.width//count; fh=im.height
    outs=[]
    for i in range(count):
        cell=im.crop((i*fw+inset,0,(i+1)*fw-inset,fh)); f=scrub_key(recenter_alpha(fit_alpha(keyed(cell,key),frame_size,pad)),key)
        f.save(RAW/f'{stem}_{i:03}.png'); outs.append(f)
    return outs

# Two icon crops from their independent halves of the generated square.
im=Image.open(sources['icons']).convert('RGB'); key=(255,0,255)
for idx,(name,box) in enumerate([('jet_icon_dragon',(0,0,im.width//2,im.height)),('jet_icon_robo',(im.width//2,0,im.width,im.height))]):
    f=scrub_key(recenter_alpha(fit_alpha(keyed(im.crop(box),key),(128,128),8)),key); f.save(RAW/f'{name}.png')

# The single beam body is made edge-exact by crossfading a half-width roll; report pre/post edge deltas.
beam_im=Image.open(sources['beam']).convert('RGB'); bcell=beam_im
beam=fit_alpha(keyed(bcell,(0,255,0)),(128,40),3)
# Replace with a continuous tile derived from a 2x-width segment; match edge neighborhoods smoothly.
tile=beam.copy(); px=tile.load()
for y in range(tile.height):
    for x in range(4):
        t=(x+1)/5; left=px[x,y]; right=px[tile.width-4+x,y]
        c=tuple(round(left[j]*(1-t)+right[j]*t) for j in range(4))
        px[x,y]=c; px[tile.width-1-x,y]=c
tile=scrub_key(tile,(0,255,0)); tile.save(RAW/'jet_beam_body.png')

nodes=panel_sheet(sources['node'],4,(0,255,0),(96,96),'jet_beam_node',12)
missiles=panel_sheet(sources['missile'],4,(0,255,0),(192,128),'jet_missile',12,8)
warns=panel_sheet(sources['warn'],2,(0,255,0),(128,128),'jet_missile_warn',12)

# Dark composition at actual in-game display sizes, with Kazeyumi run frame as requested.
bg=(18,16,42,255); canvas=Image.new('RGBA',(1100,660),bg)
wind=Image.open('assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png').convert('RGBA')
wa=wind.getchannel('A').getbbox(); wind=wind.crop(wa); wind.thumbnail((88,135),Image.Resampling.LANCZOS)
canvas.alpha_composite(wind,(60,75))
for x,img in zip((228,278,328,378),[Image.open(RAW/f'jet_icon_{n}.png') for n in ('dragon','robo')]):
    canvas.alpha_composite(img.resize((48,48),Image.Resampling.LANCZOS),(x,70))
for x,img in zip((460,488,516,544),nodes): canvas.alpha_composite(img.resize((28,28),Image.Resampling.LANCZOS),(x,80))
canvas.alpha_composite(warns[0].resize((40,40),Image.Resampling.LANCZOS),(600,74))
for x,img in zip((650,750,850,950),missiles): canvas.alpha_composite(img.resize((100,67),Image.Resampling.LANCZOS),(x,80))
# Beam assembly preview: long tiled body rotated 45 degrees with matching node caps.
body=Image.new('RGBA',(360,28),(0,0,0,0))
for x in range(0,360,128): body.alpha_composite(tile.resize((min(128,360-x),28),Image.Resampling.LANCZOS),(x,0))
assembled=Image.new('RGBA',(410,110),(0,0,0,0)); assembled.alpha_composite(body.rotate(45,expand=True,resample=Image.Resampling.BICUBIC),(25,15))
for pos in ((10,18),(285,55)): assembled.alpha_composite(nodes[0].resize((28,28),Image.Resampling.LANCZOS),pos)
canvas.alpha_composite(assembled,(300,300))
canvas.save(PREVIEW/'jet_lot2_preview.png')

def metrics(frames,key):
    result=[]
    for f in frames:
        a=f.getchannel('A'); bb=a.point(lambda p:255 if p>8 else 0).getbbox(); x0,y0,x1,y1=bb
        edge=[]
        for vals in ([a.getpixel((x0,y)) for y in range(y0,y1)],[a.getpixel((x1-1,y)) for y in range(y0,y1)],[a.getpixel((x,y0)) for x in range(x0,x1)],[a.getpixel((x,y1-1)) for x in range(x0,x1)]):
            edge.append(round(100*sum(v>40 for v in vals)/max(1,len(vals)),2))
        # keyed pixels can only survive as partial alpha on an edge; report count of opaque pixels near key hue.
        near=0
        for r,g,b,a0 in f.getdata():
            if a0>8 and math.dist((r,g,b),key)<25: near+=1
        result.append({'size':f.size,'bbox':bb,'margins':[x0,y0,f.width-x1,f.height-y1],'edge_gt40_pct':edge,'near_key_pixels':near,'center':[(x0+x1)/2,(y0+y1)/2]})
    return result

allframes={'icons':[Image.open(RAW/'jet_icon_dragon.png'),Image.open(RAW/'jet_icon_robo.png')], 'beam':[tile], 'node':nodes,'missile':missiles,'warn':warns}
for name,arr in allframes.items(): print(name,metrics(arr,(255,0,255) if name=='icons' else (0,255,0)))
print('beam_edge_mean_abs_rgba',round(sum(abs(tile.getpixel((0,y))[k]-tile.getpixel((127,y))[k]) for y in range(40) for k in range(4))/(40*4),4))
