//+------------------------------------------------------------------+
//| Price_Utils.mqh                                                  |
//| Price calculation utilities                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double GetPipValue(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   // For 3 and 5 digit brokers, pip = point * 10
   // For 2 and 4 digit brokers, pip = point * 10
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point * 10;
}

//+------------------------------------------------------------------+
//| Convert price difference to pips                                 |
//+------------------------------------------------------------------+
double PriceToPips(string symbol, double priceDiff)
{
   return priceDiff / GetPipValue(symbol);
}

//+------------------------------------------------------------------+
//| Convert pips to price difference                                 |
//+------------------------------------------------------------------+
double PipsToPrice(string symbol, double pips)
{
   return pips * GetPipValue(symbol);
}

//+------------------------------------------------------------------+
//| Get current spread in pips                                       |
//+------------------------------------------------------------------+
double GetSpreadPips(string symbol)
{
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double spread = ask - bid;
   return PriceToPips(symbol, spread);
}

//+------------------------------------------------------------------+
//| Calculate stop loss price                                        |
//+------------------------------------------------------------------+
double CalculateStopLoss(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double stopLossPips)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return entry - (stopLossPips * pipValue);
   else if(signalType == SIGNAL_SELL)
      return entry + (stopLossPips * pipValue);
   
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate take profit price                                      |
//+------------------------------------------------------------------+
double CalculateTakeProfit(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double takeProfitPips)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return entry + (takeProfitPips * pipValue);
   else if(signalType == SIGNAL_SELL)
      return entry - (takeProfitPips * pipValue);
   
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate risk/reward ratio                                      |
//+------------------------------------------------------------------+
double CalculateRiskReward(double entry, double stopLoss, double takeProfit, ENUM_SIGNAL_TYPE signalType)
{
   double risk = MathAbs(entry - stopLoss);
   double reward = MathAbs(takeProfit - entry);
   
   if(risk == 0) return 0;
   
   return reward / risk;
}

//+------------------------------------------------------------------+
//| Calculate suggested lot size based on risk percentage            |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, double entry, double stopLoss, double riskPercent, double accountBalance)
{
   double riskAmount = accountBalance * riskPercent / 100.0;
   double riskPips = MathAbs(PriceToPips(symbol, entry - stopLoss));
   double pipValue = GetPipValue(symbol);
   
   // Get contract size
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tickSize == 0 || tickValue == 0) return 0.01; // Default fallback
   
   // Calculate lot size
   double lotSize = riskAmount / (riskPips * pipValue * contractSize / tickSize * tickValue);
   
   // Round to lot step
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   
   // Apply min/max limits
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Get current price (Ask for BUY, Bid for SELL)                   |
//+------------------------------------------------------------------+
double GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_BUY)
      return SymbolInfoDouble(symbol, SYMBOL_ASK);
   else if(signalType == SIGNAL_SELL)
      return SymbolInfoDouble(symbol, SYMBOL_BID);
   
   return SymbolInfoDouble(symbol, SYMBOL_BID);
}

//+------------------------------------------------------------------+

