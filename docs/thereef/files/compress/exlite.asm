(9056)  Wed 25 Mar 92 11:15a
By: David Kirschbaum
To: Inbar Raz
Re: PkLite extractor program
St:
-----------------------------------------------------------------
Hey, your EXLITE.ASM is just fine!  Saves a lot of grunge work.
I've taken the liberty of making a few tweaks (see attached).

Do you object to your original message and the tweaked code
being uploaded to the Internet's famous SIMTEL20 archive?
You'll get full credits, of course.  (I'm only the tweaker.)

I'd like to add a "Released to the public domain" to it,
if you don't mind, just to make it absolutely clear about
copyrights, etc.  Or if you *do* have any constraints on
the code, could you let me know?

David Kirschbaum
Toad Hall
=== new EXLITE1.ASM follows ===

; ExLite, by Inbar Raz, Jan. 12th, 1992.
; via FIDO's PC Assembly Language Echo
;
; Run: ExLite <filename>.
;
;v1.1   Toad Hall Tweak, 25 Mar 92
; - Insured CS: overrides where required
; - Significant tightening
; David Kirschbaum
; Toad Hall
; kirsch@usasoc.soc.mil

CR  EQU 0DH
LF  EQU 0AH

CSEG    SEGMENT

    ASSUME  cs:CSEG, ds:CSEG
    ORG 0

progstart equ   $           ;for computing program length   v1.1

    ORG 100h

ExLite:  jmp    Begin           ;v1.1

oldInt3 dd  ?
NewName db  'EXLITED.COM', 0
filename dw ?           ; Location of filename on command line
handle  dw  ?

ATTRIB  EQU 20H ;v1.1

NoFile_ db  'No file specified$'                    ;v1.1
BadName_ db     'Bad file name, or file name can not be opened$'    ;v1.1
NotLite_ db     'File is not compressed under PKLite or is of '
    db  'unknown version of PKlite$'                ;v1.1
ReadErr_ db 'Error reading source file$'                ;v1.1
CantCreat_ db   'Error creating destination file'           ;v1.1
Abort_  db  '.',CR,LF,'Program aborting.$'              ;v1.1

NewInt3:
    mov ax,cs
    mov ds,ax
    ASSUME  DS:CSEG         ;v1.1

    mov ax,3C00h        ; Create file
    mov cx,ATTRIB       ;v1.1
    mov dx,offset NewName   ;'EXLITED.COM'
    int 21h
    jb  CantCreat
    mov handle,ax
    mov bx,ax           ;into BX for upcoming write v1.1

    mov ax,es
    mov ds,ax
    ASSUME  DS:NOTHING      ;Actually, the seg of the   v1.1
                    ;decompressed file

    mov ah,40h          ; Write file
    mov cx,di           ;program length
    mov dx,100h         ;write from .COM program onward
    sub cx,dx       ;100H   ;minus PSP length       v1.1
    int 21h

    mov ah,3Eh          ; Close file
    int 21h

    mov ax,2503h        ; Restore old Int 3 vector
    lds dx,cs:oldInt3
    int 21h

    jmp short Exit1

CantCreat:
    mov dx,offset CantCreat_    ;'Error creating destination file'
    mov ax,cs
    mov ds,ax
    ASSUME  DS:CSEG         ;v1.1

    mov ah,9            ; Display string
    int 21h

Exit1:  mov ax,4C00h
    int 21h

;-!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!-

Begin:
    ASSUME  DS:CSEG,ES:CSEG     ;v1.1

;v1.1   Use accumulator AX whenever possible (faster)
    mov ax,offset progend   ;v1.1
    add ax,4Dh          ;v1.1
    mov sp,ax           ; Save space for stack

    mov si,80h          ;PSP cmdline
    cld             ;insure fwd         v1.1
    lodsb               ;snarf cmdline length,      v1.1
                    ;bump SI
    or  al,al           ;any cmdline chars?     v1.1
    jz  NoFile          ;nope               v1.1

    mov ax,3503h        ; Get old Int 3 vector
    int 21h         ;(breakpoint)
    mov word ptr [oldInt3],bx   ;save it
    mov word ptr [oldInt3+2],es

    mov ax,2503h        ; Set new Int 3 vector
    mov dx,offset NewInt3   ;to our code
    int 21h

