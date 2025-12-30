//+------------------------------------------------------------------+
//| Signal_Accuracy_Validator.mqh                                    |
//| Validates signal accuracy by tracking price movement            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| Signal Validation Result                                         |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_ACCURACY
{
   ACCURACY_PENDING,      // Still validating (not enough candles yet)
   ACCURACY_VALID,        // Price moved X pips in predicted direction
   ACCURACY_FALSE,        // False signal - immediate reversal
   ACCURACY_LAGGING,      // Lagging signal - signal appeared too late
   ACCURACY_INVALID       // Price didn't move enough in either direction
};

//+------------------------------------------------------------------+
//| Signal Tracking Structure                                        |
//+------------------------------------------------------------------+
struct SignalTrack
{
   datetime signalTime;
   string symbol;
   ENUM_SIGNAL_TYPE signalType;
   double entryPrice;
   double stopLoss;
   double takeProfit1;
   ENUM_TIMEFRAMES timeframe;
   int validationCandles;      // Number of candles to validate
   double minPipsRequired;      // Minimum pips required for valid signal
   ENUM_SIGNAL_ACCURACY accuracy;
   bool isChecked;
   double maxPriceReached;      // Maximum price reached (for BUY)
   double minPriceReached;      // Minimum price reached (for SELL)
   int candlesElapsed;
};

//+------------------------------------------------------------------+
//| Signal Accuracy Validator Class                                  |
//+------------------------------------------------------------------+
class CSignalAccuracyValidator
{
private:
   SignalTrack m_signals[];     // Tracked signals
   int m_signalCount;
   
   double GetPipValue(string symbol);
   double CalculatePriceMovement(string symbol, double entryPrice, double currentPrice, ENUM_SIGNAL_TYPE signalType);
   bool CheckSignalAccuracy(SignalTrack &signal);
   int FindSignalIndex(string symbol, datetime signalTime);
   
public:
   CSignalAccuracyValidator();
   ~CSignalAccuracyValidator();
   
   // Register signal for validation
   void RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                      double entryPrice, double stopLoss, double takeProfit1,
                      ENUM_TIMEFRAMES timeframe, int validationCandles, double minPipsRequired);
   
   // Check all pending signals
   void CheckPendingSignals();
   
   // Get accuracy for a specific signal
   ENUM_SIGNAL_ACCURACY GetSignalAccuracy(string symbol, datetime signalTime);
   
   // Get statistics
   int GetTotalSignals();
   int GetValidSignals();
   int GetFalseSignals();
   int GetLaggingSignals();
   int GetInvalidSignals();
   double GetAccuracyRate();
   
   // Print accuracy report
   void PrintAccuracyReport();
   string GetAccuracyReportString();
   
   // Cleanup old signals
   void CleanupOldSignals(int maxAgeHours = 24);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalAccuracyValidator::CSignalAccuracyValidator()
{
   ArrayResize(m_signals, 0);
   m_signalCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalAccuracyValidator::~CSignalAccuracyValidator()
{
   ArrayResize(m_signals, 0);
}

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double CSignalAccuracyValidator::GetPipValue(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point;
}

//+------------------------------------------------------------------+
//| Calculate price movement in pips                                 |
//+------------------------------------------------------------------+
double CSignalAccuracyValidator::CalculatePriceMovement(string symbol, double entryPrice, double currentPrice, ENUM_SIGNAL_TYPE signalType)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return (currentPrice - entryPrice) / pipValue;
   else // SIGNAL_SELL
      return (entryPrice - currentPrice) / pipValue;
}

