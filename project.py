import os

# Define the desired directory structure
directory_structure = {
    "packer": ["qVvpn-packer.json", "install_software.sh"],
    "vagrant": ["Vagrantfile"],
    "terraform": ["main.tf", "variables.tf", "outputs.tf"],
    "environments": ["qVvpn_env.yml"],
    "scripts": ["install_requirements.sh", "update_certs.sh"],
    "docs": [],
}

# Base directory
base_dir = os.getcwd()  # Use the current working directory

# Create directories and files
for folder, files in directory_structure.items():
    folder_path = os.path.join(base_dir, folder)
    os.makedirs(folder_path, exist_ok=True)  # Create the folder if it doesn't exist
    for file in files:
        file_path = os.path.join(folder_path, file)
        with open(file_path, "w") as f:
            f.write("")  # Create an empty file

print(f"File structure created in {base_dir}.")
