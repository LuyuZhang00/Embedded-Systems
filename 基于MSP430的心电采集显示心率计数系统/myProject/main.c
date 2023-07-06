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
		UCSCTL6 &= ~XT1OFF;                  //����XT1
		P7SEL |= BIT2 + BIT3;                //XT2���Ź���ѡ��
		UCSCTL6 &= ~XT2OFF;                  //����XT2
		while (SFRIFG1 & OFIFG) {            //�ȴ�XT1��XT2��DCO�ȶ�
			UCSCTL7 &= ~(DCOFFG+XT1LFOFFG+XT2OFFG);
			SFRIFG1 &= ~OFIFG;
		  }

	  UCSCTL4 = SELA__XT1CLK + SELS__XT2CLK + SELM__XT2CLK; //����DCO�������ܷ�

	  UCSCTL1 = DCORSEL_5;                           //6000kHz~23.7MHz
	  UCSCTL2 = 20000000 / (4000000 / 16);           //XT2Ƶ�ʽϸߣ���Ƶ����Ϊ��׼�ɻ�ø��ߵľ���
	  UCSCTL3 = SELREF__XT2CLK + FLLREFDIV__16;      //XT2����16��Ƶ����Ϊ��׼
	  while (SFRIFG1 & OFIFG) {                      //�ȴ�XT1��XT2��DCO�ȶ�
		UCSCTL7 &= ~(DCOFFG+XT1LFOFFG+XT2OFFG);
		SFRIFG1 &= ~OFIFG;
	  }
	  UCSCTL5 = DIVA__1 + DIVS__1 + DIVM__1; //�趨����CLK�ķ�Ƶ
	  UCSCTL4 = SELA__XT1CLK + SELS__DCOCLK + SELM__DCOCLK; //�趨����CLK��ʱ��Դ
}


volatile unsigned int value = 0;//�����жϱ���
volatile unsigned int flag=0;
volatile unsigned int y0 =0;
volatile unsigned int x =4;
volatile unsigned int y =0;
volatile unsigned int tmp0 =4;
volatile char disp[4]="000";

void main(void)
{
		WDTCTL = WDTPW + WDTHOLD;//�رտ��Ź�
		UART_RS232_Init();


		TA0CTL |= MC_1 + TASSEL_2 + TACLR;
		//ʱ��ΪSMCLK,�Ƚ�ģʽ����ʼʱ���������
		TA0CCTL0 = CCIE;//�Ƚ����ж�ʹ��
		TA0CCR0  = 50000;//�Ƚ�ֵ��Ϊ50000���൱��50ms��ʱ����

		P5DIR |= BIT7;
		P8DIR |= BIT0;
		ADC12CTL0 |= ADC12MSC;//�Զ�ѭ������ת��
		ADC12CTL0 |= ADC12ON;//����ADC12ģ��
		ADC12CTL1 |= ADC12CONSEQ1 ;//ѡ��ͨ��ѭ������ת��
		ADC12CTL1 |= ADC12SHP;//��������ģʽ
		ADC12MCTL0 |= ADC12INCH_12; //ѡ��ͨ��15�����Ӳ����λ����ch12:p7.4
		ADC12CTL0 |= ADC12ENC;

		_DINT();

		initClock();
		initTFT();


		etft_AreaSet(0,0,319,239,31);
		_EINT();
		__bis_SR_register(LPM0_bits + GIE);//����͹��Ĳ��������ж�

}

volatile int pulse_n=0;
volatile int pulse_cache[15]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
volatile int pulse_sum=0;
volatile int counter_flag=0;
volatile int pulse_count=0;

