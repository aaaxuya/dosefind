import fitz
from pathlib import Path
try:
 doc=fitz.open('.dose-build/sweet-published.pdf')
 p=doc[7]; a=p.search_for('FIGURE 4')[0]
 print(p.rect,a,p.get_image_info())
 p.get_pixmap(matrix=fitz.Matrix(1.4,1.4)).save('.dose-build/paper-page.png')
except Exception as e:
 print(e)
 p=fitz.open('.dose-build/sweet.pdf')[25]
 p.get_pixmap(matrix=fitz.Matrix(3,3),clip=fitz.Rect(p.get_image_info()[0]['bbox'])).save('.dose-build/sweet-fig4.png')
