;name:Luyu Zhang 
;stu-ID:519130910018
;date:2022/11/14
;Compilation environment：dosbox MASM-v6.11

; # 实验4（15分）
; # 动态的标题栏与图形
; # [目的] 熟悉图形方式BIOS功能
; # [设计要求] 
; # 1．做一个动态显示的彩色标题栏；
; # 2．在屏幕中央动态的画一个彩色的圆环。画圆环的过程中变换两种颜色。
; # 3．* 在原来的圆环内画一个内接正方形。
; # [设计思路]
; # 1．动态显示的原理，就是显示和延时这两项操作交替使用。
; # 2．画园之前可以算出坐标值，存放于数据段。

;注意：动态标题栏和动态画圆、正方形时的显示模式不同（分别为0EH,12H）
;解决了动态标题栏最开始左方有字的问题
;画圆和正方形可中途退出，画完后按0返回，按1重画该圆
;输入半径范围0~239
;不同半径的圆的绘制时间基本一致

.386
;------公共声明-------
PUBLIC FLAGlink4 
PUBLIC Dynamic
;---------------------




;-----------符号定义----------------
colorBackgAll	EQU	0111B	;银灰色		;动态标题栏的全屏背景颜色
colorFrame		EQU 0001B	;蓝色		;动态标题栏栏框的颜色
colorBackgIn	EQU 0110B	;棕色		;动态标题栏内的背景（填充）颜色
colorBackgStr	EQU	0010B	;绿色		;动态标题栏下方提示字符串的背景颜色
colorCircle1	EQU 0101B	;紫红色		;圆圈的颜色1
colorCircle2	EQU 1010B	;淡绿色		;圆圈的颜色2
colorSquare1	EQU	1110B	;黄色		;正方形方框的颜色1
colorSquare2	EQU	1100B	;淡红色		;正方形方框的颜色2

;-----------------------------------



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

;----------------移动光标----------------------
CURSE	MACRO	YVALUE,XVALUE	;行，列 
	mov ah,02H
	mov	bh,0
	mov	dh,YVALUE
	mov dl,XVALUE
	int 10H
	ENDM

;----------------画像素点----------------------
PIXEL	MACRO YVALUEp,XVALUEp,COLOR  ;行，列，颜色
	push ax
	push bx
	push cx
	push dx

    mov	ah,0CH
	mov al,COLOR
	mov bh,00
	mov cx,XVALUEp
	mov dx,YVALUEp
    int       10H
	
	pop dx
	pop cx
	pop bx
	pop ax
    ENDM

;-----------------------------------------------

DATAS SEGMENT USE16
	FLAGlink4 DB 0

	BUF		db 31
	LEN		db ?
	TEXT	db	31 dup(?)

	COLp	dw	?	;像素列数
	ROWp	dw	?	;像素行数
	COL		db	?	;文字列数
	ROW		db	?	;文字行数
	color	db	?	;像素值（颜色）
	
	FirstTime db '1'	;记录是否首次滚动显示（首次显示左方无字）

	LEN0	db  ?
	LEN1 	db	?
	
	FlagBack 	db '0'		;用于在Delay中判断是否返回
	
	delayLOOP	dw	?
	oneLOOPtime	dw	?		;单位：微秒
	
	R	dw	?
	TEN		db  10
	Rsq		dw	?		;R的平方
	DotNum dw	?		;R/根号2，记录八分之一圆对应的点的个数
	
	X		dw	200 dup(?)
	Y		dw	200 dup(?)

	MODE0	db	?
	
	

	MESS0	db	'----------------------MENU------------------------',0DH,0AH
			db	'Press 1 to creat a dynamical title.',0DH,0AH
			db	'Press 2 to draw a circle and a square in it.',0DH,0AH
			db	'Press 3 to exit this program.',0DH,0AH
			db	'--------------------------------------------------',0DH,0AH,'$'
			
	MESS1	db  'Please input the title (1~30 characters): ',0DH,0AH,'$'
	MESS2	db	'Press 0 to go back.','$'
	
	MESS3	db  'Please input the radius (range:0~239): ',0DH,0AH,'$'

    MESS4   db  'Press 0 to go back.',0DH,0AH,'$'
	MESS5	db	'Press 0 to go back to MENU.',0DH,0AH,'Press 1 to draw again.','$'
	
	MessError1	db 0DH,0AH,'The title can not be blank! Please input again.',0DH,0AH,'$'
	MessError2	db 0DH,0AH,'The input has illegal characters! Please input again.',0DH,0AH,'$'
	MessError3	db 0DH,0AH,'The radius is out of range! Please input again.',0DH,0AH,'$'
