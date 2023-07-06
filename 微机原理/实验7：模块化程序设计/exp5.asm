;name:Luyu Zhang 
;stu-ID:519130910018
;date:2022/11/21
;Compilation environment：dosbox MASM-v6.11

; 实验5（10分）
; 代码转换
; [目的] 将键盘输入的4位十六进制数转换成等值的十进制数送屏幕显示。
; [设计要求]
; 1．程序执行后，首先给出操作提示：
;           Please input a 4-bit hexadecimal number：
; 2．程序要有保护措施，对于非法键入不受理、不回显，但可重新输入。
; 3．显示合法键入的数据，当收到第4位合法数据后，立即显示转换结果。
; 4．显示格式示范如下：
;         ABCDH=43981
; [设计思路]
; 1.程序通过DOS或BIOS调用得到的输入数据均是键盘字符的ASCII码。而程序送往屏幕显示的数据，也都是该数的ASCII码。
; 2.根据设计要求，程序应首先辨别键入的数据是否在‘0’—‘9’和‘A’—‘F’之间，不在这个范围就是非法键入。
; 3.DOS系统的7号和8号子功能，对键入的字符没有回显功能，如果键入的字符是合法数据，再用单字符输出的子功能“回显”合法数据，即可达到显示合法数据而不显示非法数据这一设计要求。
; 4.代码转换的方法：首先把键入的十六进制数ASCII码，转换成等值的二进制数，然后再把二进制数转换成十进制数。

.386
;------公共声明-------
PUBLIC FLAGlink5 
PUBLIC HexToDec
;---------------------


DATAS SEGMENT	USE16
	FLAGlink5 DB 0

	STR1 db 0DH,0AH,'Please input a 4-bit hexadecimal number:',0DH,0AH, '$'
	STR2 db 0DH,0AH,'This digit is not in the legal range. Please input it again.',0DH,0AH, '$'
	STR3 db 0DH,0AH,'Press 0 to close the program. Press any key else to input again.',0DH,0AH, '$'
	
	NUM  db 4 dup(?)
	NUM1 db 4 dup(?)
	TEN	 dw 000AH
	
	RESULT db 5 dup(?)
DATAS ENDS

STACKS SEGMENT	USE16
    dw 128 dup(?)
STACKS ENDS

CODES SEGMENT	USE16
assume cs:CODES,ds:DATAS,ss:STACKS
HexToDec PROC far

start:
	mov	ax,DATAS
	mov ds,ax
	sub	ax,ax		;初始化

start0:	
	mov ah,09
	lea dx,STR1
	int 21H			;显示提示语句“Please input a 4-bit hexadecimal number:”
	
	mov cx,4
	mov di,0
  keyboard:			;键入四位数
		mov ah,07
		int 21H		;不回显键入
		sub ah,ah	
	c09:cmp al, '0'
		jb	PointOut
		cmp al, '9'
		jna	ShowAndSave		;判断是否在‘0’~‘9’
	cAF:cmp al, 'A'
		jb	PointOut
		cmp al, 'F'
		jna	ShowAndSave		;判断是否在‘A’~‘F’
	PointOut:				
		jmp keyboard		;非法输入，不显示；返回重新键入该位数字
	ShowAndSave:
		mov ah,2
		mov dl,al
		int 21H
		mov NUM[di],al		;将此次键入的字符存入NUM
		inc di
		loop keyboard

	mov dl,'H'
	mov ah,2
	int 21H			;显示‘H’
	mov dl,'='
	mov ah,2
	int 21H			;显示‘=’
	
	
	;将键入的字符转换为对应的二进制数，并存入AX
	mov cx,4
	mov di,0
	sub ax,ax
	Binary:
		shl ax,4
		mov bl,NUM[di]
		mov NUM1[di],bl
		cmp NUM1[di],'A'
		jb  B				;若该位数字，则转至b2（数字只需减去30H，字母需减去37H）
		sub NUM1[di],7H
	B:	sub NUM1[di],30H
		add al,NUM1[di]
		inc di
		loop Binary
		
	;将AX转换为十进制，各位上的数字存放到RESULT中
	mov di,4
	Decm:
		sub dx,dx
		div TEN				;商在AX中，余数在DX中
		mov RESULT[di],DL
		cmp ax,0
		je	f			;商为0则跳出循环
		dec di
		jmp	Decm
		
	

	;显示十进制结果
	f:	
		mov ah,02
		add RESULT[di],30H
		mov dl,RESULT[di]
		int 21H
		inc di
		cmp di,5
		jne	f

	ask:
	mov ah,09
	lea dx,STR3
	int 21H			

	mov ah,01
	int 21H

	cmp al,'0'
	je E
	jmp start0

E:	CMP FLAGlink5,0
	JE	E0
	RETF
	
E0:	mov ax,4c00H
	int 21H

HexToDec ENDP

CODES ends
end HexToDec