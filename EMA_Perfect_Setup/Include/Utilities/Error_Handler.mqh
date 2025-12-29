//+------------------------------------------------------------------+
//| Error_Handler.mqh                                                |
//| Error handling utilities                                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get error description                                            |
//+------------------------------------------------------------------+
string GetErrorDescription(int errorCode)
{
   switch(errorCode)
   {
      case 0: return "No error";
      case 1: return "No error returned, but the result is unknown";
      case 2: return "Common error";
      case 3: return "Invalid trade parameters";
      case 4: return "Trade server is busy";
      case 5: return "Old version of the client terminal";
      case 6: return "No connection with trade server";
      case 7: return "Not enough rights";
      case 8: return "Too frequent requests";
      case 9: return "Malfunctional trade operation";
      case 64: return "Account blocked";
      case 65: return "Invalid account";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid trade volume";
      case 132: return "Market is closed";
      case 133: return "Trade is disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 137: return "Broker is busy";
      case 138: return "Requote";
      case 139: return "Order is locked";
      case 140: return "Long positions only allowed";
      case 141: return "Too many requests";
      case 145: return "Modification denied because order too close to market";
      case 146: return "Trade context is busy";
      case 147: return "Expirations are denied by broker";
      case 148: return "Amount of open and pending orders has reached the limit";
      default: return "Unknown error " + IntegerToString(errorCode);
   }
}

//+------------------------------------------------------------------+
//| Log error with context                                           |
//+------------------------------------------------------------------+
void LogError(string context, int errorCode)
{
   string errorMsg = GetErrorDescription(errorCode);
   Print("ERROR [", context, "]: ", errorMsg, " (Code: ", errorCode, ")");
}

//+------------------------------------------------------------------+
//| Check if operation was successful                                |
//+------------------------------------------------------------------+
bool CheckError(string context)
{
   int error = GetLastError();
   if(error != 0)
   {
      LogError(context, error);
      ResetLastError();
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+

