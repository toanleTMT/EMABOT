//+------------------------------------------------------------------+
//| Debug_Helper.mqh                                                 |
//| Debug and logging utilities                                       |
//+------------------------------------------------------------------+

#include "../Config.mqh"

//+------------------------------------------------------------------+
//| Debug Helper Class                                               |
//+------------------------------------------------------------------+
class CDebugHelper
{
private:
   bool m_enableDebug;
   string m_logPrefix;
   
public:
   CDebugHelper(bool enableDebug = false, string logPrefix = "[DEBUG]");
   
   void Log(string message);
   void LogError(string context, int errorCode);
   void LogSignal(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
   void LogScoreBreakdown(string symbol, int score, int categoryScores[]);
   void LogIndicatorData(string symbol, double emaFast[], double emaMedium[], double emaSlow[], double rsi);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDebugHelper::CDebugHelper(bool enableDebug = false, string logPrefix = "[DEBUG]")
{
   m_enableDebug = enableDebug;
   m_logPrefix = logPrefix;
}

//+------------------------------------------------------------------+
//| Log debug message                                                |
//+------------------------------------------------------------------+
void CDebugHelper::Log(string message)
{
   if(m_enableDebug)
      Print(m_logPrefix, " ", message);
}

//+------------------------------------------------------------------+
//| Log error                                                        |
//+------------------------------------------------------------------+
void CDebugHelper::LogError(string context, int errorCode)
{
   Print(m_logPrefix, " ERROR [", context, "]: Code ", errorCode);
}

//+------------------------------------------------------------------+
//| Log signal information                                           |
//+------------------------------------------------------------------+
void CDebugHelper::LogSignal(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   if(!m_enableDebug) return;
   
   string typeStr = (signalType == SIGNAL_BUY) ? "BUY" : "SELL";
   Print(m_logPrefix, " Signal detected: ", symbol, " | Type: ", typeStr, " | Score: ", score);
}

//+------------------------------------------------------------------+
//| Log score breakdown                                              |
//+------------------------------------------------------------------+
void CDebugHelper::LogScoreBreakdown(string symbol, int score, int categoryScores[])
{
   if(!m_enableDebug) return;
   
   Print(m_logPrefix, " Score breakdown for ", symbol, ":");
   Print("  Total: ", score, "/100");
   Print("  Trend: ", categoryScores[CATEGORY_TREND], "/25");
   Print("  EMA Quality: ", categoryScores[CATEGORY_EMA_QUALITY], "/20");
   Print("  Signal Strength: ", categoryScores[CATEGORY_SIGNAL_STRENGTH], "/20");
   Print("  Confirmation: ", categoryScores[CATEGORY_CONFIRMATION], "/15");
   Print("  Market: ", categoryScores[CATEGORY_MARKET], "/10");
   Print("  Context: ", categoryScores[CATEGORY_CONTEXT], "/10");
}

//+------------------------------------------------------------------+
//| Log indicator data                                               |
//+------------------------------------------------------------------+
void CDebugHelper::LogIndicatorData(string symbol, double emaFast[], double emaMedium[], double emaSlow[], double rsi)
{
   if(!m_enableDebug) return;
   
   Print(m_logPrefix, " Indicator data for ", symbol, ":");
   if(ArraySize(emaFast) >= 3)
   {
      Print("  EMA Fast: ", DoubleToString(emaFast[0], 5), " | ", DoubleToString(emaFast[1], 5), " | ", DoubleToString(emaFast[2], 5));
   }
   if(ArraySize(emaMedium) >= 3)
   {
      Print("  EMA Medium: ", DoubleToString(emaMedium[0], 5), " | ", DoubleToString(emaMedium[1], 5), " | ", DoubleToString(emaMedium[2], 5));
   }
   if(ArraySize(emaSlow) >= 3)
   {
      Print("  EMA Slow: ", DoubleToString(emaSlow[0], 5), " | ", DoubleToString(emaSlow[1], 5), " | ", DoubleToString(emaSlow[2], 5));
   }
   Print("  RSI: ", DoubleToString(rsi, 2));
}

//+------------------------------------------------------------------+

