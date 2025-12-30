//+------------------------------------------------------------------+
//| Statistics_Tracker.mqh                                            |
//| Tracks trading statistics: Win Rate, Profit Factor, Avg P/L      |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| Trade Result Structure                                           |
//+------------------------------------------------------------------+
struct TradeResult
{
   datetime entryTime;
   ENUM_SIGNAL_TYPE signalType;
   string symbol;
   double entry;
   double stopLoss;
   double takeProfit1;
   double takeProfit2;
   double actualProfit;  // Actual profit/loss in pips
   bool isWin;           // true = win, false = loss
   bool isClosed;        // true = trade closed, false = pending
};

//+------------------------------------------------------------------+
//| Statistics Tracker Class                                         |
//+------------------------------------------------------------------+
class CStatisticsTracker
{
private:
   TradeResult m_trades[];        // All trades
   int m_totalTrades;
   
   // BUY statistics
   int m_buyWins;
   int m_buyLosses;
   double m_buyTotalProfit;
   double m_buyTotalLoss;
   
   // SELL statistics
   int m_sellWins;
   int m_sellLosses;
   double m_sellTotalProfit;
   double m_sellTotalLoss;
   
   double GetPipValue(string symbol);
   double CalculateProfitPips(string symbol, double entry, double exit, ENUM_SIGNAL_TYPE signalType);
   
public:
   CStatisticsTracker();
   ~CStatisticsTracker();
   
   // Record signal (when signal is generated)
   void RecordSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime entryTime,
                    double entry, double stopLoss, double takeProfit1, double takeProfit2);
   
   // Record result (when trade is closed)
   void RecordResult(string symbol, datetime entryTime, double actualExit, bool hitTP);
   
   // Calculate and get statistics
   double GetWinRate(ENUM_SIGNAL_TYPE signalType);
   double GetAverageProfit(ENUM_SIGNAL_TYPE signalType);
   double GetAverageLoss(ENUM_SIGNAL_TYPE signalType);
   double GetProfitFactor(ENUM_SIGNAL_TYPE signalType);
   int GetTotalTrades(ENUM_SIGNAL_TYPE signalType);
   int GetWins(ENUM_SIGNAL_TYPE signalType);
   int GetLosses(ENUM_SIGNAL_TYPE signalType);
   
   // Print statistics to log
   void PrintStatistics();
   string GetStatisticsString();
   
   // Reset statistics
   void Reset();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStatisticsTracker::CStatisticsTracker()
{
   ArrayResize(m_trades, 0);
   m_totalTrades = 0;
   m_buyWins = 0;
   m_buyLosses = 0;
   m_buyTotalProfit = 0;
   m_buyTotalLoss = 0;
   m_sellWins = 0;
   m_sellLosses = 0;
   m_sellTotalProfit = 0;
   m_sellTotalLoss = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStatisticsTracker::~CStatisticsTracker()
{
   ArrayResize(m_trades, 0);
}

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double CStatisticsTracker::GetPipValue(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point;
}

//+------------------------------------------------------------------+
//| Calculate profit in pips                                        |
//+------------------------------------------------------------------+
double CStatisticsTracker::CalculateProfitPips(string symbol, double entry, double exit, ENUM_SIGNAL_TYPE signalType)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return (exit - entry) / pipValue;
   else // SIGNAL_SELL
      return (entry - exit) / pipValue;
}

//+------------------------------------------------------------------+
//| Record signal when generated                                     |
//+------------------------------------------------------------------+
void CStatisticsTracker::RecordSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime entryTime,
                                     double entry, double stopLoss, double takeProfit1, double takeProfit2)
{
   int index = m_totalTrades;
   ArrayResize(m_trades, m_totalTrades + 1);
   
   m_trades[index].entryTime = entryTime;
   m_trades[index].signalType = signalType;
   m_trades[index].symbol = symbol;
   m_trades[index].entry = entry;
   m_trades[index].stopLoss = stopLoss;
   m_trades[index].takeProfit1 = takeProfit1;
   m_trades[index].takeProfit2 = takeProfit2;
   m_trades[index].actualProfit = 0;
   m_trades[index].isWin = false;
   m_trades[index].isClosed = false;
   
   m_totalTrades++;
}

