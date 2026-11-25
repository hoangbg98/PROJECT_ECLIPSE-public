from pathlib import Path
from PIL import Image
import math

ROOT=Path('art_review/jet/jet_robo')
RAW=ROOT/'raw'; FRAMES=ROOT/'frames'; PREVIEW=ROOT/'_preview'
for d in (FRAMES,PREVIEW): d.mkdir(parents=True,exist_ok=True)
SPECS={
 'walk':('jet_robo_walk_strip_v2.png',6,362,181,362,'ground'),
 'jump':('jet_robo_jump_strip_v2.png',3,724,0,724,'jump'),
 'crush':('jet_robo_crush_strip_v2.png',4,543,90,543,'crush'),
 'break':('jet_robo_break_strip_v2.png',6,362,181,362,'break'),
}
FADE=[1.00,0.90,0.75,0.55,0.30,0.10]
KEY=(255,0,255)

def keyed(tile):
    src=tile.convert('RGB'); w,h=src.size; inp=src.load(); out=Image.new('RGBA',(w,h)); op=out.load()
    for y in range(h):
        for x in range(w):
            r,g,b=inp[x,y]
            dist=math.sqrt((r-KEY[0])**2+g*g+(b-KEY[2])**2)
            alpha=max(0,min(255,round((dist-28)*255/46)))
            if 0<alpha<255:
                spill=min(max(0,r-g),max(0,b-g))
                r=max(0,r-spill); b=max(0,b-spill)
            if alpha>8 and r>g+32 and b>g+32:
                spill=min(r-g,b-g); r-=spill; b-=spill
            op[x,y]=(r,g,b,alpha)
    return out

def despill(image):
    px=image.load()
    for y in range(image.height):
        for x in range(image.width):
            r,g,b,a=px[x,y]
            if a>8 and r>g+24 and b>g+24:
                spill=min(r-g,b-g); r-=spill; b-=spill
                px[x,y]=(r,g,b,a)

def trim(frame):
    a=frame.getchannel('A').point(lambda p:255 if p>8 else 0)
    return a.getbbox()

def put_intact(frame, bbox, scale, anchor_y):
    x0,y0,x1,y1=bbox
    cut=frame.crop(bbox)
    nw=max(1,round(cut.width*scale)); nh=max(1,round(cut.height*scale))
    cut=cut.resize((nw,nh),Image.Resampling.LANCZOS)
    despill(cut)
    canvas=Image.new('RGBA',(384,384),(0,0,0,0))
    left=192-nw//2
    top=round(anchor_y)
    canvas.alpha_composite(cut,(left,top))
    return canvas

def find_anchor(frame):
    a=frame.getchannel('A').load(); xs=[]
    for y in range(190):
        xs=[x for x in range(55,301) if a[x,y]>8]
        if xs: return (sum(xs)/len(xs),y)
    return (192.0,58)

def translate(frame,dx,dy):
    out=Image.new('RGBA',(384,384),(0,0,0,0))
    out.alpha_composite(frame,(int(dx),int(dy)))
    return out

def align_body(frame,ground=False):
    tx,ty=find_anchor(frame)
    key_x,key_y=find_anchor(Image.open('assets/jet/jet_robo.png').convert('RGBA'))
    frame=translate(frame,round(key_x-tx),round(key_y-ty))
    if ground:
        b=trim(frame); frame=translate(frame,0,346-(b[3]-1))
    despill(frame)
    return frame

def set_ground_line(frame):
    b=trim(frame)
    x0,y0,x1,y1=b
    target_h=347-y0
    cut=frame.crop(b).resize((x1-x0,target_h),Image.Resampling.LANCZOS)
    out=Image.new('RGBA',(384,384),(0,0,0,0))
    out.alpha_composite(cut,(x0,y0))
    despill(out)
    return out

def cell_crop(strip, idx, count, cell_w, crop_y, crop_size):
    tile=strip.crop((idx*cell_w,crop_y,(idx+1)*cell_w,crop_y+crop_size))
    return tile

def color_metrics(frame):
    a=frame.getchannel('A'); bbox=trim(frame); x0,y0,x1,y1=bbox
    pix=frame.load(); ap=a.load()
    edges=[[ap[x0,y] for y in range(y0,y1)],[ap[x1-1,y] for y in range(y0,y1)],[ap[x,y0] for x in range(x0,x1)],[ap[x,y1-1] for x in range(x0,x1)]]
    edge=[round(100*sum(v>40 for v in e)/len(e),2) for e in edges]
    magenta=near=gray=0
    for y in range(384):
        for x in range(384):
            r,g,b,alpha=pix[x,y]
            if alpha<=8: continue
            if r>g+32 and b>g+32: magenta+=1
            if math.sqrt((r-255)**2+g*g+(b-255)**2)<45: near+=1
            # Count nearly white/neutral opaque pixels outside the Robo silhouette interior only as a diagnostic.
            if r>238 and g>238 and b>238: gray+=1
    return bbox,edge,magenta,near,gray

