import os
import shutil
import re
from tqdm import tqdm

backups_file_list = []

def backup_file(file_path):
    """Cria um backup do arquivo original antes de modificá-lo."""
    backups_file_list.append(file_path)
    backup_path = file_path + ".clone"
    if os.path.exists(backup_path):
        os.remove(backup_path)
    shutil.copy(file_path, backup_path)

def restore_files():
    """Restaura os arquivos a partir dos backups, com uma barra de progresso."""
    if not backups_file_list:
        print("Nenhum backup para restaurar.")
        return

    print("Restaurando arquivos originais...")
    for pre_backup_file_path in tqdm(backups_file_list, desc="Restaurando arquivos", unit="file", ncols=100):
        backup_file_path = pre_backup_file_path + ".clone"
        if os.path.exists(backup_file_path):
            shutil.copy(backup_file_path, pre_backup_file_path)
            os.remove(backup_file_path)
        else:
            tqdm.write(f"Aviso: Arquivo de backup não encontrado para {os.path.basename(pre_backup_file_path)}")

def read_file(file_path):
    """Tenta ler um arquivo com diferentes codificações."""
    for enc in ('utf-8', 'ISO-8859-1', 'cp1252'):
        try:
            with open(file_path, 'r', encoding=enc) as f:
                return f.readlines(), enc
        except UnicodeDecodeError:
            continue
    raise Exception(f"Não foi possível ler o arquivo '{file_path}' com nenhuma das codificações tentadas.")

def write_file(file_path, lines, encoding):
    """Escreve as linhas de volta no arquivo com a codificação correta."""
    with open(file_path, 'w', encoding=encoding) as f:
        f.writelines(lines)

def backup_linha(indice, lines):
    """Cria um dicionário para o backup de uma linha específica."""
    return {'codigo': indice, 'valor': lines[indice]}

def modify_file(file_path):
    """
    Modifica um único arquivo .pas, movendo propriedades de 'public' para 'published',
    ignorando blocos de comentários.
    Retorna True se o arquivo foi modificado, False caso contrário.
    """
    lines, encoding = read_file(file_path)
    file_modified = False
    start_monitor = False
    start_public = False
    property_lines = []
    backup_linhas = []
    
    i = 0
    published_found = False
    in_multiline_comment = False  # NOVO: Flag para controlar o estado do comentário multilinha

    while i < len(lines):
        original_line = lines[i]
        line_to_process = original_line

        # --- LÓGICA PARA LIDAR COM COMENTÁRIOS ---
        # 1. Se já estamos em um comentário, procurar pelo fim
        if in_multiline_comment:
            end_star_pos = line_to_process.find('*)')
            end_curly_pos = line_to_process.find('}')
            
            end_pos = -1
            if end_star_pos != -1 and end_curly_pos != -1:
                end_pos = min(end_star_pos, end_curly_pos)
            elif end_star_pos != -1:
                end_pos = end_star_pos
            elif end_curly_pos != -1:
                end_pos = end_curly_pos

            if end_pos != -1:
                in_multiline_comment = False
                # A linha a ser processada é o que vem DEPOIS do comentário
                line_to_process = line_to_process[end_pos + (2 if end_pos == end_star_pos else 1):]
            else:
                # Ainda dentro do comentário, pular a linha inteira
                i += 1
                continue
        
        # 2. Remover comentários de linha única e procurar por início de multilinha
        # Remove comentários de linha (//)
        if '//' in line_to_process:
            line_to_process = line_to_process.split('//', 1)[0]

        # Lida com múltiplos comentários (*...*) ou {...} na mesma linha
        clean_line = ""
        while '(*' in line_to_process or '{' in line_to_process:
            start_star_pos = line_to_process.find('(*')
            start_curly_pos = line_to_process.find('{')

            start_pos = -1
            if start_star_pos != -1 and start_curly_pos != -1:
                start_pos = min(start_star_pos, start_curly_pos)
            elif start_star_pos != -1:
                start_pos = start_star_pos
            else:
                start_pos = start_curly_pos
            
            clean_line += line_to_process[:start_pos] # Adiciona o trecho antes do comentário
            
            # Encontrar o fim do comentário
            is_star_comment = (start_pos == start_star_pos)
            end_marker = '*)' if is_star_comment else '}'
            end_pos = line_to_process.find(end_marker, start_pos)

            if end_pos != -1: # Comentário fecha na mesma linha
                line_to_process = line_to_process[end_pos + len(end_marker):]
            else: # Comentário não fecha, entramos no modo multilinha
                in_multiline_comment = True
                line_to_process = "" # O resto da linha é comentário
                break
        
        clean_line += line_to_process
        line_to_process = clean_line.strip()
        # --- FIM DA LÓGICA DE COMENTÁRIOS ---

        if not line_to_process: # Se a linha ficou vazia após limpar comentários
            i += 1
            continue

        # A partir daqui, usar "line_to_process" para a lógica de negócio
        if "type" in line_to_process:
            start_public = True
        elif "public" in line_to_process and start_public:
            start_monitor = True
        elif "published" in line_to_process:
            published_found = True
        elif "property " in line_to_process and start_monitor:
            property_line = original_line # Coleta a linha original, não a processada

            if any(s in property_line for s in ["property Certificado: PCCERT_CONTEXT", 
                                                "property Certificado: pX509", 
                                                "property SaveOptions: TSaveOptions"]):
                i += 1
                continue
            
            alimpar = [i]
            # Usa a linha original para a lógica de multilinhas da propriedade
            temp_prop_line = original_line 
            while ";" not in temp_prop_line:
                i += 1
                if i >= len(lines):
                    break
                alimpar.append(i)
                temp_prop_line += lines[i]
                property_line += lines[i]
            
            # A verificação final usa a linha completa da propriedade
            if "read F" in temp_prop_line:
                property_lines.append(property_line)
                for index in alimpar:
                    backup_linhas.append(backup_linha(index, lines))
                    lines[index] = ''
                file_modified = True

        elif "end;" in line_to_process.replace(" ", ""):
            if property_lines:
                if not published_found:
                    lines[i-1] = lines[i-1] + "\n  published\n" + "".join(property_lines)
                else:
                    for item in backup_linhas:
                        lines[int(item['codigo'])] = item['valor']
                    file_modified = False
                
                backup_linhas.clear()
                property_lines.clear()
            
            published_found = False
            start_monitor = False
        elif "implementation" in line_to_process:
            break
        i += 1

    if file_modified:
        write_file(file_path, [l for l in lines if l is not None], encoding)
        return True
    return False

