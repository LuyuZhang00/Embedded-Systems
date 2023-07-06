;name:Zhang Luyu 
;stu-ID:519130910018
;date:2022/11/7
;Compilation environment：dosbox MASM-v6.11

; [设计要求](35分)
; 1．从键盘随机输入十个数据，统计其中负数的个数，并在屏幕上显示出来；
; 2．求出这十个数的总和， 存入数据段SUM 单元，并在屏幕上显示出来；
; 3．* 将这些数从小到大排序，存入 ORDER 为首址的存储区域，并在屏幕上显示出来。
; 4．** 编一跳转表，按键1，2，3，分别执行上述三种操作。
; 5．-99999到+99999排序；
; 6．识别错误符号并提示修改；
; 7．识别超程数字并要求重新输入；
; 8．顺利运行，无BUG。

; [注意事项]
;可输入范围-99999~+99999
;以下输入形式非法：-，+，a，+-09，00，+0，-0，01，-01，001，-001，+0，+01，+1，00001
;每个数字最多6个字符（含符号位）

.386
;-------公共声明--------
PUBLIC FLAGlink3
PUBLIC StaSumSort
;----------------------

;-------------宏定义---------------------
;-------------显示字符---------------------
CHAR	MACRO	x	
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
	FLAGlink3 DB 0

	BUF				db 7
			  		db ?
	dataStr		db 7 dup (?)		;记录输入的一个数
				
	DIGITS		db   ?			
	dataIN		db	 ?				
	haveFlag	dw	 0		;1表示有符号位，0表示无符号位
	FLAG		  db	'p'		;FLAG='p'表示正数（positive），FLAG='n'表示负数（negative）
	VALUE		  dd	 ?		;记录正在输入的数据的数值
	
	TEN	      dd	10

	ValueArr	dd	10 dup(?)		;用户输入的十个数的数值（以补码形式存放）
	NUMofNeg	dd	0						;负数个数
	SUM		    dd	0		        ;十个数之和
	ORDER		  dd	10 dup(?)		;排序后数组
	
	DISP		  db	6 dup(?)		;在宏ShowNum中使用，用于储存待显示的字符型数字
	
	MESS0		db	'Please input 10 decimal numbers. (Press ENTER after inputting each of them.)',0DH,0AH			;输入十个十进制数，并在每个数结尾输入“,”
					db	'*Please input number at -99999~99999. ',0DH,0AH   	;每个输入的数的绝对值应小于等于99999
					db	'*-, +,a, +0, -0, 01, -01, 001, -001, 00, 000,are illegal inputs. ',0DH,0AH
					db	'*The number (except 0 itself) can not begin with 0.',0DH,0AH,'$'	;每个输入的数的绝对值应小于等于99999



	MESSfuc		db  0AH,0AH
						db  '----------------------------------MENU-----------------------------------------',0DH,0AH
						db  '1. Input 10 numbers and they will be shown on screen at end.',0DH,0AH
						db  '2. Show the sum of these ten numbers.',0DH,0AH
						db  '3. Show the numbers after sorted from small to large.',0DH,0AH
						db  '4. Count the number of negative numbers.',0DH,0AH
						db  '5. Exit.',0DH,0AH
						db  '-------------------------------------------------------------------------------',0DH,0AH,'$'

	MESScheck1	db	0AH,'The numbers you input are:',0DH,0AH,'$'			
	MESSneg		  db	0AH,'The count of negative numbers is: ','$'
	MESSsum		  db	0AH,'Sum of these numbers is: ','$'
	MESSorder	  db	0AH,'Sort them from small to large: ',0DH,0AH,'$'			
	
	MESSerror1	db	'This input is illegal. Please input a legal number again: ',0DH,0AH,'$'
	MESSerror2	db	'This number is out of range. Please input number between -99999 and 99999.',0DH,0AH,'$'

DATAS	ENDS

STACKS	SEGMENT USE16
	DW	128 DUP(?)
STACKS	ENDS

;-----------代码段开始------------------------
CODES	SEGMENT USE16    
		assume	CS:CODES,DS:DATAS,SS:STACKS
StaSumSort PROC FAR 

				mov ax,DATAS
				mov	ds,ax

	theTABLE:
				STRF MESSfuc
		chooseFuc:
				mov ah,07H    ;无回显输入
				int 21H
				
				cmp al,'1'
				jb chooseFuc
				cmp al,'5'
				ja chooseFuc
				
				CHAR al        ;显示输入合法字符
				
				cmp al,'1'
				je ONE
				cmp al,'2'
				je TWO
				cmp al,'3'
				je THREE
				cmp al,'4'
				je FOUR


	final:	CMP FLAGlink3,0
					JE	exit0
					RETF
	exit0:	mov	ax,4c00H
					int 21H


; -------功能1------------------------
	ONE:
				call    INPUT 
				;显示输入的十个数
				STRF	MESScheck1
				mov	cx,10
				mov si,0
		show:
				mov eax,ValueArr[si]
				mov VALUE,eax
				call ShowNum
				cmp cx,1
				je show01
				CHAR ','
		show01:	add	si,4
						loop show
			  jmp theTABLE
				CHAR 0AH
				CHAR 0DH

FOUR:		STRF	MESSneg     ;显示负数个数（-0算做正数）
				mov		eax,NUMofNeg
				mov		VALUE,eax
				call	ShowNum	
				CHAR	0AH
				CHAR	0DH
				jmp theTABLE


; -----------功能2----------------------------
	TWO:
				STRF	MESSsum
				mov		eax,SUM
				mov		VALUE,eax
				call	ShowNum		

				CHAR 0AH
				CHAR 0DH

				jmp	theTABLE


