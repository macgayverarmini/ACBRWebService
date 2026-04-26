import os
import re
import json

def parse_routes(routes_dir):
    paths = {}
    
    # Regex para identificar THorse.Get('rota', metodo) e THorse.Post('rota', metodo)
    route_pattern = re.compile(r'THorse\.(Get|Post|Put|Delete)\s*\(\s*([^,]+)\s*,\s*([^\)]+)\s*\)', re.IGNORECASE)
    
    for filename in os.listdir(routes_dir):
        if not filename.endswith('.pas'):
            continue
            
        module_tag = filename.replace('route.acbr.', '').replace('.pas', '').upper()
            
        filepath = os.path.join(routes_dir, filename)
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # Tentar ler as strings das rotas se elas forem constantes (ex: RSNFeStatusRoute)
        # O ideal aqui é ler o resource.strings.routes.pas, mas como fallback podemos usar a string literal
        
        matches = route_pattern.findall(content)
        for method, route_str, handler in matches:
            method = method.lower()
            
            # Se a rota for uma constante (ex: RSNFeNFeRoute), vamos apenas usar o nome da constante por enquanto
            # Em uma versao mais robusta, leríamos o resource.strings.routes.pas
            route_path = route_str.replace("'", "")
            
            if route_path not in paths:
                paths[route_path] = {}
                
            paths[route_path][method] = {
                "tags": [module_tag],
                "summary": f"{method.upper()} {handler.strip()}",
                "description": f"Endpoint handled by {handler.strip()}",
                "responses": {
                    "200": {
                        "description": "Sucesso"
                    },
                    "500": {
                        "description": "Erro interno do servidor"
                    }
                }
            }
            
            # Se for POST, adicionar um body generico
            if method in ['post', 'put']:
                paths[route_path][method]["requestBody"] = {
                    "description": "Payload com as configurações do ACBr e dados do documento",
                    "required": True,
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "config": {
                                        "type": "object",
                                        "description": "Configurações do ACBr (Certificado, Arquivos, etc)"
                                    },
                                    "dados": {
                                        "type": "string",
                                        "description": "XML ou dados estruturados em Base64 ou Texto"
                                    }
                                }
                            }
                        }
                    }
                }
                
    return paths

def resolve_constants(paths, strings_file):
    with open(strings_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        
    constants = {}
    # Busca consts: RSNFeRoute = '/nfe/enviar';
    const_pattern = re.compile(r'([A-Za-z0-9_]+)\s*=\s*\'([^\']+)\'')
    for match in const_pattern.findall(content):
        constants[match[0]] = match[1]
        
    resolved_paths = {}
    for route, data in paths.items():
        if route in constants:
            real_route = constants[route]
            resolved_paths[real_route] = data
        else:
            resolved_paths[route] = data
            
    return resolved_paths

def generate_swagger():
    src_dir = os.path.dirname(os.path.abspath(__file__))
    routes_dir = os.path.join(src_dir, 'routes')
    strings_file = os.path.join(src_dir, 'resources', 'resource.strings.routes.pas')
    output_file = os.path.join(src_dir, 'resources', 'swagger.json')
    
    print("Analisando rotas...")
    raw_paths = parse_routes(routes_dir)
    
    print("Resolvendo constantes de rota...")
    paths = resolve_constants(raw_paths, strings_file)
    
    swagger = {
        "openapi": "3.0.0",
        "info": {
            "title": "ACBRWebService API",
            "description": "API REST gerada automaticamente para os componentes ACBr.",
            "version": "1.0.0"
        },
        "paths": paths
    }
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(swagger, f, indent=2, ensure_ascii=False)
        
    print(f"Swagger JSON gerado com sucesso em: {output_file}")

if __name__ == "__main__":
    generate_swagger()
