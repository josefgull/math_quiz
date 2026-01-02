import os
from pathlib import Path


def dart_safe_name(name: str) -> str:
    """
    Convert file/folder names into Dart-safe identifiers
    """
    name = name.replace(" ", "_").replace("-", "_")
    return name


def generate_folder(path: Path, indent=0) -> str:
    indent_str = "  " * indent
    lines = []

    lines.append(f"{indent_str}Folder(")
    lines.append(f"{indent_str}  name: '{path.name}',")

    subfolders = []
    files = []

    for item in sorted(path.iterdir()):
        if item.is_dir():
            subfolders.append(item)
        elif item.is_file() and item.suffix == ".dart":
            files.append(item)

    if subfolders:
        lines.append(f"{indent_str}  subfolders: [")
        for folder in subfolders:
            lines.append(generate_folder(folder, indent + 2) + ",")
        lines.append(f"{indent_str}  ],")

    if files:
        lines.append(f"{indent_str}  files: [")
        for file in files:
            name = file.stem.replace("_", " ")
            getter = dart_safe_name(file.stem)
            lines.append(
                f"{indent_str}    FileNode(name: '{name}', getQuestions: () => {getter}),"
            )
        lines.append(f"{indent_str}  ],")

    lines.append(f"{indent_str})")
    return "\n".join(lines)


def generate_root(root_path: str) -> str:
    root = Path(root_path)
    return f"""final Folder rootMenu = {generate_folder(root)};
"""


def generate_imports(root_path: str, base_folder="questions") -> str:
    """
    Generate Dart import statements for all .dart files.
    `base_folder` is the relative path used in imports.
    """
    root = Path(root_path)
    imports = []

    for file_path in root.rglob("*.dart"):
        # compute relative path from the root folder
        rel_path = file_path.relative_to(root)
        rel_path_str = str(rel_path).replace(os.sep, "/")
        imports.append(f"import '{base_folder}/{rel_path_str}';")

    # sort imports alphabetically
    imports.sort()
    return "\n".join(imports)



if __name__ == "__main__":
    # CHANGE THIS PATH 👇
    ROOT_FOLDER_PATH = os.getcwd() + "/lib/questions"
    BASE_IMPORT_FOLDER = "questions"
    # generate
    dart_code = generate_root(ROOT_FOLDER_PATH)
    imports_code = generate_imports(ROOT_FOLDER_PATH, BASE_IMPORT_FOLDER)

    # output
    print("// Dart imports:\n" + imports_code + "\n")
    print("// Folder tree:\n" + dart_code)