//+------------------------------------------------------------------+
//| Record result when trade is closed                               |
//+------------------------------------------------------------------+
void CStatisticsTracker::RecordResult(string symbol, datetime entryTime, double actualExit, bool hitTP)
{
   // Find the trade by symbol and entry time
   for(int i = 0; i < m_totalTrades; i++)
   {
      if(m_trades[i].symbol == symbol && 
         m_trades[i].entryTime == entryTime && 
         !m_trades[i].isClosed)
      {
         // Calculate actual profit in pips
         m_trades[i].actualProfit = CalculateProfitPips(symbol, m_trades[i].entry, actualExit, m_trades[i].signalType);
         m_trades[i].isWin = (m_trades[i].actualProfit > 0);
         m_trades[i].isClosed = true;
         
         // Update statistics
         if(m_trades[i].signalType == SIGNAL_BUY)
         {
            if(m_trades[i].isWin)
            {
               m_buyWins++;
               m_buyTotalProfit += m_trades[i].actualProfit;
            }
            else
            {
               m_buyLosses++;
               m_buyTotalLoss += MathAbs(m_trades[i].actualProfit);
            }
         }
         else // SIGNAL_SELL
         {
            if(m_trades[i].isWin)
            {
               m_sellWins++;
               m_sellTotalProfit += m_trades[i].actualProfit;
            }
            else
            {
               m_sellLosses++;
               m_sellTotalLoss += MathAbs(m_trades[i].actualProfit);
            }
         }
         
         break; // Found and updated
      }
   }
}

//+------------------------------------------------------------------+
//| Get win rate for signal type                                     |
//+------------------------------------------------------------------+
double CStatisticsTracker::GetWinRate(ENUM_SIGNAL_TYPE signalType)
{
   int wins, losses;
   
   if(signalType == SIGNAL_BUY)
   {
      wins = m_buyWins;
      losses = m_buyLosses;
   }
   else // SIGNAL_SELL
   {
      wins = m_sellWins;
      losses = m_sellLosses;
   }
   
   int total = wins + losses;
   if(total == 0)
      return 0.0;
   
   return (double)wins / total * 100.0;
}

//+------------------------------------------------------------------+
//| Get average profit for signal type                               |
//+------------------------------------------------------------------+
double CStatisticsTracker::GetAverageProfit(ENUM_SIGNAL_TYPE signalType)
{
   int wins;
   double totalProfit;
   
   if(signalType == SIGNAL_BUY)
   {
      wins = m_buyWins;
      totalProfit = m_buyTotalProfit;
   }
   else // SIGNAL_SELL
   {
      wins = m_sellWins;
      totalProfit = m_sellTotalProfit;
   }
   
   if(wins == 0)
      return 0.0;
   
   return totalProfit / wins;
}

//+------------------------------------------------------------------+
//| Get average loss for signal type                                 |
//+------------------------------------------------------------------+
double CStatisticsTracker::GetAverageLoss(ENUM_SIGNAL_TYPE signalType)
{
   int losses;
   double totalLoss;
   
   if(signalType == SIGNAL_BUY)
   {
      losses = m_buyLosses;
      totalLoss = m_buyTotalLoss;
   }
   else // SIGNAL_SELL
   {
      losses = m_sellLosses;
      totalLoss = m_sellTotalLoss;
   }
   
   if(losses == 0)
      return 0.0;
   
   return totalLoss / losses;
}

//+------------------------------------------------------------------+
//| Get profit factor for signal type                                |
//+------------------------------------------------------------------+
double CStatisticsTracker::GetProfitFactor(ENUM_SIGNAL_TYPE signalType)
{
   double totalProfit, totalLoss;
   
   if(signalType == SIGNAL_BUY)
   {
      totalProfit = m_buyTotalProfit;
      totalLoss = m_buyTotalLoss;
   }
   else // SIGNAL_SELL
   {
      totalProfit = m_sellTotalProfit;
      totalLoss = m_sellTotalLoss;
   }
   
   if(totalLoss == 0)
   {
      if(totalProfit > 0)
         return 999.99; // Infinite profit factor
      else
         return 0.0;
   }
   
   return totalProfit / totalLoss;
}

//+------------------------------------------------------------------+
//| Get total trades for signal type                                 |
//+------------------------------------------------------------------+
int CStatisticsTracker::GetTotalTrades(ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return m_buyWins + m_buyLosses;
   else // SIGNAL_SELL
      return m_sellWins + m_sellLosses;
}

//+------------------------------------------------------------------+
//| Get wins for signal type                                         |
//+------------------------------------------------------------------+
int CStatisticsTracker::GetWins(ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return m_buyWins;
   else // SIGNAL_SELL
      return m_sellWins;
}

//+------------------------------------------------------------------+
//| Get losses for signal type                                       |
//+------------------------------------------------------------------+
int CStatisticsTracker::GetLosses(ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return m_buyLosses;
   else // SIGNAL_SELL
      return m_sellLosses;
}

