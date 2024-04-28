# OCFM
Simple command-line file manager for Linux written in Python 3.5. Programmed on GalliumOS on my potato of a Chromebook.

# How do I install/uninstall it? I can't run (un)install.sh!
In a command line, CD to the OCFM directory. Then, run 'chmod +x install.sh uninstall.sh OCFM2.py' without the quotes. Once you have done that you should be able to run './install.sh' and './uninstall.sh', as well as './OCFM2.py'. install.sh and uninstall.sh will ask for your password as they involve adding/removing system files.

# How do I use it?
Commands are somewhat Vi-like:

:q or :quit or :exit - exit OCFM.

:/ - return to the / directory.

<Directory Name> - Move to specified directory.

:delete - delete a file. Will ask for confirmation.

:open <file> - open a file in nano. Only for text files.

Type :h or :help at any time whilst using to view these commands again.

# What does OCFM require?
The OS Python module. A standard installation of Python 3.5 should cover this. Also requires the Nano text editor.
