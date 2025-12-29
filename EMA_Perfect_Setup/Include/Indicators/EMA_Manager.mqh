//+------------------------------------------------------------------+
//| EMA_Manager.mqh                                                  |
//| EMA indicator management                                         |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| EMA Manager Class                                                |
//+------------------------------------------------------------------+
class CEMAManager
{
private:
   int m_emaFastHandle[];
   int m_emaMediumHandle[];
   int m_emaSlowHandle[];
   string m_symbols[];
   ENUM_TIMEFRAMES m_timeframe;
   int m_fastPeriod;
   int m_mediumPeriod;
   int m_slowPeriod;
   ENUM_MA_METHOD m_method;
   ENUM_APPLIED_PRICE m_appliedPrice;
   
   int FindSymbolIndex(string symbol);
   bool InitializeIndicator(string symbol, int index);
   
public:
   CEMAManager();
   ~CEMAManager();
   
   bool Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, 
                   int fastPeriod, int mediumPeriod, int slowPeriod,
                   ENUM_MA_METHOD method, ENUM_APPLIED_PRICE appliedPrice);
   void Deinitialize();
   
   bool GetEMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[]);
   bool IsEMAsAligned(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf);
   double GetEMASeparation(string symbol, ENUM_TIMEFRAMES tf);
   bool IsEMACrossed(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEMAManager::CEMAManager()
{
   ArrayResize(m_emaFastHandle, 0);
   ArrayResize(m_emaMediumHandle, 0);
   ArrayResize(m_emaSlowHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEMAManager::~CEMAManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize EMA indicators for all symbols                        |
//+------------------------------------------------------------------+
bool CEMAManager::Initialize(string symbols[], ENUM_TIMEFRAMES timeframe,
                            int fastPeriod, int mediumPeriod, int slowPeriod,
                            ENUM_MA_METHOD method, ENUM_APPLIED_PRICE appliedPrice)
{
   m_timeframe = timeframe;
   m_fastPeriod = fastPeriod;
   m_mediumPeriod = mediumPeriod;
   m_slowPeriod = slowPeriod;
   m_method = method;
   m_appliedPrice = appliedPrice;
   
   int count = ArraySize(symbols);
   ArrayResize(m_symbols, count);
   ArrayResize(m_emaFastHandle, count);
   ArrayResize(m_emaMediumHandle, count);
   ArrayResize(m_emaSlowHandle, count);
   
   for(int i = 0; i < count; i++)
   {
      m_symbols[i] = symbols[i];
      if(!InitializeIndicator(symbols[i], i))
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Find symbol index in array                                       |
//+------------------------------------------------------------------+
int CEMAManager::FindSymbolIndex(string symbol)
{
   for(int i = 0; i < ArraySize(m_symbols); i++)
   {
      if(m_symbols[i] == symbol)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Initialize indicator for specific symbol                         |
//+------------------------------------------------------------------+
bool CEMAManager::InitializeIndicator(string symbol, int index)
{
   // Create EMA handles
   m_emaFastHandle[index] = iMA(symbol, m_timeframe, m_fastPeriod, 0, m_method, m_appliedPrice);
   m_emaMediumHandle[index] = iMA(symbol, m_timeframe, m_mediumPeriod, 0, m_method, m_appliedPrice);
   m_emaSlowHandle[index] = iMA(symbol, m_timeframe, m_slowPeriod, 0, m_method, m_appliedPrice);
   
   if(m_emaFastHandle[index] == INVALID_HANDLE ||
      m_emaMediumHandle[index] == INVALID_HANDLE ||
      m_emaSlowHandle[index] == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create EMA indicators for ", symbol);
      return false;
   }
   
   // Wait for indicator to calculate (with timeout)
   int maxWait = 10; // Maximum wait iterations
   int waitCount = 0;
   while(BarsCalculated(m_emaFastHandle[index]) < m_slowPeriod + 10 && waitCount < maxWait)
   {
      Sleep(100);
      waitCount++;
   }
   
   // Final check
   if(BarsCalculated(m_emaFastHandle[index]) < m_slowPeriod + 10)
   {
      Print("WARNING: EMA indicator for ", symbol, " may not have enough data. Bars calculated: ", 
            BarsCalculated(m_emaFastHandle[index]), " (need: ", m_slowPeriod + 10, ")");
      // Don't fail - indicator may still work with less data
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize all indicators                                      |
//+------------------------------------------------------------------+
void CEMAManager::Deinitialize()
{
   for(int i = 0; i < ArraySize(m_emaFastHandle); i++)
   {
      if(m_emaFastHandle[i] != INVALID_HANDLE)
         IndicatorRelease(m_emaFastHandle[i]);
      if(m_emaMediumHandle[i] != INVALID_HANDLE)
         IndicatorRelease(m_emaMediumHandle[i]);
      if(m_emaSlowHandle[i] != INVALID_HANDLE)
         IndicatorRelease(m_emaSlowHandle[i]);
   }
   
   ArrayResize(m_emaFastHandle, 0);
   ArrayResize(m_emaMediumHandle, 0);
   ArrayResize(m_emaSlowHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Get EMA data for symbol                                          |
//+------------------------------------------------------------------+
bool CEMAManager::GetEMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[])
{
   int index = FindSymbolIndex(symbol);
   if(index < 0) return false;
   
   ArrayResize(emaFast, 3);
   ArrayResize(emaMedium, 3);
   ArrayResize(emaSlow, 3);
   
   // Copy current, previous, and before previous values
   if(CopyBuffer(m_emaFastHandle[index], 0, 0, 3, emaFast) <= 0) return false;
   if(CopyBuffer(m_emaMediumHandle[index], 0, 0, 3, emaMedium) <= 0) return false;
   if(CopyBuffer(m_emaSlowHandle[index], 0, 0, 3, emaSlow) <= 0) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if EMAs are aligned for signal type                        |
//+------------------------------------------------------------------+
bool CEMAManager::IsEMAsAligned(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf)
{
   // Need to get data from correct timeframe
   // For now, use current timeframe - caller should use correct manager instance
   double emaFast[], emaMedium[], emaSlow[];
   if(!GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: EMA 9 > EMA 21 > EMA 50
      return (emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]);
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: EMA 9 < EMA 21 < EMA 50
      return (emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get average EMA separation in pips                               |
//+------------------------------------------------------------------+
double CEMAManager::GetEMASeparation(string symbol, ENUM_TIMEFRAMES tf)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   // OPTIMIZATION: Cache pip value calculation (same for all cases)
   double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   // Note: For 3/5 digit brokers, pipValue is still point * 10 (no change needed)
   
   double sep1 = MathAbs(emaFast[0] - emaMedium[0]) / pipValue;
   double sep2 = MathAbs(emaMedium[0] - emaSlow[0]) / pipValue;
   
   return (sep1 + sep2) / 2.0;
}

//+------------------------------------------------------------------+
//| Check if EMA crossover occurred                                  |
//+------------------------------------------------------------------+
bool CEMAManager::IsEMACrossed(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: EMA 9 crosses above EMA 21
      return (emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1]);
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: EMA 9 crosses below EMA 21
      return (emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1]);
   }
   
   return false;
}

//+------------------------------------------------------------------+

