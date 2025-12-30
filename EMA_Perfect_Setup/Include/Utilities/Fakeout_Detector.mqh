//+------------------------------------------------------------------+
//| Fakeout_Detector.mqh                                             |
//| Detects false signals and fakeouts                               |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"

//+------------------------------------------------------------------+
//| Fakeout Detector Class                                          |
//+------------------------------------------------------------------+
class CFakeoutDetector
{
private:
   CEMAManager *m_emaM5;
   int m_confirmationCandles;      // Number of candles to confirm signal
   double m_minMomentumPips;        // Minimum price movement for valid signal
   int m_maxRecentCrossovers;      // Max crossovers in recent bars (choppy market)
   
   bool CheckMultiCandleConfirmation(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckPriceMomentum(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckReversalRisk(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckFalseBreakout(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckChoppyMarket(string symbol);
   
public:
   CFakeoutDetector(CEMAManager *emaM5, int confirmationCandles = 2, 
                    double minMomentumPips = 3.0, int maxRecentCrossovers = 3);
   
   bool IsFakeout(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetFakeoutReason(string symbol, ENUM_SIGNAL_TYPE signalType);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFakeoutDetector::CFakeoutDetector(CEMAManager *emaM5, int confirmationCandles, 
                                    double minMomentumPips, int maxRecentCrossovers)
{
   m_emaM5 = emaM5;
   m_confirmationCandles = confirmationCandles;
   m_minMomentumPips = minMomentumPips;
   m_maxRecentCrossovers = maxRecentCrossovers;
}

//+------------------------------------------------------------------+
//| Check if signal is a fakeout                                    |
//+------------------------------------------------------------------+
bool CFakeoutDetector::IsFakeout(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   // Check multiple fakeout patterns
   if(!CheckMultiCandleConfirmation(symbol, signalType))
      return true;  // False breakout - signal doesn't hold
   
   if(!CheckPriceMomentum(symbol, signalType))
      return true;  // Weak momentum - likely fakeout
   
   if(CheckReversalRisk(symbol, signalType))
      return true;  // High reversal risk - whipsaw pattern
   
   if(CheckFalseBreakout(symbol, signalType))
      return true;  // False breakout detected
   
   if(CheckChoppyMarket(symbol))
      return true;  // Choppy market - too many crossovers
   
   return false;  // Signal appears valid
}

//+------------------------------------------------------------------+
//| Check multi-candle confirmation                                  |
//| Verifies signal holds for multiple candles                       |
//+------------------------------------------------------------------+
bool CFakeoutDetector::CheckMultiCandleConfirmation(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   // ANTI-REPAINT: Check last N closed candles to confirm direction
   // Use closed bars (bar 1 onwards) - emaFast[0] is closed bar, emaFast[1] is previous, etc.
   for(int i = 0; i < m_confirmationCandles && i < 3; i++)
   {
      // Get closed bar price (bar 1+i, but we access as i since GetEMAData starts from bar 1)
      double price = iClose(symbol, PERIOD_M5, 1 + i);  // Bar 1, 2, 3...
      
      if(signalType == SIGNAL_BUY)
      {
         // For BUY: Price should be above EMA9 and EMAs should stay aligned
         if(price <= emaFast[i] || emaFast[i] <= emaMedium[i] || emaMedium[i] <= emaSlow[i])
            return false;  // Signal doesn't hold
      }
      else if(signalType == SIGNAL_SELL)
      {
         // For SELL: Price should be below EMA9 and EMAs should stay aligned
         if(price >= emaFast[i] || emaFast[i] >= emaMedium[i] || emaMedium[i] >= emaSlow[i])
            return false;  // Signal doesn't hold
      }
   }
   
   return true;  // Signal confirmed across multiple candles
}

//+------------------------------------------------------------------+
//| Check price momentum                                             |
//| Verifies price is moving with sufficient momentum                |
//+------------------------------------------------------------------+
bool CFakeoutDetector::CheckPriceMomentum(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   // Get price movement over last few candles
   double price0 = iClose(symbol, PERIOD_M5, 0);
   double price1 = iClose(symbol, PERIOD_M5, 1);
   double price2 = iClose(symbol, PERIOD_M5, 2);
   
   // Get pip value (same for all digit counts in MQL5)
   double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: Price should be moving up
      double momentum0 = (price0 - price1) / pipValue;  // Current candle momentum
      double momentum1 = (price1 - price2) / pipValue;  // Previous candle momentum
      
      // At least one candle should show positive momentum
      if(momentum0 < m_minMomentumPips && momentum1 < m_minMomentumPips)
         return false;  // Weak momentum
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: Price should be moving down
      double momentum0 = (price1 - price0) / pipValue;  // Current candle momentum
      double momentum1 = (price2 - price1) / pipValue;  // Previous candle momentum
      
      // At least one candle should show positive momentum (downward for SELL)
      if(momentum0 < m_minMomentumPips && momentum1 < m_minMomentumPips)
         return false;  // Weak momentum
   }
   
   return true;  // Sufficient momentum
}

//+------------------------------------------------------------------+
//| Check reversal risk                                              |
//| Detects whipsaw patterns and recent reversals                    |
//+------------------------------------------------------------------+
bool CFakeoutDetector::CheckReversalRisk(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return true;  // Assume risk if can't check
   
   // Check if there was a recent opposite signal (whipsaw risk)
   // Look at previous 3-5 candles for opposite crossover
   for(int i = 1; i <= 5 && i < ArraySize(emaFast); i++)
   {
      if(signalType == SIGNAL_BUY)
      {
         // Check for recent SELL signal (EMA9 was below EMA21, now above)
         if(emaFast[i] < emaMedium[i] && emaFast[i-1] >= emaMedium[i-1])
         {
            // Recent SELL crossover detected - high whipsaw risk
            return true;
         }
      }
      else if(signalType == SIGNAL_SELL)
      {
         // Check for recent BUY signal (EMA9 was above EMA21, now below)
         if(emaFast[i] > emaMedium[i] && emaFast[i-1] <= emaMedium[i-1])
         {
            // Recent BUY crossover detected - high whipsaw risk
            return true;
         }
      }
   }
   
   // ANTI-REPAINT: Check if closed bar price is near EMA50 (potential reversal zone)
   double price = iClose(symbol, PERIOD_M5, 1);  // Closed bar price
   // Get pip value (same for all digit counts in MQL5)
   double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   // emaSlow[0] is from closed bar (bar 1) via GetEMAData
   double distanceToEMA50 = MathAbs(price - emaSlow[0]) / pipValue;
   
   // If price is very close to EMA50, higher reversal risk
   if(distanceToEMA50 < 5.0)  // Within 5 pips of EMA50
      return true;  // High reversal risk
   
   return false;  // Low reversal risk
}

//+------------------------------------------------------------------+
//| Check false breakout                                             |
//| Detects when price breaks EMA but immediately reverses           |
//+------------------------------------------------------------------+
bool CFakeoutDetector::CheckFalseBreakout(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return true;  // Assume false if can't check
   
   // ANTI-REPAINT: Get closed bar and previous closed bar data
   // Bar 1 = closed bar, Bar 2 = previous closed bar
   double open1 = iOpen(symbol, PERIOD_M5, 1);   // Closed bar
   double close1 = iClose(symbol, PERIOD_M5, 1); // Closed bar
   double high1 = iHigh(symbol, PERIOD_M5, 1);   // Closed bar
   double low1 = iLow(symbol, PERIOD_M5, 1);     // Closed bar
   
   double open2 = iOpen(symbol, PERIOD_M5, 2);   // Previous closed bar
   double close2 = iClose(symbol, PERIOD_M5, 2); // Previous closed bar
   
   // emaFast[0] = closed bar, emaFast[1] = previous bar (from GetEMAData)
   if(signalType == SIGNAL_BUY)
   {
      // BUY false breakout: Previous closed bar broke above EMA but current closed bar closed below
      if(close2 > emaFast[1] && close1 < emaFast[0])
         return true;  // False breakout - price broke but reversed
      
      // Check for rejection wick (long upper wick suggests rejection)
      double upperWick = high1 - MathMax(open1, close1);
      double bodySize = MathAbs(close1 - open1);
      if(bodySize > 0 && upperWick > bodySize * 2.0 && close1 < emaFast[0])
         return true;  // Strong rejection wick
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL false breakout: Previous closed bar broke below EMA but current closed bar closed above
      if(close2 < emaFast[1] && close1 > emaFast[0])
         return true;  // False breakout - price broke but reversed
      
      // Check for rejection wick (long lower wick suggests rejection)
      double lowerWick = MathMin(open1, close1) - low1;
      double bodySize = MathAbs(close1 - open1);
      if(bodySize > 0 && lowerWick > bodySize * 2.0 && close1 > emaFast[0])
         return true;  // Strong rejection wick
   }
   
   return false;  // No false breakout detected
}

//+------------------------------------------------------------------+
//| Check choppy market                                              |
//| Detects too many crossovers in short time (choppy/range-bound)   |
//+------------------------------------------------------------------+
bool CFakeoutDetector::CheckChoppyMarket(string symbol)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return true;  // Assume choppy if can't check
   
   // Count crossovers in last 10 candles
   int crossoverCount = 0;
   int barsToCheck = MathMin(10, ArraySize(emaFast) - 1);
   
   for(int i = 1; i <= barsToCheck; i++)
   {
      // Check for crossover (EMA9 crosses EMA21)
      bool currentAbove = emaFast[i] > emaMedium[i];
      bool previousAbove = emaFast[i-1] > emaMedium[i-1];
      
      if(currentAbove != previousAbove)
         crossoverCount++;  // Crossover detected
   }
   
   // Too many crossovers = choppy market
   if(crossoverCount > m_maxRecentCrossovers)
      return true;  // Choppy market detected
   
   return false;  // Market is trending, not choppy
}

//+------------------------------------------------------------------+
//| Get fakeout reason                                               |
//+------------------------------------------------------------------+
string CFakeoutDetector::GetFakeoutReason(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(!CheckMultiCandleConfirmation(symbol, signalType))
      return "False breakout: Signal doesn't hold across multiple candles";
   
   if(!CheckPriceMomentum(symbol, signalType))
      return "Weak momentum: Insufficient price movement";
   
   if(CheckReversalRisk(symbol, signalType))
      return "High reversal risk: Recent opposite signal or price near EMA50";
   
   if(CheckFalseBreakout(symbol, signalType))
      return "False breakout: Price broke but immediately reversed";
   
   if(CheckChoppyMarket(symbol))
      return "Choppy market: Too many recent crossovers";
   
   return "Unknown fakeout pattern";
}

//+------------------------------------------------------------------+

