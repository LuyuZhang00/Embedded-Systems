;name:Zhang Luyu 
;stu-ID:5191300910018
;date:2022/11/26
;Compilation environment：dosbox MASM-v6.11

; 简单的电子琴 --- 8254的应用
; [目的]  熟悉8254 在微机系统中的应用。
; [设计要求]  
; 利用机内 8254 芯片和扬声器, 编一简单的电子琴演奏程序, 按键盘数字键
; 1 — 7，发出相应简谱音符的声调（C调），每次按键后，持续发音 1 秒钟。键入
; “0”结束。 
; [设计思路]
; 1. 只接受键 0 – 7, 屏蔽其余键。 然后将1-7 的ASCII 码转换为数值。
; 2. 可利用1-7 的数值，作为数据区的指针。因为音频以word 为单元存放，1-7的数值应乘以2 。
; 3．* 把以上这一操作运用转移地址表的方式的进行。

; -----------
;接收L,M,H,l,m,h的输入以改变低/中/高音

.386
;------公共声明-------
PUBLIC FLAGlink6 
PUBLIC SimpleElecOrgan
;---------------------


;-------------符号定义-------------------
CNT2		EQU	42H
ControlReg	EQU	43H
PB			EQU	61H

;-------------宏定义---------------------
;-------------显示字符串---------------------
STRF	MACRO	string	;string为字符串首单元
	mov ah,09H
	lea dx,string
	int 21H
	ENDM
	
;---------------------------------------------
DATAS	SEGMENT USE16
	FLAGlink6 DB 0
	tableFL	dw	0,262,294,330,349,392,440,494		;第一位空置。依次为C调低音do~si的频率（单位：Hz）
	tableFM	dw	0,523,587,659,698,784,880,988		;第一位空置。依次为C调中音do~si的频率（单位：Hz）
	tableFH	dw	0,1046,1175,1318,1397,1568,1760,1976;第一位空置。依次为C调高音do~si的频率（单位：Hz）
	
	indata	db	?
	
	delayLOOP	dw	800	;DELAY1s过程体中的循环次数
	oneLOOPtime	dw	40		;DELAY1s过程体中循环一次用时（单位：微秒）
	
	Mess0	db	'Press 1 to 7 to play.',0DH,0AH
			db	'You can press L, M,and H to switch among low, middle and high pitch.',0DH,0AH
			db	'Press any key (except 0) to end one note.',0DH,0AH
			db	'Press 0 to exit the program.',0DH,0AH,'$'
DATAS	ENDS

STACKS	SEGMENT	USE16
	dw	128 dup(?)
STACKS	ENDS
;---------------------------------------------

CODES	SEGMENT	USE16
assume	cs:CODES,ds:DATAS,ss:STACKS
SimpleElecOrgan PROC FAR
start:
			mov	ax,DATAS
			mov	ds,ax
	
			STRF Mess0
	
			lea	si,tableFL	;si为频率表指针，默认低音
	
	key:	mov	ah,07
			int	21H			;等待输入
			
		k0:	mov	indata,al
			
			cmp indata,'0'
			je	final
			
			cmp	indata,'1'
			jb	key
			cmp	indata,'7'
			jna	play		;'1'<=indata<='7'时，跳转至play
			
			cmp	indata,'L'
			je	change
			cmp	indata,'l'
			je	change
			cmp	indata,'M'
			je	change
			cmp	indata,'m'
			je	change
			cmp	indata,'H'
			je	change
			cmp	indata,'h'
			je	change
			
			jmp	key
					
	play:	mov		ah,02
			mov		dl,indata
			int		21H
			call	TOSOUND		;初始化8254
			call	DELAY1s		;延时1秒（该过程体也负责了扬声器的开关）
			jmp		key
	
	change:	mov		ah,02
			mov		dl,indata
			int		21H
			call	CHAN		;更改频率表表头指针
			jmp		key

			
			
	
	final:	  
			CMP FLAGlink6,0
			JE	final0
			RETF
  
 	final0:	mov ax,4c00h
	    	int 21H
SimpleElecOrgan ENDP
;---------------初始化8254-----------------------
TOSOUND	PROC	NEAR
		;先输入控制字，设定工作方式
		mov	al,10110110B  	;设定时器工作方式，方式3
		out	ControlReg,al          ;送8254的控制端口
		
		;计算计数初值
		sub bl,bl
		mov	bl,indata
		sub	bl,30H		;将字符转化为数值
		add	bx,bx		;对应频率指针
		mov	ax,34DEH
		mov	dx,0012H	;输入频率为 001234DE H
		
		div word ptr[si+bx]	;(计数初值)=(输入频率)/(输出频率)
		
		
		;存入计数初值
		out	CNT2,al
		mov al,ah
		out CNT2,al
		
		ret
TOSOUND ENDP

;---------连通扬声器，打开定时器-----------------
OPEN	PROC	NEAR
		in	al,PB
		or	al,00000011B
		out	PB,al			;置PB1=PB0=1
		ret
OPEN	ENDP		

;---------关闭扬声器、定时器---------------------
CLOSE	PROC	NEAR
		in	al,PB
		and	al,11111100B
		out	PB,al			;置PB1=PB0=1
		ret
CLOSE	ENDP		

;---------------延时1s---------------------------
DELAY1s	PROC	NEAR
		call	OPEN	
		mov		cx,delayLOOP
		
	d:	mov		ah,01
		int 	16H
		jnz		stopDelay		;延时期间又有键入，则停止延时，关闭扬声器、定时器，转去处理新的键入
		push	cx
		mov		ah,86H
		mov		cx,0
		mov		dx,oneLOOPtime
		int		15H
		pop		cx
		loop	d

	stopDelay:	
		call	CLOSE
		ret
DELAY1s	ENDP

;---------更改频率表表头指针---------------------
CHAN	PROC	NEAR
		cmp	indata,'L'
		je	FL
		cmp	indata,'l'
		je	FL
		cmp	indata,'M'
		je	FM
		cmp	indata,'m'
		je	FM
		cmp	indata,'H'
		je	FH
		cmp	indata,'h'
		je	FH
		
	FL:	lea si,tableFL
		jmp	done
	FM:	lea si,tableFM
		jmp	done
	FH:	lea si,tableFH
		jmp	done		
	
	done:ret
CHAN	ENDP

;-------------------------------------
CODES	ENDS
END	SimpleElecOrgan

