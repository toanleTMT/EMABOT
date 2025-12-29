//+------------------------------------------------------------------+
//| Object_Helper.mqh                                                 |
//| Helper functions for chart object management                     |
//+------------------------------------------------------------------+

#include "../Config.mqh"

//+------------------------------------------------------------------+
//| Object Helper Functions                                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Create label object with error handling                          |
//+------------------------------------------------------------------+
bool CreateLabelSafe(string name, int x, int y, string text, color clr, int fontSize, string font = "Arial")
{
   // Delete if exists
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   // Create new
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      Print("ERROR: Failed to create label object: ", name, " | Error: ", GetLastError());
      return false;
   }
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create rectangle label with error handling                       |
//+------------------------------------------------------------------+
bool CreateRectangleSafe(string name, int x, int y, int width, int height, color bgColor)
{
   // Delete if exists
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   // Create new
   if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      Print("ERROR: Failed to create rectangle object: ", name, " | Error: ", GetLastError());
      return false;
   }
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   
   return true;
}

//+------------------------------------------------------------------+
//| Update label text safely                                          |
//+------------------------------------------------------------------+
bool UpdateLabelText(string name, string text)
{
   if(ObjectFind(0, name) < 0)
      return false;
   
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   return true;
}

//+------------------------------------------------------------------+
//| Update label color safely                                         |
//+------------------------------------------------------------------+
bool UpdateLabelColor(string name, color clr)
{
   if(ObjectFind(0, name) < 0)
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   return true;
}

//+------------------------------------------------------------------+
//| Delete object safely                                              |
//+------------------------------------------------------------------+
bool DeleteObjectSafe(string name)
{
   if(ObjectFind(0, name) < 0)
      return true; // Already deleted
   
   if(!ObjectDelete(0, name))
   {
      Print("WARNING: Failed to delete object: ", name, " | Error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if object exists                                            |
//+------------------------------------------------------------------+
bool ObjectExists(string name)
{
   return (ObjectFind(0, name) >= 0);
}

//+------------------------------------------------------------------+

