import zipfile
from pathlib import Path
z=zipfile.ZipFile('C:/Users/23676/Desktop/组会汇报.docx')
for n in z.namelist():
 if n.startswith('word/media/'):
  b=z.read(n); print(n,len(b),b[:16]); Path('.dose-build',Path(n).stem+'.png').write_bytes(b)
