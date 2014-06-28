xsmouse.sys: xsmouse.def xsmouse.mak xsmouse.obj
  link /a:16 /map /nod xsmouse,xsmouse.sys,,os2,xsmouse

xsmouse.obj: xsmouse.asm xsmouse.mak
  tasm /la /m2 /oi xsmouse.asm,xsmouse.obj
