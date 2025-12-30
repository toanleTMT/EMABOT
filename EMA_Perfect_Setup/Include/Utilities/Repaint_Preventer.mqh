//+------------------------------------------------------------------+
//| Repaint_Preventer.mqh                                            |
//| Prevents signal repainting by ensuring closed bar confirmation   |
//+------------------------------------------------------------------+

#include "../Config.mqh"

//+------------------------------------------------------------------+
//| Repaint Preventer Class                                          |
//+------------------------------------------------------------------+
class CRepaintPreventer
{
private:
   static datetime m_lastBarTime[];
   static string m_lastSymbol[];
   static ENUM_TIMEFRAMES m_lastTF[];
   
   static int FindIndex(string symbol, ENUM_TIMEFRAMES timeframe);
   
public:
   // Check if bar is closed (use bar 1, not bar 0)
   static bool IsBarClosed(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Get closed bar time (bar 1)
   static datetime GetClosedBarTime(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Verify bar close confirmation
   static bool VerifyBarClose(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Check if we should process this bar (prevents duplicate processing)
   static bool ShouldProcessBar(string symbol, ENUM_TIMEFRAMES timeframe);
};

// Static member initialization
datetime CRepaintPreventer::m_lastBarTime[];
string CRepaintPreventer::m_lastSymbol[];
ENUM_TIMEFRAMES CRepaintPreventer::m_lastTF[];

//+------------------------------------------------------------------+
//| Find index for symbol/timeframe combination                     |
//+------------------------------------------------------------------+
int CRepaintPreventer::FindIndex(string symbol, ENUM_TIMEFRAMES timeframe)
{
   for(int i = 0; i < ArraySize(m_lastSymbol); i++)
   {
      if(m_lastSymbol[i] == symbol && m_lastTF[i] == timeframe)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Check if bar is closed (use bar 1, not bar 0)                  |
//| Bar 0 = current forming bar (repaints)                          |
//| Bar 1 = last closed bar (no repaint)                            |
//+------------------------------------------------------------------+
bool CRepaintPreventer::IsBarClosed(string symbol, ENUM_TIMEFRAMES timeframe)
{
   // ANTI-LAG OPTIMIZATION: Faster bar close detection
   // Get bar 1 time (closed bar) and bar 0 time (current bar) in one check
   datetime times[];
   if(CopyTime(symbol, timeframe, 0, 2, times) < 2)  // Get both bar 0 and bar 1
      return false;
   
   datetime currentBarTime = times[0];  // Bar 0
   datetime closedBarTime = times[1];    // Bar 1
   
   // Bar is closed if bar 1 time is different from bar 0 time
   // This means a new bar has formed, so bar 1 is confirmed closed
   return (closedBarTime < currentBarTime);
}

//+------------------------------------------------------------------+
//| Get closed bar time (bar 1)                                     |
//+------------------------------------------------------------------+
datetime CRepaintPreventer::GetClosedBarTime(string symbol, ENUM_TIMEFRAMES timeframe)
{
   datetime times[];
   if(CopyTime(symbol, timeframe, 1, 1, times) > 0)
      return times[0];
   
   return 0;
}

//+------------------------------------------------------------------+
//| Verify bar close confirmation                                   |
//| Ensures we only process signals on confirmed closed bars        |
//+------------------------------------------------------------------+
bool CRepaintPreventer::VerifyBarClose(string symbol, ENUM_TIMEFRAMES timeframe)
{
   // Get closed bar time (bar 1)
   datetime closedBarTime = GetClosedBarTime(symbol, timeframe);
   if(closedBarTime == 0)
      return false;
   
   // Find or create index
   int index = FindIndex(symbol, timeframe);
   if(index < 0)
   {
      int size = ArraySize(m_lastSymbol);
      ArrayResize(m_lastSymbol, size + 1);
      ArrayResize(m_lastTF, size + 1);
      ArrayResize(m_lastBarTime, size + 1);
      
      index = size;
      m_lastSymbol[index] = symbol;
      m_lastTF[index] = timeframe;
      m_lastBarTime[index] = 0;
   }
   
   // Check if this bar was already processed
   if(m_lastBarTime[index] == closedBarTime)
      return false;  // Already processed
   
   // Verify bar is actually closed (not current bar)
   if(!IsBarClosed(symbol, timeframe))
      return false;  // Bar not closed yet
   
   // Mark as processed
   m_lastBarTime[index] = closedBarTime;
   return true;  // Bar is closed and ready to process
}

//+------------------------------------------------------------------+
//| Check if we should process this bar                             |
//| Prevents duplicate processing of the same bar                   |
//+------------------------------------------------------------------+
bool CRepaintPreventer::ShouldProcessBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return VerifyBarClose(symbol, timeframe);
}

//+------------------------------------------------------------------+

