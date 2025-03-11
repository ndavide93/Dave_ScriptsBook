import os
import tkinter as tk
from tkinter import filedialog

def run_script():
    selected_script = filedialog.askopenfilename(
        initialdir="./",
        title="Seleziona uno script da eseguire",
        filetypes=(("Python files", "*.py"), ("PowerShell files", "*.ps1"))
    )
    if selected_script:
        if selected_script.endswith('.py'):
            os.system(f'python "{selected_script}"')
        elif selected_script.endswith('.ps1'):
            os.system(f'powershell -ExecutionPolicy Bypass -File "{selected_script}"')

root = tk.Tk()
root.title("Launcher")
root.geometry("300x200")

button = tk.Button(root, text="Scegli e esegui uno script", command=run_script)
button.pack(expand=True)

root.mainloop()
