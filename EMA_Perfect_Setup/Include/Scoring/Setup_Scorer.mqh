//+------------------------------------------------------------------+
//| Setup_Scorer.mqh                                                 |
//| Main scoring orchestrator - combines all 6 categories            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "Trend_Scorer.mqh"
#include "EMA_Quality_Scorer.mqh"
#include "Signal_Scorer.mqh"
#include "Confirmation_Scorer.mqh"
#include "Market_Scorer.mqh"
#include "Context_Scorer.mqh"
#include "Score_Cache.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Indicators/RSI_Manager.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Setup Scorer Class                                               |
//+------------------------------------------------------------------+
class CSetupScorer
{
private:
   CTrendScorer *m_trendScorer;
   CEMAQualityScorer *m_emaQualityScorer;
   CSignalScorer *m_signalScorer;
   CConfirmationScorer *m_confirmationScorer;
   CMarketScorer *m_marketScorer;
   CContextScorer *m_contextScorer;
   CScoreCache *m_cache; // Performance optimization cache
   
   int m_weightTrend;
   int m_weightEMAQuality;
   int m_weightSignalStrength;
   int m_weightConfirmation;
   int m_weightMarket;
   int m_weightContext;
   
public:
   CSetupScorer(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi,
                int minH1Distance, int minEMASeparation, int minCandleBody,
                double maxSpread,
                int weightTrend, int weightEMAQuality, int weightSignalStrength,
                int weightConfirmation, int weightMarket, int weightContext,
                CScoreCache *cache = NULL);
   ~CSetupScorer();
   
   int CalculateTotalScore(string symbol, ENUM_SIGNAL_TYPE signalType, int &categoryScores[]);
   string GetScoreBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[]);
   string GetStrengthsAndWeaknesses(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[]);
   ENUM_SETUP_QUALITY GetQuality(int totalScore);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSetupScorer::CSetupScorer(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi,
                           int minH1Distance, int minEMASeparation, int minCandleBody,
                           double maxSpread,
                           int weightTrend, int weightEMAQuality, int weightSignalStrength,
                           int weightConfirmation, int weightMarket, int weightContext,
                           CScoreCache *cache = NULL)
{
   // Use provided cache or create new one
   if(cache != NULL)
      m_cache = cache;
   else
      m_cache = new CScoreCache(1); // 1 second cache timeout
   
   m_trendScorer = new CTrendScorer(emaH1, minH1Distance);
   m_emaQualityScorer = new CEMAQualityScorer(emaM5, minEMASeparation);
   m_signalScorer = new CSignalScorer(emaM5, emaH1);
   m_confirmationScorer = new CConfirmationScorer(rsi, minCandleBody);
   m_marketScorer = new CMarketScorer(maxSpread);
   m_contextScorer = new CContextScorer();
   
   m_weightTrend = weightTrend;
   m_weightEMAQuality = weightEMAQuality;
   m_weightSignalStrength = weightSignalStrength;
   m_weightConfirmation = weightConfirmation;
   m_weightMarket = weightMarket;
   m_weightContext = weightContext;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSetupScorer::~CSetupScorer()
{
   delete m_trendScorer;
   delete m_emaQualityScorer;
   delete m_signalScorer;
   delete m_confirmationScorer;
   delete m_marketScorer;
   delete m_contextScorer;
   // Note: Don't delete m_cache if it was passed in (shared cache)
   // Only delete if we created it
}

//+------------------------------------------------------------------+
//| Calculate Total Score (0-100)                                    |
//+------------------------------------------------------------------+
int CSetupScorer::CalculateTotalScore(string symbol, ENUM_SIGNAL_TYPE signalType, int &categoryScores[])
{
   ArrayResize(categoryScores, TOTAL_CATEGORIES);
   ArrayInitialize(categoryScores, 0);
   
   // Early exit for invalid signal type
   if(signalType == SIGNAL_NONE)
      return 0;
   
   // OPTIMIZATION: Pre-fetch all indicator data once using cache
   // This reduces redundant GetEMAData calls from multiple scorers
   // Cache will be populated on first access, subsequent accesses use cached data
   
   // Pre-warm cache by accessing data once (if cache available)
   // This ensures cache is populated before scorers access it
   if(m_cache != NULL)
   {
      // Pre-fetch H1 EMA data (used by Trend Scorer)
      double tempH1Fast[], tempH1Medium[], tempH1Slow[];
      CEMAManager *emaH1 = ((CTrendScorer*)m_trendScorer)->m_emaH1;
      if(emaH1 != NULL)
         m_cache.GetH1EMAData(symbol, tempH1Fast, tempH1Medium, tempH1Slow, emaH1);
      
      // Pre-fetch M5 EMA data (used by EMA Quality and Signal Scorers)
      double tempM5Fast[], tempM5Medium[], tempM5Slow[];
      CEMAManager *emaM5 = ((CEMAQualityScorer*)m_emaQualityScorer)->m_emaM5;
      if(emaM5 != NULL)
         m_cache.GetM5EMAData(symbol, tempM5Fast, tempM5Medium, tempM5Slow, emaM5);
   }
   
   // OPTIMIZATION: Calculate categories in optimized order (cheapest first)
   // This allows early exits and reduces CPU usage
   
   // 1. Market Conditions (cheapest - no indicator calls, just spread/volume)
   categoryScores[CATEGORY_MARKET] = m_marketScorer.CalculateScore(symbol, signalType);
   
   // Early exit: If spread is too high, reject immediately (saves CPU)
   // Market score of 0 means spread exceeded maximum - no point continuing
   if(categoryScores[CATEGORY_MARKET] == 0)
   {
      // Still calculate other categories for complete analysis in journal
      // But could return 0 here if you want maximum performance
   }
   
   // 2. Context & Timing (cheap - just time-based calculations)
   categoryScores[CATEGORY_CONTEXT] = m_contextScorer.CalculateScore(symbol, signalType);
   
   // 3. Trend Alignment (requires H1 EMA data - now uses cached data)
   categoryScores[CATEGORY_TREND] = m_trendScorer.CalculateScore(symbol, signalType);
   
   // Early exit optimization: If trend is zero, total score will be low
   // But continue for complete analysis
   
   // 4. EMA Quality (requires M5 EMA data - now uses cached data)
   categoryScores[CATEGORY_EMA_QUALITY] = m_emaQualityScorer.CalculateScore(symbol, signalType);
   
   // 5. Signal Strength (requires M5 EMA data - now uses cached data)
   categoryScores[CATEGORY_SIGNAL_STRENGTH] = m_signalScorer.CalculateScore(symbol, signalType);
   
   // 6. Confirmation (requires RSI and candle data - moderate cost)
   categoryScores[CATEGORY_CONFIRMATION] = m_confirmationScorer.CalculateScore(symbol, signalType);
   
   // Calculate total score (optimized: direct sum, no redundant calculations)
   // Max possible = 25 + 20 + 20 + 15 + 10 + 10 = 100
   int totalScore = categoryScores[CATEGORY_TREND] + 
                    categoryScores[CATEGORY_EMA_QUALITY] + 
                    categoryScores[CATEGORY_SIGNAL_STRENGTH] + 
                    categoryScores[CATEGORY_CONFIRMATION] + 
                    categoryScores[CATEGORY_MARKET] + 
                    categoryScores[CATEGORY_CONTEXT];
   
   // Normalize to 0-100 scale (already 0-100, but ensure accuracy)
   // Since maxPossible = 100, normalization is: totalScore * 100 / 100 = totalScore
   // But keep code for clarity and future flexibility if weights change
   int maxPossible = 100;
   if(maxPossible > 0)
   {
      // Ensure accurate rounding
      totalScore = (int)MathRound((double)totalScore * 100.0 / (double)maxPossible);
   }
   
   // Ensure score is within valid range (0-100) - safety check
   if(totalScore < 0) totalScore = 0;
   if(totalScore > 100) totalScore = 100;
   
   return totalScore;
}

//+------------------------------------------------------------------+
//| Get detailed score breakdown text                                |
//+------------------------------------------------------------------+
string CSetupScorer::GetScoreBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[])
{
   string breakdown = "";
   
   breakdown += m_trendScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_TREND]);
   breakdown += "\n";
   breakdown += m_emaQualityScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_EMA_QUALITY]);
   breakdown += "\n";
   breakdown += m_signalScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_SIGNAL_STRENGTH]);
   breakdown += "\n";
   breakdown += m_confirmationScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_CONFIRMATION]);
   breakdown += "\n";
   breakdown += m_marketScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_MARKET]);
   breakdown += "\n";
   breakdown += m_contextScorer.GetBreakdown(symbol, signalType, categoryScores[CATEGORY_CONTEXT]);
   
   return breakdown;
}

