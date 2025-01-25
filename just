def load_all_mappings(file_path):
    mappings = {}
    current_mapping = None

    with open(file_path, "r") as f:
        for line in f:
            line = line.strip()

            # Check if it's a new mapping section
            if line.startswith("[") and line.endswith("]"):
                current_mapping = line[1:-1]  # Get section name without brackets
                mappings[current_mapping] = {}
            elif ":" in line and current_mapping:
                # Parse key-value pairs
                key, value = line.split(":")
                mappings[current_mapping][key.strip()] = value.strip()

    return mappings