Spc:    lodsb
    cmp al,20h          ; Space - 20h, 32d
    jz  Spc         ;gobble leading spaces
    dec si          ;back up from last LODSB
    mov filename,si     ; Store its location

Loop1:  lodsb               ; Search for end of line
    cmp al,CR           ;terminating CR?
    jnz Loop1           ;nope

    dec si          ;back up to terminating CR
    mov byte ptr [si],0h    ; Set it to ASCIIZ string

    mov ax,3D00h        ; Open for read only
    mov dx,filename     ;pointer to cmdline filename
    int 21h
    jb  BadName         ;open failed            v1.1

    mov handle,ax       ; Save the file handle
    mov bx,ax           ;in BX for upcoming read    v1.1

;v1.1   Why do the computation with runtime code
;   when you can let the assembler to the work?

;v1.1   mov bx,offset Exit      ; End of program
;   mov cl,4
;   shr bx,cl
;   add bx,05h
;   mov ax,cs
;   add bx,ax
;   mov es,bx           ; Initialize segment

;v1.1   New code

CODELEN =   (progend-progstart+0Fh) SHR 4   ;v1.1

    mov ax,CS           ;v1.1
    add ax,CODELEN+5        ;v1.1
    mov ES,ax           ;into ES            v1.1

    mov cx,100h /2      ;PSP length in words        v1.1
    xor si,si       ;0  ;v1.1
    xor di,di       ;0  ;v1.1
    rep movsw           ;copy PSP (words are faster)    v1.1

    mov ax,es
    mov ds,ax
    ASSUME  DS:NOTHING,ES:NOTHING   ;v1.1

    mov ah,3Fh          ; Read from file
    mov cx,0FFFFh       ; Can't be more than that...
    mov dx,100h         ;  (it's a COM file...)
    int 21h
    jb  ReadErr
    mov cx,ax           ;save real file size for later  v1.1

    mov ah,3Eh          ; Close file
    int 21h         ;(BX still unchanged)       v1.1
    jmp short Label1

NoFile: mov dx,offset NoFile_   ;'No file specified'        v1.1
    jmp short Print

BadName:
    mov dx,offset BadName_  ;'Bad file name'        v1.1
    jmp short Print

Label1:
;v1.1   CX has bytes read (file size).
    mov al,8Bh          ; ( equ MOV DI )        v1.1
    mov di,100h         ;search from prog start onward

Scan:   repnz   scasb           ; Search for it
    jcxz    NotLite         ;didn't find it

    cmp word ptr [di],0CBF8h    ; ( equ ,AX RETF )
    jnz Scan            ;wrong MOV DI, keep scanning

    dec di          ;back up to that MOV DI
    mov byte ptr [di],0CCh  ; ( equ INT 3 )

;Set up stack for the decompressing .COM program
;(Just like MS-DOS would do it)

    mov ax,ds
    mov ss,ax
    mov sp,0FFFEh
    push    ax          ;.COM program's CSEG
    mov ax,100h         ;first line of code
    push    ax          ;fake a FAR's return address
    retf                ; Jump to original program
                    ;where our breakpoint will  v1.1
                    ;handle the file write      v1.1

NotLite:
    mov al,0FFH         ;-1 error           v1.1
    mov dx,offset NotLite_  ;'Not compressed under PkLite...'
    jmp short Print

ReadErr:
    mov dx,offset ReadErr_  ;'Error reading source file...'

Print:  push    ax          ;save ERRORLEVEL in AL      v1.1
    mov ax,cs
    mov ds,ax
    ASSUME  DS:CSEG         ;v1.1

    mov ah,9h           ; Display string
    int 21h
    mov dx,offset Abort_    ;'Program aborting.'        v1.1
    mov ah,9            ;v1.1
    int 21H         ;v1.1
    pop ax          ;restore ERRORLEVEL in AL   v1.1

    EVEN                ;To insure stack alignment  v1.1
progend EQU $           ;v1.1

    mov ah,4Ch          ; Terminate process
    int 21h

CSEG    ENDS
    END ExLite          ;v1.1

... $1,000,000 Guaranteed!! Call this number now!! 1-800-531-
--- Blue Wave/Max v2.05
 * Origin: The Federal Post -{*}- Fayetteville, NC (1:3634/2.0)

@PATH: 3634/2 1 373/2 151/1003 13/13 266/22 260/1
