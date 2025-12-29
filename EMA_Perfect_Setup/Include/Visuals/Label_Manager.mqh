//+------------------------------------------------------------------+
//| Label_Manager.mqh                                                |
//| Manages detailed labels on chart                                 |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Label Manager Class                                              |
//+------------------------------------------------------------------+
class CLabelManager
{
private:
   int m_fontSize;
   int m_labelCounter;
   
public:
   CLabelManager(int fontSize);
   
   void DrawDetailedLabel(string symbol, datetime time, double price,
                         int score, int categoryScores[], ENUM_SIGNAL_TYPE signalType,
                         double entry, double sl, double tp1, double tp2);
   void CleanupOldLabels(int keepLastN = 20);
   void DeleteAllLabels();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLabelManager::CLabelManager(int fontSize)
{
   m_fontSize = fontSize;
   m_labelCounter = 0;
}

//+------------------------------------------------------------------+
//| Draw detailed label near arrow                                   |
//+------------------------------------------------------------------+
void CLabelManager::DrawDetailedLabel(string symbol, datetime time, double price,
                                     int score, int categoryScores[], ENUM_SIGNAL_TYPE signalType,
                                     double entry, double sl, double tp1, double tp2,
                                     string strengths = "")
{
   if(signalType == SIGNAL_NONE || score < 85) return; // Only show perfect setups
   
   // Calculate label position - Near arrow but readable
   double labelPrice = price;
   double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5)
      pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   
   if(signalType == SIGNAL_BUY)
   {
      double low = iLow(symbol, PERIOD_CURRENT, 0);
      labelPrice = low - (10 * pipValue); // 10 pips below low for label (below arrow)
   }
   else
   {
      double high = iHigh(symbol, PERIOD_CURRENT, 0);
      labelPrice = high + (10 * pipValue); // 10 pips above high for label (above arrow)
   }
   
   // Build label text - matching specification format exactly
   string labelText = "";
   labelText += "PERFECT SETUP 🟢 " + IntegerToString(score) + "/100\n\n";
   labelText += GetSignalTypeString(signalType) + " Signal\n";
   labelText += "Entry: " + FormatPrice(symbol, entry) + "\n";
   
   double slPips = PriceToPips(symbol, MathAbs(entry - sl));
   labelText += "SL: " + FormatPrice(symbol, sl) + " (-" + FormatPips(slPips) + ")\n";
   
   double tp1Pips = PriceToPips(symbol, MathAbs(tp1 - entry));
   double tp2Pips = PriceToPips(symbol, MathAbs(tp2 - entry));
   labelText += "TP1: " + FormatPrice(symbol, tp1) + " (+" + FormatPips(tp1Pips) + ") [50%]\n";
   labelText += "TP2: " + FormatPrice(symbol, tp2) + " (+" + FormatPips(tp2Pips) + ") [50%]\n";
   
   double rr = CalculateRiskReward(entry, sl, tp2, signalType);
   labelText += "R:R = 1:" + DoubleToString(rr, 1) + "\n\n";
   
   labelText += "SCORE BREAKDOWN:\n";
   labelText += "✓ Trend: " + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25\n";
   labelText += "✓ EMA Quality: " + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20\n";
   labelText += "✓ Signal: " + IntegerToString(categoryScores[CATEGORY_SIGNAL_STRENGTH]) + "/20\n";
   labelText += "✓ Confirmation: " + IntegerToString(categoryScores[CATEGORY_CONFIRMATION]) + "/15\n";
   labelText += "✓ Market: " + IntegerToString(categoryScores[CATEGORY_MARKET]) + "/10\n";
   labelText += "~ Context: " + IntegerToString(categoryScores[CATEGORY_CONTEXT]) + "/10";
   
   // Add "WHY PERFECT" section if strengths provided
   if(StringLen(strengths) > 0)
   {
      labelText += "\n\nWHY PERFECT:\n";
      // Parse strengths and format
      string strengthLines[];
      int count = StringSplit(strengths, '\n', strengthLines);
      for(int i = 0; i < count && i < 5; i++) // Limit to 5 lines
      {
         if(StringFind(strengthLines[i], "•") >= 0 || StringFind(strengthLines[i], "STRENGTHS:") < 0)
            labelText += strengthLines[i] + "\n";
      }
   }
   
   // Add suggested lot size if auto lot size enabled
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(accountBalance > 0)
   {
      double suggestedLot = CalculateLotSize(symbol, entry, sl, 1.0, accountBalance);
      labelText += "\nSuggested Lot: " + DoubleToString(suggestedLot, 2) + " (1% risk)";
   }
   
   // Create unique object name
   string objName = PREFIX_LABEL + symbol + "_" + IntegerToString(time) + "_" + IntegerToString(m_labelCounter++);
   
   // Create text label with error handling
   if(ObjectCreate(0, objName, OBJ_TEXT, 0, time, labelPrice))
   {
      ObjectSetString(0, objName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_fontSize);
      ObjectSetString(0, objName, OBJPROP_FONT, "Courier New");
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, objName, OBJPROP_ANCHOR, signalType == SIGNAL_BUY ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER);
      
      // Verify object was created successfully
      if(!CheckError("CreateLabel"))
      {
         Print("WARNING: Failed to create label object: ", objName);
      }
   }
   else
   {
      LogError("CreateLabel", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Cleanup old labels                                               |
//+------------------------------------------------------------------+
void CLabelManager::CleanupOldLabels(int keepLastN = 20)
{
   string names[];
   int count = 0;
   
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PREFIX_LABEL) == 0)
      {
         ArrayResize(names, count + 1);
         names[count++] = name;
      }
   }
   
   // Sort by time
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         datetime time1 = (datetime)ObjectGetInteger(0, names[i], OBJPROP_TIME);
         datetime time2 = (datetime)ObjectGetInteger(0, names[j], OBJPROP_TIME);
         if(time1 < time2)
         {
            string temp = names[i];
            names[i] = names[j];
            names[j] = temp;
         }
      }
   }
   
   // Delete old labels
   for(int i = keepLastN; i < count; i++)
   {
      ObjectDelete(0, names[i]);
   }
}

//+------------------------------------------------------------------+
//| Delete all labels                                                |
//+------------------------------------------------------------------+
void CLabelManager::DeleteAllLabels()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PREFIX_LABEL) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+