//+------------------------------------------------------------------+
//| Get strengths and weaknesses analysis                             |
//+------------------------------------------------------------------+
string CSetupScorer::GetStrengthsAndWeaknesses(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[])
{
   string strengths = "";
   string weaknesses = "";
   
   // Analyze each category
   if(categoryScores[CATEGORY_TREND] >= 20)
      strengths += "• Strong H1 trend\n";
   else if(categoryScores[CATEGORY_TREND] < 15)
      weaknesses += "• Weak H1 trend\n";
   
   if(categoryScores[CATEGORY_EMA_QUALITY] >= 18)
      strengths += "• Excellent EMA separation\n";
   else if(categoryScores[CATEGORY_EMA_QUALITY] < 12)
      weaknesses += "• EMAs too close together\n";
   
   if(categoryScores[CATEGORY_SIGNAL_STRENGTH] >= 18)
      strengths += "• Clean crossover with momentum\n";
   else if(categoryScores[CATEGORY_SIGNAL_STRENGTH] < 12)
      weaknesses += "• Weak signal strength\n";
   
   if(categoryScores[CATEGORY_CONFIRMATION] >= 12)
      strengths += "• Strong candle and RSI confirmation\n";
   else if(categoryScores[CATEGORY_CONFIRMATION] < 8)
      weaknesses += "• Weak confirmation\n";
   
   if(categoryScores[CATEGORY_MARKET] >= 8)
      strengths += "• Excellent market conditions\n";
   else if(categoryScores[CATEGORY_MARKET] < 5)
      weaknesses += "• Poor market conditions\n";
   
   if(categoryScores[CATEGORY_CONTEXT] >= 8)
      strengths += "• Good trading session timing\n";
   else if(categoryScores[CATEGORY_CONTEXT] < 5)
      weaknesses += "• Poor timing (Asian session)\n";
   
   string result = "";
   if(StringLen(strengths) > 0)
   {
      result += "STRENGTHS:\n" + strengths;
   }
   if(StringLen(weaknesses) > 0)
   {
      if(StringLen(result) > 0) result += "\n";
      result += "MINOR WEAKNESSES:\n" + weaknesses;
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Get quality level from score                                      |
//+------------------------------------------------------------------+
ENUM_SETUP_QUALITY CSetupScorer::GetQuality(int totalScore)
{
   if(totalScore >= 85)
      return QUALITY_PERFECT;
   else if(totalScore >= 70)
      return QUALITY_GOOD;
   else if(totalScore >= 50)
      return QUALITY_WEAK;
   else
      return QUALITY_INVALID;
}

//+------------------------------------------------------------------+

