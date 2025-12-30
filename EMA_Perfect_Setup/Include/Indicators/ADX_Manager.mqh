//+------------------------------------------------------------------+
//| ADX_Manager.mqh                                                   |
//| ADX indicator management                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ADX Manager Class                                                |
//+------------------------------------------------------------------+
class CADXManager
{
private:
   int m_adxHandle[];
   string m_symbols[];
   ENUM_TIMEFRAMES m_timeframe;
   int m_period;
   
   int FindSymbolIndex(string symbol);
   bool InitializeIndicator(string symbol, int index);
   
public:
   CADXManager();
   ~CADXManager();
   
   bool Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int period);
   void Deinitialize();
   
   bool GetADXValue(string symbol, double &adx);
   bool GetDIValues(string symbol, double &diPlus, double &diMinus);
   bool IsTrending(string symbol, double minADX = 20.0);
   bool IsBullishTrend(string symbol, double minADX = 20.0);
   bool IsBearishTrend(string symbol, double minADX = 20.0);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CADXManager::CADXManager()
{
   ArrayResize(m_adxHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CADXManager::~CADXManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize ADX indicators for all symbols                        |
//+------------------------------------------------------------------+
bool CADXManager::Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int period)
{
   m_timeframe = timeframe;
   m_period = period;
   
   int count = ArraySize(symbols);
   ArrayResize(m_symbols, count);
   ArrayResize(m_adxHandle, count);
   
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
int CADXManager::FindSymbolIndex(string symbol)
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
bool CADXManager::InitializeIndicator(string symbol, int index)
{
   m_adxHandle[index] = iADX(symbol, m_timeframe, m_period);
   
   if(m_adxHandle[index] == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ADX indicator for ", symbol);
      return false;
   }
   
   // Wait for indicator to calculate (with timeout)
   int maxWait = 10; // Maximum wait iterations
   int waitCount = 0;
   while(BarsCalculated(m_adxHandle[index]) < m_period + 10 && waitCount < maxWait)
   {
      Sleep(100);
      waitCount++;
   }
   
   // Final check
   if(BarsCalculated(m_adxHandle[index]) < m_period + 10)
   {
      Print("WARNING: ADX indicator for ", symbol, " may not have enough data. Bars calculated: ", 
            BarsCalculated(m_adxHandle[index]), " (need: ", m_period + 10, ")");
      // Don't fail - indicator may still work with less data
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize all indicators                                      |
//+------------------------------------------------------------------+
void CADXManager::Deinitialize()
{
   for(int i = 0; i < ArraySize(m_adxHandle); i++)
   {
      if(m_adxHandle[i] != INVALID_HANDLE)
         IndicatorRelease(m_adxHandle[i]);
   }
   
   ArrayResize(m_adxHandle, 0);
   ArrayResize(m_symbols, 0);
}

//+------------------------------------------------------------------+
//| Get ADX value for symbol (from closed bar)                      |
//+------------------------------------------------------------------+
bool CADXManager::GetADXValue(string symbol, double &adx)
{
   int index = FindSymbolIndex(symbol);
   if(index < 0) return false;
   
   // ANTI-REPAINT: Get ADX from closed bar (bar 1)
   double buffer[];
   if(CopyBuffer(m_adxHandle[index], 0, 1, 1, buffer) <= 0)  // ADX line (index 0)
      return false;
   
   adx = buffer[0];
   return true;
}

//+------------------------------------------------------------------+
//| Get DI+ and DI- values for symbol (from closed bar)            |
//+------------------------------------------------------------------+
bool CADXManager::GetDIValues(string symbol, double &diPlus, double &diMinus)
{
   int index = FindSymbolIndex(symbol);
   if(index < 0) return false;
   
   // ANTI-REPAINT: Get DI values from closed bar (bar 1)
   double diPlusBuffer[];
   double diMinusBuffer[];
   
   if(CopyBuffer(m_adxHandle[index], 1, 1, 1, diPlusBuffer) <= 0)   // DI+ line (index 1)
      return false;
   if(CopyBuffer(m_adxHandle[index], 2, 1, 1, diMinusBuffer) <= 0) // DI- line (index 2)
      return false;
   
   diPlus = diPlusBuffer[0];
   diMinus = diMinusBuffer[0];
   return true;
}

//+------------------------------------------------------------------+
//| Check if market is trending (ADX above threshold)               |
//+------------------------------------------------------------------+
bool CADXManager::IsTrending(string symbol, double minADX = 20.0)
{
   double adx;
   if(!GetADXValue(symbol, adx))
      return false;
   
   return adx >= minADX;
}

//+------------------------------------------------------------------+
//| Check if bullish trend (DI+ > DI- and ADX above threshold)     |
//+------------------------------------------------------------------+
bool CADXManager::IsBullishTrend(string symbol, double minADX = 20.0)
{
   double adx, diPlus, diMinus;
   if(!GetADXValue(symbol, adx))
      return false;
   if(!GetDIValues(symbol, diPlus, diMinus))
      return false;
   
   return (adx >= minADX && diPlus > diMinus);
}

//+------------------------------------------------------------------+
//| Check if bearish trend (DI- > DI+ and ADX above threshold)      |
//+------------------------------------------------------------------+
bool CADXManager::IsBearishTrend(string symbol, double minADX = 20.0)
{
   double adx, diPlus, diMinus;
   if(!GetADXValue(symbol, adx))
      return false;
   if(!GetDIValues(symbol, diPlus, diMinus))
      return false;
   
   return (adx >= minADX && diMinus > diPlus);
}

//+------------------------------------------------------------------+

