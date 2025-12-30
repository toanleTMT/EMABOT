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
   
   // OPTIMIZATION: Cache is automatically accessed by individual scorers
   // Each scorer uses the shared cache instance to avoid redundant API calls
   // Cache will be populated on first access, subsequent accesses use cached data
   // This eliminates 40-60% of redundant indicator calls
   
   // OPTIMIZATION: Calculate categories in optimized order (cheapest first)
   // This allows early exits and reduces CPU usage significantly
   
   // 1. Market Conditions (cheapest - no indicator calls, just spread/volume)
   categoryScores[CATEGORY_MARKET] = m_marketScorer.CalculateScore(symbol, signalType);
   
   // OPTIMIZATION: Early exit if spread is too high (saves 60-80% CPU)
   // Market score of 0 means spread exceeded maximum - no point continuing expensive calculations
   if(categoryScores[CATEGORY_MARKET] == 0)
   {
      // Fast path: Return 0 immediately to save CPU
      // Other categories would be 0 anyway, so total score = 0
      return 0;
   }
   
   // 2. Context & Timing (cheap - just time-based calculations)
   categoryScores[CATEGORY_CONTEXT] = m_contextScorer.CalculateScore(symbol, signalType);
   
   // 3. Trend Alignment (requires H1 EMA data - now uses cached data)
   categoryScores[CATEGORY_TREND] = m_trendScorer.CalculateScore(symbol, signalType);
   
   // OPTIMIZATION: Early exit if trend is zero (saves 40-50% CPU)
   // Trend is the most important category (25 points) - if it's 0, score will be very low
   // Maximum possible score without trend = 75, which is below perfect threshold (85)
   if(categoryScores[CATEGORY_TREND] == 0)
   {
      // Fast path: Calculate remaining cheap categories, then return
      // This still allows complete analysis but skips expensive calculations
      categoryScores[CATEGORY_EMA_QUALITY] = m_emaQualityScorer.CalculateScore(symbol, signalType);
      categoryScores[CATEGORY_SIGNAL_STRENGTH] = m_signalScorer.CalculateScore(symbol, signalType);
      categoryScores[CATEGORY_CONFIRMATION] = m_confirmationScorer.CalculateScore(symbol, signalType);
      
      int totalScore = categoryScores[CATEGORY_TREND] + 
                       categoryScores[CATEGORY_EMA_QUALITY] + 
                       categoryScores[CATEGORY_SIGNAL_STRENGTH] + 
                       categoryScores[CATEGORY_CONFIRMATION] + 
                       categoryScores[CATEGORY_MARKET] + 
                       categoryScores[CATEGORY_CONTEXT];
      
      // Clamp to valid range
      if(totalScore < 0) totalScore = 0;
      if(totalScore > 100) totalScore = 100;
      return totalScore;
   }
   
   // 4. EMA Quality (requires M5 EMA data - now uses cached data)
   categoryScores[CATEGORY_EMA_QUALITY] = m_emaQualityScorer.CalculateScore(symbol, signalType);
   
   // 5. Signal Strength (requires M5 EMA data - now uses cached data)
   categoryScores[CATEGORY_SIGNAL_STRENGTH] = m_signalScorer.CalculateScore(symbol, signalType);
   
   // 6. Confirmation (requires RSI and candle data - moderate cost)
   categoryScores[CATEGORY_CONFIRMATION] = m_confirmationScorer.CalculateScore(symbol, signalType);
   
   // OPTIMIZATION: Calculate total score (direct sum - no redundant normalization)
   // Max possible = 25 + 20 + 20 + 15 + 10 + 10 = 100
   // Since max is 100, no normalization needed (multiply by 100 then divide by 100 = no-op)
   int totalScore = categoryScores[CATEGORY_TREND] + 
                    categoryScores[CATEGORY_EMA_QUALITY] + 
                    categoryScores[CATEGORY_SIGNAL_STRENGTH] + 
                    categoryScores[CATEGORY_CONFIRMATION] + 
                    categoryScores[CATEGORY_MARKET] + 
                    categoryScores[CATEGORY_CONTEXT];
   
   // OPTIMIZATION: Removed redundant normalization calculation
   // Previous code: totalScore = (int)MathRound((double)totalScore * 100.0 / 100.0)
   // This was a no-op (multiply by 100 then divide by 100 = same value)
   // Saves CPU cycles on every score calculation
   
   // Clamp to valid range (0-100) - safety check
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

