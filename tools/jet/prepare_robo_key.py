from pathlib import Path
from PIL import Image
import math
src = Path('art_review/jet/jet_robo/raw/jet_robo_key_magenta.png')
root=Path('art_review/jet/jet_robo')
for d in ('raw','frames','_preview'): (root/d).mkdir(parents=True,exist_ok=True)
raw=Image.open(src).convert('RGB')
w,h=raw.size; keyed=Image.new('RGBA',(w,h)); ip=raw.load(); op=keyed.load()
for y in range(h):
 for x in range(w):
  r,g,b=ip[x,y]; dist=math.sqrt((r-255)**2+g*g+(b-255)**2)
  alpha=max(0,min(255,round((dist-45)*255/55)))
  # Remove the key hue from antialiased pixels: clamp red/blue to their shared neutral component.
  if 0 < alpha < 255:
   neutral=min(r,b)
   r=neutral; b=neutral
  op[x,y]=(r,g,b,alpha)
bbox=keyed.getchannel('A').point(lambda p:255 if p>40 else 0).getbbox()
subject=keyed.crop(bbox); new_w=336; new_h=round(subject.height*new_w/subject.width)
subject=subject.resize((new_w,new_h),Image.Resampling.LANCZOS)
# Final despill pass after resampling; neutralize any pink/magenta fringe left on the silhouette.
sp=subject.load()
for yy in range(subject.height):
 for xx in range(subject.width):
  r,g,b,alpha=sp[xx,yy]
  if alpha>8 and ((r-255)**2+g*g+(b-255)**2)**0.5 < 45:
   sp[xx,yy]=(r,g,b,0)
  elif alpha>8 and r>g+28 and b>g+28:
   neutral=min(r,b)
   sp[xx,yy]=(neutral,g,neutral,alpha)
frame=Image.new('RGBA',(384,384),(0,0,0,0)); frame.alpha_composite(subject,((384-new_w)//2,346-new_h)); frame.save(root/'frames/jet_robo_key.png')
# Preview: dark background; Robo 190 px high and Kazeyumi 135 px high, seated over open cockpit.
s=190/new_h; rw=round(384*s); canvas=Image.new('RGBA',(rw+260,250),(18,16,42,255)); rx=8; ry=52
canvas.alpha_composite(frame.resize((rw,190),Image.Resampling.LANCZOS),(rx,ry))
wind=Image.open('assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png').convert('RGBA'); wind=wind.crop(wind.getchannel('A').getbbox()); wh=135; ww=round(wind.width*wh/wind.height); wind=wind.resize((ww,wh),Image.Resampling.LANCZOS)
seat_y=ry+round(147*s); canvas.alpha_composite(wind,(rx+round(170*s)-ww//2,seat_y-wh+5))
canvas.convert('RGB').save(root/'_preview/jet_robo_key_preview.png')
# Measurements from processed 384x384.
a=frame.getchannel('A'); bb=a.point(lambda p:255 if p>8 else 0).getbbox(); px=a.load(); x0,y0,x1,y1=bb
regions=[[px[x0,y] for y in range(y0,y1)],[px[x1-1,y] for y in range(y0,y1)],[px[x,y0] for x in range(x0,x1)],[px[x,y1-1] for x in range(x0,x1)]]
edge=[round(sum(v>40 for v in row)*100/len(row),2) for row in regions]
fp=frame.load(); residue=sum(1 for y in range(384) for x in range(384) if fp[x,y][3]>8 and ((fp[x,y][0]-255)**2+fp[x,y][1]**2+(fp[x,y][2]-255)**2)**0.5<45)
print('source_size',raw.size,'raw_bbox',bbox,'processed_bbox',bb,'frame_size',frame.size,'object_height',new_h,'edge_alpha_gt40_percent',edge,'margins_top_left_right',y0,x0,384-x1,'visible_near_key_pixels_distance_lt45',residue)
