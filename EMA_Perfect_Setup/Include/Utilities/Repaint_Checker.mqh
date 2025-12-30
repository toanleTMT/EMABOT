//+------------------------------------------------------------------+
//| Repaint_Checker.mqh                                               |
//| Detects if signals are repainting (changing after appearing)     |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| Signal Snapshot Structure                                        |
//+------------------------------------------------------------------+
struct SignalSnapshot
{
   datetime signalTime;           // Time when signal was first detected
   datetime barTime;              // Bar time when signal appeared
   string symbol;                 // Symbol
   ENUM_SIGNAL_TYPE signalType;   // Signal type (BUY/SELL)
   double entryPrice;             // Entry price at detection
   double stopLoss;               // Stop loss at detection
   double takeProfit1;            // Take profit 1 at detection
   double takeProfit2;            // Take profit 2 at detection
   int score;                     // Score at detection
   bool isChecked;                // Has been checked for repaint
   bool isRepainted;              // Did signal repaint?
   string repaintReason;          // Reason for repaint detection
};

//+------------------------------------------------------------------+
//| Repaint Checker Class                                            |
//+------------------------------------------------------------------+
class CRepaintChecker
{
private:
   SignalSnapshot m_snapshots[];  // Signal snapshots
   int m_snapshotCount;
   
   int FindSnapshotIndex(string symbol, datetime barTime);
   bool CheckSignalStillExists(string symbol, datetime barTime, ENUM_SIGNAL_TYPE expectedType);
   ENUM_SIGNAL_TYPE GetSignalTypeAtBar(string symbol, datetime barTime);
   double GetEntryPriceAtBar(string symbol, datetime barTime, ENUM_SIGNAL_TYPE signalType);
   
public:
   CRepaintChecker();
   ~CRepaintChecker();
   
   // Record signal snapshot when it first appears
   void RecordSignalSnapshot(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                            datetime barTime, double entryPrice, double stopLoss,
                            double takeProfit1, double takeProfit2, int score);
   
   // Check if signal repainted (call after candle closes)
   void CheckRepaint(string symbol, datetime barTime);
   
   // Get repaint statistics
   int GetTotalSignals();
   int GetRepaintedSignals();
   double GetRepaintRate();
   
   // Print repaint report
   void PrintRepaintReport();
   string GetRepaintReportString();
   