DATAS	ENDS

STACKS SEGMENT USE16
    DW  128 DUP(?)
STACKS ENDS

CODES   SEGMENT USE16
    assume CS:CODES,DS:DATAS,SS:STACKS

Dynamic PROC FAR
start:
	mov	ax,DATAS
	mov	ds,ax
	mov es,ax
	
	mov	ah,0FH
	int	10H
	mov	MODE0,al		;保存初始显示模式 

menu:	
	mov	ah,00
	mov al,02H	;80×25,16色,文本
	int 10H		;设置菜单界面显示模式
	
    call BackgroundALL

	CURSE 0,0
	
	STRF MESS0
	
	mov ah,07
	int 21H
	cmp al,'1'
	je	DyTITLE
	cmp al,'2'
	jne	IS3
	jmp CircleSquare
IS3:	
	cmp al,'3'
	jne	menu
	jmp exit
	
	
DyTITLE:
	CHAR al		;回显键入字符
	CHAR 0AH	;换行
	mov FlagBack,'0'
	mov FirstTime,'1'
	mov delayLOOP,200
	mov	oneLOOPtime,200
dyT0:	STRF MESS1
		mov ah,0AH		
		lea dx,BUF
		int 21H			;用户输入标题内容
	
		cmp LEN,0		
		jne dyT1
		STRF MessError1	;标题不能为空
		jmp dyT0

dyT1:	call	DyTMODE			;设置新的显示模式
		call	BackgroundALL	;设置整个屏幕的背景
		call	DyTFrame		;绘制动态标题栏边框
		call	DyTBackgroud	;设置动态标题栏内的背景（填充）色
		CURSE	16,20
		call	MessToBack		;在动态标题栏下方显示“Press 0 to go back.”
		
		mov		ROW,12
		mov		COL,59
dyT2:	call	DyTBackgroud		;清空上次显示内容
		call	DyTShiftLeft		;变换动态标题首字光标的列数，使标题滚动显示
		cmp		COL,20
		jne		dyT20
		mov		FirstTime,'0'
dyT20:	call	DyTShow
		call	Delay
		
dyT3:	cmp		FlagBack,'0'		;判断是否结束动态标题栏的显示
		je		dyT2
		jmp		menu
		
		
CircleSquare: 
	CHAR al
	CHAR 0AH
	mov FlagBack,'0'

	Circle:	STRF MESS3
			mov ah,0AH
			lea dx,BUF
			int 21H		;用户输入半径
		
			cmp LEN,0
			je	radiError
		
			mov R,0
			mov	bx,0
   radi0:	mov	ax,R	;将圆的半径存入Radius
			mul	TEN
			mov R,ax
			mov al,TEXT[bx]
			cmp al,'0'
			jb	radiError
			cmp al,'9'
			ja	radiError
			sub al,30H
			sub ah,ah
			add	R,ax
			inc	bx
			cmp bl,LEN
			je	radi1
			jmp	radi0
			
   radi1:	
			cmp	R,239
			ja	radiError2
			jmp	cir0
	
	radiError: STRF MessError2
				jmp Circle
	radiError2: STRF MessError3
				jmp Circle
	
	cir0:	mov	ax,R
			mov dx,0
			mul	R
			mov	Rsq,ax		;Rsq为R的平方
			mov cx,2
			div cx
			mov si,ax
			call SQROOT
			mov DotNum,si		;八分之一圆对应的像素点的个数	
			call CirCalcu	;以（0，0）为圆心，计算坐标点并存入X,Y,XN,YN		
		
	
			mov ax,500	;500为相对速度，可以根据输出需要自行调整
			mov bx,R
			inc bx		;防止R为0时作为除数
			div bx
			mov delayLOOP,ax
			mov oneLOOPtime,100

	cir1:	
			call CirSquMode
			CURSE 0,0
			STRF MESS4
			call CirDraw
			cmp FlagBack,'0'
			je	Square
			jmp	menu
			
	Square: call SquDraw
			cmp FlagBack,'0'
			jne	back
			CURSE 0,0
			STRF MESS5
	ask:	mov ah,07
			int 21H
			cmp al,'0'
			je	back
			cmp al,'1'
			je	cir1
			jmp ask
	back:	jmp menu

exit:	
	mov	ah,00
	mov al,MODE0	;恢复初始显示模式		
	int 10H

	CMP FLAGlink4,0
	JE	exit0
	RETF
	
exit0:	
	 mov ax,4c00H
	 int 21H

