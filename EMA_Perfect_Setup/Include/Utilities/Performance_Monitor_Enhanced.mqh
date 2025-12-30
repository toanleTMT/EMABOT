//+------------------------------------------------------------------+
//| Performance_Monitor_Enhanced.mqh                                  |
//| Comprehensive performance monitoring for indicator signals       |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"

//+------------------------------------------------------------------+
//| Performance Track Structure                                      |
//+------------------------------------------------------------------+
struct PerformanceTrack
{
   datetime signalTime;
   string symbol;
   ENUM_SIGNAL_TYPE signalType;
   double entryPrice;
   double stopLoss;
   double takeProfit1;
   double takeProfit2;
   ENUM_TIMEFRAMES timeframe;
   int qualityBars;              // Number of bars to evaluate quality
   
   // Results
   bool isClosed;                 // Has trade closed?
   bool isWin;                    // Did trade win?
   double closePrice;             // Price when closed
   double maxDrawdown;            // Maximum drawdown in pips (MAE)
   double maxFavorable;           // Maximum favorable movement in pips (MFE)
   double priceMovement;          // Final price movement in pips
   double qualityScore;           // Signal quality score (0-100)
   int barsToClose;               // Bars elapsed before close
   bool closedAtTP;               // Closed at TP?
   bool closedAtSL;               // Closed at SL?
};

//+------------------------------------------------------------------+
//| Enhanced Performance Monitor Class                               |
//+------------------------------------------------------------------+
class CPerformanceMonitorEnhanced
{
private:
   PerformanceTrack m_tracks[];    // Performance tracks
   int m_trackCount;
   
   double GetPipValue(string symbol);
   double CalculatePips(string symbol, double price1, double price2, ENUM_SIGNAL_TYPE signalType);
   double GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType);
   double CalculateQualityScore(string symbol, ENUM_SIGNAL_TYPE signalType, double entryPrice,
                                double currentPrice, double takeProfit1, int barsElapsed, int qualityBars);
   bool CheckIfTPHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double tp);
   bool CheckIfSLHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double sl);
   int FindTrackIndex(string symbol, datetime signalTime);
   void UpdateTrack(int index);
   
public:
   CPerformanceMonitorEnhanced();
   ~CPerformanceMonitorEnhanced();
   
   // Register signal for performance tracking
   void RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                      double entryPrice, double stopLoss, double takeProfit1, double takeProfit2,
                      ENUM_TIMEFRAMES timeframe, int qualityBars);
   
   // Update all active tracks
   void UpdateTracks();
   
   // Get Win/Loss ratio
   double GetWinLossRatio();
   int GetTotalTrades();
   int GetWins();
   int GetLosses();
   double GetWinRate();
   
   // Get Signal Quality Score statistics
   double GetAverageQualityScore();
   double GetAverageQualityScore_Wins();
   double GetAverageQualityScore_Losses();
   double GetMinQualityScore();
   double GetMaxQualityScore();
   
   // Get Maximum Drawdown statistics
   double GetAverageMaxDrawdown();
   double GetAverageMaxDrawdown_Wins();
   double GetAverageMaxDrawdown_Losses();
   double GetMaxDrawdown();
   double GetMinDrawdown();
   
   // Get SL effectiveness
   double GetSLHitRate();         // Percentage of trades that hit SL
   double GetAverageDrawdownToSL(); // Average drawdown as % of SL
   bool IsSLSetCorrectly();       // Analysis if SL is appropriate
   
   // Print comprehensive performance report
   void PrintPerformanceReport();
   string GetPerformanceReportString();
   
   // Export to CSV
   bool ExportToCSV(string filename);
   string GetCSVHeader();
   string GetCSVRow(int index);
   
   // Cleanup old tracks
   void CleanupOldTracks(int maxAgeHours = 24);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPerformanceMonitorEnhanced::CPerformanceMonitorEnhanced()
{
   ArrayResize(m_tracks, 0);
   m_trackCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPerformanceMonitorEnhanced::~CPerformanceMonitorEnhanced()
{
   ArrayResize(m_tracks, 0);
}

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetPipValue(string symbol)
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
double CPerformanceMonitorEnhanced::CalculatePips(string symbol, double price1, double price2, ENUM_SIGNAL_TYPE signalType)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return (price2 - price1) / pipValue;
   else // SIGNAL_SELL
      return (price1 - price2) / pipValue;
}

