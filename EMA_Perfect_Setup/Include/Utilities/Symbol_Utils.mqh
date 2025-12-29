//+------------------------------------------------------------------+
//| Symbol_Utils.mqh                                                 |
//| Symbol-related utility functions                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if symbol is valid and available                           |
//+------------------------------------------------------------------+
bool IsSymbolValid(string symbol)
{
   if(!SymbolSelect(symbol, true))
   {
      Print("WARNING: Symbol ", symbol, " not found in Market Watch");
      return false;
   }
   
   // Check if symbol is tradeable
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
   {
      Print("WARNING: Symbol ", symbol, " is not tradeable");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Normalize symbol name                                           |
//+------------------------------------------------------------------+
string NormalizeSymbol(string symbol)
{
   StringToUpper(symbol);
   StringTrimLeft(symbol);
   StringTrimRight(symbol);
   return symbol;
}

//+------------------------------------------------------------------+
//| Get symbol digits                                                |
//+------------------------------------------------------------------+
int GetSymbolDigits(string symbol)
{
   return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
}

//+------------------------------------------------------------------+
//| Check if market is open for symbol                               |
//+------------------------------------------------------------------+
bool IsMarketOpen(string symbol)
{
   // Check if symbol is tradeable
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
      return false;
   
   // Check if symbol is visible
   if(!SymbolInfoInteger(symbol, SYMBOL_VISIBLE))
      return false;
   
   // Get current time
   datetime current = TimeCurrent();
   
   // Check trading sessions (simplified check)
   // In production, you would check against actual trading session times
   // For forex, market is typically open 24/5 (Sunday 22:00 GMT to Friday 22:00 GMT)
   MqlDateTime dt;
   TimeToStruct(current, dt);
   
   // Check if it's weekend (Saturday or Sunday before 22:00 GMT)
   if(dt.day_of_week == 0) // Sunday
   {
      if(dt.hour < 22) // Before 22:00 GMT on Sunday
         return false;
   }
   else if(dt.day_of_week == 6) // Saturday
   {
      return false; // Market closed on Saturday
   }
   
   return true;
}

//+------------------------------------------------------------------+