Dynamic ENDP

;------------为动态标题栏设置显示模式----------------
DyTMODE	PROC	NEAR
	mov	ah,00
	mov al,0EH		;640*200
	int 10H
	ret
DyTMODE ENDP

;-------------设置整个屏幕的背景----------------------
BackgroundALL PROC NEAR
	mov	ah,06H		;屏幕上卷
	mov al,0		
	mov	bh,colorBackgAll	;卷入行属性
	mov cx,0000H
	mov dx,184FH
	int	10H
	ret
BackgroundALL ENDP

;-------------绘制动态标题栏边框----------------------
DyTFrame PROC	NEAR
	
	mov COLp,159
	mov ROWp,79
dytf1:	PIXEL ROWp,COLp,colorFrame	;上边框
		cmp	COLp,472
		je	dytf2
		inc COLp
		jmp dytf1

dytf2:	PIXEL ROWp,COLp,colorFrame	;右边框
		cmp	ROWp,120
		je	dytf3
		inc ROWp
		jmp dytf2

dytf3:	PIXEL ROWp,COLp,colorFrame	;下边框
		cmp	COLp,159
		je	dytf4
		dec	COLp
		jmp dytf3

dytf4:	PIXEL ROWp,COLp,colorFrame	;左边框
		cmp	ROWp,79
		je	dytf5
		dec	ROWp
		jmp dytf4

dytf5:	ret
DyTFrame	ENDP	
	
;---------设置动态标题栏内的背景（填充）色-----------
DyTBackgroud	PROC	NEAR
	mov	ah,06H
	mov al,5
	mov bh,colorBackgIn
	mov cx,0A14H
	mov dx,0E3AH
	int 10H
	ret
DyTBackgroud	ENDP

;---------在动态标题栏下方显示返回提示信息-----------
MessToBack	PROC	NEAR
	mov	ah,0BH
	mov bh,00
	mov bl,colorBackgStr
	int 10H
	STRF MESS2
	ret
MessToBack ENDP

;---------------在动态标题中显示标题-----------------
DyTShow	PROC	NEAR
	CURSE	ROW,COL
	mov	ax,58
	sub al,COL
	add al,1
	mov LEN0,al		;LEN0：最右方能显示的字符数
	cmp al,LEN		;最右方空间是否足够使标题完整显示
	jb	dyts1

dyts0:	mov ah,13H
		mov al,0
		mov bh,00
		mov bl,10001000B
		lea BP,TEXT
		mov ch,0
		mov cl,LEN
		mov dh,ROW
		mov dl,COL
		int 10H
		jmp dyts2
		
dyts1:	
		mov al,LEN
		sub al,LEN0
		mov LEN1,al		;将最右方无法显示的字符数存入LEN1
		
		mov ah,13H
		mov al,0
		mov bh,00
		mov bl,10001000B
		lea BP,TEXT
		mov ch,0
		mov cl,LEN0
		mov dh,ROW
		mov dl,COL
		int 10H			;在最右方显示标题前半段
		
		cmp FirstTime,'1'
		je	dyts2

		mov ah,00
		mov al,LEN0
		add BP,ax	
		mov ah,13H
		mov al,0
		mov cl,LEN1
		mov dl,20
		int 10H			;在最左方显示标题后半段

dyts2:	ret
DyTShow ENDP		

;------------变换动态标题首字光标的列数---------------
DyTShiftLeft PROC NEAR
		cmp COL,20
		jne	dytSR0
		mov COL,59
dytSR0: dec COL	
		ret
DyTShiftLeft ENDP



;--------------动态画图时的显示模式--------------------
CirSquMode	PROC	NEAR
	mov	ah,00
	mov al,12H	;640*480 16色
	int 10H
	
	MOV		AH,0BH
	MOV		BX,0000H
	INT		10H
	ret
CirSquMode ENDP

;----------计算坐标点（以（0，0）为圆心）-------------
CirCalcu	PROC	NEAR
	mov di,0
	mov cx,0
	calcu:	
			mov ax,cx
			mov dx,0
			mul cx			;(ax)为(cx)的平方
			
			mov si,Rsq
			sub si,ax
			call SQROOT		;(si)=[(Rsq)-(ax)]的平方根
					
			mov word ptr X[di],cx
			mov word ptr Y[di],si

			inc cx
			inc di
			inc di
			cmp cx,DotNum	;各数组有1+DotNum个元素(0 ~ 2(DotNum)+1)
							;仅需这八分之一圆圈上的坐标点，可通过变换得到一个完整的圆圈
			jna	calcu
		
	ret
