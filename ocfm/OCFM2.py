#!/usr/bin/env python3
#  _____     _____   _______  __    __
# /OOOOO\   /CCCCC\  |FFFFFF||MM\  /MM|
#/O/   \O\ /C/   \C\ |F|___  |M\M\/M/M|
#|O|   |O| |C|       |FFFFF| |M|\MM/|M|
#|O|   |O| |C|       |F|     |M| \/ |M|
#\O\___/O/ \C\___/C/ |F|     |M|    |M|
# \OOOOO/   \CCCCC/  |F|     |M|    |M|
#
#OC File Manager
#
#Sorry for the bad ASCII art.
#
#OCFM by Ocawesome101. Made with Python 3.5, and works through an interface
#with Bash. This is strictly command-line and somewhat Vi-like.

from os import system
CurrentDir = '/'
system('ls ' + CurrentDir)
print('OCFM 2.0. Type \':\' before commands.')
while 1:
    command = input('> ')
    if command == ':q' or command == ':quit' or command == ':exit': #Quit command
        exit()
    elif command == ':/': #Return to root command
        CurrentDir = '/' #Set current directory to /
    elif command == ':h' or command == ':help': #Help command
        print('OCFM Help\nCommands:\n:q or :quit or :exit - exit OCFM\n:/ - Return to the root directory\n <Directory Name> - Move to that directory\n:delete <file> - delete a file. Will ask for confirmation.')
        print(':mkdir - makes a directory.\n:bk - moves up a directory.\n:open <file> - open specified file. OCFM will try to recognize the file extension. You must NOT specify a directory.')
    elif command[0:7] == ':delete': #Delete command
        command = command[8:len(command)] #Remove the ':delete ' from the command variable
        delete = input('Are you sure you want to delete file ' + command + '? (y/n)') #Ask for confirmation
        if delete == 'y': #If we have confirmation then
            system('rm -r ' + command) #delete the file, assuming you have permissions to delete it
        elif delete == 'n': #If we do not have confirmation then
            print('Aborting') #abort
        elif delete != 'y' and delete != 'n': #If answer is not Y or N then
            print('Aborting - you did not type Y or N.') #abort
    elif command[0:6] == ':mkdir': #Make directory command
        command = command[7:(len(command) - 1)] #Remove ':mkdir ' from the command variable
        system('mkdir ' + command) #Make directory
    elif command == ':bk' or command == '..' or command == '../': #Go back up a directory, and intercept .. and ../
        if CurrentDir == '/' or CurrentDir == '//': #If user is already in the root directory then warn them
            print('You are already in the root directory and cannot go up any further!')
        else: #If user is NOT in the root directory then
            CurrentDir = CurrentDir[0:(len(CurrentDir) - 2)] #Remove any '/' characters due to the potential for there to be more than one because of the way my script works
            while CurrentDir[(len(CurrentDir) - 1)] != '/': #Repeat until we hit a '/' character signifying the upper directory
                CurrentDir = CurrentDir[0:(len(CurrentDir) - 1)] #Remove one character from the current directory variable. I know this can probably be done in more efficient ways but this is how I have decided to do it.
    elif command[0:5] == ':open': #Detect if command is :open
        command = command[6:len(command)] #Remove the ':open' from the command
        system('nano ' + CurrentDir + command) #Nano the file
    elif command[0] != ':':
        CurrentDir += command + '/'
    elif command[0] == ':':
        print('ERROR - UNRECOGNIZED COMMAND')
    system('ls ' + CurrentDir)
