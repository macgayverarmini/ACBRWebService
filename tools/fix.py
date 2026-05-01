import os
import re

root = r'C:\NFMonitor\acbr\Fontes'
pattern = re.compile(r'(?s)published([\s\r\n]+(?!(?:\s*property FormatSettings:)).*?)^\s*property FormatSettings:\s*TFormatSettings\s*read\s*FFormatSettings\s*write\s*FFormatSettings;', re.MULTILINE)
count = 0

for d, _, files in os.walk(root):
    for f in files:
        if f.endswith('.pas'):
            path = os.path.join(d, f)
            with open(path, 'r', encoding='iso-8859-1') as file:
                content = file.read()
            if 'FormatSettings: TFormatSettings' in content and 'published' in content:
                new_content = pattern.sub(r'published\1\n  public\n    property FormatSettings: TFormatSettings read FFormatSettings write FFormatSettings;', content)
                if new_content != content:
                    with open(path, 'w', encoding='iso-8859-1') as file:
                        file.write(new_content)
                    count += 1
                    print(f'Fixed {f}')
print(f'Total fixed: {count}')
