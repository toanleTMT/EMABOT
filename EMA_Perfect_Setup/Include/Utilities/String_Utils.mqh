//+------------------------------------------------------------------+
//| String_Utils.mqh                                                 |
//| String manipulation utilities                                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Parse comma-separated symbols into array                        |
//+------------------------------------------------------------------+
void ParseSymbols(string input, string &output[])
{
   string temp[];
   int count = StringSplit(input, ',', temp);
   
   ArrayResize(output, count);
   
   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(temp[i]);
      StringTrimRight(temp[i]);
      output[i] = temp[i];
   }
}

//+------------------------------------------------------------------+
//| Format score with quality emoji                                  |
//+------------------------------------------------------------------+
string FormatScore(int score)
{
   if(score >= 85)
      return IntegerToString(score) + "/100 🟢 PERFECT";
   else if(score >= 70)
      return IntegerToString(score) + "/100 🟡 GOOD";
   else if(score >= 50)
      return IntegerToString(score) + "/100 ⚪ WEAK";
   else
      return IntegerToString(score) + "/100 🔴 INVALID";
}

//+------------------------------------------------------------------+
//| Format price with proper digits                                  |
//+------------------------------------------------------------------+
string FormatPrice(string symbol, double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return DoubleToString(price, digits);
}

//+------------------------------------------------------------------+
//| Format pips                                                      |
//+------------------------------------------------------------------+
string FormatPips(double pips)
{
   return DoubleToString(pips, 1) + " pips";
}

//+------------------------------------------------------------------+
//| Create progress bar string                                       |
//+------------------------------------------------------------------+
string CreateProgressBar(int current, int max, int barLength = 5)
{
   string bar = "";
   double percent = (double)current / max;
   int filled = (int)MathRound(percent * barLength);
   
   for(int i = 0; i < filled; i++)
      bar += "█";
   for(int i = filled; i < barLength; i++)
      bar += "░";
   
   return bar;
}

//+------------------------------------------------------------------+
//| Get signal type string                                           |
//+------------------------------------------------------------------+
string GetSignalTypeString(ENUM_SIGNAL_TYPE type)
{
   if(type == SIGNAL_BUY)
      return "BUY";
   else if(type == SIGNAL_SELL)
      return "SELL";
   else
      return "NONE";
}

//+------------------------------------------------------------------+
//| Get quality label                                                |
//+------------------------------------------------------------------+
string GetQualityLabel(int score)
{
   if(score >= 85)
      return "PERFECT";
   else if(score >= 70)
      return "GOOD";
   else if(score >= 50)
      return "WEAK";
   else
      return "INVALID";
}

//+------------------------------------------------------------------+
//| Format datetime for display                                      |
//+------------------------------------------------------------------+
string FormatDateTime(datetime dt)
{
   MqlDateTime mdt;
   TimeToStruct(dt, mdt);
   return StringFormat("%02d:%02d:%02d", mdt.hour, mdt.min, mdt.sec);
}

//+------------------------------------------------------------------+
//| Format date for display                                          |
//+------------------------------------------------------------------+
string FormatDate(datetime dt)
{
   MqlDateTime mdt;
   TimeToStruct(dt, mdt);
   return StringFormat("%04d.%02d.%02d", mdt.year, mdt.mon, mdt.day);
}

//+------------------------------------------------------------------+

