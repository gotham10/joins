import json
import re

def extract_all_inventory_data():
    with open('index.html', 'r', encoding='utf-8') as file:
        content = file.read()
    
    chunks = re.findall(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)', content, re.DOTALL)
    
    combined = ""
    for chunk in chunks:
        try:
            combined += json.loads('"' + chunk + '"')
        except:
            combined += chunk.replace('\\"', '"').replace('\\\\', '\\')
            
    start_pos = combined.find('"initialPets":[')
    if start_pos == -1:
        start_pos = combined.find(':[{"image":')
    
    if start_pos == -1:
        return
        
    start_idx = combined.find('[', start_pos)
    bracket_count = 0
    end_idx = -1
    for i in range(start_idx, len(combined)):
        if combined[i] == '[':
            bracket_count += 1
        elif combined[i] == ']':
            bracket_count -= 1
            if bracket_count == 0:
                end_idx = i + 1
                break
                
    if end_idx != -1:
        try:
            raw_data = json.loads(combined[start_idx:end_idx])
            all_items = []
            for item in raw_data:
                val = item.get('value', item.get('rvalue', '0'))
                
                item_data = {
                    "name": item.get('name', ''),
                    "trading_value": str(val),
                    "category": item.get('type', ''),
                    "rarity": item.get('rarity', item.get('raity', '')),
                    "internal_score": str(item.get('score', '')),
                    "is_favorite": str(item.get('favorite', 'false')),
                    "image_url": item.get('image', '')
                }
                all_items.append(item_data)
                
            with open('pets.json', 'w', encoding='utf-8') as outfile:
                json.dump(all_items, outfile, indent=2)
        except:
            pass

if __name__ == "__main__":
    extract_all_inventory_data()