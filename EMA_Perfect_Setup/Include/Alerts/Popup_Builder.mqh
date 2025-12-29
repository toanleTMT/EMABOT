//+------------------------------------------------------------------+
//| Popup_Builder.mqh                                                |
//| Builds popup alert windows                                       |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Popup Builder Class                                              |
//+------------------------------------------------------------------+
class CPopupBuilder
{
public:
   static void ShowPerfectSetupPopup(string symbol, int score, ENUM_SIGNAL_TYPE signalType,
                                     double entry, double sl, double tp1, double tp2,
                                     string strengths, string weaknesses);
   static void ShowGoodSetupPopup(string symbol, int score, ENUM_SIGNAL_TYPE signalType);
};

//+------------------------------------------------------------------+
//| Show perfect setup popup                                         |
//+------------------------------------------------------------------+
void CPopupBuilder::ShowPerfectSetupPopup(string symbol, int score, ENUM_SIGNAL_TYPE signalType,
                                         double entry, double sl, double tp1, double tp2,
                                         string strengths, string weaknesses)
{
   string message = "";
   message += "╔══════════════════════════════════════╗\n";
   message += "║   🎯 PERFECT SETUP ALERT! 🎯         ║\n";
   message += "╠══════════════════════════════════════╣\n";
   message += "║                                      ║\n";
   message += "║  Symbol: " + symbol + "\n";
   message += "║  Direction: " + GetSignalTypeString(signalType) + " ";
   message += (signalType == SIGNAL_BUY) ? "📈" : "📉";
   message += "\n";
   message += "║  Quality: 🟢 PERFECT (" + IntegerToString(score) + "/100)\n";
   message += "║                                      ║\n";
   message += "║  ─────────────────────────────────── ║\n";
   message += "║                                      ║\n";
   message += "║  Entry: " + FormatPrice(symbol, entry) + " (Market)\n";
   
   double slPips = PriceToPips(symbol, MathAbs(entry - sl));
   message += "║  Stop Loss: " + FormatPrice(symbol, sl) + " (" + FormatPips(slPips) + ")\n";
   
   double tp1Pips = PriceToPips(symbol, MathAbs(tp1 - entry));
   double tp2Pips = PriceToPips(symbol, MathAbs(tp2 - entry));
   message += "║  Take Profit 1: " + FormatPrice(symbol, tp1) + " (" + FormatPips(tp1Pips) + ")\n";
   message += "║  Take Profit 2: " + FormatPrice(symbol, tp2) + " (" + FormatPips(tp2Pips) + ")\n";
   message += "║                                      ║\n";
   
   double rr = CalculateRiskReward(entry, sl, tp2, signalType);
   message += "║  Risk/Reward: 1:" + DoubleToString(rr, 1) + " ⭐⭐\n";
   message += "║                                      ║\n";
   message += "║  ─────────────────────────────────── ║\n";
   message += "║                                      ║\n";
   message += "║  WHY THIS IS PERFECT:\n";
   
   // Add strengths
   string lines[];
   int count = StringSplit(strengths, '\n', lines);
   for(int i = 0; i < count && i < 5; i++) // Limit to 5 lines
   {
      message += "║  " + lines[i] + "\n";
   }
   
   if(StringLen(weaknesses) > 0)
   {
      message += "║                                      ║\n";
      message += "║  Only Minor Weakness:\n";
      count = StringSplit(weaknesses, '\n', lines);
      for(int i = 0; i < count && i < 2; i++) // Limit to 2 lines
      {
         message += "║  " + lines[i] + "\n";
      }
   }
   
   message += "║                                      ║\n";
   message += "╚══════════════════════════════════════╝\n";
   
   Alert(message);
}

//+------------------------------------------------------------------+
//| Show good setup popup                                            |
//+------------------------------------------------------------------+
void CPopupBuilder::ShowGoodSetupPopup(string symbol, int score, ENUM_SIGNAL_TYPE signalType)
{
   string message = "🟡 Good setup detected (Score: " + IntegerToString(score) + ") but not perfect - Consider carefully";
   Alert(message);
}

//+------------------------------------------------------------------+

