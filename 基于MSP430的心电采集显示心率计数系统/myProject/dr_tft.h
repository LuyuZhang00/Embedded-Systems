#ifndef __DR_TFT_H_
#define __DR_TFT_H_

#include <stdint.h>

#ifndef MCLK_FREQ
  #define MCLK_FREQ 20000000
#endif

#ifndef SMCLK_FREQ
  #define SMCLK_FREQ 20000000
#endif

#define SPI_FREQ 10000000

#define TFT_XSIZE 240
#define TFT_YSIZE 320

#define TFTREG_RAM_XADDR  0x0201
#define TFTREG_RAM_YADDR  0x0200
#define TFTREG_RAM_ACCESS 0x0202

#define TFTREG_SOFT_RESET 0x0003

#define TFTREG_WIN_MINX   0x0212
#define TFTREG_WIN_MAXX   0x0213
#define TFTREG_WIN_MINY   0x0210
#define TFTREG_WIN_MAXY   0x0211



/* TFT屏底层接口 */

//初始化TFT
void initTFT();

//向TFT屏发送一个地址，返回是否发送成功
int tft_SendIndex(uint16_t val);

//向TFT屏发送一个数据，返回是否发送成功
int tft_SendData(uint16_t val);

//向TFT屏的寄存器reg发送数据data，返回是否发送成功
int tft_SendCmd(uint16_t reg, uint16_t data);

/* TFT屏高层接口 */
/* 所有高层接口内置X、Y对调，即接口处X为横Y为纵 */

//将0~255表示的RGB颜色转换为TFT屏幕使用的颜色
static inline uint16_t etft_Color(uint8_t r, uint8_t g, uint8_t b)
{
  uint16_t temp = 0;
  temp |= (r << 8) & 0xF800;
  temp |= (g << 3) & 0x07E0;
  temp |= (b >> 3) & 0x001F;
  return temp;
}

//将一个区域置为某个颜色
void etft_AreaSet(uint16_t startX, uint16_t startY, uint16_t endX, uint16_t endY, uint16_t color);

//在指定的位置显示一个字符串
void etft_DisplayString(volatile char* str, uint16_t sx, uint16_t sy, uint16_t fRGB, uint16_t bRGB);

//在指定的位置显示一幅图片，image以24位位图数据区表示
//即像素顺序从左到右、从下到上(即行顺序倒转)，每3字节一个像素，顺序为B、G、R，每行字节数用0补齐至4的整倍数
//对常见24位位图，从0x36复制到文件末尾即可
void etft_DisplayImage(const uint8_t* image, uint16_t sx, uint16_t sy, uint16_t width, uint16_t height);

#endif