//+------------------------------------------------------------------+
//| Get current price for signal type                                |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return SymbolInfoDouble(symbol, SYMBOL_BID);
   else // SIGNAL_SELL
      return SymbolInfoDouble(symbol, SYMBOL_ASK);
}

//+------------------------------------------------------------------+
//| Calculate Signal Quality Score (0-100)                           |
//| Based on how far price travels in predicted direction within N bars |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::CalculateQualityScore(string symbol, ENUM_SIGNAL_TYPE signalType, 
                                                         double entryPrice, double currentPrice, double takeProfit1,
                                                         int barsElapsed, int qualityBars)
{
   // Calculate price movement in pips from entry to current
   double movementPips = CalculatePips(symbol, entryPrice, currentPrice, signalType);
   
   // Calculate TP1 distance in pips (target distance)
   double tp1DistancePips = MathAbs(CalculatePips(symbol, entryPrice, takeProfit1, signalType));
   
   // Quality score is based on:
   // 1. Distance traveled in predicted direction as % of TP1 (0-70 points)
   // 2. Speed of movement (0-20 points)
   // 3. Time efficiency (0-10 points)
   
   double score = 0.0;
   
   // Factor 1: Distance traveled in predicted direction (0-70 points)
   // Score based on how far price moved relative to TP1 target
   if(movementPips > 0)
   {
      // Movement in predicted direction
      if(tp1DistancePips > 0)
      {
         // Calculate percentage of TP1 reached
         double tp1Percent = (movementPips / tp1DistancePips) * 100.0;
         
         if(tp1Percent >= 100.0)
         {
            // Reached or exceeded TP1 - full points
            score += 70.0;
         }
         else
         {
            // Partial movement toward TP1 - proportional score
            score += (tp1Percent / 100.0) * 70.0;
         }
      }
      else
      {
         // TP1 distance is 0 or invalid - use absolute movement
         // Assume good quality if moved 10+ pips
         if(movementPips >= 10.0)
            score += 70.0;
         else
            score += (movementPips / 10.0) * 70.0;
      }
   }
   else
   {
      // Negative movement (against signal) - penalize heavily
      double adversePips = MathAbs(movementPips);
      if(adversePips < 3.0)
         score += 5.0; // Very small adverse movement - minimal points
      // Otherwise score = 0 (already initialized)
   }
   
   // Factor 2: Speed of movement (0-20 points)
   // How fast price moved in predicted direction (pips per bar)
   if(barsElapsed > 0 && movementPips > 0)
   {
      double pipsPerBar = movementPips / barsElapsed;
      
      // Ideal speed: 2+ pips per bar for good quality
      if(pipsPerBar >= 2.0)
         score += 20.0; // Fast movement - full points
      else if(pipsPerBar >= 1.0)
         score += (pipsPerBar / 2.0) * 20.0; // Moderate speed - proportional
      else if(pipsPerBar > 0)
         score += (pipsPerBar / 1.0) * 10.0; // Slow movement - partial points
   }
   
   // Factor 3: Time efficiency (0-10 points)
   // Did price move within the evaluation period?
   if(barsElapsed > 0 && movementPips > 0)
   {
      if(barsElapsed <= qualityBars)
      {
         // Moved within expected time - bonus points
         double timeEfficiency = (double)(qualityBars - barsElapsed) / qualityBars;
         score += timeEfficiency * 10.0; // More time remaining = better efficiency
      }
   }
   
   // Ensure score is 0-100
   if(score > 100.0) score = 100.0;
   if(score < 0.0) score = 0.0;
   
   return score;
}

