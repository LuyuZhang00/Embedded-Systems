#include <msp430.h>
#include "dr_tft.h"

//--------------P5.0---------------------------------
#define	LCD_CS_SET		P5OUT |= 0x01
#define 	LCD_CS_CLR		P5OUT &=~0x01
//--------------P5.2---------------------------------
#define 	LCD_RS_SET		P5OUT |= 0x04
#define 	LCD_RS_CLR		P5OUT &=~0x04
//--------------P1.1---------------------------------
#define 	LCD_RST_SET		P1OUT |= 0x02
#define 	LCD_RST_CLR		P1OUT &=~0x02

//--------------P8.4---------------------------------
#define 	LCD_SCL_SET		P8OUT |= 0x10
#define 	LCD_SCL_CLR		P8OUT &=~0x10
//--------------P8.5---------------------------------
#define 	LCD_SCI_SET		P8OUT |= 0x20
#define 	LCD_SCI_CLR		P8OUT &=~0x20

#define tft_send_and_wait(x, y) tft_SendCmd(x, y);__delay_cycles(MCLK_FREQ / 1000);
#define tft_send_and_wait2(x, y, z) tft_SendCmd(x, y);__delay_cycles(MCLK_FREQ / 1000 * z);

//初始化TFT
void initTFT()
{
  //初始化RS、CS端口
  P5DIR |= BIT0 + BIT2;
  P1DIR |= BIT1;
  
  //LCD背光
  P3DIR |= BIT3;
  P3OUT &= ~BIT3;

  //复位TFTLCD
  LCD_RST_CLR;
  __delay_cycles(200); //20MHz下也能保证10us的延时
  LCD_RST_SET;
  __delay_cycles(MCLK_FREQ / 1000 * 100); //延时100ms
  LCD_CS_SET; //不用时关掉片选，有利于SPI容错性
  
  //配置与TFTLCD通信的串口
  UCB1CTL1 |= UCSWRST;
  UCB1CTL0 = UCCKPL + UCMSB + UCMST + UCSYNC; //下降沿变数据、上升沿采样；高位先；8位模式；主机；3线；同步
  UCB1CTL1 = UCSSEL__SMCLK + UCSWRST;
  UCB1BRW = SMCLK_FREQ / SPI_FREQ;
  P8REN |= BIT6;
  P8OUT &= ~BIT6;
  P8SEL |= BIT4 + BIT5 + BIT6;
  P8DIR |= BIT4 + BIT5;
  UCB1CTL1 &= ~UCSWRST;
  
  //写入初始化TFTLCD的指令
  tft_send_and_wait(TFTREG_SOFT_RESET, 0x0001); //软件复位
  tft_send_and_wait( 0x100, 0x0000 ); /*power supply setup*/
  tft_send_and_wait( 0x101, 0x0000 );
  tft_send_and_wait( 0x102, 0x3110 );
  tft_send_and_wait( 0x103, 0xe200 );
  tft_send_and_wait( 0x110, 0x009d );
  tft_send_and_wait( 0x111, 0x0022 );
  tft_send_and_wait( 0x100, 0x0120 );
  __delay_cycles(2000);;

  tft_send_and_wait( 0x100, 0x3120 );
  __delay_cycles(10000);;
  	/* Display control */
  tft_send_and_wait( 0x001, 0x0000 );
  tft_send_and_wait( 0x002, 0x0000 );
  tft_send_and_wait( 0x003, 0x1238 );
  tft_send_and_wait( 0x006, 0x0000 );
  tft_send_and_wait( 0x007, 0x0101 );
  tft_send_and_wait( 0x008, 0x0808 );
  tft_send_and_wait( 0x009, 0x0000 );
  tft_send_and_wait( 0x00b, 0x0000 );
  tft_send_and_wait( 0x00c, 0x0100 );
  tft_send_and_wait( 0x00d, 0x0018 );
  	/* LTPS control settings */
  tft_send_and_wait( 0x012, 0x0000 );
  tft_send_and_wait( 0x013, 0x0000 );
  tft_send_and_wait( 0x018, 0x0000 );
  tft_send_and_wait( 0x019, 0x0000 );

  tft_send_and_wait( 0x203, 0x0000 );
  tft_send_and_wait( 0x204, 0x0000 );

  tft_send_and_wait( 0x210, 0x0000 );
  tft_send_and_wait( 0x211, 0x00ef );
  tft_send_and_wait( 0x212, 0x0000 );
  tft_send_and_wait( 0x213, 0x013f );
  tft_send_and_wait( 0x214, 0x0000 );
  tft_send_and_wait( 0x215, 0x0000 );
  tft_send_and_wait( 0x216, 0x0000 );
  tft_send_and_wait( 0x217, 0x0000 );

  	// Gray scale settings
  tft_send_and_wait( 0x300, 0x5343);
  tft_send_and_wait( 0x301, 0x1021);
  tft_send_and_wait( 0x302, 0x0003);
  tft_send_and_wait( 0x303, 0x0011);
  tft_send_and_wait( 0x304, 0x050a);
  tft_send_and_wait( 0x305, 0x4342);
  tft_send_and_wait( 0x306, 0x1100);
  tft_send_and_wait( 0x307, 0x0003);
  tft_send_and_wait( 0x308, 0x1201);
  tft_send_and_wait( 0x309, 0x050a);

  	/* RAM access settings */
  tft_send_and_wait( 0x400, 0x4027 );
  tft_send_and_wait( 0x401, 0x0000 );
  tft_send_and_wait( 0x402, 0x0000 );	/* First screen drive position (1) */
  tft_send_and_wait( 0x403, 0x013f );	/* First screen drive position (2) */
  tft_send_and_wait( 0x404, 0x0000 );

  tft_send_and_wait( 0x200, 0x0000 );
  tft_send_and_wait( 0x201, 0x0000 );

  tft_send_and_wait( 0x100, 0x7120 );
  tft_send_and_wait( 0x007, 0x0103 );
  __delay_cycles(2000);
  tft_send_and_wait( 0x007, 0x0113 );
}

void tft_AddTxData(uint16_t val)
{
  while(!(UCB1IFG & UCTXIFG)); //等待发送缓冲区空
  UCB1TXBUF = (val >> 8) & 0xFF; //发送高位
  while(!(UCB1IFG & UCTXIFG)); //等待发送缓冲区空
  UCB1TXBUF = val & 0xFF; //发送低位
  while(UCB1STAT & UCBUSY); //等待最后一位实际送出
}

//向TFT屏发送一个地址，返回是否发送成功
int tft_SendIndex(uint16_t val)
{
  LCD_CS_CLR;
  LCD_RS_CLR;
  tft_AddTxData(val);
  LCD_CS_SET;
  return 1;
}

//向TFT屏发送一个数据，返回是否发送成功
int tft_SendData(uint16_t val)
{
  LCD_CS_CLR;
  LCD_RS_SET;
  tft_AddTxData(val);
  LCD_CS_SET;
  return 1;
}

//向TFT屏的寄存器reg发送数据data，返回是否发送成功
int tft_SendCmd(uint16_t reg, uint16_t data)
{
  tft_SendIndex(reg);
  tft_SendData(data);
  return 1;
}
