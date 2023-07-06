/*
 * main.c
 */
#include <msp430.h>
#include <stdint.h>
#include <stdio.h>
#include "dr_tft.h"

//unsigned char flag0=0,flag1=0;
unsigned char send_data[]={'0','\0'};
unsigned char recv_data[]={'0','\0'};
void UART_RS232_Init(void);
void initClock()
{
	  while(BAKCTL & LOCKIO)                 // Unlock XT1 pins for operation
		BAKCTL &= ~(LOCKIO);
		UCSCTL6 &= ~XT1OFF;                  //启动XT1
		P7SEL |= BIT2 + BIT3;                //XT2引脚功能选择
		UCSCTL6 &= ~XT2OFF;                  //启动XT2
		while (SFRIFG1 & OFIFG) {            //等待XT1、XT2与DCO稳定
			UCSCTL7 &= ~(DCOFFG+XT1LFOFFG+XT2OFFG);
			SFRIFG1 &= ~OFIFG;
		  }

	  UCSCTL4 = SELA__XT1CLK + SELS__XT2CLK + SELM__XT2CLK; //避免DCO调整中跑飞

	  UCSCTL1 = DCORSEL_5;                           //6000kHz~23.7MHz
	  UCSCTL2 = 20000000 / (4000000 / 16);           //XT2频率较高，分频后作为基准可获得更高的精度
	  UCSCTL3 = SELREF__XT2CLK + FLLREFDIV__16;      //XT2进行16分频后作为基准
	  while (SFRIFG1 & OFIFG) {                      //等待XT1、XT2与DCO稳定
		UCSCTL7 &= ~(DCOFFG+XT1LFOFFG+XT2OFFG);
		SFRIFG1 &= ~OFIFG;
	  }
	  UCSCTL5 = DIVA__1 + DIVS__1 + DIVM__1; //设定几个CLK的分频
	  UCSCTL4 = SELA__XT1CLK + SELS__DCOCLK + SELM__DCOCLK; //设定几个CLK的时钟源
}


volatile unsigned int value = 0;//设置判断变量
volatile unsigned int flag=0;
volatile unsigned int y0 =0;
volatile unsigned int x =4;
volatile unsigned int y =0;
volatile unsigned int tmp0 =4;
volatile char disp[4]="000";

void main(void)
{
		WDTCTL = WDTPW + WDTHOLD;//关闭看门狗
		UART_RS232_Init();


		TA0CTL |= MC_1 + TASSEL_2 + TACLR;
		//时钟为SMCLK,比较模式，开始时清零计数器
		TA0CCTL0 = CCIE;//比较器中断使能
		TA0CCR0  = 50000;//比较值设为50000，相当于50ms的时间间隔

		P5DIR |= BIT7;
		P8DIR |= BIT0;
		ADC12CTL0 |= ADC12MSC;//自动循环采样转换
		ADC12CTL0 |= ADC12ON;//启动ADC12模块
		ADC12CTL1 |= ADC12CONSEQ1 ;//选择单通道循环采样转换
		ADC12CTL1 |= ADC12SHP;//采样保持模式
		ADC12MCTL0 |= ADC12INCH_12; //选择通道15，连接拨码电位器；ch12:p7.4
		ADC12CTL0 |= ADC12ENC;

		_DINT();

		initClock();
		initTFT();


		etft_AreaSet(0,0,319,239,31);
		_EINT();
		__bis_SR_register(LPM0_bits + GIE);//进入低功耗并开启总中断

}

volatile int pulse_n=0;
volatile int pulse_cache[15]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
volatile int pulse_sum=0;
volatile int counter_flag=0;
volatile int pulse_count=0;

