		ORG 0000H
		LJMP START
		ORG 0013H
		LJMP INTT
		ORG 040H
			
START:   
         SETB EA						;CPU���ж�
         SETB EX1						;ѡ�����ж�Ϊ���ش�����ʽ
		 CLR  PX1
		 SETB INT1						;�ⲿ�ж�1��ʼ�����
		 MOV  R1,#0FFH					;���
		 MOV  R2,#0FFH			
		 MOV  R3,#0FFH					;���
         MOV  DPTR,#7FF8H				;DPTRָ��0808ͨ��0
		 MOVX @DPTR,A					;����0808��IN0ͨ��ת��
		 MOV  SP,#60H					;���ö�ջָ��ָ��RAM��ַ60H
		 MOV SCON,#50H					;���ô��пڹ�����ʽ1,����������Ϊ����
         MOV  TMOD,#20H    			    ;��ʱ��1��Ϊ��ʽ2
		 MOV  TH1,#0FDH    			    ;װ�ض�ʱ����ֵ,������9600 
		 MOV  TL1,#0FDH     			;װ�ض�ʱ����ֵ,������9600 
		 SETB  TR1            		   ;������ʱ��
		 SJMP $ 
INTT:
		 MOV  P1,#0FFH					;���
         MOVX A,@DPTR					;��ȡA/D���
		 MOV  30H,A						;������ŵ��ڲ�RAM��Ԫ30H
		 MOV SBUF,A						;�ͳ������͵�����
		 JNB TI,$						;�ȴ�һ֡���ݷ��ͽ���
		 CLR TI							;�崫�ͽ�����־
		 
NEXT:    
         MOV  A,30H;
		 MOV  B,#10;
         DIV  AB;
         PUSH B							;�����3λ
         MOV  B,#10;
         DIV  AB;
         PUSH B							;�����2λ
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
LOP:     MOV  P2,#01H			;ֻ��ʾ��1λ
         MOV  P1,R1				;��ʾ��1λ��
		 MOV  P1,#0FFH			;���
		 MOV  P2,#02H			;ֻ��ʾ��2λ
		 MOV  P1,R2				;��ʾ��2λ��
		 MOV  P1,#0FFH			;���
		 MOV  P2,#04H			;ֻ��ʾ��3λ
		 MOV  P1,R3				;��ʾ��3λ��
		 MOV  P1,#0FFH			;���
		 MOV  P2,#08H			;ֻ��ʾ��4λ
		 MOV  P1,#0C0H			;0
		 MOV  P1,#0FFH			;���
		 DJNZ R0,LOP
		 MOVX @DPTR,A			;����0808��IN0ͨ��ת��
		 
		 RETI

END ;
	
	