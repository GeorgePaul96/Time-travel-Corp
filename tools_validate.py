import sys
import glob

def validate_gd_syntax(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    errors = []

    for i, line in enumerate(lines):
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        if line.startswith('func ') and not line.endswith(':'):
            errors.append(f"Line {i+1}: func definition without trailing colon")

        if line.startswith('if ') and not line.endswith(':'):
            errors.append(f"Line {i+1}: if statement without trailing colon")

        if line.startswith('for ') and not line.endswith(':'):
            errors.append(f"Line {i+1}: for loop without trailing colon")

        if line.startswith('match ') and not line.endswith(':'):
            errors.append(f"Line {i+1}: match statement without trailing colon")

    return errors

if __name__ == '__main__':
    all_files = glob.glob('**/*.gd', recursive=True)
    has_errors = False

    for file in all_files:
        errors = validate_gd_syntax(file)
        if errors:
            print(f"Errors in {file}:")
            for err in errors:
                print(f"  {err}")
            has_errors = True

    if not has_errors:
        print("Basic syntax check passed.")
