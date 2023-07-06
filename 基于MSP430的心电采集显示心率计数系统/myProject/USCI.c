#include <msp430.h>
#include "USCI.h"


//void UART_RS232_Init(void)	//RS232接口初始化函数
//{
//	/*通过对P3.4。P3.5，P4.4，P4.5的配置实现通道选择
//	 	 使USCI切换到UART模式*/
//	P3DIR|=(1<<4)|(1<<5);
//	P4DIR|=(1<<4)|(1<<5);
//	P4OUT|=(1<<4);
//	P4OUT&=~(1<<5);
//	P3OUT|=(1<<5);
//	P3OUT&=~(1<<4);
//	P8SEL|=0x0c;	//模块功能接口设置，即P8.2与P8.3作为USCI的接收口与发射口
//	UCA1CTL1|=UCSWRST;	//复位USCI
//	UCA1CTL1|=UCSSEL_1;	//设置辅助时钟，用于发生特定波特率
//	UCA1BR0=0x03;		//设置波特率
//	UCA1BR1=0x00;
//	UCA1MCTL=UCBRS_3+UCBRF_0;
//	UCA1CTL1&=~UCSWRST;	//结束复位
//	UCA1IE|=UCRXIE;		//使能接收中断
//}
