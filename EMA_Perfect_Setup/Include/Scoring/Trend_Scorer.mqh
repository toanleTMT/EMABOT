//+------------------------------------------------------------------+
//| Trend_Scorer.mqh                                                 |
//| Category 1: Trend Alignment Scoring (25 points max)             |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Trend Scorer Class                                               |
//+------------------------------------------------------------------+
class CTrendScorer
{
private:
   CEMAManager *m_emaH1;
   int m_minH1Distance;
   
   int ScoreH1PriceDistance(string symbol, ENUM_SIGNAL_TYPE signalType);
   int ScoreH1EMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType);
   
public:
   CTrendScorer(CEMAManager *emaH1, int minH1Distance);
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTrendScorer::CTrendScorer(CEMAManager *emaH1, int minH1Distance)
{
   m_emaH1 = emaH1;
   m_minH1Distance = minH1Distance;
}

//+------------------------------------------------------------------+
//| Calculate Trend Alignment Score (max 25 points)                 |
//+------------------------------------------------------------------+
int CTrendScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // H1 Price-EMA50 Distance (max 15 points)
   score += ScoreH1PriceDistance(symbol, signalType);
   
   // H1 EMA Alignment (max 10 points)
   score += ScoreH1EMAAlignment(symbol, signalType);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score H1 Price-EMA50 Distance (max 15 points)                   |
//+------------------------------------------------------------------+
int CTrendScorer::ScoreH1PriceDistance(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaH1.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   // Get current price (optimized: single call)
   double price = iClose(symbol, PERIOD_H1, 0);
   double ema50 = emaSlow[0];
   
   // Early exit optimization: Check signal direction first
   if(signalType == SIGNAL_BUY && price <= ema50)
      return 0; // BUY requires price > EMA50
   if(signalType == SIGNAL_SELL && price >= ema50)
      return 0; // SELL requires price < EMA50
   
   // Calculate distance in pips (only if direction is correct)
   double distance = MathAbs(price - ema50);
   double distancePips = PriceToPips(symbol, distance);
   
   // Direction already checked above, now just score distance
   if(distancePips >= MIN_H1_DISTANCE_EXCELLENT)
      return 15;  // ≥50 pips clear: 15 points
   else if(distancePips >= MIN_H1_DISTANCE_GOOD)
      return 10;  // 20-50 pips: 10 points
   else if(distancePips >= m_minH1Distance)
      return 5;   // <20 pips but above minimum: 5 points
   else
      return 0;   // Touching/crossing: 0 points
}

//+------------------------------------------------------------------+
//| Score H1 EMA Alignment (max 10 points)                           |
//+------------------------------------------------------------------+
int CTrendScorer::ScoreH1EMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaH1.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   bool perfectOrder = false;
   bool partialAlignment = false;
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: EMA 9 > EMA 21 > EMA 50
      perfectOrder = (emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]);
      partialAlignment = (emaFast[0] > emaSlow[0]); // At least fast above slow
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: EMA 9 < EMA 21 < EMA 50
      perfectOrder = (emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]);
      partialAlignment = (emaFast[0] < emaSlow[0]); // At least fast below slow
   }
   
   if(perfectOrder)
      return 10;  // Perfect order: 10 points
   else if(partialAlignment)
      return 5;   // Partial alignment: 5 points
   else
      return 0;   // Tangled: 0 points
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CTrendScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaH1.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return "";
   
   // OPTIMIZATION: Calculate values once and reuse
   double price = iClose(symbol, PERIOD_H1, 0);
   double ema50 = emaSlow[0];
   double distancePips = PriceToPips(symbol, MathAbs(price - ema50));
   int priceDistanceScore = ScoreH1PriceDistance(symbol, signalType);
   int alignmentScore = ScoreH1EMAAlignment(symbol, signalType);
   
   string breakdown = "H1 TREND:\n";
   
   // Format price distance score (reuse calculated value)
   if(signalType == SIGNAL_BUY && price > ema50)
   {
      breakdown += "✓ Price " + DoubleToString(distancePips, 1) + " pips above EMA50: +" + 
                   IntegerToString(priceDistanceScore) + "\n";
   }
   else if(signalType == SIGNAL_SELL && price < ema50)
   {
      breakdown += "✓ Price " + DoubleToString(distancePips, 1) + " pips below EMA50: +" + 
                   IntegerToString(priceDistanceScore) + "\n";
   }
   else
   {
      breakdown += "✗ Price not on correct side of EMA50: +0\n";
   }
   
   // Format alignment score (reuse calculated value)
   if(alignmentScore == 10)
      breakdown += "✓ EMAs aligned perfectly: +10\n";
   else if(alignmentScore == 5)
      breakdown += "~ Partial EMA alignment: +5\n";
   else
      breakdown += "✗ EMAs tangled: +0\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

