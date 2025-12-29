//+------------------------------------------------------------------+
//| Input_Validator.mqh                                              |
//| Validates EA input parameters                                    |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "String_Utils.mqh"
#include "Symbol_Utils.mqh"

//+------------------------------------------------------------------+
//| Input Validator Class                                            |
//+------------------------------------------------------------------+
class CInputValidator
{
public:
   static bool ValidateInputs(string symbols, int minScore, double maxSpread,
                             int stopLossPips, int tp1Pips, int tp2Pips,
                             double riskPercent, int &errors[]);
   static string GetValidationErrors(int errors[]);
   static bool ValidateSymbols(string symbols, string &validSymbols[]);
   static bool ValidateRiskParameters(double riskPercent, int stopLossPips);
};

//+------------------------------------------------------------------+
//| Validate all input parameters                                    |
//+------------------------------------------------------------------+
bool CInputValidator::ValidateInputs(string symbols, int minScore, double maxSpread,
                                     int stopLossPips, int tp1Pips, int tp2Pips,
                                     double riskPercent, int &errors[])
{
   ArrayResize(errors, 0);
   int errorCount = 0;
   
   // Validate symbols
   if(StringLen(symbols) == 0)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 1; // No symbols error
   }
   
   // Validate min score
   if(minScore < 50 || minScore > 100)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 2; // Invalid score range
   }
   
   // Validate spread
   if(maxSpread <= 0 || maxSpread > 10)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 3; // Invalid spread
   }
   
   // Validate stop loss
   if(stopLossPips <= 0 || stopLossPips > 1000)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 4; // Invalid stop loss
   }
   
   // Validate take profit
   if(tp1Pips <= 0 || tp2Pips <= 0)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 5; // Invalid take profit
   }
   
   if(tp2Pips <= tp1Pips)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 6; // TP2 must be greater than TP1
   }
   
   // Validate risk
   if(riskPercent <= 0 || riskPercent > 10)
   {
      ArrayResize(errors, errorCount + 1);
      errors[errorCount++] = 7; // Invalid risk percentage
   }
   
   return (errorCount == 0);
}

//+------------------------------------------------------------------+
//| Get validation error messages                                    |
//+------------------------------------------------------------------+
string CInputValidator::GetValidationErrors(int errors[])
{
   string errorMsg = "";
   
   for(int i = 0; i < ArraySize(errors); i++)
   {
      switch(errors[i])
      {
         case 1:
            errorMsg += "ERROR: No symbols specified!\n";
            break;
         case 2:
            errorMsg += "ERROR: Minimum score must be between 50-100!\n";
            break;
         case 3:
            errorMsg += "ERROR: Max spread must be between 0-10 pips!\n";
            break;
         case 4:
            errorMsg += "ERROR: Stop loss must be between 1-1000 pips!\n";
            break;
         case 5:
            errorMsg += "ERROR: Take profit values must be greater than 0!\n";
            break;
         case 6:
            errorMsg += "ERROR: TP2 must be greater than TP1!\n";
            break;
         case 7:
            errorMsg += "ERROR: Risk percentage must be between 0.1-10%!\n";
            break;
         default:
            errorMsg += "ERROR: Unknown validation error!\n";
      }
   }
   
   return errorMsg;
}

//+------------------------------------------------------------------+
//| Validate symbols list                                            |
//+------------------------------------------------------------------+
bool CInputValidator::ValidateSymbols(string symbols, string &validSymbols[])
{
   string temp[];
   ParseSymbols(symbols, temp);
   
   ArrayResize(validSymbols, 0);
   int validCount = 0;
   
   for(int i = 0; i < ArraySize(temp); i++)
   {
      // Normalize symbol
      string symbol = NormalizeSymbol(temp[i]);
      
      // Check if symbol exists
      if(IsSymbolValid(symbol))
      {
         ArrayResize(validSymbols, validCount + 1);
         validSymbols[validCount++] = symbol;
      }
      else
      {
         Print("WARNING: Symbol ", symbol, " is not valid or not available. Skipping.");
      }
   }
   
   return (validCount > 0);
}

//+------------------------------------------------------------------+
//| Validate risk parameters                                         |
//+------------------------------------------------------------------+
bool CInputValidator::ValidateRiskParameters(double riskPercent, int stopLossPips)
{
   if(riskPercent <= 0 || riskPercent > 10)
      return false;
   
   if(stopLossPips <= 0 || stopLossPips > 1000)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+

