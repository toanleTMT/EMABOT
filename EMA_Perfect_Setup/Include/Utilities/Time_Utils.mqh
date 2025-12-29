//+------------------------------------------------------------------+
//| Time_Utils.mqh                                                   |
//| Time utility functions                                           |
//+------------------------------------------------------------------+

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Check if current time is in London-NY overlap session           |
//| Vietnam time: 19:00-23:00                                        |
//+------------------------------------------------------------------+
bool IsLondonNYOverlap()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Convert to Vietnam time (UTC+7)
   int vietnamHour = dt.hour;
   
   return (vietnamHour >= LONDON_NY_OVERLAP_START && vietnamHour < LONDON_NY_OVERLAP_END);
}

//+------------------------------------------------------------------+
//| Check if current time is in London session                       |
//| Vietnam time: 15:00-24:00                                        |
//+------------------------------------------------------------------+
bool IsLondonSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   int vietnamHour = dt.hour;
   
   return (vietnamHour >= LONDON_SESSION_START || vietnamHour < 4);
}

//+------------------------------------------------------------------+
//| Check if current time is in NY session                          |
//| Vietnam time: 20:00-04:00 (next day)                             |
//+------------------------------------------------------------------+
bool IsNYSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   int vietnamHour = dt.hour;
   
   return (vietnamHour >= NY_SESSION_START || vietnamHour < NY_SESSION_END);
}

//+------------------------------------------------------------------+
//| Check if current time is in Asian session                       |
//+------------------------------------------------------------------+
bool IsAsianSession()
{
   return !IsLondonSession() && !IsNYSession();
}

//+------------------------------------------------------------------+
//| Get trading session score (for Context category)                |
//+------------------------------------------------------------------+
int GetTradingSessionScore()
{
   if(IsLondonNYOverlap())
      return 5;  // Best session
   else if(IsLondonSession() || IsNYSession())
      return 3;  // Good session
   else
      return 0;  // Asian session - avoid
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
   static datetime lastBarTime[];
   static string lastSymbol[];
   static ENUM_TIMEFRAMES lastTF[];
   
   // Find or create entry for this symbol/TF combination
   int index = -1;
   for(int i = 0; i < ArraySize(lastSymbol); i++)
   {
      if(lastSymbol[i] == symbol && lastTF[i] == timeframe)
      {
         index = i;
         break;
      }
   }
   
   // Create new entry if not found
   if(index == -1)
   {
      int size = ArraySize(lastSymbol);
      ArrayResize(lastSymbol, size + 1);
      ArrayResize(lastTF, size + 1);
      ArrayResize(lastBarTime, size + 1);
      
      index = size;
      lastSymbol[index] = symbol;
      lastTF[index] = timeframe;
      lastBarTime[index] = 0;
   }
   
   // Get current bar time
   datetime times[];
   if(CopyTime(symbol, timeframe, 0, 1, times) <= 0)
      return false;
   
   datetime currentBarTime = times[0];
   
   // Check if new bar
   if(currentBarTime != lastBarTime[index])
   {
      lastBarTime[index] = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get start of day (Vietnam time)                                  |
//+------------------------------------------------------------------+
datetime GetStartOfDay(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Check if new day started                                         |
//+------------------------------------------------------------------+
bool IsNewDay(datetime &lastDayCheck)
{
   datetime currentDay = GetStartOfDay(TimeCurrent());
   if(currentDay != lastDayCheck)
   {
      lastDayCheck = currentDay;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+

