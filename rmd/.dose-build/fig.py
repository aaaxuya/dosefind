import fitz
doc=fitz.open('.dose-build/sweet.pdf')
for i,p in enumerate(doc):
 for s in ['Figure 4:', 'Figure 3:', 'Figure 4.', 'Figure 3.']:
  for a in p.search_for(s):
   print(i,s,a,p.rect); print([(b[:4],str(b[4])[:90]) for b in p.get_text('blocks') if a.y0-325<b[1]<a.y0+15]); print(p.get_image_info())
