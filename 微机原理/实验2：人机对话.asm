;name:Zhang Luyu 
;stu-ID:519130910018
;date:2022/10/17
;Compilation environment：dosbox MASM-v6.11

; 人机对话(5分)
; [目的] 学习和熟悉DOS功能调用。
; [设计要求]
; 1.程序执行后，首先询问：
;        What’s your name？
; 2.要求用户键入回答，例如输入：lily。
; 3.再次询问:
;        Which class are you in？
; 4.要求用户再次键入回答，例如输入：F0008201。
; 5.回车换行。
; 6.显示：Your name is lily，and your class is F0008201. confirm(y/n)。
; 7.如果回答y，退出程序；否则，返回1。

; [设计思路]
; 1.程序通过Dos的9号功能调用显示字符串。
; 2.通过调用Dos的0A号功能显示和接收输入的字符串。
; 3.单个控制键可通过调用Dos的2号功能来完成。
; 4.接收单个字符可调用Dos的1号功能来完成。
; 5.注意接收完字符串后，加入串结束符。

assume cs:code,ds:data

data segment
	ASK1 db 'What',27H,'s your name?',0DH,0AH, '$'		; 27H、0DH、0AH分别为“'”，回车和换行符的
	ASK2 db 0AH,0DH,'Which class are you in?',0DH,0AH, '$'
	
	STR1 db 'Your name is $'
	STR2 db ' ,and your class is $'
	STR3 db 0AH,0DH,'Press ',27H,'y',27H,' to confirm. Press ',27H,'n',27H,' to input again.',0DH,0AH, '$'

	;定义字符串输入缓冲区的格式
	;姓名：
	BUF1 db 40	;最大可键入字符数
	LEN1 db ?	;实际键入字符数
	USER db 40 dup (?)	;键入字符存放区
	;班级：
	BUF2 db 10	;最大可键入字符数
	LEN2 db ?	;实际键入字符数
	CLASS db 10 dup (?)	;键入字符存放区
data ends


code segment
start:
	mov ax,data
	mov ds,ax
	
	sub ax,ax	;将ax清零待用

	;显示第一个问题“What’s your name？”
	mov ah,09
	mov dx,offset ASK1
	int 21H
	
	;输入第一个问题的答案（即用户姓名）,储存到USER
	LEA dx,BUF1
	mov ah,0AH
	int 21H
	
	;显示第二个问题“Which class are you in?”
	mov ah,09
	mov dx,offset ASK2
	int 21H
	
	;输入第二个问题的答案（即用户班级）,储存到CLASS
	LEA dx,BUF2
	mov ah,0AH
	int 21H
	
	;回车换行。
	mov ah ,02
	mov dl,0DH	;0DH是回车的ascii码
	int 21H
	
	;在USER中字符串末尾加上传结束符“$”，为显示该字符串做准备。
	LEA di,USER
	sub ax,ax
	mov al,LEN1
	CBW
	add di,ax
	mov byte ptr [di], '$'
	
	;在CLASS中字符串末尾加上传结束符“$”，为显示该字符串做准备。
	LEA di,CLASS
	sub ax,ax
	mov al,LEN2
	CBW
	add di,ax
	mov byte ptr [di], '$'
	
	;显示已收集信息。
	mov ah,09
	mov dx,offset STR1	
	int 21H				;显示“Your name is ”
	
	mov ah,09
	mov dx,offset USER	
	int 21H				;显示“USER”
	
	mov ah,09
	mov dx,offset STR2	
	int 21H				;显示“，and your class is ”
	
	mov ah,09
	mov dx,offset CLASS	
	int 21H				
	mov ah,02
	mov dl,'.'
	int 21H
	;显示“CLASS”
	
	mov ah,09
	mov dx,offset STR3	
	int 21H				;显示“. confirm(y/n)。”


 con:
	;单字符输入（用户输入“y”或“n”）
	mov AH,07	
	int 21H		;键入的字符被存在AL中。
	

	;判断用户输入，输入“y”则继续，输入“n”则跳转至start
	mov ah,0
	
	cmp al,'n'
	jz n	;输入为“n”时跳到n
	cmp al,'N'
	jz n	;输入为“N”时跳到n
	
	cmp al,'y'
	jz y	;输入为“y”时跳到y
	cmp al,'Y'
	jz y	;输入为“Y”时跳到y

	jmp con
	
	
n:
	mov ah,02
	mov dl,al
	int 21H

	mov ah ,02
	mov dl,0AH	;换行
	int 21H		;回车换行。

	jmp start
  y:
	mov ah,02
	mov dl,al
	int 21H

	mov ax,4c00h
	int 21H
code ends
end start


