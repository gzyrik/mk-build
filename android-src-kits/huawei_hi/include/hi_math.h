/******************************************************************************

  Copyright (C), 2009-2014, Huawei Tech. Co., Ltd.

 ******************************************************************************
  File Name     : hi_math.h
  Version       : Initial Draft
  Author        : c55300
  Created       : 2009/04/09
  Last Modified :
  Description   : mathematical functions.
  Function List :
  History       :
  1.Date        : 2009/04/09
    Author      : c55300
    Modification: Created file
    
  2.Date        : 2009/05/04
    Author      : c55300
    Modification: Add ENDIAN and VALUE_BETWEEN.

  3.Date        : 2009/05/21
    Author      : c55300
    Modification: Add macro of FRACTION operation and CMP.
    
******************************************************************************/
#ifndef __HI_MATH_H__
#define __HI_MATH_H__

#include "hi_type.h"

#ifdef __cplusplus
#if __cplusplus
extern "C"{
#endif
#endif /* __cplusplus */

/******************************************************************************
** ABS(x)                 absolute value of x
** SIGN(x)                sign of x
** CMP(x,y)               0 if x==y; 1 if x>y; -1 if x<y
******************************************************************************/
#define ABS(x)          ( (x) >= 0 ? (x) : (-(x)) )
#define SIGN(x)         ( (x) >= 0 ? 1 : -1 )
#define CMP(x,y)        (((x) == (y)) ? 0 : (((x) > (y)) ? 1 : -1))

/******************************************************************************
** MAX2(x,y)              maximum of x and y
** MIN2(x,y)              minimum of x and y
** MAX3(x,y,z)            maximum of x, y and z
** MIN3(x,y,z)            minimun of x, y and z
** MEDIAN(x,y,z)          median of x,y,z
** MEAN2(x,y)             mean of x,y
******************************************************************************/
#define MAX2(x,y)       ( (x)>(y) ? (x):(y) )
#define MIN2(x,y)       ( (x)<(y) ? (x):(y) )
#define MAX3(x,y,z)     ( (x)>(y) ? MAX2(x,z) : MAX2(y,z) )
#define MIN3(x,y,z)     ( (x)<(y) ? MIN2(x,z) : MIN2(y,z) )
#define MEDIAN(x,y,z)   (((x)+(y)+(z) - MAX3(x,y,z)) - MIN3(x,y,z) )
#define MEAN2(x,y)      (((x)+(y)) >> 1 )

/******************************************************************************
** CLIP3(x,min,max)       clip x within [min,max]
** WRAP_MAX(x,max,min)    wrap to min if x equal max
** WRAP_MIN(x,min,max)    wrap to max if x equal min
** VALUE_BETWEEN(x,min.max)   True if x is between [min,max] inclusively.
******************************************************************************/
#define CLIP3(x,min,max)         ( (x)< (min) ? (min) : ((x)>(max)?(max):(x)) )
#define WRAP_MAX(x,max,min)      ( (x)>=(max) ? (min) : (x) )
#define WRAP_MIN(x,min,max)      ( (x)<=(min) ? (max) : (x) )
#define VALUE_BETWEEN(x,min,max) (((x)>=(min)) && ((x) <= (max)))

/******************************************************************************
** MULTI_OF_2_POWER(x,a)  whether x is multiple of a(a must be power of 2)
** CEILING_2_POWER(x,a)   ceiling x to multiple of a(a must be power of 2)
** FLOOR_2_POWER(x,a)     floor x to multiple of a(a must be power of 2)
** HIALIGN(x, a)            align x to multiple of a
**
** Example:
** CEILING_2_POWER(5,4) = 8
** FLOOR_2_POWER(5,4)   = 4
******************************************************************************/
#define MULTI_OF_2_POWER(x,a)    (!((x) & ((a) - 1) ) )
#define CEILING_2_POWER(x,a)     ( ((x) + ((a) - 1) ) & ( ~((a) - 1) ) )
#define FLOOR_2_POWER(x,a)       (  (x) & (~((a) - 1) ) )
#define HIALIGN(x, a)              ((a) * (((x) + (a) - 1) / (a)))
#define HICEILING(x, a)           (((x)+(a)-1)/(a))
#define HIALIGN_UP(x, a)         ((((x) + (a) - 1)/(a))*(a))
#define HIALIGN_DOWN(x, a)       ((x) - (x)%(a))
#define HI_SYS_GET_STRIDE(w)   ((((w)%256)==0)?(w):(((((w)/256)%2)==0)?((((w)/256)+1)*256):((((w)/256)+2)*256)))

/******************************************************************************
** Get the span between two unsinged number, such as
** SPAN(HI_U32, 100, 200) is 200 - 100 = 100
** SPAN(HI_U32, 200, 100) is 0xFFFFFFFF - 200 + 100
** SPAN(HI_U64, 200, 100) is 0xFFFFFFFFFFFFFFFF - 200 + 100
******************************************************************************/
#define SPAN(type, begin, end)\
({                            \
   type b = (begin);          \
   type e = (end);            \
   (type)((b >= e) ? (b - e) : (b + ((~((type)0))-e))); \
})

/******************************************************************************
** ENDIAN32(x,y)              little endian <---> big endian
** IS_LITTLE_END()            whether the system is little end mode
******************************************************************************/
#define  ENDIAN32( x )						\
	(   ( (x) << 24 ) |						\
		( ( (x) & 0x0000ff00 ) << 8 ) |		\
		( ( (x) & 0x00ff0000 ) >> 8 ) |		\
		( ( (x) >> 24 ) & 0x000000ff )  )

__inline static HI_BOOL IS_LITTLE_END(void)
{
    union unEND_TEST_U
    {
        HI_CHAR cTest[4];
        HI_U32  u32Test;
    } unEndTest;

    unEndTest.cTest[0] = 0x01;
    unEndTest.cTest[1] = 0x02;
    unEndTest.cTest[2] = 0x03;
    unEndTest.cTest[3] = 0x04;
    
    return (unEndTest.u32Test > 0x01020304) ? (HI_TRUE) : (HI_FALSE);
}


/******************************************************************************
** FRACTION32(de,nu)          fraction: nu(minator) / de(nominator).
** NUMERATOR32(x)              of x(x is fraction)
** DENOMINATOR32(x)           Denominator of x(x is fraction)

** represent fraction in 32 bit. LSB 16 is numerator, MSB 16 is denominator
** It is integer if denominator is 0.
******************************************************************************/
#define FRACTION32(de,nu)       ( ((de) << 16) | (nu) ) 
#define NUMERATOR32(x)          ( (x) & 0xffff)
#define DENOMINATOR32(x)        ( (x) >> 16 )  

/******************************************************************************
** RGB(r,g,b)    assemble the r,g,b to 24bit color
** RGB_R(c)      get RED   from 24bit color
** RGB_G(c)      get GREEN from 24bit color
** RGB_B(c)      get BLUE  from 24bit color
******************************************************************************/
#define RGB(r,g,b) ((((r) & 0xff) << 16) | (((g) & 0xff) << 8) | ((b) & 0xff))
#define RGB_R(c)   ( ((c) & 0xff0000) >> 16)
#define RGB_G(c)   ( ((c) & 0xff00) >> 8)
#define RGB_B(c)   (  (c) & 0xff)

/******************************************************************************
** YUV(y,u,v)    assemble the y,u,v to 24bit color
** YUV_Y(c)      get Y from 24bit color
** YUV_U(c)      get U from 24bit color
** YUV_V(c)      get V from 24bit color
******************************************************************************/
#define YUV(y,u,v) ((((y) & 0xff) << 16) | (((u) & 0xff) << 8) | ((v) & 0xff))
#define YUV_Y(c)   ( ((c) & 0xff0000) >> 16)
#define YUV_U(c)   ( ((c) & 0xff00) >> 8)
#define YUV_V(c)   (  (c) & 0xff)

/******************************************************************************
** Rgb2Yc(r, g, b, *y, *u, *u)    convert r,g,b to y,u,v
** Rgb2Yuv(rgb, *yuv)             convert rgb to yuv
******************************************************************************/
__inline static HI_VOID Rgb2Yc(HI_U8 r, HI_U8 g, HI_U8 b, HI_U8 * py, HI_U8 * pcb, HI_U8 * pcr)
{
    /* Y */
    *py = (HI_U8)(((r*66+g*129+b*25) >> 8) + 16);

    /* Cb */
    *pcb = (HI_U8)((((b*112-r*38)-g*74) >> 8) + 128);

    /* Cr */
    *pcr = (HI_U8)((((r*112-g*94)-b*18) >> 8) + 128);
}

__inline static HI_U32 Rgb2Yuv(HI_U32 u32Rgb)
{
    HI_U8 y,u,v;

    Rgb2Yc(RGB_R(u32Rgb), RGB_G(u32Rgb), RGB_B(u32Rgb), &y, &u, &v);

    return YUV(y,u,v);
}

/******************************************************************************
** GetYCFromRGB(rgb, *y, *cbcr)    convert rgb to yyyy, uvuv, 
******************************************************************************/
__inline static HI_VOID GetYCFromRGB(HI_U32 rgb, HI_U32 * pY, HI_U32 * pC)
{
    HI_U8 y, cb, cr;
    HI_U32 color_y, color_c, tmp;

    Rgb2Yc(RGB_R(rgb), RGB_G(rgb), RGB_B(rgb), &y, &cb, &cr);

    tmp = y & 0xFF;
    color_y = (tmp<<24) + (tmp<<16) + (tmp<<8) + tmp;

    tmp = cb & 0xFF;
    color_c = (tmp<<24) + (tmp<<8);
    
    tmp = cr & 0xFF;
    color_c = color_c + (tmp<<16) + tmp;

    *pY = color_y;
    *pC = color_c;
}

/*******************************************************************************
** FpsControl Useing Sample:
**  FPS_CTRL_S g_stFpsCtrl;
**
**  Take 12 frame uniform in 25.
**  InitFps(&g_stFpsCtrl, 25, 12);
**
**  {
**       if(FpsControl(&g_stFpsCtrl)) printf("Yes, this frmae should be token");
**  }
**
*******************************************************************************/
typedef struct hiFPS_CTRL_S
{
    HI_U32 u32Ffps;    /* Full frame rate    */
    HI_U32 u32Tfps;    /* Target frame rate  */
    HI_U32 u32FrmKey;  /* update key frame   */
} FPS_CTRL_S;

__inline static HI_VOID InitFps(FPS_CTRL_S *pFrmCtrl, HI_U32 u32FullFps,
                                HI_U32 u32TagFps)
{
    pFrmCtrl->u32Ffps   = u32FullFps;
    pFrmCtrl->u32Tfps   = u32TagFps;
    pFrmCtrl->u32FrmKey = 0;
}

__inline static HI_BOOL FpsControl(FPS_CTRL_S *pFrmCtrl)
{
    HI_BOOL   bReturn       = HI_FALSE;

    pFrmCtrl->u32FrmKey += pFrmCtrl->u32Tfps;
    if (pFrmCtrl->u32FrmKey >= pFrmCtrl->u32Ffps)
    {
        pFrmCtrl->u32FrmKey -= pFrmCtrl->u32Ffps;
        bReturn = HI_TRUE;
    }
    
    return bReturn;
}

/*******************************************************************************
** GetSysTimeBySec   
** GetSysTimeByUsec 
*******************************************************************************/
#ifdef __KERNEL__
    #include <linux/time.h>
#else
    #include <sys/time.h>
#endif
__inline static HI_U32 GetSysTimeBySec(void)
{
    struct timeval stTime;
    #ifdef __KERNEL__
        do_gettimeofday(&stTime);
    #else
        gettimeofday(&stTime, NULL);
    #endif
    return stTime.tv_sec;
}

__inline static HI_U64 GetSysTimeByUsec(void)
{
    struct timeval stTime;
    #ifdef __KERNEL__
        do_gettimeofday(&stTime);
    #else
        gettimeofday(&stTime, NULL);
    #endif
    return  (stTime.tv_sec * 1000000LLU) + stTime.tv_usec;
}


#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */


#endif /* __HI_MATH_H__ */

