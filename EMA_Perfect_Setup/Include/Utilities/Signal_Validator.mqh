//+------------------------------------------------------------------+
//| Signal_Validator.mqh                                             |
//| Validates signals before processing                               |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Indicators/RSI_Manager.mqh"
#include "Price_Utils.mqh"
#include "Symbol_Utils.mqh"
#include "String_Utils.mqh"

//+------------------------------------------------------------------+
//| Signal Validator Class                                           |
//+------------------------------------------------------------------+
class CSignalValidator
{
private:
   CEMAManager *m_emaH1;
   CEMAManager *m_emaM5;
   CRSIManager *m_rsi;
   double m_maxSpread;
   int m_minEMASeparation;
   bool m_useRSI;
   int m_rsiBuyLevel;
   int m_rsiSellLevel;
   
public:
   CSignalValidator(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi,
                   double maxSpread, int minEMASeparation,
                   bool useRSI, int rsiBuyLevel, int rsiSellLevel);
   
   bool ValidateBuySignal(string symbol);
   bool ValidateSellSignal(string symbol);
   bool CheckSpread(string symbol);
   bool CheckEMASeparation(string symbol);
   bool CheckRSI(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetValidationErrors(string symbol, ENUM_SIGNAL_TYPE signalType);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalValidator::CSignalValidator(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi,
                                   double maxSpread, int minEMASeparation,
                                   bool useRSI, int rsiBuyLevel, int rsiSellLevel)
{
   m_emaH1 = emaH1;
   m_emaM5 = emaM5;
   m_rsi = rsi;
   m_maxSpread = maxSpread;
   m_minEMASeparation = minEMASeparation;
   m_useRSI = useRSI;
   m_rsiBuyLevel = rsiBuyLevel;
   m_rsiSellLevel = rsiSellLevel;
}

//+------------------------------------------------------------------+
//| Validate BUY signal                                              |
//+------------------------------------------------------------------+
bool CSignalValidator::ValidateBuySignal(string symbol)
{
   // Check symbol validity
   if(!IsSymbolValid(symbol))
      return false;
   
   // Get H1 EMA data
   double emaFastH1[], emaMediumH1[], emaSlowH1[];
   if(!m_emaH1.GetEMAData(symbol, emaFastH1, emaMediumH1, emaSlowH1))
      return false;
   
   // Get M5 EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   // Get current price
   double price = iClose(symbol, PERIOD_M5, 0);
   double priceH1 = iClose(symbol, PERIOD_H1, 0);
   
   // H1: Price > EMA 50
   if(priceH1 <= emaSlowH1[0])
      return false;
   
   // H1: EMAs aligned (9 > 21 > 50)
   if(!(emaFastH1[0] > emaMediumH1[0] && emaMediumH1[0] > emaSlowH1[0]))
      return false;
   
   // M5: EMAs aligned (9 > 21 > 50)
   if(!(emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]))
      return false;
   
   // M5: EMA 9 crosses above EMA 21
   if(!(emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1]))
      return false;
   
   // M5: Current candle closes above EMA 9
   if(price <= emaFast[0])
      return false;
   
   // M5: Price, EMA 9, and EMA 21 all above EMA 50
   if(!(price > emaSlow[0] && emaFast[0] > emaSlow[0] && emaMedium[0] > emaSlow[0]))
      return false;
   
   // M5: RSI > 50 (if enabled)
   if(m_useRSI && m_rsi != NULL)
   {
      if(!CheckRSI(symbol, SIGNAL_BUY))
         return false;
   }
   
   // M5: EMAs have clear separation
   if(!CheckEMASeparation(symbol))
      return false;
   
