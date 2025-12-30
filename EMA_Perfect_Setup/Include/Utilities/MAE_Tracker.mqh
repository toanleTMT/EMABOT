//+------------------------------------------------------------------+
//| MAE_Tracker.mqh                                                   |
//| Tracks Maximum Adverse Excursion (MAE) for each signal           |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| MAE Tracking Structure                                           |
//+------------------------------------------------------------------+
struct MAETrack
{
   datetime signalTime;
   string symbol;
   ENUM_SIGNAL_TYPE signalType;
   double entryPrice;
   double stopLoss;
   double takeProfit1;
   double takeProfit2;
   ENUM_TIMEFRAMES timeframe;
   bool isActive;              // Is trade still active?
   bool isClosed;              // Has trade closed (TP/SL hit)?
   double maxAdverseExcursion; // Maximum drawdown in pips (worst price movement)
   double maxFavorableExcursion; // Maximum favorable movement in pips
   double currentPrice;        // Current price
   double closePrice;          // Price when trade closed
   bool closedAtTP;           // Did it close at TP?
   bool closedAtSL;           // Did it close at SL?
   int barsElapsed;            // Bars elapsed since entry
};

//+------------------------------------------------------------------+
//| MAE Tracker Class                                                |
//+------------------------------------------------------------------+
class CMAETracker
{
private:
   MAETrack m_trades[];        // Active and closed trades
   int m_tradeCount;
   
   double GetPipValue(string symbol);
   double CalculatePips(string symbol, double price1, double price2, ENUM_SIGNAL_TYPE signalType);
   double GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckIfTPHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double tp);
   bool CheckIfSLHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double sl);
   int FindTradeIndex(string symbol, datetime signalTime);
   
public:
   CMAETracker();
   ~CMAETracker();
   
   // Register signal for MAE tracking
   void RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                      double entryPrice, double stopLoss, double takeProfit1, double takeProfit2,
                      ENUM_TIMEFRAMES timeframe);
   
   // Update MAE for all active trades
   void UpdateMAE();
   
   // Get MAE statistics
   double GetAverageMAE();
   double GetMaxMAE();
   double GetMinMAE();
   double GetAverageMAE_Wins();
   double GetAverageMAE_Losses();
   int GetTotalTrades();
   int GetActiveTrades();
   int GetClosedTrades();
   
   // Get MAE for specific trade
   double GetTradeMAE(string symbol, datetime signalTime);
   
   // Print MAE report
   void PrintMAEReport();
   string GetMAEReportString();
   
   // Cleanup old trades
   void CleanupOldTrades(int maxAgeHours = 24);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMAETracker::CMAETracker()
{
   ArrayResize(m_trades, 0);
   m_tradeCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMAETracker::~CMAETracker()
{
   ArrayResize(m_trades, 0);
}

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double CMAETracker::GetPipValue(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point;
}

//+------------------------------------------------------------------+
//| Calculate pips between two prices                                |
//+------------------------------------------------------------------+
double CMAETracker::CalculatePips(string symbol, double price1, double price2, ENUM_SIGNAL_TYPE signalType)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return (price2 - price1) / pipValue;  // Positive = favorable, Negative = adverse
   else // SIGNAL_SELL
      return (price1 - price2) / pipValue;  // Positive = favorable, Negative = adverse
}

//+------------------------------------------------------------------+
//| Get current price for signal type                                |
//+------------------------------------------------------------------+
double CMAETracker::GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return SymbolInfoDouble(symbol, SYMBOL_BID);  // For BUY, use BID (sell price)
   else // SIGNAL_SELL
      return SymbolInfoDouble(symbol, SYMBOL_ASK);  // For SELL, use ASK (buy price)
}

//+------------------------------------------------------------------+
//| Check if TP was hit                                              |
//+------------------------------------------------------------------+
bool CMAETracker::CheckIfTPHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double tp)
{
   if(signalType == SIGNAL_BUY)
      return (currentPrice >= tp);
   else // SIGNAL_SELL
      return (currentPrice <= tp);
}

//+------------------------------------------------------------------+
//| Check if SL was hit                                              |
//+------------------------------------------------------------------+
bool CMAETracker::CheckIfSLHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double sl)
{
   if(signalType == SIGNAL_BUY)
      return (currentPrice <= sl);
   else // SIGNAL_SELL
      return (currentPrice >= sl);
}

