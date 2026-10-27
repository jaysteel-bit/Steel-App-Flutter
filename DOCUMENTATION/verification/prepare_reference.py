from pathlib import Path
import re, shutil
root=Path('DOCUMENTATION/verification')
src=Path('C:/Users/viole/Desktop/WEBSITES/steelaccess-html/steel.html').read_text(encoding='utf-8')
def safe(m):
    s=m.group(0)
    return s if ('cdn.tailwindcss.com' in s or 'lucide@' in s or 'tailwind.config' in s) else ''
src=re.sub(r'<script\b[^>]*>.*?</script>',safe,src,flags=re.S|re.I)
src=re.sub(r'<noscript>.*?</noscript>','',src,flags=re.S|re.I)
src=src.replace('assets/images/steel-assets/alexa-pfp.jpg','../../assets/images/alexa-pfp.jpg')
src=src.replace('</head>', '''<style>
header,main>section,body>footer{display:none!important} main{padding:32px!important;gap:0!important}
#phone-tilt{animation:none!important} #profile{opacity:1!important;pointer-events:auto!important}
#locked,#verification{display:none!important}
</style></head>''')
src=src.replace('</body>','<script>lucide.createIcons();</script></body>')
(root/'reference.html').write_text(src,encoding='utf-8')
