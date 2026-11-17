from PIL import Image
import glob
files=sorted(glob.glob('.dose-build/slide-*.png'))
sheet=Image.new('RGB',(1440,5*280),'#dce5e0')
for i,f in enumerate(files):
 im=Image.open(f).convert('RGB')
 im.thumbnail((468,265))
 sheet.paste(im,((i%3)*480+6,(i//3)*280+6))
sheet.save('.dose-build/contact.png')
import fitz
p=fitz.open('.dose-build/sweet-published.pdf')
print(len(files),len(p))
for page in p: print(page.get_text()[:180])