// 函数 pulse_counter 接收两个整数参数：y 和 y0
int pulse_counter(int y,int t0)
{
	// 从总的脉冲总和中减去旧的脉冲值
	pulse_sum-=pulse_cache[pulse_n];

	// 计算当前脉冲和上一个脉冲的差值，并更新脉冲缓存数组
	pulse_cache[pulse_n]=y-y0;

	// 将新的脉冲差值加入总的脉冲总和
	pulse_sum+=pulse_cache[pulse_n];

	// 将脉冲缓存数组的索引增加1
	pulse_n++;

	// 如果脉冲缓存数组的索引达到15（数组大小），则将其重置为0
	if(pulse_n>=15) pulse_n=0;

	// 如果未检测到脉冲的开始且脉冲总和大于等于40
	if((counter_flag==0)&&(pulse_sum>=40))
		{
			// 设置标志位，表示检测到脉冲的开始
			counter_flag=1;

			// 保存当前的脉冲数量，并将其重置为0
			int tmp=pulse_count;
			pulse_count=0;

			// 返回脉冲的频率
			return 6000/tmp;
		}
	// 如果脉冲总和小于40
	else if(pulse_sum<40) counter_flag=0; // 将标志位重置，表示脉冲已结束

	// 增加脉冲数量
	pulse_count++;

	// 如果在当前函数调用中未检测到脉冲的结束，返回-1
	return -1;
}

#pragma vector = TIMER0_A0_VECTOR
__interrupt void Timer_A (void) //定义Timer_A中断服务函数
{
	ADC12CTL0 |= ADC12SC; //启动ADC转换
	value = ADC12MEM0; //将ADC转换结果赋值给变量value

	x++; //x坐标加1

	if (flag==0) //如果flag为0
	{
		flag=1; //将flag设为1
		y0=232-value/18; //将y0设为经过特定计算后的值

		ADC12CTL0 |= ADC12SC; //开始另一次ADC转换
		value = ADC12MEM0; //将ADC转换结果赋值给变量value
		UCA1TXBUF=value;
	}


	y=232-value/18; //将y设为经过特定计算后的值
	UCA1TXBUF=value;

	if (x>=309) //如果x大于或等于309
	{
		x=4; //将x设为4
		etft_AreaSet(x,4,x+12,235,0); //在指定区域设置像素颜色
		x++; //x坐标加1
	}

	tmp0=(y0+y)/2; //将tmp0设为y0和y的平均值

	etft_AreaSet(x+1,4,x+6,235,0); //在指定区域设置像素颜色

	if (y0<y) //如果y0小于y
	{
		etft_AreaSet(x,y0,x,tmp0,0xf800); //在指定区域设置像素颜色
		etft_AreaSet(x+1,tmp0,x+1,y,0xf800); //在指定区域设置像素颜色
	}
	else //否则
	{
		etft_AreaSet(x,tmp0,x,y0,0xf800); //在指定区域设置像素颜色
		etft_AreaSet(x+1,y,x+1,tmp0,0xf800); //在指定区域设置像素颜色
	}

	int freq=pulse_counter(y,y0); //计算y和y0的脉冲计数

	if(freq>0) //如果freq大于0
	{
		disp[0]=freq/100+'0'; //将频率的百位数转换为字符并存入数组
		disp[1]=(freq%100)/10+'0'; //将频率的十位数转换为字符并存入数组
		disp[2]=freq%10+'0'; //将频率的个位数转换为字符并存入数组
	}

	etft_DisplayString(disp, 280,215,0xffff, 0x0000); //在指定位置显示字符串

	y0=y; //将y赋值给y0
}

void UART_RS232_Init(void)	//RS232接口初始化函数
{
	/*通过对P3.4。P3.5，P4.4，P4.5的配置实现通道选择
	 	 使USCI切换到UART模式*/
	P3DIR|=(1<<4)|(1<<5);
	P4DIR|=(1<<4)|(1<<5);
	P4OUT|=(1<<4);
	P4OUT&=~(1<<5);
	P3OUT|=(1<<5);
	P3OUT&=~(1<<4);
	P8SEL|=0x0c;	//模块功能接口设置，即P8.2与P8.3作为USCI的接收口与发射口
	UCA1CTL1|=UCSWRST;	//复位USCI
	UCA1CTL1|=UCSSEL_1;	//设置辅助时钟，用于发生特定波特率
	UCA1BR0=0x03;		//设置波特率
	UCA1BR1=0x00;
	UCA1MCTL=UCBRS_3+UCBRF_0;
	UCA1CTL1&=~UCSWRST;	//结束复位
	UCA1IE|=UCRXIE;		//使能接收中断
}