//+------------------------------------------------------------------+
//| Find signal index by symbol and time                             |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::FindSignalIndex(string symbol, datetime signalTime)
{
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].symbol == symbol && m_signals[i].signalTime == signalTime)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Register signal for validation                                   |
//+------------------------------------------------------------------+
void CSignalAccuracyValidator::RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                                             double entryPrice, double stopLoss, double takeProfit1,
                                             ENUM_TIMEFRAMES timeframe, int validationCandles, double minPipsRequired)
{
   int index = m_signalCount;
   ArrayResize(m_signals, m_signalCount + 1);
   
   m_signals[index].signalTime = signalTime;
   m_signals[index].symbol = symbol;
   m_signals[index].signalType = signalType;
   m_signals[index].entryPrice = entryPrice;
   m_signals[index].stopLoss = stopLoss;
   m_signals[index].takeProfit1 = takeProfit1;
   m_signals[index].timeframe = timeframe;
   m_signals[index].validationCandles = validationCandles;
   m_signals[index].minPipsRequired = minPipsRequired;
   m_signals[index].accuracy = ACCURACY_PENDING;
   m_signals[index].isChecked = false;
   m_signals[index].candlesElapsed = 0;
   
   // Initialize max/min prices
   if(signalType == SIGNAL_BUY)
   {
      m_signals[index].maxPriceReached = entryPrice;
      m_signals[index].minPriceReached = entryPrice;
   }
   else // SIGNAL_SELL
   {
      m_signals[index].maxPriceReached = entryPrice;
      m_signals[index].minPriceReached = entryPrice;
   }
   
   m_signalCount++;
}

