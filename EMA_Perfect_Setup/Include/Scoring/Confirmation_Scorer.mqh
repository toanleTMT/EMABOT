//+------------------------------------------------------------------+
//| Confirmation_Scorer.mqh                                          |
//| Category 4: Confirmation Scoring (15 points max)                |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/RSI_Manager.mqh"

//+------------------------------------------------------------------+
//| Confirmation Scorer Class                                        |
//+------------------------------------------------------------------+
class CConfirmationScorer
{
private:
   CRSIManager *m_rsi;
   int m_minCandleBody;
   
   int ScoreCandleStrength(string symbol);
   int ScoreRSIConfirmation(string symbol, ENUM_SIGNAL_TYPE signalType);
   
public:
   CConfirmationScorer(CRSIManager *rsi, int minCandleBody);
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CConfirmationScorer::CConfirmationScorer(CRSIManager *rsi, int minCandleBody)
{
   m_rsi = rsi;
   m_minCandleBody = minCandleBody;
}

//+------------------------------------------------------------------+
//| Calculate Confirmation Score (max 15 points)                     |
//+------------------------------------------------------------------+
int CConfirmationScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // Candle Strength (max 8 points)
   score += ScoreCandleStrength(symbol);
   
   // RSI Confirmation (max 7 points)
   score += ScoreRSIConfirmation(symbol, signalType);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score Candle Strength (max 8 points)                            |
//+------------------------------------------------------------------+
int CConfirmationScorer::ScoreCandleStrength(string symbol)
{
   double open = iOpen(symbol, PERIOD_M5, 0);
   double close = iClose(symbol, PERIOD_M5, 0);
   double high = iHigh(symbol, PERIOD_M5, 0);
   double low = iLow(symbol, PERIOD_M5, 0);
   
   double bodySize = MathAbs(close - open);
   double candleRange = high - low;
   
   if(candleRange == 0) return 0;
   
   double bodyPercent = (bodySize / candleRange) * 100.0;
   
   if(bodyPercent >= MIN_CANDLE_BODY_STRONG)
      return 8;  // Strong body (>70%): 8 points
   else if(bodyPercent >= MIN_CANDLE_BODY_MODERATE)
      return 5;  // Moderate body (50-70%): 5 points
   else
      return 2;  // Weak body (<50%): 2 points
}

//+------------------------------------------------------------------+
//| Score RSI Confirmation (max 7 points)                           |
//+------------------------------------------------------------------+
int CConfirmationScorer::ScoreRSIConfirmation(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   double rsi;
   if(!m_rsi.GetRSIValue(symbol, rsi))
      return 0;
   
   if(signalType == SIGNAL_BUY)
   {
      if(rsi > RSI_STRONG_BUY)
         return 7;  // Strongly favorable (>60): 7 points
      else if(rsi > RSI_MODERATE_BUY)
         return 4;  // Moderately favorable (50-60): 4 points
      else if(rsi >= 45 && rsi <= 55)
         return 0;  // Neutral (45-55): 0 points
      else
         return 0;  // Unfavorable: 0 points
   }
   else if(signalType == SIGNAL_SELL)
   {
      if(rsi < RSI_STRONG_SELL)
         return 7;  // Strongly favorable (<40): 7 points
      else if(rsi < RSI_MODERATE_SELL)
         return 4;  // Moderately favorable (40-50): 4 points
      else if(rsi >= 45 && rsi <= 55)
         return 0;  // Neutral (45-55): 0 points
      else
         return 0;  // Unfavorable: 0 points
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CConfirmationScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   string breakdown = "CONFIRMATION:\n";
   
   // OPTIMIZATION: Calculate scores once and reuse
   int candleScore = ScoreCandleStrength(symbol);
   int rsiScore = ScoreRSIConfirmation(symbol, signalType);
   
   // Calculate candle body percentage (needed for display)
   double open = iOpen(symbol, PERIOD_M5, 0);
   double close = iClose(symbol, PERIOD_M5, 0);
   double high = iHigh(symbol, PERIOD_M5, 0);
   double low = iLow(symbol, PERIOD_M5, 0);
   double bodySize = MathAbs(close - open);
   double candleRange = high - low;
   double bodyPercent = candleRange > 0 ? (bodySize / candleRange) * 100.0 : 0;
   
   // Format candle score (reuse calculated value)
   if(candleScore == 8)
      breakdown += "✓ Strong candle (" + DoubleToString(bodyPercent, 1) + "%): +8\n";
   else if(candleScore == 5)
      breakdown += "~ Moderate candle (" + DoubleToString(bodyPercent, 1) + "%): +5\n";
   else
      breakdown += "~ Weak candle (" + DoubleToString(bodyPercent, 1) + "%): +2\n";
   
   // Get RSI value for display (ScoreRSIConfirmation already fetched it, but we need it again for display)
   double rsi;
   if(!m_rsi.GetRSIValue(symbol, rsi))
      rsi = 50.0; // Default if unavailable
   
   // Format RSI score (reuse calculated value)
   if(rsiScore == 7)
      breakdown += "✓ RSI strongly favorable (" + DoubleToString(rsi, 1) + "): +7\n";
   else if(rsiScore == 4)
      breakdown += "~ RSI moderate (" + DoubleToString(rsi, 1) + "): +4\n";
   else
      breakdown += "~ RSI neutral (" + DoubleToString(rsi, 1) + "): +0\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

