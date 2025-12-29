//+------------------------------------------------------------------+
//| Signal_Scorer.mqh                                                |
//| Category 3: Signal Strength Scoring (20 points max)            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Signal Strength Scorer Class                                     |
//+------------------------------------------------------------------+
class CSignalScorer
{
private:
   CEMAManager *m_emaM5;
   CEMAManager *m_emaH1;
   
   int ScoreEMACrossover(string symbol, ENUM_SIGNAL_TYPE signalType);
   int ScorePricePosition(string symbol, ENUM_SIGNAL_TYPE signalType);
   
public:
   CSignalScorer(CEMAManager *emaM5, CEMAManager *emaH1);
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalScorer::CSignalScorer(CEMAManager *emaM5, CEMAManager *emaH1)
{
   m_emaM5 = emaM5;
   m_emaH1 = emaH1;
}

//+------------------------------------------------------------------+
//| Calculate Signal Strength Score (max 20 points)                  |
//+------------------------------------------------------------------+
int CSignalScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // EMA Crossover Quality (max 10 points)
   score += ScoreEMACrossover(symbol, signalType);
   
   // Price Position (max 10 points)
   score += ScorePricePosition(symbol, signalType);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score EMA Crossover Quality (max 10 points)                     |
//+------------------------------------------------------------------+
int CSignalScorer::ScoreEMACrossover(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   // Check if crossover occurred
   bool crossed = false;
   if(signalType == SIGNAL_BUY)
      crossed = (emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1]);
   else if(signalType == SIGNAL_SELL)
      crossed = (emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1]);
   
   if(!crossed)
      return 0;
   
   // Check momentum (how strong the cross is)
   double crossStrength = MathAbs(emaFast[0] - emaMedium[0]);
   double pipValue = GetPipValue(symbol);
   double crossStrengthPips = crossStrength / pipValue;
   
   // Check if choppy (rapid crosses back and forth)
   bool choppy = false;
   if(ArraySize(emaFast) >= 3)
   {
      if(signalType == SIGNAL_BUY)
         choppy = (emaFast[2] > emaMedium[2]); // Was already above before
      else
         choppy = (emaFast[2] < emaMedium[2]); // Was already below before
   }
   
   if(choppy)
      return 2;  // Choppy cross: 2 points
   else if(crossStrengthPips > 2.0)
      return 10; // Clean, decisive cross with momentum: 10 points
   else
      return 6;  // Clean but weak momentum: 6 points
}

//+------------------------------------------------------------------+
//| Score Price Position (max 10 points)                             |
//+------------------------------------------------------------------+
int CSignalScorer::ScorePricePosition(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0;
   
   double price = iClose(symbol, PERIOD_M5, 0);
   double ema50 = emaSlow[0];
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: Price AND both EMAs 9,21 clearly above EMA 50
      bool priceAbove = (price > ema50);
      bool ema9Above = (emaFast[0] > ema50);
      bool ema21Above = (emaMedium[0] > ema50);
      
      if(priceAbove && ema9Above && ema21Above)
      {
         // Check if clearly above (not just touching)
         double pipValue = GetPipValue(symbol);
         double minGap = 5 * pipValue; // At least 5 pips clear
         
         if((price - ema50) > minGap && 
            (emaFast[0] - ema50) > minGap && 
            (emaMedium[0] - ema50) > minGap)
            return 10; // All clearly correct side: 10 points
         else
            return 5;  // Only price or only one EMA clear: 5 points
      }
      else
         return 0; // Unclear: 0 points
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: Price AND both EMAs 9,21 clearly below EMA 50
      bool priceBelow = (price < ema50);
      bool ema9Below = (emaFast[0] < ema50);
      bool ema21Below = (emaMedium[0] < ema50);
      
      if(priceBelow && ema9Below && ema21Below)
      {
         // Check if clearly below (not just touching)
         double pipValue = GetPipValue(symbol);
         double minGap = 5 * pipValue; // At least 5 pips clear
         
         if((ema50 - price) > minGap && 
            (ema50 - emaFast[0]) > minGap && 
            (ema50 - emaMedium[0]) > minGap)
            return 10; // All clearly correct side: 10 points
         else
            return 5;  // Only price or only one EMA clear: 5 points
      }
      else
         return 0; // Unclear: 0 points
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CSignalScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   string breakdown = "SIGNAL STRENGTH:\n";
   
   // OPTIMIZATION: Calculate scores once and reuse
   int crossScore = ScoreEMACrossover(symbol, signalType);
   int posScore = ScorePricePosition(symbol, signalType);
   
   // Format crossover score (reuse calculated value)
   if(crossScore == 10)
      breakdown += "✓ Clean decisive cross: +10\n";
   else if(crossScore == 6)
      breakdown += "~ Clean but weak momentum: +6\n";
   else if(crossScore == 2)
      breakdown += "~ Choppy cross: +2\n";
   else
      breakdown += "✗ No crossover: +0\n";
   
   // Format price position score (reuse calculated value)
   if(posScore == 10)
      breakdown += "✓ All above/below EMA50: +10\n";
   else if(posScore == 5)
      breakdown += "~ Partial position: +5\n";
   else
      breakdown += "✗ Unclear position: +0\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

