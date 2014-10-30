/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.00
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include "rgbConvertMex.cpp"
#include "imPadMex.cpp"
#include "convConst.cpp"
#include "imResampleMex.cpp"
#include "gradientMex.cpp"

// compile and test standalone channels source code
int main(int argc, const char* argv[])
{
  // initialize test array (misalign controls memory mis-alignment)
  const int h=12, w=12, misalign=1; int x, y, d;
  float I[h*w*3+misalign], *I0=I+misalign;
  for( x=0; x<h*w*3; x++ ) I0[x]=0;
  for( d=0; d<3; d++ ) I0[int(h*w/2+h/2)+d*h*w]=1;

  // initialize memory for results with given misalignment
  const int pad=2, rad=2, sf=sizeof(float); d=3;
  const int h1=h+2*pad, w1=w+2*pad, h2=h1/2, w2=w1/2, h3=h2/4, w3=w2/4;
  float *I1, *I2, *I3, *I4, *Gx, *Gy, *M, *O, *H, *G;
  I1 = (float*) wrCalloc(h1*w1*d+misalign,sf) + misalign;
  I3 = (float*) wrCalloc(h1*w1*d+misalign,sf) + misalign;
  I4 = (float*) wrCalloc(h2*w2*d+misalign,sf) + misalign;
  Gx = (float*) wrCalloc(h2*w2*d+misalign,sf) + misalign;
  Gy = (float*) wrCalloc(h2*w2*d+misalign,sf) + misalign;
  M  = (float*) wrCalloc(h2*w2*d+misalign,sf) + misalign;
  O  = (float*) wrCalloc(h2*w2*d+misalign,sf) + misalign;
  H  = (float*) wrCalloc(h3*w3*d*6+misalign,sf) + misalign;
  G  = (float*) wrCalloc(h3*w3*d*24+misalign,sf) + misalign;

  // perform tests of imPad, rgbConvert, convConst, resample and gradient
  imPad(I0,I1,h,w,d,pad,pad,pad,pad,0,0.0f);
  I2 = rgbConvert(I1,h1*w1,d,0,1.0f); d=1;
  convTri(I2,I3,h1,w1,d,rad,1);
  resample(I3,I4,h1,h2,w1,w2,d,1.0f);
  grad2( I4, Gx, Gy, h2, w2, d );
  gradMag( I4, M, O, h2, w2, d );
  gradHist(M,O,H,h2,w2,4,6,0);
  hog(H,G,h2,w2,4,6,.2f);

  // print some test arrays
  printf("---------------- M: ----------------\n");
  for(y=0;y<h2;y++){ for(x=0;x<w2;x++) printf("%.4f ",M[x*h2+y]); printf("\n");}
  printf("---------------- O: ----------------\n");
  for(y=0;y<h2;y++){ for(x=0;x<w2;x++) printf("%.4f ",O[x*h2+y]); printf("\n");}

  // free memory and return
  wrFree(I1-misalign); wrFree(I2); wrFree(I3-misalign); wrFree(I4-misalign);
  wrFree(Gx-misalign); wrFree(Gy-misalign); wrFree(M-misalign);
  wrFree(O-misalign); wrFree(H-misalign); wrFree(G-misalign);
  system("pause"); return 0;
}
