#!/usr/bin/env python3.5
import os
from tkinter import *
import time

current_y = 30
avgs = []

def add_average(number):
    print('running function add_average()')
    global avgs
    print('made variables global for function add_average()')
    print('assuming we have ping greater than 9.9ms')
    avgs.append(float(number))
    print('finished runnning function add_average()')

def average_time():
    print('running function average_time()')
    global avgs
    print('made variables global for function average_time()')
    t = (len(avgs) - 1)
    print('got length of list \'avgs\' and converted to zero base')
    l = 0
    r = 0
    print('defined computational utility variables \'l\' and \'r\'')
    while l <= t:
        print('l =', l)
        r = float(r) + float(avgs[l])
        l += 1
    r = r/l
    print('got average ping time')
    print('average ping time was', r,'ms')
    print('finished running function average_time()')

def print_line():
    print('running function print_line()')
    global window
    global current_y
    global pingoutput
    print('made variables global for function print_line()')
    main_text = Label(window, text=pingoutput)
    print('set properties for instance of main_text')
    main_text.place(x=0, y=current_y)
    print('placed instance of main_text at x 0, y ', current_y)
    current_y += 15
    print('increased variable current_y by 15')
    print('finished running function print_line()')

def get_ping_output():
    print('running function get_ping_output()')
    global current_y
    global pingoutput
    global ip
    print('made variables global for function get_ping_output()')
    print('pinging IP address', ip)
    pingcmd = 'rm output.txt; echo $(ping -c 1 ' + ip + ') >> output.txt'
    print('defined ping command in variable \'cmd\' - this is done to allow for a custom ip address')
    os.system(pingcmd)
    print('pinging', ip)
    print('replaced contents of \'output.txt\' with output of command ping -c 1', ip)
    outping = open("output.txt", "r")
    print('opened file \'output.txt\'')
    output = outping.read()[:-1]
    print('contents of output.txt are:', output)
    if output == '':
        print('ERROR: internet down')
        quit()
    print('read 1 line from \'output.txt\'')
    pingoutput = output[67:98]
    print('got', pingoutput, 'as output of ping command from file \'output.txt\'')
    outping.close()
    print('closed \'output.txt\'')
    add_average(pingoutput[24:(len(pingoutput) - 2)])
    print('added', pingoutput[24:27], 'to list \'avgs\'')
    print_line()
    window.update()
    print('updated window \'window\'')
    print('finished running function get_ping_output()')

def initialize():
    print('running function initialize()')
    global window
    global ip
    print('made variables global for function initialize()')
    i = int(input('How many times should I ping? '))
    if i >= 46:
        print('ERROR: max amount of times is 45')
        time.sleep(1)
        exit()
    ip = input('What IP should I ping? Any 4-digit IP (i.e. 4.2.2.1) will work. Anything else will not. ')
    print('pinging', ip, i, 'times')
    if i >= 10:
        geo = '300x' + str((i + 3)*15)
    else:
        geo = '300x150'
    print('creating window \'window\' with size', geo)
    window = Tk()
    print('aliasing Tk() to window')
    window.geometry(geo)
    print('set window geometry')
    window.title('Test Network')
    print('set title for window \'window\' to \'Test Network\'')
    toptext = 'Ping times from ' + ip
    top_text = Label(window, text=toptext)
    print('defined parameters for instance of \'top_text\'')
    top_text.place(x=0, y=0)
    print('placed top_text')
    while i != 0:
        i -= 1
        print('getting ping output')
        get_ping_output()
    print('done')
    print('getting average ping time')
    average_time()
    time.sleep(1)
    print('destroying window \'window\' and exiting program')
    time.sleep(1)
    window.destroy()
    print('finished running function initialize()')

initialize()