// ���� pulse_counter ������������������y �� y0
int pulse_counter(int y,int t0)
{
	// ���ܵ������ܺ��м�ȥ�ɵ�����ֵ
	pulse_sum-=pulse_cache[pulse_n];

	// ���㵱ǰ�������һ������Ĳ�ֵ�����������建������
	pulse_cache[pulse_n]=y-y0;

	// ���µ������ֵ�����ܵ������ܺ�
	pulse_sum+=pulse_cache[pulse_n];

	// �����建���������������1
	pulse_n++;

	// ������建������������ﵽ15�������С������������Ϊ0
	if(pulse_n>=15) pulse_n=0;

	// ���δ��⵽����Ŀ�ʼ�������ܺʹ��ڵ���40
	if((counter_flag==0)&&(pulse_sum>=40))
		{
			// ���ñ�־λ����ʾ��⵽����Ŀ�ʼ
			counter_flag=1;

			// ���浱ǰ����������������������Ϊ0
			int tmp=pulse_count;
			pulse_count=0;

			// ���������Ƶ��
			return 6000/tmp;
		}
	// ��������ܺ�С��40
	else if(pulse_sum<40) counter_flag=0; // ����־λ���ã���ʾ�����ѽ���

	// ������������
	pulse_count++;

	// ����ڵ�ǰ����������δ��⵽����Ľ���������-1
	return -1;
}

#pragma vector = TIMER0_A0_VECTOR
__interrupt void Timer_A (void) //����Timer_A�жϷ�����
{
	ADC12CTL0 |= ADC12SC; //����ADCת��
	value = ADC12MEM0; //��ADCת�������ֵ������value

	x++; //x�����1

	if (flag==0) //���flagΪ0
	{
		flag=1; //��flag��Ϊ1
		y0=232-value/18; //��y0��Ϊ�����ض�������ֵ

		ADC12CTL0 |= ADC12SC; //��ʼ��һ��ADCת��
		value = ADC12MEM0; //��ADCת�������ֵ������value
		UCA1TXBUF=value;
	}


	y=232-value/18; //��y��Ϊ�����ض�������ֵ
	UCA1TXBUF=value;

	if (x>=309) //���x���ڻ����309
	{
		x=4; //��x��Ϊ4
		etft_AreaSet(x,4,x+12,235,0); //��ָ����������������ɫ
		x++; //x�����1
	}

	tmp0=(y0+y)/2; //��tmp0��Ϊy0��y��ƽ��ֵ

	etft_AreaSet(x+1,4,x+6,235,0); //��ָ����������������ɫ

	if (y0<y) //���y0С��y
	{
		etft_AreaSet(x,y0,x,tmp0,0xf800); //��ָ����������������ɫ
		etft_AreaSet(x+1,tmp0,x+1,y,0xf800); //��ָ����������������ɫ
	}
	else //����
	{
		etft_AreaSet(x,tmp0,x,y0,0xf800); //��ָ����������������ɫ
		etft_AreaSet(x+1,y,x+1,tmp0,0xf800); //��ָ����������������ɫ
	}

	int freq=pulse_counter(y,y0); //����y��y0���������

	if(freq>0) //���freq����0
	{
		disp[0]=freq/100+'0'; //��Ƶ�ʵİ�λ��ת��Ϊ�ַ�����������
		disp[1]=(freq%100)/10+'0'; //��Ƶ�ʵ�ʮλ��ת��Ϊ�ַ�����������
		disp[2]=freq%10+'0'; //��Ƶ�ʵĸ�λ��ת��Ϊ�ַ�����������
	}

	etft_DisplayString(disp, 280,215,0xffff, 0x0000); //��ָ��λ����ʾ�ַ���

	y0=y; //��y��ֵ��y0
}

void UART_RS232_Init(void)	//RS232�ӿڳ�ʼ������
{
	/*ͨ����P3.4��P3.5��P4.4��P4.5������ʵ��ͨ��ѡ��
	 	 ʹUSCI�л���UARTģʽ*/
	P3DIR|=(1<<4)|(1<<5);
	P4DIR|=(1<<4)|(1<<5);
	P4OUT|=(1<<4);
	P4OUT&=~(1<<5);
	P3OUT|=(1<<5);
	P3OUT&=~(1<<4);
	P8SEL|=0x0c;	//ģ�鹦�ܽӿ����ã���P8.2��P8.3��ΪUSCI�Ľ��տ��뷢���
	UCA1CTL1|=UCSWRST;	//��λUSCI
	UCA1CTL1|=UCSSEL_1;	//���ø���ʱ�ӣ����ڷ����ض�������
	UCA1BR0=0x03;		//���ò�����
	UCA1BR1=0x00;
	UCA1MCTL=UCBRS_3+UCBRF_0;
	UCA1CTL1&=~UCSWRST;	//������λ
	UCA1IE|=UCRXIE;		//ʹ�ܽ����ж�
}
