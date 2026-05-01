import json
import copy

def update_collection():
    with open('ACBRWebAPI.postman_collection.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Encontrar a pasta NF-e
    nfe_folder = None
    for item in data.get('item', []):
        if item.get('name') == 'NFe':
            nfe_folder = item
            break
            
    if not nfe_folder:
        print("Pasta NFe não encontrada na coleção.")
        return
        
    # Remover pasta CTe existente se estiver vazia ou for substituída
    data['item'] = [i for i in data['item'] if i.get('name') != 'CTe']

    # Duplicar a pasta NFe e renomear tudo para CTe
    cte_folder = copy.deepcopy(nfe_folder)
    cte_folder['name'] = 'CTe'
    
    def replace_strings(obj):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if isinstance(v, str):
                    v = v.replace('nfe', 'cte').replace('NFe', 'CTe').replace('NFE', 'CTE')
                    obj[k] = v
                else:
                    replace_strings(v)
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                if isinstance(item, str):
                    obj[i] = item.replace('nfe', 'cte').replace('NFe', 'CTe').replace('NFE', 'CTE')
                else:
                    replace_strings(item)

    replace_strings(cte_folder)

    # Inserir após a pasta NFe
    items = data.get('item', [])
    nfe_index = items.index(nfe_folder)
    items.insert(nfe_index + 1, cte_folder)
    
    with open('ACBRWebAPI.postman_collection.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        
    print("Coleção Postman atualizada com sucesso!")

if __name__ == '__main__':
    update_collection()
