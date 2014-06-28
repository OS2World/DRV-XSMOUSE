/*
** This rexx example file writes the absolute pointing device event which moves
** the pointer to the center of the screen into the common event buffer and
** displays it in hexadecimal format.
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

/* set touch screen dimensions */
xMin=0 ; yMin=0 ; xMax=2048 ; yMax=2048

/* precalculate maximum values for common event buffer */
xMaxHex=d2x(xMax,4) ; xMaxOut=x2c(Right(xMaxHex,2)||Left(xMaxHex,2))
yMaxHex=d2x(yMax,4) ; yMaxOut=x2c(Right(yMaxHex,2)||Left(yMaxHex,2))

/* initialize mouse event flags */
MoveOnly=x2c(0100) ; NoButMov=x2c(0000)

/* move pointer to center of screen */
xPos=trunc(xMax/2) ; yPos=trunc(yMax/2)
/* calculate current values for common event buffer */
xPosHex=d2x(xPos,4) ; xPosOut=x2c(Right(xPosHex,2)||Left(xPosHex,2))
yPosHex=d2x(yPos,4) ; yPosOut=x2c(Right(yPosHex,2)||Left(yPosHex,2))
sBuffer = MoveOnly||yPosOut||xPosOut||yMaxOut||xMaxOut
call PutMouseEvent

/* report this event */
say 'sBuffer='c2x(sbuffer)
/* wait */
'@pause'

/* release the emulate mouse driver */
rc=stream(sName,'command','close')

exit

PutMouseEvent:
/* write mouse event */
rc=charout(sName,sBuffer)
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
/* pacing */
beep(32767,30)
return