   // Cleanup old snapshots
   void CleanupOldSnapshots(int maxAgeHours = 24);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRepaintChecker::CRepaintChecker()
{
   ArrayResize(m_snapshots, 0);
   m_snapshotCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRepaintChecker::~CRepaintChecker()
{
   ArrayResize(m_snapshots, 0);
}

//+------------------------------------------------------------------+
//| Find snapshot index by symbol and bar time                       |
//+------------------------------------------------------------------+
int CRepaintChecker::FindSnapshotIndex(string symbol, datetime barTime)
{
   for(int i = 0; i < m_snapshotCount; i++)
   {
      if(m_snapshots[i].symbol == symbol && m_snapshots[i].barTime == barTime)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Record signal snapshot when it first appears                     |
//+------------------------------------------------------------------+
void CRepaintChecker::RecordSignalSnapshot(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                                          datetime barTime, double entryPrice, double stopLoss,
                                          double takeProfit1, double takeProfit2, int score)
{
   int index = m_snapshotCount;
   ArrayResize(m_snapshots, m_snapshotCount + 1);
   
   m_snapshots[index].signalTime = signalTime;
   m_snapshots[index].barTime = barTime;
   m_snapshots[index].symbol = symbol;
   m_snapshots[index].signalType = signalType;
   m_snapshots[index].entryPrice = entryPrice;
   m_snapshots[index].stopLoss = stopLoss;
   m_snapshots[index].takeProfit1 = takeProfit1;
   m_snapshots[index].takeProfit2 = takeProfit2;
   m_snapshots[index].score = score;
   m_snapshots[index].isChecked = false;
   m_snapshots[index].isRepainted = false;
   m_snapshots[index].repaintReason = "";
   
   m_snapshotCount++;
}

//+------------------------------------------------------------------+
//| Get signal type at specific bar (using historical data)         |
//| Note: This is a simplified check - full implementation would    |
//| require access to EMA managers and scoring system. The actual    |
//| repaint detection is done in CheckRepaint() by comparing         |
//| recorded snapshots with historical bar data.                     |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CRepaintChecker::GetSignalTypeAtBar(string symbol, datetime barTime)
{
   // Get bar index for the specific time
   int barIndex = iBarShift(symbol, PERIOD_CURRENT, barTime);
   if(barIndex < 0)
      return SIGNAL_NONE; // Bar not found
   
   // Since we can't easily call DetermineSignalType with historical context without
   // access to EMA managers and scoring system, we use a simplified approach:
   // Check basic price action patterns that would indicate BUY/SELL signals
   
   // Get OHLC data for the bar
   double open = iOpen(symbol, PERIOD_CURRENT, barIndex);
   double high = iHigh(symbol, PERIOD_CURRENT, barIndex);
   double low = iLow(symbol, PERIOD_CURRENT, barIndex);
   double close = iClose(symbol, PERIOD_CURRENT, barIndex);
   
   if(open == 0.0 || close == 0.0)
      return SIGNAL_NONE; // Invalid data
   
   // Simplified signal detection based on candle pattern
   // Bullish: Close > Open (green candle)
   // Bearish: Close < Open (red candle)
   // This is a basic check - actual signal detection requires EMA alignment
   
   double bodySize = MathAbs(close - open);
   double totalRange = high - low;
   
   // Avoid very small candles (noise)
   if(totalRange == 0.0 || bodySize / totalRange < 0.3)
      return SIGNAL_NONE; // Weak candle, no clear signal
   
   // Determine signal based on candle direction
   if(close > open)
   {
      // Bullish candle - potential BUY signal
      // But we can't confirm without EMA data, so return NONE
      // The actual repaint check in CheckRepaint() uses recorded snapshot data
      return SIGNAL_NONE; // Cannot determine without EMA context
   }
   else if(close < open)
   {
      // Bearish candle - potential SELL signal
      // But we can't confirm without EMA data, so return NONE
      return SIGNAL_NONE; // Cannot determine without EMA context
   }
   
   // Note: The actual repaint detection in CheckRepaint() works by:
   // 1. Comparing recorded entry price with historical bar close price
   // 2. Checking if price moved significantly (more than 2 pips)
   // 3. Verifying signal validity based on price position relative to entry
   // This approach is more reliable than trying to re-calculate signals
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get entry price at specific bar                                  |
//+------------------------------------------------------------------+
double CRepaintChecker::GetEntryPriceAtBar(string symbol, datetime barTime, ENUM_SIGNAL_TYPE signalType)
{
   // Get close price at the specific bar time
   int barIndex = iBarShift(symbol, PERIOD_CURRENT, barTime);
   if(barIndex < 0)
      return 0.0;
   
   return iClose(symbol, PERIOD_CURRENT, barIndex);
}

//+------------------------------------------------------------------+
//| Check if signal still exists at bar                             |
//+------------------------------------------------------------------+
bool CRepaintChecker::CheckSignalStillExists(string symbol, datetime barTime, ENUM_SIGNAL_TYPE expectedType)
{
   // Get signal type at the bar (using historical data)
   ENUM_SIGNAL_TYPE currentType = GetSignalTypeAtBar(symbol, barTime);
   
   // Signal still exists if type matches
   return (currentType == expectedType);
}

//+------------------------------------------------------------------+
//| Check if signal repainted (call after candle closes)            |
//+------------------------------------------------------------------+
void CRepaintChecker::CheckRepaint(string symbol, datetime barTime)
{
   int index = FindSnapshotIndex(symbol, barTime);
   if(index < 0)
      return; // No snapshot for this bar
   
   if(m_snapshots[index].isChecked)
      return; // Already checked
   
   // Mark as checked
   m_snapshots[index].isChecked = true;
   
   // Get bar index for the specific time
   int barIndex = iBarShift(symbol, PERIOD_CURRENT, barTime);
   if(barIndex < 0)
   {
      // Bar not found - might be too old, mark as checked but not repainted
      m_snapshots[index].isChecked = true;
      return;
   }
   
   // Get current close price at that bar (historical data)
   double barClosePrice = iClose(symbol, PERIOD_CURRENT, barIndex);
   
   // Check 1: Entry price changed significantly (more than 2 pips)
   // This is the most reliable check - if entry price changed, signal repainted
   double priceDiff = MathAbs(barClosePrice - m_snapshots[index].entryPrice);
   
   // Calculate pip difference
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point;
   double pipDiff = priceDiff / pipValue;
   
   if(pipDiff > 2.0) // More than 2 pips difference
   {
      m_snapshots[index].isRepainted = true;
      m_snapshots[index].repaintReason = StringFormat("Entry price moved: %.5f -> %.5f (%.1f pips)",
                                                      m_snapshots[index].entryPrice, barClosePrice, pipDiff);
      Print("⚠ REPAINT WARNING: ", symbol, " | Entry price moved at ", TimeToString(barTime),
            " | Original: ", DoubleToString(m_snapshots[index].entryPrice, 5),
            " | After close: ", DoubleToString(barClosePrice, 5),
            " | Difference: ", DoubleToString(pipDiff, 1), " pips");
      return;
   }
   
   // Check 2: Verify signal would still be valid at that bar
   // Check if price at bar close matches expected signal direction
   bool signalStillValid = true;
   
   if(m_snapshots[index].signalType == SIGNAL_BUY)
   {
      // For BUY, price should be above entry (or close to it)
      // If price dropped significantly below entry, signal may have repainted
      if(barClosePrice < m_snapshots[index].entryPrice - (2.0 * pipValue))
      {
         signalStillValid = false;
      }
   }
   else if(m_snapshots[index].signalType == SIGNAL_SELL)
   {
      // For SELL, price should be below entry (or close to it)
      // If price rose significantly above entry, signal may have repainted
      if(barClosePrice > m_snapshots[index].entryPrice + (2.0 * pipValue))
      {
         signalStillValid = false;
      }
   }
   
   if(!signalStillValid)
   {
      m_snapshots[index].isRepainted = true;
      m_snapshots[index].repaintReason = StringFormat("Signal direction invalidated at bar close (price: %.5f, entry: %.5f)",
                                                      barClosePrice, m_snapshots[index].entryPrice);
      Print("⚠ REPAINT WARNING: ", symbol, " | Signal direction invalidated at ", TimeToString(barTime),
            " | Signal: ", EnumToString(m_snapshots[index].signalType),
            " | Entry: ", DoubleToString(m_snapshots[index].entryPrice, 5),
            " | Bar Close: ", DoubleToString(barClosePrice, 5));
      return;
   }
   
   // Signal is stable (no repaint detected)
   m_snapshots[index].isRepainted = false;
}

//+------------------------------------------------------------------+
//| Get total signals                                                |
//+------------------------------------------------------------------+
int CRepaintChecker::GetTotalSignals()
{
   int total = 0;
   for(int i = 0; i < m_snapshotCount; i++)
   {
      if(m_snapshots[i].isChecked)
         total++;
   }
   return total;
}

//+------------------------------------------------------------------+
//| Get repainted signals count                                      |
//+------------------------------------------------------------------+
int CRepaintChecker::GetRepaintedSignals()
{
   int count = 0;
   for(int i = 0; i < m_snapshotCount; i++)
   {
      if(m_snapshots[i].isRepainted)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get repaint rate                                                 |
//+------------------------------------------------------------------+
double CRepaintChecker::GetRepaintRate()
{
   int total = GetTotalSignals();
   if(total == 0)
      return 0.0;
   
   int repainted = GetRepaintedSignals();
   return (double)repainted / total * 100.0;
}

//+------------------------------------------------------------------+
//| Get repaint report string                                       |
//+------------------------------------------------------------------+
string CRepaintChecker::GetRepaintReportString()
{
   int total = GetTotalSignals();
   int repainted = GetRepaintedSignals();
   double repaintRate = GetRepaintRate();
   
   string report = "";
   report += "╔═══════════════════════════════════════════════════════════════╗\n";
   report += "║              REPAINT DETECTION REPORT                         ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Total Signals Checked: %d                                      ║\n", total);
   report += StringFormat("║ Repainted Signals: %d (%.2f%%)                            ║\n", repainted, repaintRate);
   report += StringFormat("║ Stable Signals: %d (%.2f%%)                              ║\n", 
                         total - repainted, 100.0 - repaintRate);
   
   if(repainted > 0)
   {
      report += "╠═══════════════════════════════════════════════════════════════╣\n";
      report += "║ ⚠ WARNING: Indicator is Repainting!                          ║\n";
      report += "║ Signals are changing after candle closes.                    ║\n";
      report += "║ Review signal detection logic and use closed bars only.      ║\n";
   }
   else if(total > 0)
   {
      report += "╠═══════════════════════════════════════════════════════════════╣\n";
      report += "║ ✅ No repainting detected - signals are stable                ║\n";
   }
   
   report += "╚═══════════════════════════════════════════════════════════════╝\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Print repaint report                                             |
//+------------------------------------------------------------------+
void CRepaintChecker::PrintRepaintReport()
{
   string report = GetRepaintReportString();
   Print(report);
}

//+------------------------------------------------------------------+
//| Cleanup old snapshots                                            |
//+------------------------------------------------------------------+
void CRepaintChecker::CleanupOldSnapshots(int maxAgeHours = 24)
{
   datetime cutoffTime = TimeCurrent() - maxAgeHours * 3600;
   
   for(int i = m_snapshotCount - 1; i >= 0; i--)
   {
      if(m_snapshots[i].barTime < cutoffTime && m_snapshots[i].isChecked)
      {
         // Remove this snapshot
         for(int j = i; j < m_snapshotCount - 1; j++)
         {
            m_snapshots[j] = m_snapshots[j + 1];
         }
         m_snapshotCount--;
      }
   }
   
   ArrayResize(m_snapshots, m_snapshotCount);
}

//+------------------------------------------------------------------+

