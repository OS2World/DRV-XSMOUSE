.386p
model use16 small
ideal

extrn Dos16Write:far

dataseg
; device driver header
hdrlnk dd 0FFFFFFFFh
hdratr dw 0C080h
hdrstr dw offset(strategy)
hdridc dw offset(idcentry)
hdrddn db "XSMOUSE$"
hdrres db 8 dup(0)

dataseg
; device helper
devhlp dd 0

dataseg
; allocgdtselector
gdtsel dw @data

dataseg
; attachdd mouse.sys
ddname db "MOUSE$  "
idcepi dw 6 dup(0)

dataseg
; access mouse.sys
PacketOffset dw 0
ReadEnabled db 0

codeseg
proc idcentry far
; verify mouse requests
; check read enable request
  cmp ax,0002h ; read enable
  jne NotReadEnable ; no
; check not yet enabled
  cmp [ReadEnabled],0
  jne EndReadEnable
; save packet address
  mov [PacketOffset],di
; obtain MOUSE$ idc info
  push bx ; save register
  mov bx,offset(ddname)
  mov di,offset(idcepi)
  mov dl,2Ah ; attachdd
  call [devhlp] ; helper
  pop bx ; restore register
; verify access possible
  jc EndReadEnable ; no
  mov [ReadEnabled],1
Label EndReadEnable near
  ret; return
label NotReadEnable near
  mov ax,1 ; error
  stc ; failure
  ret ; return
endp idcentry

dataseg
MouseSem dd 0

codeseg
proc IssueIoRequest near
; verify access possible
  cmp [ReadEnabled],1
  mov al,03h ; unrecognized
  jne EndIssueIoRequest
; request mouse semaphore
  push bx cx ; save registers
  mov ax,ds ; data selector
  mov bx,offset(MouseSem)
  mov cx,-1 ; <waitforever
  mov di,cx ; >waitforever
  mov dl,06h ; semrequest
  call [devhlp] ; helper
  pop cx bx ; restore registers
  mov ax,810Ch ; error/done/general
  jc EndIssueIoRequest ; failure
; obtain data buffer address
  push bx ; save register
  mov si,[gdtsel] ; gdtselector
  mov ax,[word(es:bx+16)] ; >address
  mov bx,[word(es:bx+14)] ; <address
  mov dl,2Eh ; phystogdtselector
  call [devhlp] ; helper
  pop bx ; restore register
  mov ax,810Ch ; error/done/general
  jc ReleaseSemaphore ; failure
  push es ds ; save registers
  cld ; increment indexes
; process read mouse packet
  cmp [byte(es:bx+02)],04h
  jne NotProcessRead ; write
; obtain absolute event packet
  sub di,di ; target offset
  mov es,si ; target selector
  mov si,[PacketOffset] ; offset
  mov ds,[idcepi+10] ; selector
  rep movsb ; mouse event
  jmp DoneIssueIoRequest
label NotProcessRead near
; process write mouse packet
  mov dx,ds ; data selector
; supply absolute event packet
  mov es,[idcepi+10] ; selector
  mov di,[PacketOffset] ; offset
  mov ds,si ; source selector
  sub si,si ; source offset
  rep movsb ; mouse event
; issue process absolute
  mov ax,0003h ; request
; obtain mouse entry point
  mov ds,dx ; data selector
  mov es,dx ; data selector
  lea di,[idcepi+06] ; target
; provide mouse data selector
  mov ds,[idcepi+10] ; selector
; invoke mouse device driver
  push bx ; save register
  call [dword(es:di)]
  pop bx ; restore register
label DoneIssueIoRequest near
  pop ds es ; restore registers
  mov ax,0100h ; success/done
label ReleaseSemaphore near
; release mouse semaphore
  push ax bx ; save register
  mov ax,ds ; data selector
  mov bx,offset(MouseSem)
  mov dl,07h ; semclear
  call [devhlp] ; helper
  pop bx ax ; restore register
  jnc EndIssueIoRequest ; success
  mov ax,810Ch ; error/done/general
label EndIssueIoRequest near
  ret ; return
endp IssueIoRequest

codeseg
proc strategy far
; set parm failure status code
  mov ax,8113h ; error/done/parm
; obtain driver request code
  mov cl,[es:bx+02] ; request
; handle doswrite request
  cmp cl,08h ; write normal
  jb NotDosWrite ; other
  cmp cl,09h ; write verify
  ja NotDosWrite ; other
; verify buffer length
  mov cx,[word(es:bx+18)]
  cmp cx,10 ; proper length
  jne EndStrategy ; failure
; issue write operation
  call IssueIoRequest
  jmp EndStrategy ; done
label NotDosWrite near
; handle dosread request
  cmp cl,04h ; read normal
  jne NotDosRead ; other
; verify buffer length
  mov cx,[word(es:bx+18)]
  cmp cx,10 ; proper length
  jne EndStrategy ; failure
; issue read operation
  call IssueIoRequest
  jmp EndStrategy ; done
label NotDosRead near
; handle initialization
  cmp cl,00h ; initialize
  je Initialize ; once
label EndStrategy near
; return status code
  mov [es:bx+03],ax
  ret ; return
endp strategy

codeseg
; end of code segment
label EndCode near

dataseg
; end of data segment
label EndData byte

dataseg
InitMsg0 db "XSMOUSE.SYS - "
InitMsg1 db "Attach Driver NOT possible",13,10
InitMsg2 db "GDT selector NOT available",13,10
InitMsg3 db "Emulate Mouse Driver",13,10
label InitMsg4 byte
Written dw 0

codeseg
proc Initialize near
; save devhlp entry point
  mov ax,[es:bx+14]
  mov [word(devhlp+00)],ax
  mov ax,[es:bx+16]
  mov [word(devhlp+02)],ax
; reduce module size
  mov ax,offset(EndCode)
  mov [es:bx+14],ax
  mov ax,offset(EndData)
  mov [es:bx+16],ax
; write startup message
  mov si,InitMsg1-InitMsg0
  mov di,offset(InitMsg0)
  call IssueMessage
; verify driver ddname
  push bx ; save register
  mov bx,offset(hdrddn)
  mov di,offset(idcepi)
  mov dl,2Ah ; attachdd
  call [devhlp] ; helper
  pop bx ; restore register
  mov si,InitMsg2-InitMsg1
  mov di,offset(InitMsg1)
  jnc InitFailure ; used
; allocate GDT selector
  push es ; save register
  mov es,[gdtsel] ; selector
  mov di,offset(gdtsel) ; offset
  mov dl,2Dh ; allocgdtselector
  mov cx,0001h ; one selector
  call [devhlp] ; helper
  pop es ; restore register
  mov si,InitMsg3-InitMsg2
  mov di,offset(InitMsg2)
  jc InitFailure ; error
; write success message
  mov si,InitMsg4-InitMsg3
  mov di,offset(InitMsg3)
  call IssueMessage
; set success status code
  mov ax,0100h ; ok/done
  jmp EndStrategy ; success
label InitFailure near
; indicate init failure
  sub ax,ax ; ensure zeroes
  mov [es:bx+13],al ; data byte
  mov [es:bx+14],ax ; code size
  mov [es:bx+16],ax ; data size
; write failure message
  call IssueMessage
; set failure status code
  mov ax,8115h ; error/done/quiet
  jmp EndStrategy ; failure
endp Initialize

codeseg
proc IssueMessage near
; issue message to stdout
  call Dos16Write pascal,0,ds,di,si,ds,offset(Written)
  ret ; return
endp IssueMessage

end