processed={}; reports={}
for anim,(filename,count,cell_w,crop_y,crop_size,kind) in SPECS.items():
    strip=Image.open(RAW/filename).convert('RGB')
    assert strip.width==cell_w*count and crop_y+crop_size<=strip.height,(anim,strip.size)
    raw_frames=[keyed(cell_crop(strip,i,count,cell_w,crop_y,crop_size)) for i in range(count)]
    boxes=[trim(f) for f in raw_frames]
    dims=[(b[2]-b[0],b[3]-b[1]) for b in boxes]
    if kind in ('ground','crush'):
        # Common scale preserves Robo proportions frame-to-frame; ground anchor is fixed at the standard foot line.
        scale=min(288/max(h for w,h in dims),336/max(max(w,h) for w,h in dims))
        anchor_y=58
        frames=[align_body(put_intact(f,b,scale,anchor_y),True) for f,b in zip(raw_frames,boxes)]
    elif kind=='jump':
        # Match key-art scale; place each cockpit top at the key-art seat anchor, while keeping the body at the same Y.
        scale=min(0.56,336/max(max(w,h) for w,h in dims))
        seat_y=[245,110,184]
        frames=[]
        for i,(f,b) in enumerate(zip(raw_frames,boxes)):
            x0,y0,x1,y1=b
            cut=f.crop(b); nw=round(cut.width*scale); nh=round(cut.height*scale)
            cut=cut.resize((nw,nh),Image.Resampling.LANCZOS)
            despill(cut)
            canvas=Image.new('RGBA',(384,384),(0,0,0,0))
            left=192-nw//2
            top=round(58-(seat_y[i]-y0)*scale)
            canvas.alpha_composite(cut,(left,top)); frames.append(set_ground_line(canvas) if i in (0,2) else canvas)
    else:
        # Break frames use one scale and centered debris, then code applies the prescribed frame opacity.
        scale=min(336/max(max(w,h) for w,h in dims),1.00)
        frames=[]
        for i,(f,b) in enumerate(zip(raw_frames,boxes)):
            x0,y0,x1,y1=b; cut=f.crop(b)
            nw=max(1,round(cut.width*scale)); nh=max(1,round(cut.height*scale))
            cut=cut.resize((nw,nh),Image.Resampling.LANCZOS)
            despill(cut)
            canvas=Image.new('RGBA',(384,384),(0,0,0,0))
            left=192-nw//2; top=192-nh//2
            canvas.alpha_composite(cut,(left,top))
            factor=FADE[i]
            canvas.putalpha(canvas.getchannel('A').point(lambda p,f=factor:round(p*f)))
            despill(canvas)
            frames.append(canvas)
    processed[anim]=frames
    for i,frame in enumerate(frames):
        frame.save(FRAMES/f'jet_robo_{anim}_{i:03d}.png')
        reports[(anim,i)]=color_metrics(frame)
    print(anim,'raw_boxes',boxes,'dims',dims,'scale',round(scale,4))
    for i in range(count):
        b,e,m,n,g=reports[(anim,i)]
        print(' ',i,'bbox',b,'edges',e,'magentahue',m,'near_key',n,'nearwhite',g,'fade',FADE[i] if anim=='break' else 1.0)

# Render four preview rows. Kazeyumi stays pixel-fixed within every row.
rider=Image.open('assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png').convert('RGBA')
rider=rider.crop(rider.getchannel('A').getbbox()); rh=135; rw=round(rider.width*rh/rider.height); rider=rider.resize((rw,rh),Image.Resampling.LANCZOS)
for anim,frames in processed.items():
    max_h=max((trim(f)[3]-trim(f)[1]) for f in frames)
    display_scale=190/max_h
    render=round(384*display_scale); gap=18; cell=render+18; top=92
    canvas=Image.new('RGBA',(len(frames)*cell+gap,top+render+22),(18,16,42,255))
    seat_contact=145
    for i,frame in enumerate(frames):
        x=gap//2+i*cell
        shown=frame.resize((render,render),Image.Resampling.LANCZOS)
        canvas.alpha_composite(shown,(x,top))
        canvas.alpha_composite(rider,(x+render//2-rw//2,top+round(seat_contact*display_scale)-rh+4))
    canvas.convert('RGB').save(PREVIEW/f'jet_robo_{anim}_preview.png')
print('walk_jump_crush_break_frames_written',sum(map(len,processed.values())))
