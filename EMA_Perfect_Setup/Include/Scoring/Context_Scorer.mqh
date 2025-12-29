//+------------------------------------------------------------------+
//| Context_Scorer.mqh                                               |
//| Category 6: Context & Timing Scoring (10 points max)            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/Time_Utils.mqh"

//+------------------------------------------------------------------+
//| Context & Timing Scorer Class                                    |
//+------------------------------------------------------------------+
class CContextScorer
{
private:
   int ScoreTradingSession();
   int ScoreSupportResistance(string symbol);
   
public:
   CContextScorer();
   
   int CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CContextScorer::CContextScorer()
{
}

//+------------------------------------------------------------------+
//| Calculate Context & Timing Score (max 10 points)                  |
//+------------------------------------------------------------------+
int CContextScorer::CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   int score = 0;
   
   // Trading Session (max 5 points)
   score += ScoreTradingSession();
   
   // M15 S/R Level (max 5 points)
   score += ScoreSupportResistance(symbol);
   
   return score;
}

//+------------------------------------------------------------------+
//| Score Trading Session (max 5 points)                             |
//+------------------------------------------------------------------+
int CContextScorer::ScoreTradingSession()
{
   return GetTradingSessionScore();
}

//+------------------------------------------------------------------+
//| Score Support/Resistance Level (max 5 points)                    |
//+------------------------------------------------------------------+
int CContextScorer::ScoreSupportResistance(string symbol)
{
   // Simple S/R detection: check if price is near recent highs/lows on M15
   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if(CopyHigh(symbol, PERIOD_M15, 0, 20, high) < 20) return 2;
   if(CopyLow(symbol, PERIOD_M15, 0, 20, low) < 20) return 2;
   if(CopyClose(symbol, PERIOD_M15, 0, 1, close) < 1) return 2;
   
   double currentPrice = close[0];
   double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5)
      pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   // Find recent high/low
   double recentHigh = high[ArrayMaximum(high, 0, 10)];
   double recentLow = low[ArrayMinimum(low, 0, 10)];
   
   // Check if price is near S/R (within 10 pips)
   double threshold = 10 * pipValue;
   
   if(MathAbs(currentPrice - recentHigh) < threshold || 
      MathAbs(currentPrice - recentLow) < threshold)
      return 5;  // At key S/R level: 5 points
   else
      return 2;  // No clear level: 2 points
}

//+------------------------------------------------------------------+
//| Get score breakdown text                                         |
//+------------------------------------------------------------------+
string CContextScorer::GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int score)
{
   string breakdown = "CONTEXT:\n";
   
   // OPTIMIZATION: Calculate scores once and reuse
   int sessionScore = ScoreTradingSession();
   int srScore = ScoreSupportResistance(symbol);
   
   // Format trading session score (reuse calculated value)
   if(sessionScore == 5)
      breakdown += "✓ London-NY overlap: +5\n";
   else if(sessionScore == 3)
      breakdown += "~ London or NY session: +3\n";
   else
      breakdown += "~ Asian session: +0\n";
   
   // Format support/resistance score (reuse calculated value)
   if(srScore == 5)
      breakdown += "✓ At key S/R level: +5\n";
   else
      breakdown += "~ No clear S/R: +2\n";
   
   return breakdown;
}

//+------------------------------------------------------------------+

