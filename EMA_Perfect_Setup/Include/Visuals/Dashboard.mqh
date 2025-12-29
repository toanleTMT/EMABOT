//+------------------------------------------------------------------+
//| Dashboard.mqh                                                    |
//| Main dashboard display                                           |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"
#include "../Utilities/Time_Utils.mqh"
#include "Dashboard_Helper.mqh"

//+------------------------------------------------------------------+
//| Dashboard Class                                                  |
//+------------------------------------------------------------------+
class CDashboard
{
private:
   string m_dashboardName;
   bool m_visible;
   int m_xPos, m_yPos;
   int m_width, m_height;
   
   void CreateBackground();
   void CreateTextObjects();
   
public:
   CDashboard();
   ~CDashboard();
   
   void Initialize();
   void Update(string symbol, int score, int categoryScores[], ENUM_SIGNAL_TYPE signalType,
              double entry, double sl, double tp1, double tp2,
              int perfectToday, int goodToday, int weakToday, double spread);
   void Flash(color flashColor, int durationMs = 5000);
   void CheckFlashRestore();
   void Show();
   void Hide();
   void Delete();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
   m_dashboardName = PREFIX_DASHBOARD + "Main";
   m_visible = true;
   // Position at top-right with 10px margin as per specification
   m_xPos = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - m_width - 10;
   m_yPos = 30;
   m_width = 350;
   m_height = 450; // Increased for recommendation section
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
   Delete();
}

//+------------------------------------------------------------------+
//| Initialize dashboard                                              |
//+------------------------------------------------------------------+
void CDashboard::Initialize()
{
   CreateBackground();
   CreateTextObjects();
}

//+------------------------------------------------------------------+
//| Create background panel                                           |
//+------------------------------------------------------------------+
void CDashboard::CreateBackground()
{
   string bgName = m_dashboardName + "_BG";
   
   if(ObjectFind(0, bgName) < 0)
   {
      if(ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_xPos);
         ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_yPos);
         ObjectSetInteger(0, bgName, OBJPROP_XSIZE, m_width);
         ObjectSetInteger(0, bgName, OBJPROP_YSIZE, m_height);
         ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, C'30,30,30');
         ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
         ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);
      }
   }
}

//+------------------------------------------------------------------+
//| Create text objects                                              |
//+------------------------------------------------------------------+
void CDashboard::CreateTextObjects()
{
   // Title
   string titleName = m_dashboardName + "_Title";
   if(ObjectFind(0, titleName) < 0)
   {
      ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, m_yPos + 10);
      ObjectSetString(0, titleName, OBJPROP_TEXT, "EMA PERFECT SETUP SCANNER v2.0");
      ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
   }
   
   // Create other text objects (status, score, etc.)
   // These will be updated in Update() method
}