   // Spread check
   if(!CheckSpread(symbol))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate SELL signal                                             |
//+------------------------------------------------------------------+
bool CSignalValidator::ValidateSellSignal(string symbol)
{
   // Check symbol validity
   if(!IsSymbolValid(symbol))
      return false;
   
   // Get H1 EMA data
   double emaFastH1[], emaMediumH1[], emaSlowH1[];
   if(!m_emaH1.GetEMAData(symbol, emaFastH1, emaMediumH1, emaSlowH1))
      return false;
   
   // Get M5 EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   // Get current price
   double price = iClose(symbol, PERIOD_M5, 0);
   double priceH1 = iClose(symbol, PERIOD_H1, 0);
   
   // H1: Price < EMA 50
   if(priceH1 >= emaSlowH1[0])
      return false;
   
   // H1: EMAs aligned (9 < 21 < 50)
   if(!(emaFastH1[0] < emaMediumH1[0] && emaMediumH1[0] < emaSlowH1[0]))
      return false;
   
   // M5: EMAs aligned (9 < 21 < 50)
   if(!(emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]))
      return false;
   
   // M5: EMA 9 crosses below EMA 21
   if(!(emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1]))
      return false;
   
   // M5: Current candle closes below EMA 9
   if(price >= emaFast[0])
      return false;
   
   // M5: Price, EMA 9, and EMA 21 all below EMA 50
   if(!(price < emaSlow[0] && emaFast[0] < emaSlow[0] && emaMedium[0] < emaSlow[0]))
      return false;
   
   // M5: RSI < 50 (if enabled)
   if(m_useRSI && m_rsi != NULL)
   {
      if(!CheckRSI(symbol, SIGNAL_SELL))
         return false;
   }
   
   // M5: EMAs have clear separation
   if(!CheckEMASeparation(symbol))
      return false;
   
   // Spread check
   if(!CheckSpread(symbol))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check spread                                                     |
//+------------------------------------------------------------------+
bool CSignalValidator::CheckSpread(string symbol)
{
   double spread = GetSpreadPips(symbol);
   return spread <= m_maxSpread;
}

//+------------------------------------------------------------------+
//| Check EMA separation                                              |
//+------------------------------------------------------------------+
bool CSignalValidator::CheckEMASeparation(string symbol)
{
   double separation = m_emaM5.GetEMASeparation(symbol, PERIOD_M5);
   return separation >= m_minEMASeparation;
}

//+------------------------------------------------------------------+
//| Check RSI                                                         |
//+------------------------------------------------------------------+
bool CSignalValidator::CheckRSI(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(m_rsi == NULL) return true;
   
   double rsi;
   if(!m_rsi.GetRSIValue(symbol, rsi))
      return false;
   
   if(signalType == SIGNAL_BUY)
      return rsi > m_rsiBuyLevel;
   else if(signalType == SIGNAL_SELL)
      return rsi < m_rsiSellLevel;
   
   return false;
}

//+------------------------------------------------------------------+
//| Get validation errors                                            |
//+------------------------------------------------------------------+
string CSignalValidator::GetValidationErrors(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   string errors = "";
   
   if(!IsSymbolValid(symbol))
      errors += "• Symbol not valid or not in Market Watch\n";
   
   if(!CheckSpread(symbol))
   {
      double spread = GetSpreadPips(symbol);
      errors += "• Spread too high: " + FormatPips(spread) + " (max: " + FormatPips(m_maxSpread) + ")\n";
   }
   
   if(!CheckEMASeparation(symbol))
   {
      double separation = m_emaM5.GetEMASeparation(symbol, PERIOD_M5);
      errors += "• EMA separation too tight: " + FormatPips(separation) + " (min: " + FormatPips(m_minEMASeparation) + ")\n";
   }
   
   if(m_useRSI && !CheckRSI(symbol, signalType))
   {
      double rsi;
      if(m_rsi != NULL && m_rsi.GetRSIValue(symbol, rsi))
      {
         errors += "• RSI not favorable: " + DoubleToString(rsi, 1);
         if(signalType == SIGNAL_BUY)
            errors += " (need > " + IntegerToString(m_rsiBuyLevel) + ")\n";
         else
            errors += " (need < " + IntegerToString(m_rsiSellLevel) + ")\n";
      }
   }
   
   return errors;
}

//+------------------------------------------------------------------+