//+------------------------------------------------------------------+
//| Check signal accuracy                                            |
//+------------------------------------------------------------------+
bool CSignalAccuracyValidator::CheckSignalAccuracy(SignalTrack &signal)
{
   // Get current bar index (bar 0 = current forming, bar 1 = last closed)
   // We need to check from bar 1 (signal bar) to bar 1+validationCandles
   
   // Calculate how many candles have passed since signal
   datetime currentBarTime = iTime(signal.symbol, signal.timeframe, 1); // Last closed bar
   int barsSinceSignal = 0;
   
   // Count bars from signal time to current
   for(int i = 1; i <= signal.validationCandles + 5; i++) // Check a bit more to be safe
   {
      datetime barTime = iTime(signal.symbol, signal.timeframe, i);
      if(barTime <= signal.signalTime)
      {
         barsSinceSignal = i - 1; // Bars that have closed since signal
         break;
      }
   }
   
   signal.candlesElapsed = barsSinceSignal;
   
   // Not enough candles yet
   if(barsSinceSignal < 1)
   {
      signal.accuracy = ACCURACY_PENDING;
      return false;
   }
   
   // Get prices from signal bar to current
   double prices[];
   int copied = CopyClose(signal.symbol, signal.timeframe, 1, barsSinceSignal + 1, prices);
   if(copied < barsSinceSignal + 1)
   {
      signal.accuracy = ACCURACY_PENDING;
      return false;
   }
   
   // Reverse array so prices[0] = signal bar, prices[N] = most recent
   // MQL5 doesn't have ArrayReverse, so we manually reverse
   int size = ArraySize(prices);
   for(int i = 0; i < size / 2; i++)
   {
      double temp = prices[i];
      prices[i] = prices[size - 1 - i];
      prices[size - 1 - i] = temp;
   }
   
   // Track max/min price movement
   double maxMovement = 0;
   double minMovement = 0;
   bool hitSL = false;
   bool hitTP = false;
   
   for(int i = 0; i <= barsSinceSignal && i < ArraySize(prices); i++)
   {
      double currentPrice = prices[i];
      double movement = CalculatePriceMovement(signal.symbol, signal.entryPrice, currentPrice, signal.signalType);
      
      if(signal.signalType == SIGNAL_BUY)
      {
         if(currentPrice > signal.maxPriceReached)
            signal.maxPriceReached = currentPrice;
         if(currentPrice < signal.minPriceReached)
            signal.minPriceReached = currentPrice;
         
         // Check if hit SL (price went below stop loss)
         if(currentPrice <= signal.stopLoss)
            hitSL = true;
         
         // Check if hit TP1
         if(currentPrice >= signal.takeProfit1)
            hitTP = true;
      }
      else // SIGNAL_SELL
      {
         if(currentPrice > signal.maxPriceReached)
            signal.maxPriceReached = currentPrice;
         if(currentPrice < signal.minPriceReached)
            signal.minPriceReached = currentPrice;
         
         // Check if hit SL (price went above stop loss)
         if(currentPrice >= signal.stopLoss)
            hitSL = true;
         
         // Check if hit TP1
         if(currentPrice <= signal.takeProfit1)
            hitTP = true;
      }
      
      if(movement > maxMovement)
         maxMovement = movement;
      if(movement < minMovement)
         minMovement = movement;
   }
   
   // Get current price (last closed bar)
   double currentPrice = prices[ArraySize(prices) - 1];
   double currentMovement = CalculatePriceMovement(signal.symbol, signal.entryPrice, currentPrice, signal.signalType);
   
   // Check accuracy based on validation rules
   
   // 1. FALSE SIGNAL: Immediate reversal (price reversed within first 2 candles)
   if(barsSinceSignal >= 2)
   {
      double firstCandleMovement = CalculatePriceMovement(signal.symbol, signal.entryPrice, prices[1], signal.signalType);
      double secondCandleMovement = CalculatePriceMovement(signal.symbol, signal.entryPrice, prices[2], signal.signalType);
      
      // If first candle moved in wrong direction or second candle reversed
      if((firstCandleMovement < 0 && MathAbs(firstCandleMovement) > signal.minPipsRequired * 0.5) ||
         (firstCandleMovement > 0 && secondCandleMovement < firstCandleMovement * 0.5 && secondCandleMovement < 0))
      {
         signal.accuracy = ACCURACY_FALSE;
         signal.isChecked = true;
         return true;
      }
   }
   
   // 2. LAGGING SIGNAL: Signal appeared too late (price already moved significantly before signal)
   // Check if price was already moving in signal direction before signal bar
   if(barsSinceSignal >= 1)
   {
      // Get price 2 bars before signal (if available)
      double preSignalPrices[];
      if(CopyClose(signal.symbol, signal.timeframe, barsSinceSignal + 2, 3, preSignalPrices) >= 2)
      {
         double preMovement = CalculatePriceMovement(signal.symbol, preSignalPrices[0], signal.entryPrice, signal.signalType);
         if(preMovement > signal.minPipsRequired * 0.7) // Already moved 70% of required pips
         {
            signal.accuracy = ACCURACY_LAGGING;
            signal.isChecked = true;
            return true;
         }
      }
   }
   
   // 3. VALID SIGNAL: Price moved X pips in predicted direction within validation period
   if(barsSinceSignal >= signal.validationCandles)
   {
      // Check if price moved required pips in predicted direction
      if(currentMovement >= signal.minPipsRequired)
      {
         signal.accuracy = ACCURACY_VALID;
         signal.isChecked = true;
         return true;
      }
      
      // Check if hit TP1 (definitely valid)
      if(hitTP)
      {
         signal.accuracy = ACCURACY_VALID;
         signal.isChecked = true;
         return true;
      }
      
      // If we've passed validation period and didn't reach target, it's invalid
      if(barsSinceSignal >= signal.validationCandles)
      {
         if(hitSL)
         {
            signal.accuracy = ACCURACY_FALSE; // Hit SL = false signal
         }
         else if(currentMovement < signal.minPipsRequired * 0.5)
         {
            signal.accuracy = ACCURACY_INVALID; // Didn't move enough
         }
         else
         {
            signal.accuracy = ACCURACY_LAGGING; // Moved some but not enough = lagging
         }
         signal.isChecked = true;
         return true;
      }
   }
   
   // Still pending
   signal.accuracy = ACCURACY_PENDING;
   return false;
}

