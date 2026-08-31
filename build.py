import os,sys
PUBLIC = 'public' in sys.argv
def r(p): return open(p,encoding='utf-8').read()
FILES=[('%CSS%','src/style.css'),('%ART%','src/art.js'),('%DATA%','src/data.js'),
       ('%ENGINE%','src/engine.js'),('%AUDIO%','src/audio.js'),('%ICONS%','src/icons.js'),
       ('%UI%','src/ui.js'),('%FX%','src/fx.js'),('%DEV%','src/devtools.js')]
html = """<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>Axie Dice Tactics: Lunacia Mutants</title>
<meta name="description" content="A deterministic tactical roguelike. Every Axie is a six-sided die, and every face is a body part. Build the die, then break the game.">
<meta name="theme-color" content="#3c081b">
<meta property="og:type" content="website">
<meta property="og:title" content="Axie Dice Tactics: Lunacia Mutants">
<meta property="og:description" content="A deterministic tactical roguelike. Every Axie is a six-sided die, and every face is a body part.">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="data:image/png;base64,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">
<style>
%CSS%
</style>
</head><body>
<div id="app"></div>
<script>
%ART%
%DATA%
%ENGINE%
%AUDIO%
%ICONS%
%UI%
%FX%
%DEV%
</script>
</body></html>
"""
for k,f in FILES:
    if PUBLIC and k=='%DEV%':
        html=html.replace(k,'/* dev tools stripped from public build */'); continue
    html=html.replace(k,r(f))
out='index.html' if PUBLIC else 'AxieDiceTactics.html'
open(out,'w',encoding='utf-8').write(html)
print(('PUBLIC ' if PUBLIC else 'DEV    ')+out, round(os.path.getsize(out)/1024),'KB')
