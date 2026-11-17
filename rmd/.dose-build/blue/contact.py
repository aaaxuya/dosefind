from PIL import Image
import glob
files=sorted(glob.glob('.dose-build/blue/slide-*.png'))
sheet=Image.new('RGB',(1440,5*280),'#dce5e0')
for i,f in enumerate(files):
 im=Image.open(f).convert('RGB')
 im.thumbnail((468,265))
 sheet.paste(im,((i%3)*480+6,(i//3)*280+6))
sheet.save('.dose-build/blue/contact.png')
