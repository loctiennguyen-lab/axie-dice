"""Cuts the BACK VIEW of Liam's official Tempest sheet (Variation 1) into tempest_back_ref.png.
Run with plain python3 (needs Pillow):  python3 cut_tempest_ref.py "<.../Bird_Design_Sheet_Official_Variation_1_PNG.png>"
The crop is taken 475 sheet-px above the FRONT VIEW crop (sheet y 125..455 vs 600..930) so that
back-view pixel coordinates equal front-view ones; half resolution keeps the file small."""
import sys
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
k = 5.35   # sheet is 10707 px wide, shown at 2000 in the coordinates below
A = Image.open(sys.argv[1]).convert("RGB")
im = A.crop(tuple(int(v * k) for v in (130, 125, 950, 455)))
im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
im.save(__file__.replace("cut_tempest_ref.py", "tempest_back_ref.png"), optimize=True)
print(im.size)
