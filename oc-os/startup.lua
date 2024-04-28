--[[
The OC-OS Startup file. Do not touch unless you
know what you are doing!
]]--

print('Welcome to OC Boot Loader version 1.0.0.')

term.write('Enter boot choice [1. CraftOS], [2. OC-OS] :')
OPT = read()
if OPT == '1' then
 print('Booting CraftOS...')
else
 if OPT == '2' then
  print('Booting OC-OS...')
  os.loadAPI('/apis/log')
  log.info('Loaded required API: OC Logging API v1.0')
  if fs.exists('/scripts/bash') then
   log.info('Found required file: OC Bash v0.5.0')
  else
   log.err('Failed to locate required file: /scripts/bash')
   os.shutdown()
  end
  if fs.exists('/scripts/ocfm') then
   log.info('Found required file: OC File Manager v1.0.0')
  else
   log.err('Failed to locate required file: /scripts/ocfm')
   os.shutdown()
  end
  if os.version() ~= 'CraftOS 1.8' then
   log.warn('Running on unsupported CraftOS version!')
  end
  log.info('Starting Main Menu....')
  shell.setDir('/scripts')
  sleep(1)
  shell.run('ui')
 else
 print('Invalid boot choice!')
 sleep(1)
 os.reboot()
 end
end