# O restante do script (print_result, alter_files, e o bloco main) permanece o mesmo da versão anterior.
# Por questão de completude, o incluí abaixo sem alterações.

def print_result(files_altered, modified_files):
    """Imprime o resultado final da operação."""
    print("\nConcluído!")
    if files_altered > 0:
        print(f"Total de arquivos alterados: {files_altered}")
    else:
        print("Nenhum arquivo foi modificado.")

def alter_files(path, search_subdirectories):
    """Percorre os diretórios, encontra os arquivos .pas e os modifica."""
    if not os.path.isdir(path):
        print("O caminho informado não é uma pasta válida.")
        return 0, []

    pas_files_to_process = []
    if search_subdirectories == 's':
        for root, _, files in os.walk(path):
            for filename in files:
                if filename.endswith(".pas"):
                    pas_files_to_process.append(os.path.join(root, filename))
    else:
        for filename in os.listdir(path):
            if filename.endswith(".pas"):
                pas_files_to_process.append(os.path.join(path, filename))

    if not pas_files_to_process:
        print("Nenhum arquivo .pas encontrado no caminho especificado.")
        return 0, []

    modified_files = []
    
    for file_path in tqdm(pas_files_to_process, desc="Processando arquivos Pascal", unit="file", ncols=100):
        try:
            backup_file(file_path)
            if modify_file(file_path):
                modified_files.append(os.path.basename(file_path))
        except Exception as e:
            tqdm.write(f"\nErro ao processar o arquivo {os.path.basename(file_path)}: {e}")


    return len(modified_files), modified_files

# --- Bloco Principal ---
if __name__ == "__main__":
    try:
        path = input("Digite o caminho da pasta ACBR (ex: C:\\ACBr\\Fontes\\ACBrDFe\\): ")
        if not path:
            path = 'C:\\NFMonitor\\acbr\\Fontes\\ACBrDFe\\'
            print(f"Usando caminho padrão: {path}")

        search_subdirectories = input("Deseja pesquisar em subdiretórios (s/n)? [s]: ") or 's'

        files_altered, modified_files = alter_files(path, search_subdirectories)
        print_result(files_altered, modified_files)

        if files_altered > 0:
            undo = input("Deseja desfazer as alterações (s/n)? [n]: ") or 'n'
            if undo.lower() == "s":
                restore_files()
                print("Alterações desfeitas com sucesso.")
    except KeyboardInterrupt:
        print("\nOperação interrompida pelo usuário. Desfazendo alterações...")
        restore_files()
        print("Alterações desfeitas.")
    except Exception as e:
        print(f"\nOcorreu um erro inesperado: {e}")