CirCalcu ENDP

;-------------------画圆圈----------------------------
CirDraw	PROC NEAR

		cmp R,0
		je Ris0
		cmp R,1
		je Ris1
		jmp	Rnb2
Ris0:	PIXEL 239,319,colorCircle1
		jmp cdE
Ris1:	PIXEL 238,319,colorCircle1
		call DELAY
		PIXEL 239,320,colorCircle2
		call DELAY
		PIXEL 240,319,colorCircle1
		call DELAY
		PIXEL 239,318,colorCircle2
		call DELAY
		jmp cdE

Rnb2:	;半径大于等于2
		mov bx,0		;画00:00~01:30
		mov cx,0
cd0:	mov ax,X[bx]
		add	ax,319
		mov COLp,ax
		mov ax,Y[bx]
		neg ax
		add ax,239		;ax=239-Y[bx]
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle1
		call DELAY
		cmp FlagBack,'1'
		jne cd00
		jmp cdE
cd00:	add bx,2
		inc cx
		cmp cx,DotNum
		jna	cd0

		mov bx,DotNum		;画01:30~3:00
		add bx,DotNum
		mov cx,0
cd1:	mov ax,Y[bx]
		add	ax,319
		mov COLp,ax
		mov ax,X[bx]
		neg ax
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle2
		call DELAY
		cmp FlagBack,'1'
		jne cd10
		jmp cdE
cd10:	sub bx,2
		inc cx
		cmp cx,DotNum
		jna	cd1

		mov bx,0		;画03:00~04:30
		mov cx,0
cd2:	mov ax,Y[bx]
		add	ax,319
		mov COLp,ax
		mov ax,X[bx]
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle1
		call DELAY
		cmp FlagBack,'1'
		jne cd20
		jmp cdE
cd20:	add bx,2
		inc cx
		cmp cx,DotNum
		jna	cd2	

		mov bx,DotNum		;画04:30~6:00
		add bx,DotNum
		mov cx,0
cd3:	mov ax,X[bx]
		add	ax,319
		mov COLp,ax
		mov ax,Y[bx]
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle2
		call DELAY
		cmp FlagBack,'1'
		jne cd30
		jmp cdE
cd30:	sub bx,2
		inc cx
		cmp cx,DotNum
		jna	cd3		

		mov bx,0		;画06:00~07:30
		mov cx,0
cd4:	mov ax,X[bx]
		neg ax
		add	ax,319
		mov COLp,ax
		mov ax,Y[bx]
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle1
		call DELAY
		cmp FlagBack,'1'
		jne cd40
		jmp cdE
cd40:	add bx,2
		inc cx
		cmp cx,DotNum
		jna	cd4	

		mov bx,DotNum		;画07:30~09:00
		add bx,DotNum
		mov cx,0
cd5:	mov ax,Y[bx]
		neg ax
		add	ax,319
		mov COLp,ax
		mov ax,X[bx]
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle2
		call DELAY
		cmp FlagBack,'1'
		jne cd50
		jmp cdE
cd50:	sub bx,2
		inc cx
		cmp cx,DotNum
		jna	cd5				

		mov bx,0		;画09:00~10:30
		mov cx,0
cd6:	mov ax,Y[bx]
		neg ax
		add	ax,319
		mov COLp,ax
		mov ax,X[bx]
		neg ax
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle1
		call DELAY
		cmp FlagBack,'1'
		jne cd60
		jmp cdE
cd60:	add bx,2
		inc cx
		cmp cx,DotNum
		jna	cd6	
		
		mov bx,DotNum		;画09:30~00:00
		add bx,DotNum
		mov cx,0
cd7:	mov ax,X[bx]
		neg ax
		add	ax,319
		mov COLp,ax
		mov ax,Y[bx]
		neg ax
		add ax,239		
		mov ROWp,ax
		PIXEL ROWp,COLp,colorCircle2
		call DELAY
		cmp FlagBack,'1'
		jne cd70
		jmp cdE
cd70:	sub bx,2
		inc cx
		cmp cx,DotNum
		jna	cd7		
		
cdE:	ret
CirDraw ENDP

;----------------画内接正方形-------------------------
SquDraw	PROC NEAR

		cmp R,0
		je SRis0
		cmp R,1
		je SRis1
		jmp	SRnb2
SRis0:	PIXEL 239,319,colorCircle1
		jmp sdE
SRis1:	PIXEL 239,319,colorCircle1
		jmp sdE

