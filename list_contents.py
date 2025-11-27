import subprocess
import pyperclip

# Folder to feed into list_files.py
folder_path = r"C:\Users\covec\Desktop\love-projects\bloxee"

# Run the Python script and capture output
result = subprocess.run(
    ["python", r"C:\Users\covec\Desktop\py\list_files.py"],
    input=folder_path + "\n",  # feed folder path as stdin
    capture_output=True,
    text=True
)

# Split lines and skip the first line
lines = result.stdout.splitlines()
output_to_clipboard = "\n".join(lines[1:])

# Copy to clipboard
pyperclip.copy(output_to_clipboard)

print("Output copied to clipboard!")