//+------------------------------------------------------------------+
//| Get statistics as formatted string                               |
//+------------------------------------------------------------------+
string CStatisticsTracker::GetStatisticsString()
{
   string stats = "";
   
   // BUY Statistics
   int buyTotal = GetTotalTrades(SIGNAL_BUY);
   double buyWinRate = GetWinRate(SIGNAL_BUY);
   double buyAvgProfit = GetAverageProfit(SIGNAL_BUY);
   double buyAvgLoss = GetAverageLoss(SIGNAL_BUY);
   double buyProfitFactor = GetProfitFactor(SIGNAL_BUY);
   
   // SELL Statistics
   int sellTotal = GetTotalTrades(SIGNAL_SELL);
   double sellWinRate = GetWinRate(SIGNAL_SELL);
   double sellAvgProfit = GetAverageProfit(SIGNAL_SELL);
   double sellAvgLoss = GetAverageLoss(SIGNAL_SELL);
   double sellProfitFactor = GetProfitFactor(SIGNAL_SELL);
   
   // Overall Statistics
   int overallTotal = buyTotal + sellTotal;
   int overallWins = m_buyWins + m_sellWins;
   int overallLosses = m_buyLosses + m_sellLosses;
   double overallWinRate = 0.0;
   if(overallTotal > 0)
      overallWinRate = (double)overallWins / overallTotal * 100.0;
   double overallTotalProfit = m_buyTotalProfit + m_sellTotalProfit;
   double overallTotalLoss = m_buyTotalLoss + m_sellTotalLoss;
   double overallAvgProfit = 0.0;
   if(overallWins > 0)
      overallAvgProfit = overallTotalProfit / overallWins;
   double overallAvgLoss = 0.0;
   if(overallLosses > 0)
      overallAvgLoss = overallTotalLoss / overallLosses;
   double overallProfitFactor = 0.0;
   if(overallTotalLoss > 0)
      overallProfitFactor = overallTotalProfit / overallTotalLoss;
   else if(overallTotalProfit > 0)
      overallProfitFactor = 999.99;
   
   stats += "╔═══════════════════════════════════════════════════════════════╗\n";
   stats += "║              TRADING STATISTICS REPORT                        ║\n";
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += "║ OVERALL STATISTICS                                            ║\n";
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += StringFormat("║ Total Trades: %d (Wins: %d, Losses: %d)                    ║\n", 
                        overallTotal, overallWins, overallLosses);
   stats += StringFormat("║ Win Rate: %.2f%%                                          ║\n", overallWinRate);
   stats += StringFormat("║ Average Profit: %.2f pips                                ║\n", overallAvgProfit);
   stats += StringFormat("║ Average Loss: %.2f pips                                  ║\n", overallAvgLoss);
   stats += StringFormat("║ Profit Factor: %.2f                                      ║\n", overallProfitFactor);
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += "║ BUY SIGNALS STATISTICS                                         ║\n";
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += StringFormat("║ Total Trades: %d (Wins: %d, Losses: %d)                    ║\n", 
                        buyTotal, m_buyWins, m_buyLosses);
   stats += StringFormat("║ Win Rate: %.2f%%                                          ║\n", buyWinRate);
   stats += StringFormat("║ Average Profit: %.2f pips                                ║\n", buyAvgProfit);
   stats += StringFormat("║ Average Loss: %.2f pips                                  ║\n", buyAvgLoss);
   stats += StringFormat("║ Profit Factor: %.2f                                      ║\n", buyProfitFactor);
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += "║ SELL SIGNALS STATISTICS                                        ║\n";
   stats += "╠═══════════════════════════════════════════════════════════════╣\n";
   stats += StringFormat("║ Total Trades: %d (Wins: %d, Losses: %d)                    ║\n", 
                        sellTotal, m_sellWins, m_sellLosses);
   stats += StringFormat("║ Win Rate: %.2f%%                                          ║\n", sellWinRate);
   stats += StringFormat("║ Average Profit: %.2f pips                                ║\n", sellAvgProfit);
   stats += StringFormat("║ Average Loss: %.2f pips                                  ║\n", sellAvgLoss);
   stats += StringFormat("║ Profit Factor: %.2f                                      ║\n", sellProfitFactor);
   stats += "╚═══════════════════════════════════════════════════════════════╝\n";
   
   return stats;
}

//+------------------------------------------------------------------+
//| Print statistics to log                                          |
//+------------------------------------------------------------------+
void CStatisticsTracker::PrintStatistics()
{
   string stats = GetStatisticsString();
   Print(stats);
}

//+------------------------------------------------------------------+
//| Reset statistics                                                 |
//+------------------------------------------------------------------+
void CStatisticsTracker::Reset()
{
   ArrayResize(m_trades, 0);
   m_totalTrades = 0;
   m_buyWins = 0;
   m_buyLosses = 0;
   m_buyTotalProfit = 0;
   m_buyTotalLoss = 0;
   m_sellWins = 0;
   m_sellLosses = 0;
   m_sellTotalProfit = 0;
   m_sellTotalLoss = 0;
}

//+------------------------------------------------------------------+