; -----------功能3----------------------------
	THREE:
				STRF MESSorder
				call BubbleSort
				mov	si,0
		thr:mov		eax,ORDER[si]
				mov		VALUE,eax
				call	ShowNum	
				cmp si,36
				je	thr0
				CHAR ','
		thr0:	
				add si,4
				cmp	si,40
				jb	thr
				jmp theTABLE

StaSumSort ENDP

;----------------------------功能子程序------------------------------
;-----------------------------输入十个数并保存-----------------------    
INPUT   PROC    NEAR 
   
	CHAR 0AH;换行
	CHAR 0AH;换行	
	STRF MESS0

	mov SUM,0
	mov NUMofNeg,0
	mov SI,0FFFCH

	mov cx,10
	
strTOnum:
	push cx
	mov VALUE,0
	mov DIGITS,0
	mov FLAG,'p'
	mov haveFlag,0
	
	;用户键入一个数
	mov ah,0AH
	lea dx,BUF
	int 21H

	CHAR 0AH
	CHAR 0DH
	
	;处理缓冲区中的数据
	mov di,0
	stn1:	;处理首位字符，该字符可为正负号或数字	
			mov al,dataStr[di]
			mov dataIN,al
			cmp dataIN,'-'	;该数为负
			jne  stn11
			mov FLAG,'n'
			mov haveFlag,1
			inc di
			jmp stn2
		
		stn11:	cmp dataIN,'+'
						jne  stn12		;该符号不是正负号
						mov haveFlag,1
						inc di
						jmp stn2
		
		stn12:	cmp dataIN,'0'
						jb  stnError
						cmp dataIN,'9'	
						ja  stnError
						call UpdateVALUE
						inc DIGITS
						inc di
						jmp stn2
	
    stnError: STRF MESSerror1
							pop cx
							jmp strTOnum
	
	stn2:	;处理非首位，键入只能为数字字符（或换行符表示结束）
			mov al,dataStr[di]
			mov dataIN,al

		stn20:	cmp dataIN,0DH		;是否为换行符
						je	stn3			
				
		stn21:	cmp dataIN,'0'
						jb	stnError
						cmp dataIN,'9'
						ja	stnError
						call UpdateVALUE
						inc DIGITS
						inc di
						jmp stn2
	
	stn3: 	;处理到回车符，将数据写入数组
			cmp DIGITS,0
			je stnError		;只输入符号位属于非法输入

			cmp DIGITS,1
			je stnD1
			mov bx,0	;键入多位数的情况下，首位数字不能为0（包括00、000等也是非法的）	
			add bx,haveFlag
			mov al,dataStr[bx]
			cmp al,'0'
			je	stnError
			jmp stn30

		stnD1: cmp VALUE,0		;键入1位数的情况下，只有-0和+0非法
					 jne	stn30
					 cmp haveFlag,0
					 jne stnError


		stn30:  cmp FLAG,'n'
						jne stn31
						cmp VALUE,0
						je	stn31 	;-0算作正数
						neg VALUE
						inc NUMofNeg			
			
		stn31:  cmp DIGITS,5	;输入绝对值大于了99999（也可用VALUE和-99999和99999进行有符号数比较，jl,jg等）
						ja	stnError2
						mov eax,VALUE
						add SI,4
						mov ValueArr[SI],eax
						mov ORDER[SI],eax
						add SUM,eax
	
	pop cx
	dec cx
	cmp cx,0
	je inputend
	jmp strTOnum

	stnError2:
			  STRF MESSerror2
			  pop cx
			  jmp strTOnum	

inputend:
		ret

INPUT ENDP
;----------------根据新的键入更新VALUE--------------------
UpdateVALUE	PROC	NEAR
	mov	eax,VALUE
	mul	TEN		;TEN=10,是双字型数据；结果存放在EDX:EAX，由于限定了dataIN的范围，结果EDX一定为0
	mov	VALUE,eax
	
	sub	dataIN,30H	;转换为对应数值
	sub eax,eax
	mov	al,dataIN
	add	VALUE,eax
	
	ret
UpdateVALUE ENDP


;---------------显示数据---------------------
ShowNum	PROC NEAR

	cmp	VALUE,0
	jge sn0	;有符号数比较
	CHAR '-'
	neg	VALUE
	
	sn0:  mov di,5				        ;最多转换成6位的十进制数(总和可能是6位数)
			  mov eax,VALUE

	sn1:  mov edx,0 
				div	TEN		;商在EAX中，余数在EDX中
				
				add	dl,30H	;转换为字符型数字，准备输出
				mov	DISP[di],dl
					
				cmp eax,0
				je	sn2			;商为0则跳出循环
				dec di
				jmp sn1

	sn2:  CHAR DISP[di]
				inc di
				cmp di,6
				je  snE
				jmp sn2
		
	snE:
			ret
ShowNum	ENDP

;----------------排序（冒泡排序法）--------------------
BubbleSort	PROC	NEAR		;将ValueArr从小到大排序，结果送入ORDER	
	mov	cx,9								;共10个数，最坏情况需要9次循环

	sort:   mov	 bx,0
					push cx					;保护大循环的cx，将cx现在的值用于控制小循环sort0
		
	sort0:	mov eax,ORDER[bx]
					cmp	eax,ORDER[bx+4]
					JLE	sort1
					xchg eax,ORDER[bx+4]
					xchg ORDER[bx],eax
	sort1:	add bx,4
					loop sort0
					
					pop cx
					loop sort
	ret
BubbleSort ENDP	
;-----------------------------------------------------

CODES ENDS
		END	StaSumSort