//+------------------------------------------------------------------+
//| Check if TP was hit                                              |
//+------------------------------------------------------------------+
bool CPerformanceMonitorEnhanced::CheckIfTPHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double tp)
{
   if(signalType == SIGNAL_BUY)
      return (currentPrice >= tp);
   else // SIGNAL_SELL
      return (currentPrice <= tp);
}

//+------------------------------------------------------------------+
//| Check if SL was hit                                              |
//+------------------------------------------------------------------+
bool CPerformanceMonitorEnhanced::CheckIfSLHit(string symbol, ENUM_SIGNAL_TYPE signalType, double currentPrice, double sl)
{
   if(signalType == SIGNAL_BUY)
      return (currentPrice <= sl);
   else // SIGNAL_SELL
      return (currentPrice >= sl);
}

//+------------------------------------------------------------------+
//| Find track index by symbol and signal time                        |
//+------------------------------------------------------------------+
int CPerformanceMonitorEnhanced::FindTrackIndex(string symbol, datetime signalTime)
{
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].symbol == symbol && m_tracks[i].signalTime == signalTime)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Update track                                                     |
//+------------------------------------------------------------------+
void CPerformanceMonitorEnhanced::UpdateTrack(int index)
{
   if(index < 0 || index >= m_trackCount)
      return;
   
   if(m_tracks[index].isClosed)
      return; // Already closed
   
   // Get current price
   double currentPrice = GetCurrentPrice(m_tracks[index].symbol, m_tracks[index].signalType);
   
   // Calculate current movement
   double currentMovement = CalculatePips(m_tracks[index].symbol, m_tracks[index].entryPrice, 
                                         currentPrice, m_tracks[index].signalType);
   
   // Update maximum drawdown (most negative movement - MAE)
   if(currentMovement < m_tracks[index].maxDrawdown)
   {
      m_tracks[index].maxDrawdown = currentMovement;
   }
   
   // Update maximum favorable excursion (best positive movement - MFE)
   if(currentMovement > m_tracks[index].maxFavorable)
   {
      m_tracks[index].maxFavorable = currentMovement;
   }
   
   // Update price movement
   m_tracks[index].priceMovement = currentMovement;
   
   // Calculate bars elapsed
   datetime currentTime = TimeCurrent();
   int timeDiff = (int)(currentTime - m_tracks[index].signalTime);
   if(m_tracks[index].timeframe == PERIOD_M5)
      m_tracks[index].barsToClose = timeDiff / 300;
   else if(m_tracks[index].timeframe == PERIOD_M15)
      m_tracks[index].barsToClose = timeDiff / 900;
   else if(m_tracks[index].timeframe == PERIOD_H1)
      m_tracks[index].barsToClose = timeDiff / 3600;
   else
      m_tracks[index].barsToClose = timeDiff / 300;
   
   // Calculate quality score
   m_tracks[index].qualityScore = CalculateQualityScore(m_tracks[index].symbol, m_tracks[index].signalType,
                                                        m_tracks[index].entryPrice, currentPrice,
                                                        m_tracks[index].takeProfit1, m_tracks[index].barsToClose, 
                                                        m_tracks[index].qualityBars);
   
   // Check if TP1 was hit
   if(CheckIfTPHit(m_tracks[index].symbol, m_tracks[index].signalType, currentPrice, m_tracks[index].takeProfit1))
   {
      m_tracks[index].isClosed = true;
      m_tracks[index].isWin = true;
      m_tracks[index].closePrice = currentPrice;
      m_tracks[index].closedAtTP = true;
      m_tracks[index].closedAtSL = false;
      return;
   }
   
   // Check if SL was hit
   if(CheckIfSLHit(m_tracks[index].symbol, m_tracks[index].signalType, currentPrice, m_tracks[index].stopLoss))
   {
      m_tracks[index].isClosed = true;
      m_tracks[index].isWin = false;
      m_tracks[index].closePrice = currentPrice;
      m_tracks[index].closedAtTP = false;
      m_tracks[index].closedAtSL = true;
      return;
   }
}

