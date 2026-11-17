from pathlib import Path
import os,zipfile,re,hashlib,csv
out=next(Path('汇报成品').glob('*.pptx'))
draft=Path('.dose-build/draft.pptx')
assert hashlib.sha256(out.read_bytes()).digest()==hashlib.sha256(draft.read_bytes()).digest()
with zipfile.ZipFile(out) as z:
 assert z.testzip() is None
 slides=[n for n in z.namelist() if re.fullmatch(r'ppt/slides/slide\d+.xml',n)]
 assert len(slides)==13
 media=[z.read(n) for n in z.namelist() if n.startswith('ppt/media/') and not n.endswith('/')]
 for value in ['0c5fee64-2070-4dda-a0a8-24140c375fb4','b95aa5c5-2f7e-44d9-92b5-cbe4aa000ab3']:
  assert (Path(os.environ['TEMP'])/f'codex-clipboard-{value}.png').read_bytes() in media
 assert b'https://github.com/aaaxuya/dosefind' in z.read('ppt/slides/_rels/slide13.xml.rels')
 result=z.read('ppt/slides/slide9.xml').decode()
 with open('../DoseFindingResearch/results/pcs_comparison/comparison.csv') as f:
  for row in csv.DictReader(f):
   assert f'{int(row["n_correct"]):,}' in result
 print('13 slides; 2 original images byte-identical; three PCS counts and GitHub link verified')
