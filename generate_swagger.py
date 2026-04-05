import os
import re
import yaml

# Constants for tags and descriptions
TAGS = {
    'NFe': 'Nota Fiscal Eletrônica (NF-e)',
    'CTe': 'Conhecimento de Transporte Eletrônico (CT-e)',
    'NFSe': 'Nota Fiscal de Serviços Eletrônica (NFS-e)',
    'MDFe': 'Manifesto de Documentos Fiscais Eletrônicos (MDF-e)',
    'Certificados': 'Manipulação de Certificados Digitais',
    'Diversos': 'Rotinas Diversas (Validador, Extenso)'
}

def get_routes_from_strings_pas(filepath):
    routes_vars = {}
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    resourcestring_block = re.search(r'resourcestring(.*?)(implementation|end\.)', content, re.DOTALL | re.IGNORECASE)
    if not resourcestring_block:
        return routes_vars

    lines = resourcestring_block.group(1).split('\n')
    for line in lines:
        match = re.match(r'\s*(\w+)\s*=\s*\'([^\']+)\'\s*;', line)
        if match:
            var_name, path = match.groups()
            routes_vars[var_name] = path

    return routes_vars

def parse_routes_file(filepath, strings_dict):
    routes = []
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Determine module tag based on filename
    filename = os.path.basename(filepath)
    tag = 'Diversos'
    if 'nfe' in filename:
        tag = 'NFe'
    elif 'nfse' in filename:
        tag = 'NFSe'
    elif 'cte' in filename:
        tag = 'CTe'
    elif 'mdfe' in filename:
        tag = 'MDFe'
    elif 'certificados' in filename:
        tag = 'Certificados'

    # Extract all THorse route definitions
    # Match THorse.Get, THorse.Post, etc.
    # Handle both direct string literals and constants from resource strings
    route_matches = re.finditer(r'THorse\.(Get|Post)\(\s*([^,]+)\s*,', content, re.IGNORECASE)
    for match in route_matches:
        method = match.group(1).lower()
        path_arg = match.group(2).strip()

        path = ""
        if path_arg.startswith("'") and path_arg.endswith("'"):
            path = path_arg[1:-1]
        elif path_arg in strings_dict:
            path = strings_dict[path_arg]
        else:
            continue # Unknown path constant

        description = "Obtém o modelo JSON para esta operação." if method == 'get' else "Executa a operação usando o payload JSON."
        summary_base = path.split('/')[-1].replace('-', ' ').title()

        if method == 'get':
            summary = f"Modelo para {summary_base}"
        else:
            summary = f"Operação {summary_base}"

        routes.append({
            'path': path,
            'method': method,
            'tag': tag,
            'summary': summary,
            'description': description
        })

    return routes

def generate_openapi():
    # Parse resource strings
    strings_dict = get_routes_from_strings_pas('resources/resource.strings.routes.pas')

    routes_dir = 'routes'
    all_routes = []

    for filename in os.listdir(routes_dir):
        if filename.startswith('route.') and filename.endswith('.pas'):
            filepath = os.path.join(routes_dir, filename)
            all_routes.extend(parse_routes_file(filepath, strings_dict))

    # Remove duplicates
    unique_routes = {}
    for r in all_routes:
        key = (r['path'], r['method'])
        if key not in unique_routes:
            unique_routes[key] = r

    # Build OpenAPI dict
    openapi = {
        'openapi': '3.0.3',
        'info': {
            'title': 'ACBRWebService API',
            'description': 'API REST para integração com a biblioteca ACBR via HTTP.',
            'version': '1.0.0'
        },
        'tags': [{'name': k, 'description': v} for k, v in TAGS.items()],
        'paths': {}
    }

    for (path, method), r in sorted(unique_routes.items()):
        if path not in openapi['paths']:
            openapi['paths'][path] = {}

        operation = {
            'tags': [r['tag']],
            'summary': r['summary'],
            'description': r['description'],
            'responses': {
                '200': {
                    'description': 'Sucesso',
                    'content': {
                        'application/json': {}
                    }
                },
                '400': {
                    'description': 'Erro na requisição (ex: JSON inválido)',
                    'content': {
                        'application/json': {}
                    }
                }
            }
        }

        if method in ['post', 'put', 'patch']:
            operation['requestBody'] = {
                'description': 'Payload em formato JSON',
                'required': True,
                'content': {
                    'application/json': {
                        'schema': {
                            'type': 'object',
                            'description': 'Para saber o formato exato, chame o endpoint GET correspondente (se disponível) para obter o modelo JSON.'
                        }
                    }
                }
            }

        openapi['paths'][path][method] = operation

    with open('swagger.yaml', 'w', encoding='utf-8') as f:
        yaml.dump(openapi, f, allow_unicode=True, sort_keys=False)

    print("swagger.yaml gerado com sucesso.")

if __name__ == '__main__':
    generate_openapi()
