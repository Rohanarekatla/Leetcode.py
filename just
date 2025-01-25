import configparser

# Define the file name for mappings
mapping_file = "mappings.txt"

# Function to load all mappings from a file
def load_all_mappings(file_path):
    config = configparser.ConfigParser(allow_no_value=True, delimiters=":")
    config.optionxform = str  # Preserve case sensitivity
    config.read(file_path)

    mappings = {}
    for section in config.sections():
        mappings[section] = {key.strip(): value.strip() for key, value in config.items(section)}
    return mappings

# Load all mappings from the file
all_mappings = load_all_mappings(mapping_file)

# Example usage
locationnum = "09"
selected_mapping = "mapping1"

if selected_mapping in all_mappings:
    bidirectional_mapping = all_mappings[selected_mapping]
    if locationnum in bidirectional_mapping:
        mapped_value = bidirectional_mapping[locationnum]
        print(f"Location {locationnum} maps to {mapped_value} in {selected_mapping}")
    else:
        print(f"Location {locationnum} not found in {selected_mapping}")
else:
    print(f"Mapping {selected_mapping} not found.")