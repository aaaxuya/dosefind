
from pathlib import Path
from PIL import Image,ImageOps
root=Path('.dose-build')
stage=root/'blue'
photo=ImageOps.fit(Image.open(stage/'campus.jpg').convert('RGB'),(1440,810),centering=(0.5,0.82))
photo=ImageOps.colorize(ImageOps.grayscale(photo),'#4d6284','#f1f5fb')
for name,weight in [('campus-cover',0.17),('campus-body',0.085)]:
    Image.blend(Image.new('RGB',photo.size,'#f5f7fb'),photo,weight).save(stage/(name+'.png'))
src=(root/'build.mjs').read_text(encoding='utf-8-sig')
src=src.replace("const W=1440,H=810;","""const renderDir=path.join(stage,'blue');
const campusSource='https://zs.njmu.edu.cn/_upload/article/images/bf/a4/cc21ce9640218fe4aa1ed7ecdcfe/3ca409dc-cb14-48a8-a70d-ced750bbc875.jpg';
const backgrounds=await Promise.all(['campus-cover.png','campus-body.png'].map(name=>fs.readFile(path.join(renderDir,name))));
const W=1440,H=810;""")
src=src.replace("const ink='#162D3B', deep='#173545', muted='#526671', green='#19675F', light='#E5F0EB', paper='#F8FAF8', white='#FFFFFF', rule='#CFDCD8';","const ink='#292D34', deep='#39547B', muted='#596477', blue='#39547B', light='#E9EEF6', paper='#F5F7FB', white='#FFFFFF', rule='#C9D3E2';").replace('green','blue')
start=src.index('function note(')
end=src.index('function paragraphs(',start)
header=r"""function note(s,v){s.speakerNotes.text=v+'\n背景照片：南京医科大学本科生招生网 '+campusSource;}
function slide(title,section){
 const s=deck.slides.add();s.background.fill=paper;
 const photo=backgrounds[title?1:0];
 s.images.add({blob:photo.buffer.slice(photo.byteOffset,photo.byteOffset+photo.byteLength),contentType:'image/png',
  position:pos(0,0,W,H),fit:'contain',alt:'淡化的校园图书馆背景'});
 if(title){
  box(s,0,54,35,100,deep);
  box(s,47,54,12,100,deep);
  if(section==='研究方向')txt(s,section,78,38,129,31,{size:19,color:deep,bold:true,fill:light,align:'center'});
  else if(section)txt(s,section,78,38,410,31,{size:19,color:deep,bold:true});
  txt(s,title,78,73,W-156,82,{size:51,bold:true});
  box(s,78,154,W-156,1.5,deep);
  box(s,0,782,W,28,deep);
  txt(s,'一期剂量探索',78,782,320,28,{size:15,color:white});
  txt(s,String(deck.slides.items.length).padStart(2,'0'),1320,782,42,28,{size:15,color:white,align:'right'});
 }
 return s;
}
function foot(s,v){txt(s,v,64,741,1260,36,{size:18,color:muted});}
"""
src=src[:start]+header+src[end:]
start=src.index(' const s=slide();')
end=src.index('\n}',start)
cover=""" const s=slide();
 s.shapes.add({geometry:'custom',position:pos(0,0,482,H),fill:deep,line:{fill:'none',width:0},
  customPaths:[{width:482,height:H,commands:[
   {moveTo:{x:0,y:0}},
   {cubicBezTo:{x1:266,y1:0,x2:482,y2:181,x:482,y:405}},
   {cubicBezTo:{x1:482,y1:629,x2:266,y2:810,x:0,y:810}},
   {close:{}}
  ]}]});
 txt(s,'目录',61,120,290,103,{size:88,color:white});
 txt(s,'C O N T E N T S',67,228,340,35,{size:23,color:'#DCE5F0'});
 section.forEach((v,i)=>{
  const y=301+70*i;
  txt(s,String(i+1).padStart(2,'0'),63,y,48,42,{size:22,bold:true,fill:'#EEF3FA',color:deep,align:'center'});
  txt(s,v,126,y,282,42,{size:25,bold:true,color:white});
  if(i<section.length-1)box(s,63,y+51,272,1,'#7087A7');
 });
 txt(s,'第一次组会汇报',549,228,794,42,{size:26,color:blue,bold:true});
 txt(s,'一期剂量探索',549,280,798,99,{size:76,bold:true});
 txt(s,'多等级毒性下的 MTD 方法比较',553,393,804,61,{size:37});
 box(s,553,465,800,1.5,rule);
 txt(s,'Quasi-CRM   /   RQ-CRM   /   gBOIN',553,487,802,48,{size:28,color:muted});
 note(s,'');"""
src=src[:start]+cover+src[end:]
src=src.replace("const draft=path.join(stage,'draft.pptx');","const draft=path.join(renderDir,'draft.pptx');").replace("path.join(stage,'slide-'","path.join(renderDir,'slide-'")
(stage/'build.mjs').write_text(src,encoding='utf-8')

