
import fs from 'node:fs/promises';
import path from 'node:path';
import {Presentation,PresentationFile,FileBlob} from 'file:///C:/Users/23676/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const stage=path.resolve('.dose-build');
const renderDir=path.join(stage,'blue');
const campusSource='https://zs.njmu.edu.cn/_upload/article/images/bf/a4/cc21ce9640218fe4aa1ed7ecdcfe/3ca409dc-cb14-48a8-a70d-ced750bbc875.jpg';
const backgrounds=await Promise.all(['campus-cover.png','campus-body.png'].map(name=>fs.readFile(path.join(renderDir,name))));
const W=1440,H=810;
const deck=Presentation.create({slideSize:{width:W,height:H}});
const ink='#292D34', deep='#39547B', muted='#596477', blue='#39547B', light='#E9EEF6', paper='#F5F7FB', white='#FFFFFF', rule='#C9D3E2';
const font='Microsoft YaHei';
const mu='https://doi.org/10.1111/rssc.12263', sweet='https://doi.org/10.1093/biomtc/ujaf012', pre='https://arxiv.org/abs/2402.15460', pan='https://doi.org/10.1371/journal.pone.0098147', yuan='https://doi.org/10.1111/j.1541-0420.2006.00666.x', cran='https://cran.r-project.org/package=UnifiedDoseFinding', repo='https://github.com/aaaxuya/dosefind';
const pos=(left,top,width,height)=>({left,top,width,height});
function box(s,x,y,w,h,fill=light,border='none',geometry='rect'){
 return s.shapes.add({geometry,position:pos(x,y,w,h),fill,line:{fill:border,width:border==='none'?0:1,style:'solid'}});
}
function txt(s,content,x,y,w,h,o={}){
 const a=box(s,x,y,w,h,o.fill??'none',o.border??'none',o.fill?'rect':'textbox');
 a.text=content;
 a.text.style={typeface:font,fontSize:o.size??25,color:o.color??ink,bold:o.bold??false,alignment:o.align??'left',verticalAlignment:o.vert??'middle',insets:o.pad??0,wrap:'none'};
 return a;
}
function link(s,label,url,x,y,w,h,size=22,color=blue){
 const t=txt(s,label,x,y,w,h,{size,color});
 const run=t.text.get(label); run.link={uri:url,isExternal:true}; run.color=color;
}
function note(s,v){s.speakerNotes.text=v+'\n背景照片：南京医科大学本科生招生网 '+campusSource;}
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
function paragraphs(s,x,y,w,rows,step=132){
 rows.forEach(([a,b],i)=>{
  const yy=y+i*step;
  if(i)box(s,x,yy-13,w,1,rule);
  txt(s,a,x,yy,w,40,{size:29,bold:true,color:blue});
  b.split('\n').forEach((line,j)=>txt(s,line,x,yy+47+35*j,w,34,{size:24}));
 });
}
async function pic(s,file,x,y,w,h,alt){
 const b=await fs.readFile(file);
 s.images.add({blob:b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength),contentType:'image/png',position:pos(x,y,w,h),fit:'contain',alt});
}
function grid(s,values,x,y,widths,rowH=63){
 const w=widths.reduce((a,b)=>a+b,0);
 const table=s.tables.add({rows:values.length,columns:widths.length,left:x,top:y,width:w,height:rowH*values.length,columnWidths:widths,values});
 for(let r=0;r<values.length;r++){
  for(let c=0;c<widths.length;c++){
   const cell=table.getCell(r,c);
   cell.fill=r===0?deep:r%2?white:light;
   cell.text.style={typeface:font,fontSize:r===0?23:25,bold:r===0||c===0,color:r===0?white:ink,verticalAlignment:'middle',alignment:c===0?'left':'center'};
  }
 }
 table.borders.assign({style:'solid',fill:rule,width:1});
 return table;
}
const section=['研究方向','文献调研','模拟方法与初步成果','下一步计划'];
{
 const s=slide();
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
 note(s,'');
}
{
 const s=slide('一期剂量探索中的 MTD 选择','研究方向');
 txt(s,'研究目标',70,229,220,46,{size:29,color:blue,bold:true});
 txt(s,'比较三种使用多等级毒性的剂量探索设计。',70,290,1290,64,{size:39,bold:true});
 paragraphs(s,70,410,1290,[
 ['最大耐受剂量（MTD）','本研究把真实平均毒性评分最接近预设目标的剂量定义为真 MTD。'],
 ['正确选择率（PCS）','重复模拟一期试验，统计最终推荐剂量等于真 MTD 的比例。']
 ],135);
 note(s,'来源：组会汇报.docx；本地 DoseFindingResearch/scripts/00_parameters.R 与 R/analyse_pcs.R。MTD 的定义对应本研究模拟。');
}
{
 const s=slide('多等级毒性如何进入剂量决策','研究方向');
 txt(s,'把毒性等级换算成等效毒性评分（ETS），再比较各剂量的平均评分。',64,213,1312,48,{size:31,bold:true});
 grid(s,[['原始毒性等级','0–1 级','2 级','3 级','4 级'],['等效毒性评分','0','0.5','1.0','1.5']],64,315,[350,240,240,240,242],79);
 txt(s,'本轮示例的目标 ETS 为 0.47。',64,520,1300,44,{size:30,color:blue,bold:true});
 txt(s,'二元 DLT 记录事件是否发生，ETS 进一步区分不同严重度。',64,579,1310,43,{size:26});
 foot(s,'示例评分与目标参考 Mu 等（2019），第 3.2 节。');
 note(s,'评分来自 Mu 等（2019）第 3.2 节：'+mu+'。模拟代码中的四个类别索引 0–3 对应原文合并 0–1 级后的四档。');
}
{
 const s=slide('已有研究与直接比较','文献调研');
 txt(s,'图一  已研究的问题',64,197,735,38,{size:23,color:blue,bold:true});
 txt(s,'图二  已确认的直接比较',825,197,551,38,{size:23,color:blue,bold:true});
 await pic(s,path.join(process.env.TEMP,'codex-clipboard-0c5fee64-2070-4dda-a0a8-24140c375fb4.png'),64,241,735,490,'图一：研究问题、已有研究及代表文献');
 await pic(s,path.join(process.env.TEMP,'codex-clipboard-b95aa5c5-2f7e-44d9-92b5-cbe4aa000ab3.png'),825,241,551,245,'图二：方法之间的直接比较');
 txt(s,'本次调研的切入点',825,512,551,43,{size:26,bold:true,color:blue});
 txt(s,'已找到两项以 Quasi-CRM 为对照的比较。\n现有检索暂未找到 RQ-CRM 与 gBOIN\n的直接比较，或三种方法的同场景比较。',825,565,551,119,{size:24});
 note(s,'两图均为用户提供的原图。Pan 等（2014）'+pan+'；Mu 等（2019）'+mu+'。暂未找到仅描述本次调研范围。');
}
{
 const s=slide('本次比较的三种设计','文献调研');
 paragraphs(s,64,216,1312,[
 ['Quasi-CRM　单一 skeleton','用预设的剂量–毒性骨架拟合各剂量的毒性，再根据估计更新剂量。'],
 ['RQ-CRM　多个 skeleton','拟合多个候选骨架，本轮根据后验模型概率选择一个骨架进行剂量决策。'],
 ['gBOIN　区间决策','将当前剂量的累计平均评分与升降边界比较，决定升一级、维持或降一级。']
 ],147);
 foot(s,'Skeleton 指各候选剂量预设的毒性水平序列。');
 note(s,'Yuan 等（2007）'+yuan+'；Pan 等（2014）'+pan+'；Mu 等（2019）'+mu+'。本轮 RQ-CRM 设 mselection=1，使用模型选择。');
}
{
 const s=slide('三种设计的模拟流程','模拟方法与初步成果');
 txt(s,'基于 UnifiedDoseFinding R 包（0.1.10）',64,209,1312,48,{size:31,bold:true});
 const nodes=[
  ['设定情景','各剂量的毒性分布\n目标 ETS 与真 MTD'],
  ['生成潜在结局','按试验、入组顺序\n及剂量预生成毒性'],
  ['逐队列模拟','按当前剂量读取结局\n更新下一队列剂量'],
  ['推荐与汇总','按各方法推荐 MTD\n计算各设计的 PCS']
 ];
 nodes.forEach(([a,b],i)=>{
  const x=64+i*337;
  box(s,x,328,300,156,i===2?deep:light);
  txt(s,a,x+18,346,264,42,{size:27,bold:true,color:i===2?white:blue});
  txt(s,b,x+18,396,264,66,{size:21,color:i===2?white:ink});
  if(i<3)box(s,x+307,394,23,24,blue,'none','rightArrow');
 });
 txt(s,'三种设计共用同一份潜在结局，各自按规则给药。',64,541,1312,46,{size:29,bold:true});
 foot(s,'每次最多 10 个队列，每队列 3 人。试验结束后按各方法的规则推荐剂量。');
 note(s,'实现：DoseFindingResearch/R/generate_bank.R、get_oc_RQ_CRM_bank.R、get_oc_gBOIN_bank.R、run_pcs_comparison.R。gBOIN 复用包的连续结局决策与最终选择函数，输入使用患者库的等级评分。CRAN：'+cran);
}
{
 const s=slide('为什么先生成患者潜在结局？','模拟方法与初步成果');
 txt(s,'示例：同一个模拟患者在各剂量下的潜在毒性评分',64,215,1312,45,{size:29,bold:true});
 grid(s,[['模拟患者','D1','D2','D3','D4','D5','D6'],['第 i 位','0','0','0.5','1.0','0.5','1.5']],64,285,[232,180,180,180,180,180,180],64);
 paragraphs(s,64,454,1312,[
 ['每种设计仅观察自己分配剂量上的结局','例如某设计分到 D3，就读取 0.5。另一设计分到 D4，就读取 1.0。'],
 ['同一次试验可以逐一配对','配对用于估计 PCS 差值，也方便回溯两种方法从哪个队列开始分岔。']
 ],125);
 foot(s,'示例为演示用。本轮代码按剂量独立抽样，再将整份结局表共享给三种设计。');
 note(s,'Sweeting 等（2025）'+sweet+'。原文 MTD 案例以同一潜变量生成单调的二元 DLT 潜在结局，本实现按剂量独立抽取等级。PCS 差值方差减少取决于配对结果的正协方差。');
}
{
 const s=slide('共享结局能提高 PCS 差值的估计精度','模拟方法与初步成果');
 await pic(s,path.join(stage,'sweet-fig4.png'),64,217,863,465,'Sweeting 等，图 4。共享或独立模拟数据下，mTPI-2 与 CRM 的正确选择 MTD 比例差');
 txt(s,'论文中的 MTD 示例',962,250,412,44,{size:27,bold:true,color:blue});
 txt(s,'比较 CRM 与 mTPI-2。\n红线使用同一批模拟试验，\n蓝线使用独立模拟试验。',962,308,412,111,{size:25});
 txt(s,'在这个例子里，共享试验\n得到的差值误差条更窄。',962,445,412,84,{size:25,bold:true});
 link(s,'Sweeting 等（2025）｜论文图 4',sweet,962,571,412,39,21);
 foot(s,'图源：Sweeting 等，同题预印本图 4。图中为二元 DLT 示例。');
 note(s,'正式发表版 '+sweet+'，图4；图像取自同题预印本 '+pre+'。图中误差条为 ±1.96 × Monte Carlo 标准误。不同实现和方法间的收益取决于配对协方差。');
}
{
 const s=slide('单一情景的 MTD 正确选择率','模拟方法与初步成果');
 txt(s,'6 个剂量，从 D1 起始   /   真 MTD = D4   /   目标 ETS = 0.47   /   4,000 次模拟',64,205,1312,47,{size:25,color:blue,bold:true});
 grid(s,[['方法','正确选择次数','PCS','Monte Carlo 标准误'],['Quasi-CRM','2,030','50.75%','0.79 个百分点'],['RQ-CRM','2,276','56.90%','0.78 个百分点'],['gBOIN','2,211','55.28%','0.79 个百分点']],64,298,[333,297,250,432],79);
 txt(s,'本情景下，RQ-CRM 的 PCS 比 gBOIN 高 1.63 个百分点。',64,638,1312,47,{size:27,bold:true});
 foot(s,'差值按原始计数计算。表中标准误对应各方法的 PCS。');
 note(s,'基于已有结果文件 DoseFindingResearch/results/pcs_comparison/comparison.csv。gBOIN=2211/4000，55.275%，统一四舍五入显示为 55.28%；配对差值为 65/4000=1.625 个百分点。');
}
{
 const s=slide('与论文情景 1 的 PCS 对照','模拟方法与初步成果');
 grid(s,[['方法','本轮共享结局','Mu 等（2019）表 5','差值'],['Quasi-CRM','50.75%','50.0%','+0.75 个百分点'],['gBOIN','55.28%','56.0%','−0.73 个百分点'],['RQ-CRM','56.90%','未纳入','—']],64,235,[300,293,337,382],75);
 txt(s,'Quasi-CRM 和 gBOIN 的差距均小于 1 个百分点。',64,566,1312,47,{size:29,bold:true,color:blue});
 txt(s,'这为该情景提供了初步数值核对。两套 gBOIN 实现的升降边界略有差异。',64,622,1312,40,{size:24});
 foot(s,'差值按舍入前的 PCS 计算。RQ-CRM 原包等级模拟的 PCS 为 56.98%。');
 note(s,'Mu 等（2019）'+mu+'，§3.2、表4与表5 Scenario 1。论文边界为 0.373 / 0.566，本轮基于包函数的原始评分中点边界为 0.376 / 0.564。另据原包比较 CSV，RQ-CRM 56.975%；Quasi-CRM 50.50%；gBOIN 连续正态路径 32.30%。后者以正态分布生成连续结局（SD=0.3×剂量编号），共享结局路径输入多等级评分，两个结果的差异需在锁定决策规则后进一步分解。');
}
{
 const s=slide('扩展模拟情景与评价指标','下一步计划');
 paragraphs(s,64,215,1312,[
 ['参考已有比较论文','先整理 Pan 与 Mu 等论文的情景、主要指标和报告口径，再选定本研究的比较设置。'],
 ['扩展情景','改变真 MTD 位置和剂量–毒性曲线形状，考察相同 ETS 下的等级分布及 skeleton 错设。'],
 ['补充指标','除 PCS 外，报告剂量选择分布、过毒剂量暴露、早停率和配对 PCS 差值的标准误。']
 ],149);
 note(s,'拟参考 Pan 等（2014）'+pan+'；Mu 等（2019）'+mu+'。在扩展前保留情景 1 作为回归核对，记录版本和规则差异。');
}
{
 const s=slide('追踪未选中真 MTD 的试验','下一步计划');
 paragraphs(s,64,218,1312,[
 ['筛选配对试验','用同一试验编号，挑出一种设计选中 D4、另一种设计选错的实例。'],
 ['重放每个队列','保存剂量、观测评分和升降建议，定位两种设计第一次分岔的位置。'],
 ['区分给药路径与最终推荐','检查过早降级、升不到目标剂量或最终选剂量规则是否与错误选择有关。']
 ],146);
 foot(s,'先用个例提出解释，再用同类情景验证该模式是否反复出现。');
 note(s,'本轮参数 keep.patient.data=FALSE，当前保留试验级结果。拟固定输入和试验编号，开启逐患者或逐队列记录并补存模型权重、边界、最终决策输入等。首次分岔用于定位，需进一步验证其是否影响最终推荐。');
}
{
 const s=slide('代码与参考文献','');
 link(s,'GitHub  ·  aaaxuya/dosefind',repo,64,219,1312,64,37);
 txt(s,'R Markdown 记录了 UnifiedDoseFinding 的函数演示与示例。',64,295,1312,43,{size:26});
 box(s,64,364,1312,1,rule);
 const refs=[
  ['Yuan 等（2007）  ·  多等级毒性与 Quasi-CRM',yuan],
  ['Pan 等（2014）  ·  Robust Quasi-CRM',pan],
  ['Mu 等（2019）  ·  gBOIN 与多等级毒性',mu],
  ['Sweeting 等（2025）  ·  共享患者潜在结局',sweet],
  ['CRAN  ·  UnifiedDoseFinding',cran]
 ];
 refs.forEach(([a,u],i)=>link(s,a,u,64,396+57*i,1312,44,24));
 note(s,'GitHub 链接来自原始汇报记录：'+repo+'。本地演示文档 rmd/uniDoseFind演示.rmd。');
}
const draft=path.join(renderDir,'draft.pptx');
await (await PresentationFile.exportPptx(deck)).save(draft);
for(const [i,s] of deck.slides.items.entries()){
 const b=await deck.export({slide:s,format:'png',scale:1});
 await fs.writeFile(path.join(renderDir,'slide-'+String(i+1).padStart(2,'0')+'.png'),new Uint8Array(await b.arrayBuffer()));
}


