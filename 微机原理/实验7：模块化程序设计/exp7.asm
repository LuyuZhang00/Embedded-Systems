;name:Zhang Luyu 
;stu-ID:5191300910018
;date:2022/12/15
;Compilation environment：dosbox MASM-v6.11

; 实验7（20分）
; 模块化程序设计
; [目的] 练习模块化程序的设计。
; [设计要求]
;  设计一个主菜单，并将实验3~8的程序作为子菜单的运行结果。
; * 通过链接几个代码段的方式实现。

.386
;-------------宏定义---------------------
;-------------显示字符---------------------
CHAR	MACRO	x	;string为字符串首单元
	mov ah,02H
	mov dl,x
	int 21H
	ENDM
	
;-------------显示字符串---------------------
STRF	MACRO	string	;string为字符串首单元
	mov ah,09H
	lea dx,string
	int 21H
	ENDM

;---------------------------------------------

DATAS SEGMENT USE16
	EXTRN	FLAGlink2:byte
	EXTRN	FLAGlink3:byte
	EXTRN	FLAGlink4:byte
	EXTRN	FLAGlink5:byte
	EXTRN	FLAGlink6:byte
	
	MESS0	db  0AH
			db	'----------------MENU------------------',0DH,0AH
			db	'0. EXIT',0DH,0AH
			db	'1. Man-machine interaction',0DH,0AH			;实验2（对应文件2.asm）
			db	'2. Statistics, summation and sorting',0DH,0AH	;实验3（对应文件3.asm）
			db	'3. Dynamic title block and graphics',0DH,0AH	;实验4（对应文件4.asm）
			db	'4. Hex to Dec',0DH,0AH							;实验5（对应文件5.asm）
			db	'5. Simple electronic organ',0DH,0AH			;实验6（对应文件6.asm）
			db	'Choose 0~5 to continue.',0DH,0AH
			db  '--------------------------------------',0DH,0AH,'$'
DATAS ENDS

STACKS SEGMENT USE16
	dw 128 dup(?)
STACKS ENDS

CODES SEGMENT   USE16
assume CS:CODES,DS:DATAS,SS:STACKS

	EXTRN ManMachineInter:far		;人机对话
	EXTRN StaSumSort:far			;统计、求和与排序
	EXTRN Dynamic:far				;动态标题栏和图形
	EXTRN HexToDec:far				;将16进制数转换为10进制数
	EXTRN SimpleElecOrgan:far		;简易电子琴	
start:
	mov ax,DATAS
	mov ds,ax
	
  STRF MESS0
	
	mov ah,01
	int 21H
	
	PUSH ax
	CHAR 0AH
	POP ax
	
	cmp al,'1'
	je	LAB2
	cmp al,'2'
	je	LAB3
	cmp al,'3'
	je	LAB4
	cmp al,'4'
	je	LAB5
	cmp al,'5'
	je	LAB6
	cmp al,'0'
	je	exit
	
	jmp start
	
LAB2: mov FLAGlink2,1
			call far ptr ManMachineInter
			jmp start

LAB3: mov FLAGlink3,1
			call far ptr StaSumSort
			jmp start

LAB4: mov FLAGlink4,1
			call far ptr Dynamic
			jmp start

LAB5: mov FLAGlink5,1
			call far ptr HexToDec
			jmp start


LAB6: mov FLAGlink6,1
			call far ptr SimpleElecOrgan
			jmp start

exit:	mov FLAGlink2,0
			mov FLAGlink3,0
			mov FLAGlink4,0
			mov FLAGlink5,0
			mov FLAGlink6,0
		
		mov ax,4c00H
		int 21H



CODES ENDS
END start