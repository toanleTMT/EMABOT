//+------------------------------------------------------------------+
//| Arrow_Manager.mqh                                                |
//| Manages arrow signals on chart                                   |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"

//+------------------------------------------------------------------+
//| Arrow Manager Class                                              |
//+------------------------------------------------------------------+
class CArrowManager
{
private:
   int m_arrowSize;
   color m_buyColor;
   color m_sellColor;
   color m_goodColor;
   color m_weakColor;
   int m_arrowCounter;
   
public:
   CArrowManager(int arrowSize, color buyColor, color sellColor, color goodColor, color weakColor);
   
   void DrawArrow(string symbol, datetime time, double price, int score, ENUM_SIGNAL_TYPE signalType);
   void CleanupOldArrows(int keepLastN = 50);
   void DeleteAllArrows();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CArrowManager::CArrowManager(int arrowSize, color buyColor, color sellColor, color goodColor, color weakColor)
{
   m_arrowSize = arrowSize;
   m_buyColor = buyColor;
   m_sellColor = sellColor;
   m_goodColor = goodColor;
   m_weakColor = weakColor;
   m_arrowCounter = 0;
}

//+------------------------------------------------------------------+
//| Draw arrow signal on chart                                       |
//+------------------------------------------------------------------+
void CArrowManager::DrawArrow(string symbol, datetime time, double price, int score, ENUM_SIGNAL_TYPE signalType)
{
   if(signalType == SIGNAL_NONE) return;
   
   // Determine arrow properties based on score
   int arrowCode;
   color arrowColor;
   int size;
   
   if(score >= 85)
   {
      // PERFECT setup - Large arrow (size 3)
      // BUY: Up arrow (233), SELL: Down arrow (234)
      arrowCode = (signalType == SIGNAL_BUY) ? 233 : 234;
      arrowColor = (signalType == SIGNAL_BUY) ? m_buyColor : m_sellColor;
      size = 3; // Large arrow as per specification
   }
   else if(score >= 70)
   {
      // GOOD setup - Medium arrow (size 2)
      arrowCode = (signalType == SIGNAL_BUY) ? 233 : 234;
      arrowColor = m_goodColor;
      size = 2; // Medium arrow
   }
   else if(score >= 50)
   {
      // WEAK setup - Small arrow (size 1)
      arrowCode = (signalType == SIGNAL_BUY) ? 233 : 234;
      arrowColor = m_weakColor;
      size = 1; // Small arrow
   }
   else
   {
      return; // Don't draw invalid setups
   }
   
   // Calculate arrow position
   double arrowPrice = price;
   if(signalType == SIGNAL_BUY)
   {
      // Place below candle for BUY
      double low = iLow(symbol, PERIOD_CURRENT, 0);
      arrowPrice = low - (low * 0.0001); // Slightly below
   }
   else
   {
      // Place above candle for SELL
      double high = iHigh(symbol, PERIOD_CURRENT, 0);
      arrowPrice = high + (high * 0.0001); // Slightly above
   }
   
   // Create unique object name
   string objName = PREFIX_ARROW + symbol + "_" + IntegerToString(time) + "_" + IntegerToString(m_arrowCounter++);
   
   // Create arrow object with error handling
   if(ObjectCreate(0, objName, OBJ_ARROW, 0, time, arrowPrice))
   {
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, size);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
      
      // Verify object was created successfully
      if(!CheckError("CreateArrow"))
      {
         Print("WARNING: Failed to create arrow object: ", objName);
      }
   }
   else
   {
      LogError("CreateArrow", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Cleanup old arrows, keep only last N                             |
//+------------------------------------------------------------------+
void CArrowManager::CleanupOldArrows(int keepLastN = 50)
{
   string names[];
   int count = 0;
   
   // Find all arrow objects
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PREFIX_ARROW) == 0)
      {
         ArrayResize(names, count + 1);
         names[count++] = name;
      }
   }
   
   // Sort by time (newest first)
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
   
   // Delete old arrows
   for(int i = keepLastN; i < count; i++)
   {
      ObjectDelete(0, names[i]);
   }
}

//+------------------------------------------------------------------+
//| Delete all arrows                                                |
//+------------------------------------------------------------------+
void CArrowManager::DeleteAllArrows()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PREFIX_ARROW) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+

