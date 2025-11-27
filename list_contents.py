import subprocess
import pyperclip

# Folder to feed into list_files.py
folder_path = r"C:\Users\covec\Desktop\love-projects\bloxee"
skip_folder = r"C:\Users\covec\Desktop\love-projects\bloxee\.git"

# Run the Python script and capture output
result = subprocess.run(
    ["python", r"C:\Users\covec\Desktop\py\list_files.py"],
    input=folder_path + "\n",  # feed folder path as stdin
    capture_output=True,
    text=True
)

# Split lines, skip first line, and filter out the git folder
lines = result.stdout.splitlines()
filtered_lines = [line for line in lines[1:] if not line.startswith(skip_folder)]

# Join and copy to clipboard
output_to_clipboard = "\n".join(filtered_lines)
pyperclip.copy(output_to_clipboard)

print("Output copied to clipboard!")
