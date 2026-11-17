from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as E
folder=Path('汇报成品')
tag='{http://schemas.openxmlformats.org/drawingml/2006/main}t'
with ZipFile(next(folder.glob('*修订版.pptx'))) as old, ZipFile(next(folder.glob('*蓝灰版.pptx'))) as new:
 assert new.testzip() is None
 def texts(z,i):
  return [n.text for n in E.fromstring(z.read(f'ppt/slides/slide{i}.xml')).iter(tag)]
 for i in range(2,14):
  before=texts(old,i)[0:]
  after=texts(new,i)
  after.remove('一期剂量探索')
  assert before==after, (i,before,after)
 old_media=[old.read(n) for n in old.namelist() if n.startswith('ppt/media/') and not n.endswith('/')]
 new_media=[new.read(n) for n in new.namelist() if n.startswith('ppt/media/') and not n.endswith('/')]
 assert all(data in new_media for data in old_media)
 assert b'https://github.com/aaaxuya/dosefind' in new.read('ppt/slides/_rels/slide13.xml.rels')
 print('13 slides. Body text, original figures and GitHub link verified.')
