		ORG 0000H
		LJMP START
		ORG 0013H
		LJMP INTT
		ORG 040H
			
START:   
         SETB EA						;CPU开中断
         SETB EX1						;选择外中断为跳沿触发方式
		 CLR  PX1
		 SETB INT1						;外部中断1初始化编程
		 MOV  R1,#0FFH					;灭灯
		 MOV  R2,#0FFH			
		 MOV  R3,#0FFH					;灭灯
         MOV  DPTR,#7FF8H				;DPTR指向0808通道0
		 MOVX @DPTR,A					;启动0808对IN0通道转换
		 MOV  SP,#60H					;设置堆栈指针指向RAM地址60H
		 MOV SCON,#50H					;设置串行口工作方式1,接收数据设为允许
         MOV  TMOD,#20H    			    ;定时器1置为方式2
		 MOV  TH1,#0FDH    			    ;装载定时器初值,波特率9600 
		 MOV  TL1,#0FDH     			;装载定时器初值,波特率9600 
		 SETB  TR1            		   ;启动定时器
		 SJMP $ 
INTT:
		 MOV  P1,#0FFH					;灭灯
         MOVX A,@DPTR					;读取A/D结果
		 MOV  30H,A						;将结果放到内部RAM单元30H
		 MOV SBUF,A						;送出欲传送的数据
		 JNB TI,$						;等待一帧数据发送结束
		 CLR TI							;清传送结束标志
		 
NEXT:    
         MOV  A,30H;
		 MOV  B,#10;
         DIV  AB;
         PUSH B							;放入第3位
         MOV  B,#10;
         DIV  AB;
         PUSH B							;放入第2位
         MOV  B,#10;
         DIV  AB;
		 MOV  A,B
N10:     CJNE A,#0,N11;
         MOV  R1,#0C0H				;0
		 JMP  N20
N11:     CJNE A,#1,N12;
         MOV  R1,#0CFH				;1
		 JMP  N20
N12:     CJNE A,#2,N13;
         MOV  R1,#0A4H				;2
		 JMP  N20
N13:     CJNE A,#3,N14;
         MOV  R1,#0B0H				;3
		 JMP  N20
N14:     CJNE A,#4,N15;
         MOV  R1,#099H				;4
		 JMP  N20
N15:     CJNE A,#5,N16;
         MOV  R1,#092H				;5
		 JMP  N20
N16:     CJNE A,#6,N17;
         MOV  R1,#082H				;6
		 JMP  N20
N17:     CJNE A,#7,N18;
         MOV  R1,#0F8H				;7
		 JMP  N20
N18:     CJNE A,#8,N19;
         MOV  R1,#080H				;8
		 JMP  N20
N19:     MOV  R1,#090H				;9

N20:     POP  B
         MOV  A,B
         CJNE A,#0,N21				;
         MOV  R2,#0C0H				;0
		 JMP  N30
N21:     CJNE A,#1,N22;
         MOV  R2,#0CFH				;1
		 JMP  N30
N22:     CJNE A,#2,N23				;
         MOV  R2,#0A4H				;2
		 JMP  N30
N23:     CJNE A,#3,N24				;
         MOV  R2,#0B0H				;3
		 JMP  N30
N24:     CJNE A,#4,N25				;
         MOV  R2,#099H				;4
		 JMP  N30
N25:     CJNE A,#5,N26				;
         MOV  R2,#092H				;5
		 JMP  N30
N26:     CJNE A,#6,N27				;
         MOV  R2,#082H				;6
		 JMP  N30
N27:     CJNE A,#7,N28				;
         MOV  R2,#0F8H				;7
		 JMP  N30
N28:     CJNE A,#8,N29				;
         MOV  R2,#080H				;8
		 JMP  N30
N29:     MOV  R2,#090H				;9

N30:     POP  B
         MOV  A,B
         CJNE A,#0,N31				;
         MOV  R3,#0C0H				;0.
		 JMP  N40
N31:     CJNE A,#1,N32				;
         MOV  R3,#0CFH				;1.
		 JMP  N40
N32:     CJNE A,#2,N33				;
         MOV  R3,#0A4H				;2.
		 JMP  N40
N33:     CJNE A,#3,N34				;
         MOV  R3,#0B0H 				;3.
		 JMP  N40
N34:     CJNE A,#4,N35				;
         MOV  R3,#099H				;4.
		 JMP  N40
N35:     CJNE A,#5,N36				;
         MOV  R3,#092H				;5.
		 JMP  N40
N36:     CJNE A,#6,N37				;
         MOV  R3,#082H				;6.
		 JMP  N40
N37:     CJNE A,#7,N38				;
         MOV  R3,#0F8H				;7.
		 JMP  N40
N38:     CJNE A,#8,N39				;
         MOV  R3,#080H				;8.
		 JMP  N40
N39:     MOV  R3,#090H				;9.

N40:
         MOV  R0,#25
LOP:     MOV  P2,#01H			;只显示第1位
         MOV  P1,R1				;显示第1位数
		 MOV  P1,#0FFH			;灭灯
		 MOV  P2,#02H			;只显示第2位
		 MOV  P1,R2				;显示第2位数
		 MOV  P1,#0FFH			;灭灯
		 MOV  P2,#04H			;只显示第3位
		 MOV  P1,R3				;显示第3位数
		 MOV  P1,#0FFH			;灭灯
		 MOV  P2,#08H			;只显示第4位
		 MOV  P1,#0C0H			;0
		 MOV  P1,#0FFH			;灭灯
		 DJNZ R0,LOP
		 MOVX @DPTR,A			;启动0808对IN0通道转换
		 
		 RETI

END ;
	
	