//+------------------------------------------------------------------+
//| Register signal for performance tracking                          |
//+------------------------------------------------------------------+
void CPerformanceMonitorEnhanced::RegisterSignal(string symbol, ENUM_SIGNAL_TYPE signalType, datetime signalTime,
                                                double entryPrice, double stopLoss, double takeProfit1, double takeProfit2,
                                                ENUM_TIMEFRAMES timeframe, int qualityBars)
{
   int index = m_trackCount;
   ArrayResize(m_tracks, m_trackCount + 1);
   
   m_tracks[index].signalTime = signalTime;
   m_tracks[index].symbol = symbol;
   m_tracks[index].signalType = signalType;
   m_tracks[index].entryPrice = entryPrice;
   m_tracks[index].stopLoss = stopLoss;
   m_tracks[index].takeProfit1 = takeProfit1;
   m_tracks[index].takeProfit2 = takeProfit2;
   m_tracks[index].timeframe = timeframe;
   m_tracks[index].qualityBars = qualityBars;
   m_tracks[index].isClosed = false;
   m_tracks[index].isWin = false;
   m_tracks[index].closePrice = 0.0;
   m_tracks[index].maxDrawdown = 0.0;
   m_tracks[index].maxFavorable = 0.0;
   m_tracks[index].priceMovement = 0.0;
   m_tracks[index].qualityScore = 0.0;
   m_tracks[index].barsToClose = 0;
   m_tracks[index].closedAtTP = false;
   m_tracks[index].closedAtSL = false;
   
   m_trackCount++;
}

//+------------------------------------------------------------------+
//| Update all active tracks                                         |
//+------------------------------------------------------------------+
void CPerformanceMonitorEnhanced::UpdateTracks()
{
   for(int i = 0; i < m_trackCount; i++)
   {
      if(!m_tracks[i].isClosed)
      {
         UpdateTrack(i);
      }
   }
}

//+------------------------------------------------------------------+
//| Get Win/Loss ratio                                               |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetWinLossRatio()
{
   int wins = GetWins();
   int losses = GetLosses();
   
   if(losses == 0)
   {
      if(wins > 0)
         return 999.99; // Infinite ratio
      else
         return 0.0;
   }
   
   return (double)wins / losses;
}

//+------------------------------------------------------------------+
//| Get total trades                                                 |
//+------------------------------------------------------------------+
int CPerformanceMonitorEnhanced::GetTotalTrades()
{
   int count = 0;
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get wins count                                                   |
//+------------------------------------------------------------------+
int CPerformanceMonitorEnhanced::GetWins()
{
   int count = 0;
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].isWin)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get losses count                                                 |
//+------------------------------------------------------------------+
int CPerformanceMonitorEnhanced::GetLosses()
{
   int count = 0;
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && !m_tracks[i].isWin)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get win rate                                                     |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetWinRate()
{
   int total = GetTotalTrades();
   if(total == 0)
      return 0.0;
   
   int wins = GetWins();
   return (double)wins / total * 100.0;
}

//+------------------------------------------------------------------+
//| Get average quality score                                        |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageQualityScore()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         count++;
         total += m_tracks[i].qualityScore;
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get average quality score for wins                               |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageQualityScore_Wins()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].isWin)
      {
         count++;
         total += m_tracks[i].qualityScore;
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get average quality score for losses                             |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageQualityScore_Losses()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && !m_tracks[i].isWin)
      {
         count++;
         total += m_tracks[i].qualityScore;
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get minimum quality score                                        |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetMinQualityScore()
{
   double minScore = 100.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].qualityScore < minScore)
         minScore = m_tracks[i].qualityScore;
   }
   
   if(minScore == 100.0)
      return 0.0;
   
   return minScore;
}