//+------------------------------------------------------------------+
//| Check all pending signals                                        |
//+------------------------------------------------------------------+
void CSignalAccuracyValidator::CheckPendingSignals()
{
   for(int i = 0; i < m_signalCount; i++)
   {
      if(!m_signals[i].isChecked)
      {
         CheckSignalAccuracy(m_signals[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Get accuracy for specific signal                                 |
//+------------------------------------------------------------------+
ENUM_SIGNAL_ACCURACY CSignalAccuracyValidator::GetSignalAccuracy(string symbol, datetime signalTime)
{
   int index = FindSignalIndex(symbol, signalTime);
   if(index >= 0)
      return m_signals[index].accuracy;
   return ACCURACY_PENDING;
}

//+------------------------------------------------------------------+
//| Get total signals                                                |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::GetTotalSignals()
{
   int total = 0;
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].isChecked)
         total++;
   }
   return total;
}

//+------------------------------------------------------------------+
//| Get valid signals count                                          |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::GetValidSignals()
{
   int count = 0;
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].accuracy == ACCURACY_VALID)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get false signals count                                          |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::GetFalseSignals()
{
   int count = 0;
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].accuracy == ACCURACY_FALSE)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get lagging signals count                                        |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::GetLaggingSignals()
{
   int count = 0;
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].accuracy == ACCURACY_LAGGING)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get invalid signals count                                         |
//+------------------------------------------------------------------+
int CSignalAccuracyValidator::GetInvalidSignals()
{
   int count = 0;
   for(int i = 0; i < m_signalCount; i++)
   {
      if(m_signals[i].accuracy == ACCURACY_INVALID)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get accuracy rate                                                |
//+------------------------------------------------------------------+
double CSignalAccuracyValidator::GetAccuracyRate()
{
   int total = GetTotalSignals();
   if(total == 0)
      return 0.0;
   
   int valid = GetValidSignals();
   return (double)valid / total * 100.0;
}

//+------------------------------------------------------------------+
//| Get accuracy report string                                       |
//+------------------------------------------------------------------+
string CSignalAccuracyValidator::GetAccuracyReportString()
{
   int total = GetTotalSignals();
   int valid = GetValidSignals();
   int falseSignals = GetFalseSignals();
   int lagging = GetLaggingSignals();
   int invalid = GetInvalidSignals();
   double accuracyRate = GetAccuracyRate();
   
   string report = "";
   report += "╔═══════════════════════════════════════════════════════════════╗\n";
   report += "║              SIGNAL ACCURACY REPORT                           ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Total Signals Validated: %d                                      ║\n", total);
   report += StringFormat("║ Valid Signals: %d (%.2f%%)                                    ║\n", valid, accuracyRate);
   report += StringFormat("║ False Signals: %d (%.2f%%)                                   ║\n", falseSignals, 
                         total > 0 ? (double)falseSignals / total * 100.0 : 0.0);
   report += StringFormat("║ Lagging Signals: %d (%.2f%%)                                 ║\n", lagging,
                         total > 0 ? (double)lagging / total * 100.0 : 0.0);
   report += StringFormat("║ Invalid Signals: %d (%.2f%%)                                  ║\n", invalid,
                         total > 0 ? (double)invalid / total * 100.0 : 0.0);
   report += "╚═══════════════════════════════════════════════════════════════╝\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Print accuracy report                                            |
//+------------------------------------------------------------------+
void CSignalAccuracyValidator::PrintAccuracyReport()
{
   string report = GetAccuracyReportString();
   Print(report);
}

//+------------------------------------------------------------------+
//| Cleanup old signals                                               |
//+------------------------------------------------------------------+
void CSignalAccuracyValidator::CleanupOldSignals(int maxAgeHours = 24)
{
   datetime cutoffTime = TimeCurrent() - maxAgeHours * 3600;
   
   for(int i = m_signalCount - 1; i >= 0; i--)
   {
      if(m_signals[i].signalTime < cutoffTime && m_signals[i].isChecked)
      {
         // Remove this signal
         for(int j = i; j < m_signalCount - 1; j++)
         {
            m_signals[j] = m_signals[j + 1];
         }
         m_signalCount--;
      }
   }
   
   ArrayResize(m_signals, m_signalCount);
}

//+------------------------------------------------------------------+

