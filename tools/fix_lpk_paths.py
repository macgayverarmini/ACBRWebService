import os

root = r'C:\NFMonitor\acbr\Pacotes\Lazarus'
count = 0

for d, _, files in os.walk(root):
    for f in files:
        if f.endswith('.lpk'):
            path = os.path.join(d, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as file:
                content = file.read()
            # FPDF and similar packages have an extra ..\
            if r'..\..\..\..\..\..\..\Fontes' in content:
                new_content = content.replace(r'..\..\..\..\..\..\..\Fontes', r'..\..\..\..\..\..\Fontes')
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as file:
                        file.write(new_content)
                    count += 1
                    print(f'Fixed path in {f}')
print(f'Total fixed: {count}')