//+------------------------------------------------------------------+
//| Update dashboard content                                         |
//+------------------------------------------------------------------+
void CDashboard::Update(string symbol, int score, int categoryScores[], ENUM_SIGNAL_TYPE signalType,
                       double entry, double sl, double tp1, double tp2,
                       int perfectToday, int goodToday, int weakToday, double spread)
{
   // Status line
   string statusName = m_dashboardName + "_Status";
   string statusText = "";
   color statusColor = clrGray;
   
   if(score >= 85)
   {
      statusText = "🟢 PERFECT SETUP FOUND!";
      statusColor = clrLime;
   }
   else if(score >= 70)
   {
      statusText = "🟡 Good setup (not perfect)";
      statusColor = clrYellow;
   }
   else if(score >= 50)
   {
      statusText = "⚪ Weak setup (skipped)";
      statusColor = clrGray;
   }
   else
   {
      statusText = "🔴 Scanning...";
      statusColor = clrGray;
   }
   
   if(ObjectFind(0, statusName) < 0)
   {
      ObjectCreate(0, statusName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, statusName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, statusName, OBJPROP_YDISTANCE, m_yPos + 35);
      ObjectSetInteger(0, statusName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, statusName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, statusName, OBJPROP_HIDDEN, true);
   }
   ObjectSetString(0, statusName, OBJPROP_TEXT, "Status: " + statusText);
   ObjectSetInteger(0, statusName, OBJPROP_COLOR, statusColor);
   
   // Symbol and timeframe
   string infoName = m_dashboardName + "_Info";
   if(ObjectFind(0, infoName) < 0)
   {
      ObjectCreate(0, infoName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, infoName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, infoName, OBJPROP_YDISTANCE, m_yPos + 55);
      ObjectSetInteger(0, infoName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, infoName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, infoName, OBJPROP_HIDDEN, true);
   }
   ObjectSetString(0, infoName, OBJPROP_TEXT, "Pair: " + symbol + " | TF: M5 | Time: " + FormatDateTime(TimeCurrent()) + " | Spread: " + FormatPips(spread));
   ObjectSetInteger(0, infoName, OBJPROP_COLOR, clrWhite);
   
   // Score display
   string scoreName = m_dashboardName + "_Score";
   if(ObjectFind(0, scoreName) < 0)
   {
      ObjectCreate(0, scoreName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, scoreName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, scoreName, OBJPROP_YDISTANCE, m_yPos + 80);
      ObjectSetInteger(0, scoreName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, scoreName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, scoreName, OBJPROP_HIDDEN, true);
   }
   string scoreText = "🎯 SETUP SCORE: " + IntegerToString(score) + "/100 ";
   if(score >= 85) scoreText += "🟢 PERFECT!";
   else if(score >= 70) scoreText += "🟡 GOOD";
   else if(score >= 50) scoreText += "⚪ WEAK";
   else scoreText += "🔴 INVALID";
   ObjectSetString(0, scoreName, OBJPROP_TEXT, scoreText);
   ObjectSetInteger(0, scoreName, OBJPROP_COLOR, score >= 85 ? clrLime : (score >= 70 ? clrYellow : clrGray));
   ObjectSetInteger(0, scoreName, OBJPROP_FONTSIZE, 11);
   ObjectSetString(0, scoreName, OBJPROP_FONT, "Arial Bold");
   
   // Category scores with progress bars
   int yOffset = 110;
   string categoryNames[] = {"Trend Alignment", "EMA Quality", "Signal Strength", "Confirmation", "Market Conditions", "Context & Timing"};
   int categoryMax[] = {25, 20, 20, 15, 10, 10};
   
   for(int i = 0; i < TOTAL_CATEGORIES; i++)
   {
      string catName = m_dashboardName + "_Cat" + IntegerToString(i);
      if(ObjectFind(0, catName) < 0)
      {
         ObjectCreate(0, catName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, catName, OBJPROP_XDISTANCE, m_xPos + 10);
         ObjectSetInteger(0, catName, OBJPROP_YDISTANCE, m_yPos + yOffset + (i * 20));
         ObjectSetInteger(0, catName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, catName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, catName, OBJPROP_HIDDEN, true);
      }
      
      string catText = "✓ " + categoryNames[i] + ": " + IntegerToString(categoryScores[i]) + "/" + IntegerToString(categoryMax[i]) + " [" + 
                       CreateProgressBar(categoryScores[i], categoryMax[i]) + "]";
      ObjectSetString(0, catName, OBJPROP_TEXT, catText);
      ObjectSetInteger(0, catName, OBJPROP_COLOR, clrWhite);
   }
   
   // Today's stats
   yOffset = 250;
   string statsName = m_dashboardName + "_Stats";
   if(ObjectFind(0, statsName) < 0)
   {
      ObjectCreate(0, statsName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, statsName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, statsName, OBJPROP_YDISTANCE, m_yPos + yOffset);
      ObjectSetInteger(0, statsName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, statsName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, statsName, OBJPROP_HIDDEN, true);
   }
   string statsText = "📊 TODAY'S STATS:\n";
   statsText += "Perfect Setups: " + IntegerToString(perfectToday) + "\n";
   statsText += "Good Setups: " + IntegerToString(goodToday) + " (not alerted)\n";
   statsText += "Weak Setups: " + IntegerToString(weakToday) + " (skipped)\n";
   
   double qualityRate = CalculateQualityRate(perfectToday, goodToday, weakToday);
   int totalValid = perfectToday + goodToday + weakToday;
   if(totalValid > 0)
      statsText += "Quality Rate: " + DoubleToString(qualityRate, 1) + "% (" + IntegerToString(perfectToday) + "/" + IntegerToString(totalValid) + " valid)";
   
   ObjectSetString(0, statsName, OBJPROP_TEXT, statsText);
   ObjectSetInteger(0, statsName, OBJPROP_COLOR, clrWhite);
   
   // Recommendation section (for perfect setups)
   if(score >= 85)
   {
      string recName = m_dashboardName + "_Recommendation";
      if(ObjectFind(0, recName) < 0)
      {
         ObjectCreate(0, recName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, recName, OBJPROP_XDISTANCE, m_xPos + 10);
         ObjectSetInteger(0, recName, OBJPROP_YDISTANCE, m_yPos + 300);
         ObjectSetInteger(0, recName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, recName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, recName, OBJPROP_HIDDEN, true);
      }
      
      string recText = FormatRecommendation(symbol, signalType, entry, sl, tp1, tp2);
      ObjectSetString(0, recName, OBJPROP_TEXT, recText);
      ObjectSetInteger(0, recName, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, recName, OBJPROP_FONTSIZE, 9);
      
      // Discipline check
      string discName = m_dashboardName + "_Discipline";
      if(ObjectFind(0, discName) < 0)
      {
         ObjectCreate(0, discName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, discName, OBJPROP_XDISTANCE, m_xPos + 10);
         ObjectSetInteger(0, discName, OBJPROP_YDISTANCE, m_yPos + 340);
         ObjectSetInteger(0, discName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, discName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, discName, OBJPROP_HIDDEN, true);
      }
      
      string discText = FormatDisciplineCheck();
      ObjectSetString(0, discName, OBJPROP_TEXT, discText);
      ObjectSetInteger(0, discName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, discName, OBJPROP_FONTSIZE, 8);
   }
   else
   {
      // Hide recommendation and discipline check for non-perfect setups
      string recName = m_dashboardName + "_Recommendation";
      if(ObjectFind(0, recName) >= 0)
         ObjectSetInteger(0, recName, OBJPROP_HIDDEN, true);
      
      string discName = m_dashboardName + "_Discipline";
      if(ObjectFind(0, discName) >= 0)
         ObjectSetInteger(0, discName, OBJPROP_HIDDEN, true);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Flash dashboard with color                                       |
//+------------------------------------------------------------------+
void CDashboard::Flash(color flashColor, int durationMs = 5000)
{
   string bgName = m_dashboardName + "_BG";
   if(ObjectFind(0, bgName) >= 0)
   {
      // Store original color in object property for later restoration
      color originalColor = (color)ObjectGetInteger(0, bgName, OBJPROP_BGCOLOR);
      
      // Store original color in object description for restoration
      string originalColorStr = IntegerToString((int)originalColor);
      ObjectSetString(0, bgName, OBJPROP_TEXT, originalColorStr);
      
      // Flash to new color
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, flashColor);
      ChartRedraw();
      
      // Note: Actual restoration should be handled by timer callback
      // For now, we'll restore immediately after a short delay
      // In production, use EventSetTimer() and check in OnTimer()
      static datetime flashStartTime = 0;
      flashStartTime = TimeCurrent();
      
      // Store flash end time in object name suffix
      datetime flashEndTime = flashStartTime + durationMs / 1000;
      ObjectSetString(0, bgName + "_FlashEnd", OBJPROP_TEXT, IntegerToString((int)flashEndTime));
   }
}

//+------------------------------------------------------------------+
//| Check and restore flash if duration expired                      |
//+------------------------------------------------------------------+
void CDashboard::CheckFlashRestore()
{
   string bgName = m_dashboardName + "_BG";
   string flashEndName = bgName + "_FlashEnd";
   
   if(ObjectFind(0, flashEndName) >= 0)
   {
      datetime flashEndTime = (datetime)StringToInteger(ObjectGetString(0, flashEndName, OBJPROP_TEXT));
      
      if(TimeCurrent() >= flashEndTime)
      {
         // Restore original color
         string originalColorStr = ObjectGetString(0, bgName, OBJPROP_TEXT);
         color originalColor = (color)StringToInteger(originalColorStr);
         ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, originalColor);
         ObjectSetString(0, bgName, OBJPROP_TEXT, "");
         ObjectDelete(0, flashEndName);
         ChartRedraw();
      }
   }
}

//+------------------------------------------------------------------+
//| Show dashboard                                                   |
//+------------------------------------------------------------------+
void CDashboard::Show()
{
   m_visible = true;
   // Show all objects
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_dashboardName) == 0)
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Hide dashboard                                                   |
//+------------------------------------------------------------------+
void CDashboard::Hide()
{
   m_visible = false;
   // Hide all objects
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_dashboardName) == 0)
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete dashboard                                                 |
//+------------------------------------------------------------------+
void CDashboard::Delete()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_dashboardName) == 0)
         ObjectDelete(0, name);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+

