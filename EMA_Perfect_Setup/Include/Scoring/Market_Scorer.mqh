//+------------------------------------------------------------------+
//| Market_Scorer.mqh                                                |
//| Category 5: Market Conditions Scoring (10 points max)          |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Market Conditions Scorer Class                                   |
//+------------------------------------------------------------------+
class CMarketScorer
{
private:
   double m_maxSpread;
   
   int ScoreSpread(string symbol);
   int ScoreVolume(string symbol);
   
public:
   CMarketScorer(double maxSpread);
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketScorer::CMarketScorer(double maxSpread)
{
   m_maxSpread = maxSpread;
}

//+------------------------------------------------------------------+
//| Calculate Market Conditions Score (max 10 points)               |
//+------------------------------------------------------------------+
int CMarketScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // Spread (max 5 points)
   score += ScoreSpread(symbol);
   
   // Volume/Momentum (max 5 points)
   score += ScoreVolume(symbol);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score Spread (max 5 points)                                      |
//+------------------------------------------------------------------+
int CMarketScorer::ScoreSpread(string symbol)
{
   double spread = GetSpreadPips(symbol);
   
   if(spread > m_maxSpread)
      return 0;  // Reject signal if spread too high
   else if(spread < MAX_SPREAD_EXCELLENT)
      return 5;  // <1.5 pips: 5 points
   else if(spread <= MAX_SPREAD_GOOD)
      return 3;  // 1.5-2.5 pips: 3 points
   else
      return 0;  // >2.5 pips: 0 points (reject)
}

//+------------------------------------------------------------------+
//| Score Volume/Momentum (max 5 points)                            |
//+------------------------------------------------------------------+
int CMarketScorer::ScoreVolume(string symbol)
{
   long volumes[];
   if(CopyTickVolume(symbol, PERIOD_M5, 0, 3, volumes) < 3)
      return 0;
   
   long currentVolume = volumes[0];
   long avgVolume = (volumes[1] + volumes[2]) / 2;
   
   if(avgVolume == 0) return 3; // Default to average if no data
   
   double volumeRatio = (double)currentVolume / avgVolume;
   
   if(volumeRatio > 1.5)
      return 5;  // High volume on crossover: 5 points
   else if(volumeRatio > 0.8)
      return 3;  // Average volume: 3 points
   else
      return 0;  // Low volume: 0 points
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CMarketScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   string breakdown = "MARKET:\n";
   
   // OPTIMIZATION: Calculate scores once and reuse
   int spreadScore = ScoreSpread(symbol);
   int volScore = ScoreVolume(symbol);
   
   // Get spread for display (ScoreSpread already calculated it)
   double spread = GetSpreadPips(symbol);
   
   // Format spread score (reuse calculated value)
   if(spreadScore == 5)
      breakdown += "✓ Low spread (" + DoubleToString(spread, 1) + "): +5\n";
   else if(spreadScore == 3)
      breakdown += "~ Moderate spread (" + DoubleToString(spread, 1) + "): +3\n";
   else
      breakdown += "✗ High spread (" + DoubleToString(spread, 1) + "): +0\n";
   
   // Format volume score (reuse calculated value)
   if(volScore == 5)
      breakdown += "✓ High volume: +5\n";
   else if(volScore == 3)
      breakdown += "~ Average volume: +3\n";
   else
      breakdown += "~ Low volume: +0\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

