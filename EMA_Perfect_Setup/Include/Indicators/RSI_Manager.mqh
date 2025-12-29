//+------------------------------------------------------------------+
//| RSI_Manager.mqh                                                  |
//| RSI indicator management                                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| RSI Manager Class                                                |
//+------------------------------------------------------------------+
class CRSIManager
{
private:
   int m_rsiHandle[];
   string m_symbols[];
   ENUM_TIMEFRAMES m_timeframe;
   int m_period;
   
   int FindSymbolIndex(string symbol);
   bool InitializeIndicator(string symbol, int index);
   
public:
   CRSIManager();
   ~CRSIManager();
   
   bool Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int period);
   void Deinitialize();
   
   bool GetRSIValue(string symbol, double &rsi);
   bool IsRSIBullish(string symbol, int threshold = 50);
   bool IsRSIBearish(string symbol, int threshold = 50);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRSIManager::CRSIManager()
{
   ArrayResize(m_rsiHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRSIManager::~CRSIManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize RSI indicators for all symbols                        |
//+------------------------------------------------------------------+
bool CRSIManager::Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int period)
{
   m_timeframe = timeframe;
   m_period = period;
   
   int count = ArraySize(symbols);
   ArrayResize(m_symbols, count);
   ArrayResize(m_rsiHandle, count);
   
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
int CRSIManager::FindSymbolIndex(string symbol)
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
bool CRSIManager::InitializeIndicator(string symbol, int index)
{
   m_rsiHandle[index] = iRSI(symbol, m_timeframe, m_period, PRICE_CLOSE);
   
   if(m_rsiHandle[index] == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create RSI indicator for ", symbol);
      return false;
   }
   
   // Wait for indicator to calculate (with timeout)
   int maxWait = 10; // Maximum wait iterations
   int waitCount = 0;
   while(BarsCalculated(m_rsiHandle[index]) < m_period + 10 && waitCount < maxWait)
   {
      Sleep(100);
      waitCount++;
   }
   
   // Final check
   if(BarsCalculated(m_rsiHandle[index]) < m_period + 10)
   {
      Print("WARNING: RSI indicator for ", symbol, " may not have enough data. Bars calculated: ", 
            BarsCalculated(m_rsiHandle[index]), " (need: ", m_period + 10, ")");
      // Don't fail - indicator may still work with less data
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize all indicators                                      |
//+------------------------------------------------------------------+
void CRSIManager::Deinitialize()
{
   for(int i = 0; i < ArraySize(m_rsiHandle); i++)
   {
      if(m_rsiHandle[i] != INVALID_HANDLE)
         IndicatorRelease(m_rsiHandle[i]);
   }
   
   ArrayResize(m_rsiHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Get RSI value for symbol                                         |
//+------------------------------------------------------------------+
bool CRSIManager::GetRSIValue(string symbol, double &rsi)
{
   int index = FindSymbolIndex(symbol);
   if(index < 0) return false;
   
   double buffer[];
   if(CopyBuffer(m_rsiHandle[index], 0, 0, 1, buffer) <= 0)
      return false;
   
   rsi = buffer[0];
   return true;
}

//+------------------------------------------------------------------+
//| Check if RSI is bullish                                         |
//+------------------------------------------------------------------+
bool CRSIManager::IsRSIBullish(string symbol, int threshold = 50)
{
   double rsi;
   if(!GetRSIValue(symbol, rsi))
      return false;
   
   return rsi > threshold;
}

//+------------------------------------------------------------------+
//| Check if RSI is bearish                                          |
//+------------------------------------------------------------------+
bool CRSIManager::IsRSIBearish(string symbol, int threshold = 50)
{
   double rsi;
   if(!GetRSIValue(symbol, rsi))
      return false;
   
   return rsi < threshold;
}

//+------------------------------------------------------------------+