//+------------------------------------------------------------------+
//| Get maximum quality score                                        |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetMaxQualityScore()
{
   double maxScore = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].qualityScore > maxScore)
         maxScore = m_tracks[i].qualityScore;
   }
   
   return maxScore;
}

//+------------------------------------------------------------------+
//| Get average maximum drawdown                                     |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageMaxDrawdown()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         count++;
         total += MathAbs(m_tracks[i].maxDrawdown);
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get average maximum drawdown for wins                            |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageMaxDrawdown_Wins()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].isWin)
      {
         count++;
         total += MathAbs(m_tracks[i].maxDrawdown);
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get average maximum drawdown for losses                          |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageMaxDrawdown_Losses()
{
   int count = 0;
   double total = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && !m_tracks[i].isWin)
      {
         count++;
         total += MathAbs(m_tracks[i].maxDrawdown);
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return total / count;
}

//+------------------------------------------------------------------+
//| Get maximum drawdown                                             |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetMaxDrawdown()
{
   double maxDD = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         double dd = MathAbs(m_tracks[i].maxDrawdown);
         if(dd > maxDD)
            maxDD = dd;
      }
   }
   
   return maxDD;
}

//+------------------------------------------------------------------+
//| Get minimum drawdown                                             |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetMinDrawdown()
{
   double minDD = 999999.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         double dd = MathAbs(m_tracks[i].maxDrawdown);
         if(dd < minDD)
            minDD = dd;
      }
   }
   
   if(minDD == 999999.0)
      return 0.0;
   
   return minDD;
}

//+------------------------------------------------------------------+
//| Get SL hit rate                                                  |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetSLHitRate()
{
   int total = GetTotalTrades();
   if(total == 0)
      return 0.0;
   
   int slHits = 0;
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed && m_tracks[i].closedAtSL)
         slHits++;
   }
   
   return (double)slHits / total * 100.0;
}

//+------------------------------------------------------------------+
//| Get average drawdown as percentage of SL                         |
//+------------------------------------------------------------------+
double CPerformanceMonitorEnhanced::GetAverageDrawdownToSL()
{
   int count = 0;
   double totalPercent = 0.0;
   
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         // Calculate SL distance in pips
         double slDistance = MathAbs(CalculatePips(m_tracks[i].symbol, m_tracks[i].entryPrice, 
                                                   m_tracks[i].stopLoss, m_tracks[i].signalType));
         
         if(slDistance > 0)
         {
            double drawdownPips = MathAbs(m_tracks[i].maxDrawdown);
            double percent = (drawdownPips / slDistance) * 100.0;
            totalPercent += percent;
            count++;
         }
      }
   }
   
   if(count == 0)
      return 0.0;
   
   return totalPercent / count;
}

//+------------------------------------------------------------------+
//| Check if SL is set correctly                                     |
//+------------------------------------------------------------------+
bool CPerformanceMonitorEnhanced::IsSLSetCorrectly()
{
   double avgDrawdownToSL = GetAverageDrawdownToSL();
   double slHitRate = GetSLHitRate();
   
   // SL is set correctly if:
   // 1. Average drawdown is less than 80% of SL (gives room)
   // 2. SL hit rate is reasonable (not too high, not too low)
   
   bool condition1 = (avgDrawdownToSL < 80.0); // Average drawdown < 80% of SL
   bool condition2 = (slHitRate > 10.0 && slHitRate < 40.0); // SL hit rate 10-40%
   
   return (condition1 && condition2);
}

