#include <msp430.h>
#include "dr_tft.h"
#include "dr_tft_ascii.h"

void etft_AreaSet(uint16_t startX, uint16_t startY, uint16_t endX, uint16_t endY, uint16_t color)
{
  uint16_t i,j;
  tft_SendCmd(TFTREG_WIN_MINX, startX);
  tft_SendCmd(TFTREG_WIN_MINY, startY);
  tft_SendCmd(TFTREG_WIN_MAXX, endX);
  tft_SendCmd(TFTREG_WIN_MAXY, endY);
          
  tft_SendCmd(TFTREG_RAM_XADDR, startX);
  tft_SendCmd(TFTREG_RAM_YADDR, startY);
  
  tft_SendIndex(TFTREG_RAM_ACCESS);
  for(i=0;i<endY - startY + 1;i++)
  {
    for(j=0;j<endX - startX + 1;j++)
    {
      tft_SendData(color);
    }
  }
}

void etft_DisplayString(volatile char* str, uint16_t sx, uint16_t sy, uint16_t fRGB, uint16_t bRGB)
{
  uint16_t cc = 0;
  uint16_t cx, cy;
  
  while(1)
  {
    char curchar = str[cc];
    if(curchar == '\0') //字符串已发送完
      return;

    cx = 0;
    cy = 0;
    //屏幕是横的，XY要对调
    tft_SendCmd(TFTREG_WIN_MINX, sx);//x start point
    tft_SendCmd(TFTREG_WIN_MINY, sy);//y start point
    tft_SendCmd(TFTREG_WIN_MAXX, sx+7);//x end point
    tft_SendCmd(TFTREG_WIN_MAXY, sy+15);//y end point
    tft_SendCmd(TFTREG_RAM_XADDR, sx);//x start point
    tft_SendCmd(TFTREG_RAM_YADDR, sy);//y start point
    tft_SendIndex(TFTREG_RAM_ACCESS);
    
    uint16_t color;
    while(1)
    {
      if(cx >= 8)
      {
        cx = 0;
        cy++;
        if(cy >= 16)
        { //一个字符发送完毕
          cc++; //下一个字符
          sx+=8;
          if(sx >= TFT_YSIZE) //越过行末
          {
            sx = 0;
            sy += 16;
          }
          break;
        }
      }
      
      if((tft_ascii[curchar*16 + cy] << cx) & 0x80)
        color = fRGB;
      else
        color = bRGB;
      
      tft_SendData(color);
      cx++; //X自增 
    }
  }
}

void etft_DisplayImage(const uint8_t* image, uint16_t sx, uint16_t sy, uint16_t width, uint16_t height)
{
  uint16_t i,j;
  uint32_t row_length = width * 3; //每行像素数乘3
  if(row_length & 0x3) //非4整倍数
  {
    row_length |= 0x03;
    row_length += 1;
  }
  const uint8_t *ptr = image + (height - 1) * row_length;
  tft_SendCmd(TFTREG_WIN_MINX, sx);
  tft_SendCmd(TFTREG_WIN_MINY, sy);
  tft_SendCmd(TFTREG_WIN_MAXX, sx + width - 1);
  tft_SendCmd(TFTREG_WIN_MAXY, sy + height - 1);

  tft_SendCmd(TFTREG_RAM_XADDR, sx);
  tft_SendCmd(TFTREG_RAM_YADDR, sy);

  tft_SendIndex(TFTREG_RAM_ACCESS);
  for(i=0;i<height;i++)
  {
    for(j=0;j<width;j++)
    {
      tft_SendData(etft_Color(ptr[2], ptr[1], ptr[0]));
      ptr += 3;
    }
    ptr -= width * 3 + row_length;
  }
}

void etft_DisplayDian( uint16_t sy[],uint16_t color)
{
	uint16_t i;
	etft_AreaSet(0,sy[0],1,sy[0]+1,color);
	for(i=1;i<318;i++)
	{

		etft_AreaSet(i,6,i+1,7,color);

	}
}
