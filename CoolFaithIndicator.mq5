//+------------------------------------------------------------------+
//|                                           CoolFaithIndicator.mq5 |
//|                                 Copyright 2023, Diego Del Bianco |
//|                                         http://delbianco.emp.br/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Diego Del Bianco"
#property link      "http://delbianco.emp.br/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot Grade_of_faith
#property indicator_label1  "Grade_of_faith"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
//--- input parameters
input int      per=10;
//--- indicator buffers
double         Grade_of_faithBuffer[];
double         Histogram_colorBuffer[];
//--- vars
bool           up;
bool           down;
double         vproc;
double         highest_volume = 0;
int            highest_search = 0;
int            vol_ma_search   = 0;
double         volup_totals_ma =  0;
double         voldown_totals_ma =  0;
double         volup[];
double         voldown[];
double         maup = 0;
double         madown = 0;
double         difvol = 0;
int            u1, u2, u3, u4, u5;
int            d1, d2, d3, d4, d5;
double         dif = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Grade_of_faithBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,Histogram_colorBuffer,INDICATOR_COLOR_INDEX);
   
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Cool Faith");
   ArrayInitialize(Grade_of_faithBuffer, EMPTY_VALUE);


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
     ArrayResize(volup, rates_total);
     ArrayResize(voldown, rates_total);
     volup[0] = 0.0;
     voldown[0] = 0.0;
     Histogram_colorBuffer[0]=0.0;
     if(prev_calculated)
      for(int i=1;i<rates_total && !IsStopped();i++)
        {
            
            up    = false;
            down  = false;
            if(high[i] > high[i-1] && tick_volume[i] > tick_volume[i-1])    up    = true; //Buyers volume when both higher high and more volume
            if(low[i] < low[i-1] && tick_volume[i] > tick_volume[i-1])      down  = true; //Sellers volume when both lower low and more volume
            
            highest_search = 30;
            if(highest_search > i) highest_search = i;
            
            for(int i2=0;i2<highest_search;i2++)
              {
                  if(tick_volume[i-i2] > highest_volume) highest_volume = (double)tick_volume[i-i2];
              }
            
            vproc = tick_volume[i] / highest_volume*200; //Used for calculation of volume expansion in a kind of percentage
            volup[i] = 0.0;
            voldown[i] = 0.0;
            if(up) volup[i] = vproc;                   //Entered in the series of Buyers volume
            if(down) voldown[i] = vproc;               //Entered in the series of Sellers volume
            
            
            //Média móvel
            volup_totals_ma   = 0;
            voldown_totals_ma = 0;
            vol_ma_search     = per;
            if(per > i) vol_ma_search = i;
            for(int i2=0;i2<vol_ma_search;i2++)
              {
               volup_totals_ma = volup_totals_ma + volup[i-i2];
               voldown_totals_ma = voldown_totals_ma + voldown[i-i2];
              }
              
             maup = volup_totals_ma / vol_ma_search;
             madown = voldown_totals_ma / vol_ma_search;
                         
                         
            difvol = maup - madown;                     //Faith of the market, i.e. buyers dominate the volume or sellers dominate it
            u1 = difvol>60 ? 8 : 0;                     //Very high faith graduated as 8
            u2 = difvol>40 && difvol<=60 ? 6 : 0;      //High faith as 6
            u3 = difvol>20 && difvol<=40 ? 4 : 0;      //Good faith as 4
            u4 = difvol>10 && difvol<=20 ? 2 : 0;      //Some Faith as 2
            u5 = difvol>0 && difvol<=10 ? 1 : 0;       //Little Faith as 1
            d1 = difvol<-60 ? -8 : 0;                   //Very High mistrust graduated as -8    
            d2 = difvol<-40 && difvol >=-60 ? -6 : 0;  //High Mistrust as -6
            d3 = difvol<-20 && difvol >=-40 ? -4 : 0;  //Bad Mistrust as -4 
            d4 = difvol<-10 && difvol >=-20 ? -2 : 0;  //Some Mistrust as -2
            d5 = difvol<0 && difvol>=-10 ? -1 : 0;     //Little Mistrust as -1
            dif = u1+u2+u3+u4+u5+d1+d2+d3+d4+d5;        //Grades are either zero or something, adding them all up gives the grade in this instance
            
            
            Grade_of_faithBuffer[i] = (double)dif;
            if(dif>0)
               Histogram_colorBuffer[i]=0.0;
            else
               Histogram_colorBuffer[i]=1.0;
         
         /*
            -per = input(type=input.integer , title="periods for averaging" , defval=10)
            -up = high>high[1] and volume>volume[1]   //Buyers volume when both higher high and more volume
            -down = low<low[1] and volume>volume[1]   //Sellers volume when both lower low and more volume
            
            -vproc=volume/highest(volume, 30)*200     //Used for calculation of volume expansion in a kind of percentage
            -volup = up ? vproc : 0                   //Entered in the series of Buyers volume
            -voldown = down ? vproc : 0               //Entered in the series of Sellers volume
            
            maup = sma(volup, per)                   //Average Buyers volume, sma and 10 periods seem to work best
            madown = sma(voldown, per)               //Average Sellers volume
            
            difvol = maup - madown                     //Faith of the market, i.e. buyers dominate the volume or sellers dominate it
            u1 = difvol>60 ? 8 : 0                     //Very high faith graduated as 8
            u2 = difvol>40 and difvol<=60 ? 6 : 0      //High faith as 6
            u3 = difvol>20 and difvol<=40 ? 4 : 0      //Good faith as 4
            u4 = difvol>10 and difvol<=20 ? 2 : 0      //Some Faith as 2
            u5 = difvol>0 and difvol<=10 ? 1 : 0       //Little Faith as 1
            d1 = difvol<-60 ? -8 : 0                   //Very High mistrust graduated as -8    
            d2 = difvol<-40 and difvol >=-60 ? -6 : 0  //High Mistrust as -6
            d3 = difvol<-20 and difvol >=-40 ? -4 : 0  //Bad Mistrust as -4 
            d4 = difvol<-10 and difvol >=-20 ? -2 : 0  //Some Mistrust as -2
            d5 = difvol<0 and difvol>=-10 ? -1 : 0     //Little Mistrust as -1
            dif = u1+u2+u3+u4+u5+d1+d2+d3+d4+d5        //Grades are either zero or something, adding them all up gives the grade in this instance
            
            plot(dif , "Grade of Faith" , dif > 0 ? color.blue : color.red , style=plot.style_histogram , transp=0 , linewidth=5)
            
            //Backgroud colors taken from Hull Moving Average Agreement Indicator (Hullag)
            fhl=20                                     //number of periods for fast Hull ma
            shl=25                                     //number of periods for slow Hull ma
            trnd=0.1                                   //minimum ATR difference required to call the ma a trend
            istrend=trnd*atr(30)                       //Calculate minimum ATR as a kind of tangent

            fh=hma(close, fhl)                         //fast Hull Moving Average
            fangle=fh[0]-fh[1]                         //angle of fast hull slope calculated as a kind of tangent
            var ftrend= 0                              //initialise fast trend graduation
            ftrend:= fangle>istrend? 1:fangle<-istrend?-1:0 //fast trend either 1, 0 or -1 meaning uptrend, no trend, down trend
            
            sh=hma(close, shl)                         //slow Hull Moving Average
            sangle=sh[0]-sh[1]                         //angle of slow hull slope as a kind of tangent
            var strend=0                               // initialise slow trend graduation
            strend:= sangle>istrend? 1:sangle<-istrend? -1:0 //slow trend either 1, 0 or -1 meaning uptrend, no trend, down trend
            
            hullag= ftrend+strend                      //possible graduations are 2, 1, 0, -1, -2
            bg2 = color.new(color.blue,65)             //color when both hma agree on up trend, i.e. grade 2
            bg1 = color.new(color.green,75)            //color when one hma has up trend, one no trend, i.e. grade 1
            bg0 = color.new(color.silver,85)           //color when either both hma have no trend or have opposite trend, i.e. grad zero
            bgm1 = color.new(color.maroon,80)          //color when one hma has down trend, one no trend, i.e. grade -1
            bgm2 = color.new(color.red,65)             // color when both hma agree on down trend, i.e. grade -2
            bgcolor(hullag==2?bg2: hullag==1?bg1: hullag==0?bg0: hullag==-1?bgm1: bgm2)
         */
         
        //}
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