//+------------------------------------------------------------------+
//| Get performance report string                                    |
//+------------------------------------------------------------------+
string CPerformanceMonitorEnhanced::GetPerformanceReportString()
{
   int total = GetTotalTrades();
   int wins = GetWins();
   int losses = GetLosses();
   double winRate = GetWinRate();
   double winLossRatio = GetWinLossRatio();
   
   double avgQuality = GetAverageQualityScore();
   double avgQuality_Wins = GetAverageQualityScore_Wins();
   double avgQuality_Losses = GetAverageQualityScore_Losses();
   double minQuality = GetMinQualityScore();
   double maxQuality = GetMaxQualityScore();
   
   double avgDrawdown = GetAverageMaxDrawdown();
   double avgDrawdown_Wins = GetAverageMaxDrawdown_Wins();
   double avgDrawdown_Losses = GetAverageMaxDrawdown_Losses();
   double maxDrawdown = GetMaxDrawdown();
   double minDrawdown = GetMinDrawdown();
   
   double slHitRate = GetSLHitRate();
   double avgDrawdownToSL = GetAverageDrawdownToSL();
   bool slCorrect = IsSLSetCorrectly();
   
   string report = "";
   report += "╔═══════════════════════════════════════════════════════════════╗\n";
   report += "║         COMPREHENSIVE PERFORMANCE MONITOR REPORT              ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ WIN/LOSS RATIO                                                 ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Total Trades: %d (Wins: %d, Losses: %d)                    ║\n", total, wins, losses);
   report += StringFormat("║ Win Rate: %.2f%%                                          ║\n", winRate);
   report += StringFormat("║ Win/Loss Ratio: %.2f:1                                    ║\n", winLossRatio);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ SIGNAL QUALITY SCORE (0-100)                                   ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Average Quality Score: %.2f/100                            ║\n", avgQuality);
   report += StringFormat("║ Average Quality (Wins): %.2f/100                          ║\n", avgQuality_Wins);
   report += StringFormat("║ Average Quality (Losses): %.2f/100                        ║\n", avgQuality_Losses);
   report += StringFormat("║ Quality Range: %.2f - %.2f                              ║\n", minQuality, maxQuality);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ MAXIMUM DRAWDOWN PER TRADE                                     ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ Average Max Drawdown: %.2f pips                           ║\n", avgDrawdown);
   report += StringFormat("║ Average Drawdown (Wins): %.2f pips                       ║\n", avgDrawdown_Wins);
   report += StringFormat("║ Average Drawdown (Losses): %.2f pips                     ║\n", avgDrawdown_Losses);
   report += StringFormat("║ Drawdown Range: %.2f - %.2f pips                       ║\n", minDrawdown, maxDrawdown);
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += "║ STOP LOSS ANALYSIS                                              ║\n";
   report += "╠═══════════════════════════════════════════════════════════════╣\n";
   report += StringFormat("║ SL Hit Rate: %.2f%%                                      ║\n", slHitRate);
   report += StringFormat("║ Avg Drawdown as %% of SL: %.2f%%                        ║\n", avgDrawdownToSL);
   if(slCorrect)
      report += "║ ✅ SL is set correctly                                            ║\n";
   else
      report += "║ ⚠ SL may need adjustment - review drawdown patterns              ║\n";
   report += "╚═══════════════════════════════════════════════════════════════╝\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Print performance report                                         |
//+------------------------------------------------------------------+
void CPerformanceMonitorEnhanced::PrintPerformanceReport()
{
   string report = GetPerformanceReportString();
   Print(report);
}

//+------------------------------------------------------------------+
//| Get CSV header                                                   |
//+------------------------------------------------------------------+
string CPerformanceMonitorEnhanced::GetCSVHeader()
{
   return "Signal_Time,Type,MFE_Pips,MAE_Pips,Trade_Result,Final_Score";
}

