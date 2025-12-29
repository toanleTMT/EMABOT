//+------------------------------------------------------------------+
//| Dashboard_Helper.mqh                                              |
//| Helper functions for dashboard display                            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Dashboard Helper Functions                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Format recommendation text with entry/SL/TP                      |
//+------------------------------------------------------------------+
string FormatRecommendation(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double sl, double tp1, double tp2)
{
   string rec = "";
   
   if(signalType == SIGNAL_BUY)
      rec += "📈 RECOMMENDATION: BUY\n";
   else if(signalType == SIGNAL_SELL)
      rec += "📉 RECOMMENDATION: SELL\n";
   else
      return "";
   
   rec += "Entry: " + FormatPrice(symbol, entry) + " | SL: " + FormatPrice(symbol, sl) + "\n";
   
   double tp1Pips = PriceToPips(symbol, MathAbs(tp1 - entry));
   double tp2Pips = PriceToPips(symbol, MathAbs(tp2 - entry));
   rec += "TP1: " + FormatPrice(symbol, tp1) + " (+" + FormatPips(tp1Pips) + ") | TP2: " + FormatPrice(symbol, tp2) + " (+" + FormatPips(tp2Pips) + ")\n";
   
   double rr = CalculateRiskReward(entry, sl, tp2, signalType);
   rec += "R:R = 1:" + DoubleToString(rr, 1);
   
   return rec;
}

//+------------------------------------------------------------------+
//| Format discipline check text                                      |
//+------------------------------------------------------------------+
string FormatDisciplineCheck()
{
   string check = "⚠️ DISCIPLINE CHECK:\n";
   check += "□ All conditions verified?\n";
   check += "□ Feeling confident?\n";
   check += "□ Not revenge trading?\n";
   check += "□ Risk calculated?";
   
   return check;
}

//+------------------------------------------------------------------+
//| Calculate quality rate                                            |
//+------------------------------------------------------------------+
double CalculateQualityRate(int perfectToday, int goodToday, int weakToday)
{
   int totalValid = perfectToday + goodToday + weakToday;
   if(totalValid == 0) return 0.0;
   
   return (double)perfectToday / totalValid * 100.0;
}

//+------------------------------------------------------------------+

