import os
import subprocess
import argparse
import sys

def find_and_compile_resources(lazarus_path, acbr_path):
    """
    Percorre o diretório do ACBr, encontra arquivos .bat que compilam recursos
    e executa o comando equivalente no Linux.
    """
    lazres_exe = os.path.join(lazarus_path, "tools", "lazres")

    if not os.path.isfile(lazres_exe):
        print(f"ERRO: Compilador de recursos 'lazres' não encontrado em: {lazres_exe}")
        sys.exit(1)

    print(f"Usando compilador de recursos: {lazres_exe}")
    print("-" * 40)

    total_found = 0
    total_compiled = 0

    for root, _, files in os.walk(acbr_path):
        for file in files:
            if file.lower().endswith(".bat"):
                bat_path = os.path.join(root, file)
                try:
                    with open(bat_path, 'r', encoding='latin-1') as f:
                        content = f.read()

                    if "lazres" in content.lower():
                        total_found += 1
                        print(f"Arquivo de resource batch encontrado: {bat_path}")

                        lines = content.splitlines()
                        for line in lines:
                            line_lower = line.lower()
                            if "lazres" in line_lower and not line_lower.strip().startswith("rem"):
                                parts = line.split()
                                try:
                                    # Encontra o índice do executável 'lazres'
                                    lazres_args_idx = [p.lower().endswith("lazres") or p.lower().endswith("lazres.exe") for p in parts].index(True)
                                    args = parts[lazres_args_idx + 1:]
                                    
                                    if len(args) >= 2:
                                        output_res = args[0]
                                        input_file = args[1]
                                        
                                        cmd_list = [lazres_exe, output_res, input_file]
                                        
                                        print(f"  -> Executando: {' '.join(cmd_list)}")
                                        
                                        result = subprocess.run(cmd_list, cwd=root, capture_output=True, text=True, check=False)
                                        
                                        if result.returncode == 0:
                                            print(f"  -> SUCESSO: '{output_res}' gerado.")
                                            total_compiled += 1
                                        else:
                                            print(f"  -> ERRO ao compilar '{output_res}':")
                                            print(result.stderr or result.stdout)
                                except (ValueError, IndexError):
                                     print(f"  -> AVISO: Não foi possível interpretar a linha: '{line}'")

                except Exception as e:
                    print(f"  -> ERRO ao processar o arquivo {bat_path}: {e}")
    
    print("-" * 40)
    print(f"Busca finalizada. Encontrados: {total_found} scripts de compilação de resource.")
    print(f"Recursos compilados com sucesso: {total_compiled}.")
    
    if total_found != total_compiled:
        print("AVISO: Alguns recursos não puderam ser compilados.")
        
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compila arquivos de recurso (.res) do ACBr para Linux.")
    parser.add_argument("--lazarus-path", required=True, help="Caminho para o diretório de instalação do Lazarus.")
    parser.add_argument("--acbr-path", required=True, help="Caminho para o diretório de fontes do ACBr.")
    
    args = parser.parse_args()
    
    find_and_compile_resources(args.lazarus_path, args.acbr_path)
