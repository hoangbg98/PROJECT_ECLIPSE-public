from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(__file__).resolve().parents[2] / 'art_review/jet/jet_dragon/raw/jet_dragon_break_v2_magenta_strip.png'
OUT = ROOT / 'art_review/jet/jet_dragon/frames_v2'
PREVIEW = ROOT / 'art_review/jet/jet_dragon/_preview/jet_dragon_break_v2_preview.png'
REPORT = ROOT / 'art_review/jet/jet_dragon/_preview/jet_dragon_break_v2_alpha_report.txt'
FLY = ROOT / 'assets/jet/jet_dragon/fly/jet_dragon_fly_000.png'
KAZE = ROOT / 'assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png'
FACTORS = [1.00, .95, .80, .60, .35, .15]
W, H = 512, 384

def key_alpha(rgb):
    r, g, b = rgb
    # Euclidean distance to pure magenta; broad enough to key antialiased fringe.
    d = math.sqrt((255-r)**2 + g**2 + (255-b)**2)
    t = max(0.0, min(1.0, d / 150.0))
    return round(t*t*(3-2*t)*255)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SRC).convert('RGB')
    assert src.size == (2172, 724), src.size
    fly = Image.open(FLY).convert('RGBA')
    fb = fly.getchannel('A').getbbox()
    fw, fh = fb[2]-fb[0], fb[3]-fb[1]
    frames=[]
    for i, factor in enumerate(FACTORS):
        x0, x1 = round(i*src.width/6), round((i+1)*src.width/6)
        # The generated strip places all art in this shared vertical band.
        cell = src.crop((x0, 190, x1, 510))
        pix = cell.load(); mask=Image.new('L', cell.size); mp=mask.load()
        for y in range(cell.height):
            for x in range(cell.width):
                r,g,b=pix[x,y]
                a=key_alpha((r,g,b))
                # Remove residual magenta-colored antialias pixels from the keyed edge.
                if r > g+35 and b > g+35 and min(r,b)>75 and max(r,b)>130:
                    a=0
                mp[x,y]=a
        bbox=mask.point(lambda v: 255 if v>8 else 0).getbbox()
        if not bbox: raise RuntimeError(f'empty panel {i}')
        rgba=cell.convert('RGBA'); rgba.putalpha(mask)
        # Despill magenta along keyed edges while preserving ivory and jade.
        rp=rgba.load()
        for y in range(rgba.height):
            for x in range(rgba.width):
                r,g,b,a=rp[x,y]
                if a:
                    # Unmatte against magenta: remove the keyed-color contribution.
                    af=a/255.0; inv=1.0-af
                    rr=max(0,min(255,round((r-inv*255)/af)))
                    gg=max(0,min(255,round(g/af)))
                    bb=max(0,min(255,round((b-inv*255)/af)))
                    rp[x,y]=(rr,gg,bb,a)
        art=rgba.crop(bbox)
        # Keep a fixed shared center and reference-scale envelope matching fly_000.
        scale=min(fw/art.width, fh/art.height)
        nw,nh=max(1,round(art.width*scale)),max(1,round(art.height*scale))
        art=art.resize((nw,nh),Image.Resampling.LANCZOS)
        frame=Image.new('RGBA',(W,H),(0,0,0,0))
        frame.alpha_composite(art,((W-nw)//2,(H-nh)//2))
        # A 2 px soft outer edge keeps the silhouette antialiased after keying.
        from PIL import ImageFilter, ImageChops
        alpha=frame.getchannel('A')
        eroded=alpha.filter(ImageFilter.MinFilter(5))
        core=ImageChops.darker(alpha,eroded)
        edge=ImageChops.subtract(alpha,core).point(lambda v:round(v*.10))
        frame.putalpha(ImageChops.add(core,edge))
        frame.putalpha(frame.getchannel('A').point(lambda a:round(a*factor)))
        frame.save(OUT/f'jet_dragon_break_{i:03}.png')
        frames.append(frame)
    # Measure each of the four outer bbox columns/rows.
    lines=[]
    for i,im in enumerate(frames):
        a=im.getchannel('A'); bb=a.point(lambda v:255 if v>8 else 0).getbbox()
        x0,y0,x1,y1=bb; box=a.crop(bb)
        edges=[ [box.getpixel((0,y)) for y in range(box.height)],
                [box.getpixel((box.width-1,y)) for y in range(box.height)],
                [box.getpixel((x,0)) for x in range(box.width)],
                [box.getpixel((x,box.height-1)) for x in range(box.width)] ]
        ratios=[sum(v>40 for v in e)/len(e)*100 for e in edges]
        margin=min(x0,y0,W-x1,H-y1)
        lines.append(f'{i:03}: bbox={bb}; margins L/T/R/B={x0}/{y0}/{W-x1}/{H-y1}px; min_margin={margin}px; edges alpha>40 L/R/T/B={ratios[0]:.2f}/{ratios[1]:.2f}/{ratios[2]:.2f}/{ratios[3]:.2f}%; pass_edges={max(ratios)<15}; pass_margin={margin>=24}')
    # Dark preview panels; dragon sized and positioned alongside Kazeyumi.
    bg=(18,16,42,255); panel_w,panel_h=300,244
    preview=Image.new('RGBA',(6*panel_w,2*panel_h+38),bg); draw=ImageDraw.Draw(preview)
    font=ImageFont.load_default()
    draw.text((8,4),'jet_dragon break v2 — 18 fps',font=font,fill='white')
    kaze=Image.open(KAZE).convert('RGBA')
    kb=kaze.getchannel('A').getbbox(); kaze=kaze.crop(kb)
    for i,im in enumerate(frames):
        x=i*panel_w
        draw.rectangle((x+6,28,x+panel_w-6,panel_h+24),outline=(83,78,111,255),width=1)
        draw.text((x+12,33),f'{i:03}',font=font,fill='white')
        # same dragon placement each panel; adjacent Kazeyumi silhouette is scale reference.
        preview.alpha_composite(im.resize((panel_w-24,panel_h-34),Image.Resampling.LANCZOS),(x+12,52))
        ky=panel_h+42
        draw.rectangle((x+6,ky,x+panel_w-6,ky+panel_h-6),outline=(83,78,111,255),width=1)
        k=kaze.copy(); k.thumbnail((panel_w//3,panel_h-36),Image.Resampling.LANCZOS)
        preview.alpha_composite(k,(x+panel_w- k.width-18,ky+24))
        draw.text((x+12,ky+8),'Kazeyumi scale reference',font=font,fill=(196,210,226,255))
    PREVIEW.parent.mkdir(parents=True,exist_ok=True); preview.convert('RGB').save(PREVIEW)
    REPORT.write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print(f'preview={PREVIEW}')

if __name__=='__main__': main()