SRnb2:
	mov ax,DotNum		;正方形上边
	neg ax
	add ax,239
	mov ROWp,ax
	
	mov cx,DotNum
sd0:	push cx
		neg cx
		add cx,319
		mov COLp,cx
		PIXEL ROWp,COLp,colorSquare1
		call DELAY
		cmp FlagBack,'0'
		je sd00
		pop cx
		jmp sdE
sd00:	pop cx
		dec cx
		cmp cx,0
		jne sd0

	
	mov cx,0
sd1:	push cx
		add cx,319
		mov COLp,cx
		PIXEL ROWp,COLp,colorSquare2
		call DELAY
		cmp FlagBack,'0'
		je sd10
		pop cx
		jmp sdE
sd10:	pop cx
		inc cx
		cmp cx,DotNum
		jna sd1

	mov ax,DotNum		;正方形右边
	add ax,319
	mov COLp,ax
	
	mov cx,DotNum
sd2:	push cx
		neg cx
		add cx,239
		mov ROWp,cx
		PIXEL ROWp,COLp,colorSquare1
		call DELAY
		cmp FlagBack,'0'
		je sd20
		pop cx
		jmp sdE
sd20:	pop cx
		dec cx
		cmp cx,0
		jne sd2
	
	mov cx,0
sd3:	push cx
		add cx,239
		mov ROWp,cx
		PIXEL ROWp,COLp,colorSquare2
		call DELAY
		cmp FlagBack,'0'
		je sd30
		pop cx
		jmp sdE
sd30:	pop cx
		inc cx
		cmp cx,DotNum
		jna sd3
		
	mov ax,DotNum		;正方形下边
	add ax,239
	mov ROWp,ax
	
	mov cx,DotNum
sd4:	push cx
		add cx,319
		mov COLp,cx
		PIXEL ROWp,COLp,colorSquare1
		call DELAY
		cmp FlagBack,'0'
		je sd40
		pop cx
		jmp sdE
sd40:	pop cx
		dec cx
		cmp cx,0
		jne sd4
	
	mov cx,0
sd5:	push cx
		neg cx
		add cx,319
		mov COLp,cx
		PIXEL ROWp,COLp,colorSquare2
		call DELAY
		cmp FlagBack,'0'
		je sd50
		pop cx
		jmp sdE
sd50:	pop cx
		inc cx
		cmp cx,DotNum
		jna sd5

	mov ax,DotNum		;正方形左边
	neg ax
	add ax,319
	mov COLp,ax
	
	mov cx,DotNum
sd6:	push cx
		add cx,239
		mov ROWp,cx
		PIXEL ROWp,COLp,colorSquare1
		call DELAY
		cmp FlagBack,'0'
		je sd60
		pop cx
		jmp sdE
sd60:	pop cx
		dec cx
		cmp cx,0
		jne sd6
	
	mov cx,0
sd7:	push cx
		neg	cx
		add cx,239
		mov ROWp,cx
		PIXEL ROWp,COLp,colorSquare2
		call DELAY
		cmp FlagBack,'0'
		je sd70
		pop cx
		jmp sdE
sd70:	pop cx
		inc cx
		cmp cx,DotNum
		jna sd7

sdE: ret
SquDraw ENDP
	

;-------------------开平方----------------------------
SQROOT  PROC      NEAR        ;对SI开平方，结果存入SI
        push      ax
        push      bx
        push      cx
        mov       ax,si
        sub       cx,cx
  aga:  mov       bx,cx
        add       bx,bx
        inc       bx
        sub       ax,bx
        jc        over
        inc       cx
        jmp       aga
 over:  mov       si,cx
        pop       cx
        pop       bx
        pop       ax
        ret
SQROOT  ENDP

;-------------------------延时------------------------
DELAY	PROC	NEAR
		push	ax
		push	bx
		push	cx
		push	dx
		
		mov		cx,delayLOOP
		
	d:	push	cx
		mov		ah,86H
		mov		cx,0
		mov		dx,oneLOOPtime
		int		15H
		mov		ah,01H				
		int 	16H
		jz		d1			;ZF=1表示没有键入
	d0:	cmp		al,'0'				
		je		dE0
		mov		ah,0CH		;清除输入区缓存
		int     21H
	d1:	pop		cx
		loop	d
		
		jmp dE1
dE0:	pop cx
		mov FlagBack,'1'
		mov ah,0CH
		int 21H
dE1:	pop dx
		pop cx
		pop bx
		pop ax
		ret
DELAY	ENDP
;----------------------------------------------------
CODES ENDS
END	Dynamic