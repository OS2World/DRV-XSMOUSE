/*
** This rexx example file reads the last pointing device event from the common
** event buffer and displays it in hexadecimal.
*/

rc=RxFuncAdd('SysGetMessage','RexxUtil','SysGetMessage')

/* set device driver name */
sName='XSMOUSE$'

/* verify that the emulate mouse driver exists in config.sys */
if stream(sName,'command','query exists') \= '\DEV\' || sName
then do
  say 'DEVICE=C:\OS2\BOOT\XSMOUSE.SYS required in CONFIG.SYS'
  /* wait */
  '@pause'
  exit
  end

/* acquire the emulate mouse driver */
rc=stream(sName,'command','open')
if rc \= 'READY:'
then do
  say rc 'Device driver' sName 'currently in use. Please try later.'
  /* wait */
  '@pause'
  exit
  end

/* obtain last event */
call GetMouseEvent

/* report last event */
say 'sBuffer='c2x(sbuffer)
/* wait */
'@pause'

/* release the emulate mouse driver */
rc=stream(sName,'command','close')

exit

GetMouseEvent:
/* read last event */
sBuffer=charin(sName,,10)
rc=stream(sName,'description')
/* check completion code */
if rc \= 'READY:'
then do
  say
  /* obtain and issue error message */
  parse value rc with sState ':' mNumber
  say SysGetMessage(mNumber,,sName)
  /* wait */
  '@pause'
  exit
  end
return