//+------------------------------------------------------------------+
//| Find trade index by symbol and signal time                       |
//+------------------------------------------------------------------+
int CMAETracker::FindTradeIndex(string symbol, datetime signalTime)
{
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].symbol == symbol && m_trades[i].signalTime == signalTime)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Register signal for MAE tracking                                 |
//+------------------------------------------------------------------+
void CMAETracker::RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                                 double entryPrice, double stopLoss, double takeProfit1, double takeProfit2,
                                 ENUM_TIMEFRAMES timeframe)
{
   int index = m_tradeCount;
   ArrayResize(m_trades, m_tradeCount + 1);
   
   m_trades[index].signalTime = signalTime;
   m_trades[index].symbol = symbol;
   m_trades[index].signalType = signalType;
   m_trades[index].entryPrice = entryPrice;
   m_trades[index].stopLoss = stopLoss;
   m_trades[index].takeProfit1 = takeProfit1;
   m_trades[index].takeProfit2 = takeProfit2;
   m_trades[index].timeframe = timeframe;
   m_trades[index].isActive = true;
   m_trades[index].isClosed = false;
   m_trades[index].maxAdverseExcursion = 0.0;  // Start at 0 (no adverse movement yet)
   m_trades[index].maxFavorableExcursion = 0.0;
   m_trades[index].currentPrice = entryPrice;
   m_trades[index].closePrice = 0.0;
   m_trades[index].closedAtTP = false;
   m_trades[index].closedAtSL = false;
   m_trades[index].barsElapsed = 0;
   
   m_tradeCount++;
}

//+------------------------------------------------------------------+
//| Update MAE for all active trades                                 |
//+------------------------------------------------------------------+
void CMAETracker::UpdateMAE()
{
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(!m_trades[i].isActive || m_trades[i].isClosed)
         continue; // Skip inactive/closed trades
      
      // Get current price
      double currentPrice = GetCurrentPrice(m_trades[i].symbol, m_trades[i].signalType);
      m_trades[i].currentPrice = currentPrice;
      
      // Calculate current movement from entry
      double currentMovement = CalculatePips(m_trades[i].symbol, m_trades[i].entryPrice, currentPrice, m_trades[i].signalType);
      
      // Update maximum adverse excursion (worst drawdown)
      // MAE is the most negative movement (biggest drawdown)
      if(currentMovement < m_trades[i].maxAdverseExcursion)
      {
         m_trades[i].maxAdverseExcursion = currentMovement; // More negative = worse drawdown
      }
      
      // Update maximum favorable excursion (best movement)
      if(currentMovement > m_trades[i].maxFavorableExcursion)
      {
         m_trades[i].maxFavorableExcursion = currentMovement;
      }
      
      // Check if TP1 was hit
      if(CheckIfTPHit(m_trades[i].symbol, m_trades[i].signalType, currentPrice, m_trades[i].takeProfit1))
      {
         m_trades[i].isActive = false;
         m_trades[i].isClosed = true;
         m_trades[i].closePrice = currentPrice;
         m_trades[i].closedAtTP = true;
         m_trades[i].closedAtSL = false;
         continue;
      }
      
      // Check if SL was hit
      if(CheckIfSLHit(m_trades[i].symbol, m_trades[i].signalType, currentPrice, m_trades[i].stopLoss))
      {
         m_trades[i].isActive = false;
         m_trades[i].isClosed = true;
         m_trades[i].closePrice = currentPrice;
         m_trades[i].closedAtTP = false;
         m_trades[i].closedAtSL = true;
         continue;
      }
      
      // Increment bars elapsed (approximate - using time difference)
      // This is approximate since we don't track exact bar count
      datetime currentTime = TimeCurrent();
      int timeDiff = (int)(currentTime - m_trades[i].signalTime);
      // Approximate bars: assume 5-minute bars = 300 seconds each
      if(m_trades[i].timeframe == PERIOD_M5)
         m_trades[i].barsElapsed = timeDiff / 300;
      else if(m_trades[i].timeframe == PERIOD_M15)
         m_trades[i].barsElapsed = timeDiff / 900;
      else if(m_trades[i].timeframe == PERIOD_H1)
         m_trades[i].barsElapsed = timeDiff / 3600;
      else
         m_trades[i].barsElapsed = timeDiff / 300; // Default to M5
   }
}

//+------------------------------------------------------------------+
//| Get average MAE for all closed trades                            |
//+------------------------------------------------------------------+
double CMAETracker::GetAverageMAE()
{
   int closedCount = 0;
   double totalMAE = 0.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed)
      {
         closedCount++;
         totalMAE += MathAbs(m_trades[i].maxAdverseExcursion); // Use absolute value
      }
   }
   
   if(closedCount == 0)
      return 0.0;
   
   return totalMAE / closedCount;
}

//+------------------------------------------------------------------+
//| Get maximum MAE                                                  |
//+------------------------------------------------------------------+
double CMAETracker::GetMaxMAE()
{
   double maxMAE = 0.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed)
      {
         double mae = MathAbs(m_trades[i].maxAdverseExcursion);
         if(mae > maxMAE)
            maxMAE = mae;
      }
   }
   
   return maxMAE;
}

//+------------------------------------------------------------------+
//| Get minimum MAE                                                  |
//+------------------------------------------------------------------+
double CMAETracker::GetMinMAE()
{
   double minMAE = 999999.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed)
      {
         double mae = MathAbs(m_trades[i].maxAdverseExcursion);
         if(mae < minMAE)
            minMAE = mae;
      }
   }
   
   if(minMAE == 999999.0)
      return 0.0;
   
   return minMAE;
}