//+------------------------------------------------------------------+
//| Get CSV row for specific track                                   |
//+------------------------------------------------------------------+
string CPerformanceMonitorEnhanced::GetCSVRow(int index)
{
   if(index < 0 || index >= m_trackCount)
      return "";
   
   if(!m_tracks[index].isClosed)
      return ""; // Only export closed trades
   
   string row = "";
   
   // Signal_Time
   row += TimeToString(m_tracks[index].signalTime, TIME_DATE|TIME_MINUTES);
   row += ",";
   
   // Type (Buy/Sell)
   if(m_tracks[index].signalType == SIGNAL_BUY)
      row += "Buy";
   else if(m_tracks[index].signalType == SIGNAL_SELL)
      row += "Sell";
   else
      row += "None";
   row += ",";
   
   // MFE_Pips (Maximum Favorable Excursion)
   row += DoubleToString(m_tracks[index].maxFavorable, 2);
   row += ",";
   
   // MAE_Pips (Maximum Adverse Excursion - use absolute value)
   row += DoubleToString(MathAbs(m_tracks[index].maxDrawdown), 2);
   row += ",";
   
   // Trade_Result
   if(m_tracks[index].isWin)
      row += "Win";
   else
      row += "Loss";
   row += ",";
   
   // Final_Score (Signal Quality Score)
   row += DoubleToString(m_tracks[index].qualityScore, 2);
   
   return row;
}

//+------------------------------------------------------------------+
//| Export performance data to CSV                                   |
//+------------------------------------------------------------------+
bool CPerformanceMonitorEnhanced::ExportToCSV(string filename)
{
   // Open file for writing (append mode)
   int fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON, ',');
   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to open CSV file for writing: ", filename);
      return false;
   }
   
   // Write header (only if file is new/empty)
   if(FileSize(fileHandle) == 0)
   {
      FileWrite(fileHandle, "Signal_Time", "Type", "MFE_Pips", "MAE_Pips", "Trade_Result", "Final_Score");
   }
   
   // Write all closed trades
   int rowsWritten = 0;
   for(int i = 0; i < m_trackCount; i++)
   {
      if(m_tracks[i].isClosed)
      {
         // Signal_Time
         string signalTime = TimeToString(m_tracks[i].signalTime, TIME_DATE|TIME_MINUTES);
         
         // Type
         string type = "";
         if(m_tracks[i].signalType == SIGNAL_BUY)
            type = "Buy";
         else if(m_tracks[i].signalType == SIGNAL_SELL)
            type = "Sell";
         else
            type = "None";
         
         // MFE_Pips
         string mfePips = DoubleToString(m_tracks[i].maxFavorable, 2);
         
         // MAE_Pips (absolute value)
         string maePips = DoubleToString(MathAbs(m_tracks[i].maxDrawdown), 2);
         
         // Trade_Result
         string tradeResult = m_tracks[i].isWin ? "Win" : "Loss";
         
         // Final_Score
         string finalScore = DoubleToString(m_tracks[i].qualityScore, 2);
         
         // Write row
         FileWrite(fileHandle, signalTime, type, mfePips, maePips, tradeResult, finalScore);
         rowsWritten++;
      }
   }
   
   FileClose(fileHandle);
   
   if(rowsWritten > 0)
   {
      Print("Exported ", rowsWritten, " performance records to ", filename);
      return true;
   }
   else
   {
      Print("No closed trades to export to CSV");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Cleanup old tracks                                               |
//+------------------------------------------------------------------+
void CPerformanceMonitorEnhanced::CleanupOldTracks(int maxAgeHours = 24)
{
   datetime cutoffTime = TimeCurrent() - maxAgeHours * 3600;
   
   for(int i = m_trackCount - 1; i >= 0; i--)
   {
      if(m_tracks[i].signalTime < cutoffTime && m_tracks[i].isClosed)
      {
         // Remove this track
         for(int j = i; j < m_trackCount - 1; j++)
         {
            m_tracks[j] = m_tracks[j + 1];
         }
         m_trackCount--;
      }
   }
   
   ArrayResize(m_tracks, m_trackCount);
}

//+------------------------------------------------------------------+

