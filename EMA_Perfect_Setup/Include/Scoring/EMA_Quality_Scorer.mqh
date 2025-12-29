//+------------------------------------------------------------------+
//| EMA_Quality_Scorer.mqh                                           |
//| Category 2: M5 EMA Quality Scoring (20 points max)              |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| EMA Quality Scorer Class                                         |
//+------------------------------------------------------------------+
class CEMAQualityScorer
{
private:
   CEMAManager *m_emaM5;
   int m_minSeparation;
   
   int ScoreEMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType);
   int ScoreEMASeparation(string symbol, ENUM_SIGNAL_TYPE signalType);
   
public:
   CEMAQualityScorer(CEMAManager *emaM5, int minSeparation);
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEMAQualityScorer::CEMAQualityScorer(CEMAManager *emaM5, int minSeparation)
{
   m_emaM5 = emaM5;
   m_minSeparation = minSeparation;
}

//+------------------------------------------------------------------+
//| Calculate EMA Quality Score (max 20 points)                      |
//+------------------------------------------------------------------+
int CEMAQualityScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // EMA Alignment (max 10 points)
   score += ScoreEMAAlignment(symbol, signalType);
   
   // EMA Separation (max 10 points)
   score += ScoreEMASeparation(symbol, signalType);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score EMA Alignment (max 10 points)                              |
//+------------------------------------------------------------------+
int CEMAQualityScorer::ScoreEMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   // Optimized: Check alignment first (cheaper than separation calculation)
   bool perfectOrder = false;
   
   if(signalType == SIGNAL_BUY)
   {
      perfectOrder = (emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]);
   }
   else if(signalType == SIGNAL_SELL)
   {
      perfectOrder = (emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]);
   }
   else
   {
      return 0; // Invalid signal type
   }
   
   // Early exit: If not aligned, return 0 immediately
   if(!perfectOrder)
      return 0;  // Tangled: 0 points
   
   // Only calculate separation if alignment is correct (optimization)
   double separation = m_emaM5.GetEMASeparation(symbol, PERIOD_M5);
   if(separation < m_minSeparation)
      return 6;  // Correct order but tight: 6 points
   else
      return 10; // Perfect order with no tangles: 10 points
}

//+------------------------------------------------------------------+
//| Score EMA Separation (max 10 points)                             |
//+------------------------------------------------------------------+
int CEMAQualityScorer::ScoreEMASeparation(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double separation = m_emaM5.GetEMASeparation(symbol, PERIOD_M5);
   
   if(separation >= MIN_EMA_SEPARATION_WIDE)
      return 10;  // Wide separation (>15 pips): 10 points
   else if(separation >= MIN_EMA_SEPARATION_MODERATE)
      return 6;   // Moderate (8-15 pips): 6 points
   else if(separation >= m_minSeparation)
      return 2;   // Tight (<8 pips): 2 points
   else
      return 0;   // Tangled: 0 points
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CEMAQualityScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   string breakdown = "M5 EMA QUALITY:\n";
   
   // OPTIMIZATION: Calculate scores once and reuse
   int alignmentScore = ScoreEMAAlignment(symbol, signalType);
   double separation = m_emaM5.GetEMASeparation(symbol, PERIOD_M5);
   int sepScore = ScoreEMASeparation(symbol, signalType);
   
   // Format alignment score
   if(alignmentScore == 10)
      breakdown += "✓ Perfect alignment: +10\n";
   else if(alignmentScore == 6)
      breakdown += "~ Correct order but tight: +6\n";
   else
      breakdown += "✗ Tangled: +0\n";
   
   // Format separation score (reuse calculated value)
   if(sepScore == 10)
      breakdown += "✓ Wide separation (" + DoubleToString(separation, 1) + "p): +10\n";
   else if(sepScore == 6)
      breakdown += "~ Moderate separation (" + DoubleToString(separation, 1) + "p): +6\n";
   else if(sepScore == 2)
      breakdown += "~ Tight separation (" + DoubleToString(separation, 1) + "p): +2\n";
   else
      breakdown += "✗ Tangled: +0\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