//+------------------------------------------------------------------+
//| Get average MAE for winning trades                               |
//+------------------------------------------------------------------+
double CMAETracker::GetAverageMAE_Wins()
{
   int winCount = 0;
   double totalMAE = 0.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed && m_trades[i].closedAtTP)
      {
         winCount++;
         totalMAE += MathAbs(m_trades[i].maxAdverseExcursion);
      }
   }
   
   if(winCount == 0)
      return 0.0;
   
   return totalMAE / winCount;
}

//+------------------------------------------------------------------+
//| Get average MAE for losing trades                                 |
//+------------------------------------------------------------------+
double CMAETracker::GetAverageMAE_Losses()
{
   int lossCount = 0;
   double totalMAE = 0.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed && m_trades[i].closedAtSL)
      {
         lossCount++;
         totalMAE += MathAbs(m_trades[i].maxAdverseExcursion);
      }
   }
   
   if(lossCount == 0)
      return 0.0;
   
   return totalMAE / lossCount;
}

//+------------------------------------------------------------------+
//| Get total trades                                                  |
//+------------------------------------------------------------------+
int CMAETracker::GetTotalTrades()
{
   return m_tradeCount;
}

//+------------------------------------------------------------------+
//| Get active trades count                                          |
//+------------------------------------------------------------------+
int CMAETracker::GetActiveTrades()
{
   int count = 0;
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isActive && !m_trades[i].isClosed)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get closed trades count                                          |
//+------------------------------------------------------------------+
int CMAETracker::GetClosedTrades()
{
   int count = 0;
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get MAE for specific trade                                        |
//+------------------------------------------------------------------+
double CMAETracker::GetTradeMAE(string symbol, datetime signalTime)
{
   int index = FindTradeIndex(symbol, signalTime);
   if(index >= 0)
      return MathAbs(m_trades[index].maxAdverseExcursion);
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get MAE report string                                            |
//+------------------------------------------------------------------+
string CMAETracker::GetMAEReportString()
{
   int total = GetTotalTrades();
   int active = GetActiveTrades();
   int closed = GetClosedTrades();
   double avgMAE = GetAverageMAE();
   double maxMAE = GetMaxMAE();
   double minMAE = GetMinMAE();
   double avgMAE_Wins = GetAverageMAE_Wins();
   double avgMAE_Losses = GetAverageMAE_Losses();
   
   // Count wins and losses
   int wins = 0;
   int losses = 0;
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_trades[i].isClosed)
      {
         if(m_trades[i].closedAtTP)
            wins++;
         else if(m_trades[i].closedAtSL)
            losses++;
      }
   }
   
   string report = "";
   report += "╔═══════════════════════════════════════════════════════════════╗\n";
   report += "║              MAXIMUM ADVERSE EXCURSION (MAE) REPORT            ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Total Signals Tracked: %d                                      ║\n", total);
   report += StringFormat("║ Active Trades: %d                                             ║\n", active);
   report += StringFormat("║ Closed Trades: %d                                              ║\n", closed);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ MAE STATISTICS (Maximum Drawdown Before TP/SL)                ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Average MAE: %.2f pips                                      ║\n", avgMAE);
   report += StringFormat("║ Maximum MAE: %.2f pips                                      ║\n", maxMAE);
   report += StringFormat("║ Minimum MAE: %.2f pips                                      ║\n", minMAE);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ MAE BY TRADE OUTCOME                                            ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Average MAE (Wins): %.2f pips (%d trades)                  ║\n", avgMAE_Wins, wins);
   report += StringFormat("║ Average MAE (Losses): %.2f pips (%d trades)                ║\n", avgMAE_Losses, losses);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ INTERPRETATION                                                  ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   
   if(avgMAE > 0)
   {
      if(avgMAE > 20.0)
         report += "║ ⚠ High MAE (>20 pips): Signals may be too early                    ║\n";
      else if(avgMAE > 10.0)
         report += "║ ⚠ Moderate MAE (10-20 pips): Consider entry timing optimization    ║\n";
      else
         report += "║ ✅ Low MAE (<10 pips): Signals have good entry timing              ║\n";
      
      if(avgMAE_Wins > avgMAE_Losses * 1.5)
         report += "║ ⚠ Winning trades have higher MAE - may indicate early entries     ║\n";
   }
   
   report += "╚═══════════════════════════════════════════════════════════════╝\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Print MAE report                                                 |
//+------------------------------------------------------------------+
void CMAETracker::PrintMAEReport()
{
   string report = GetMAEReportString();
   Print(report);
}

//+------------------------------------------------------------------+
//| Cleanup old trades                                                |
//+------------------------------------------------------------------+
void CMAETracker::CleanupOldTrades(int maxAgeHours = 24)
{
   datetime cutoffTime = TimeCurrent() - maxAgeHours * 3600;
   
   for(int i = m_tradeCount - 1; i >= 0; i--)
   {
      if(m_trades[i].signalTime < cutoffTime && m_trades[i].isClosed)
      {
         // Remove this trade
         for(int j = i; j < m_tradeCount - 1; j++)
         {
            m_trades[j] = m_trades[j + 1];
         }
         m_tradeCount--;
      }
   }
   
   ArrayResize(m_trades, m_tradeCount);
}

//+------------------------------------------------------------------+

