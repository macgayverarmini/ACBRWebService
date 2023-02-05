#Código em colaboração com CHAT GPT.

import os
import shutil

def backup_file(file_path):
    backup_path = file_path + ".clone"
    if os.path.exists(backup_path):
        os.remove(backup_path)
    shutil.copy(file_path, backup_path)

def restore_file(file_path):
    backup_file_path = file_path + ".clone"
    if os.path.exists(backup_file_path):
        shutil.copy(backup_file_path, file_path)
        print("Arquivo restaurado com sucesso")
    else:
        print("Arquivo de backup não encontrado")

def read_file(file_path):
    encoding = None
    for enc in ('utf-8', 'ISO-8859-1', 'cp1252'):
        try:
            with open(file_path, 'r', encoding=enc) as f:
                encoding = enc
                return f.readlines(), encoding
        except UnicodeDecodeError:
            continue
    raise Exception(f"Unable to read file '{file_path}' with any of the encodings: utf-8, ISO-8859-1, cp1252")

def write_file(file_path, lines, encoding):
    with open(file_path, 'w', encoding=encoding) as f:
        f.writelines(lines)

def backup_linha(indice, lines):
    return {'codigo':indice,'valor':lines[indice]}

def modify_file(file_path, modified_files):    
    lines, encoding = read_file(file_path)
    file_modified = False
    adding_property_lines = False
    start_monitor = False
    property_lines = []
    #usado para desfazer as alterações caso encontre uma propriedade published
    backup_linhas = []
    
    i = 0
    published_found = False
    # passando pelas linhas
    while i < len(lines):
        line = lines[i]
        # só inicia a verificação quando achar a sessão public no arquivo pascal.
        if "public" in line:
            start_monitor = True
        # quando achar na linha a palavra property, devemos verificar a partir da aqui, todas as linhas por ";"
        # a fim de garantir mover as propriedades que são multilinhas corretamente.
        elif "published" in line:        
            published_found = True        
        elif "property " in line and start_monitor:
            property_line = line
            alimpar = []
            alimpar.append(i)            
            #caso especial, quando a propriedade está em mais de uma linha
            while ";" not in property_line:
                                
                i += 1
                if i == len(lines):
                    break                
                alimpar.append(i)
                property_line += lines[i]
                                    
            # para uma propriedade ser válida para se tornar published, ela precisa ter na property_line
            # os termos "write F" e "read F".
            if "write F" in property_line and "read F" in property_line:
                property_lines.append(property_line)
                
                #limpando as linhas, e fazendo o backup delas
                for index in alimpar:                                    
                    backup_linhas.append(backup_linha(index, lines))                
                    lines[index] = ''
                adding_property_lines = True
        # quando encontrar o end, provávlemente foi encontrado o fim da classe que estamos passando
        # nesse caso vamos adicionar as propriedades uma linha antes.
        elif "end" in line and adding_property_lines:
            adding_property_lines = False            
            # se achou published, que dizer que a classe atual que está sendo processada no arquivo 
            # não precisa de alteração.
            if not published_found:
                lines[i-1] = lines[i-1] + "\npublished\n" + "".join(property_lines)                                        
            else:
                for item in backup_linhas:
                    lines[int(item['codigo'])] = item['valor']

            file_modified = True                    
            property_lines.clear()
            start_monitor = False
        # quando encontrar "implementation", é hora de terminar a função. 
        elif "implementation" in line:
            break
        i += 1

    if file_modified:
        modified_files.append(os.path.basename(file_path))
        write_file(file_path, lines, encoding)
        return True
    else:
        return False



def print_result(files_altered, modified_files):
    print("Concluído! Arquivos alterados:", files_altered)
    if files_altered > 0:
        print("Nomes dos arquivos alterados:")
        for filename in modified_files:
            print(filename)

def alter_files(path, search_subdirectories):
    if not os.path.isdir(path):
        print("O caminho informado não é uma pasta válida.")
        exit()

    files_altered = 0
    modified_files = []

    if search_subdirectories == 's':
        for root, dirs, files in os.walk(path):
            for filename in files:
                if filename.endswith(".pas"):                    
                    file_path = os.path.join(root, filename)
                    backup_file(file_path)
                    files_altered += modify_file(file_path, modified_files)
    else:
        for filename in os.listdir(path):
            if filename.endswith(".pas"):                
                file_path = os.path.join(path, filename)
                backup_file(file_path)
                files_altered += modify_file(file_path, modified_files)

    return files_altered, modified_files
  

path = input("Digite o caminho da pasta ACBR: ")

if path == '':
    path = 'C:\\NFMonitor\\acbr\\Fontes\\ACBrDFe\\ACBrNFe\\'

search_subdirectories = input("Deseja pesquisar em subdiretórios (s/n)? ")

files_altered, modified_files = alter_files(path, search_subdirectories)

print_result(files_altered, modified_files)

if files_altered > 0:
    undo = input("Deseja desfazer as alterações (s/n)? (Dica: você pode tentar compilar no Lazarus antes de tentar desfazer aqui!) ")
    if undo == "s":
        for file_path in modified_files:
            restore_file(os.path.join(path, file_path))
        print("Alterações desfeitas.")


