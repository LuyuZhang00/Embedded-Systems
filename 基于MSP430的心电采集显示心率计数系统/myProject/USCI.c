#include <msp430.h>
#include "USCI.h"


//void UART_RS232_Init(void)	//RS232�ӿڳ�ʼ������
//{
//	/*ͨ����P3.4��P3.5��P4.4��P4.5������ʵ��ͨ��ѡ��
//	 	 ʹUSCI�л���UARTģʽ*/
//	P3DIR|=(1<<4)|(1<<5);
//	P4DIR|=(1<<4)|(1<<5);
//	P4OUT|=(1<<4);
//	P4OUT&=~(1<<5);
//	P3OUT|=(1<<5);
//	P3OUT&=~(1<<4);
//	P8SEL|=0x0c;	//ģ�鹦�ܽӿ����ã���P8.2��P8.3��ΪUSCI�Ľ��տ��뷢���
//	UCA1CTL1|=UCSWRST;	//��λUSCI
//	UCA1CTL1|=UCSSEL_1;	//���ø���ʱ�ӣ����ڷ����ض�������
//	UCA1BR0=0x03;		//���ò�����
//	UCA1BR1=0x00;
//	UCA1MCTL=UCBRS_3+UCBRF_0;
//	UCA1CTL1&=~UCSWRST;	//������λ
//	UCA1IE|=UCRXIE;		//ʹ�ܽ����ж�
//}
