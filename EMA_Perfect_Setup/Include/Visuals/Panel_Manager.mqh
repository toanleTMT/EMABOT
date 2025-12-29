//+------------------------------------------------------------------+
//| Panel_Manager.mqh                                                |
//| Score breakdown panel                                            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Scoring/Setup_Scorer.mqh"

//+------------------------------------------------------------------+
//| Panel Manager Class                                              |
//+------------------------------------------------------------------+
class CPanelManager
{
private:
   string m_panelName;
   bool m_visible;
   int m_xPos, m_yPos;
   int m_width, m_height;
   
public:
   CPanelManager();
   ~CPanelManager();
   
   void Initialize();
   void Update(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[], CSetupScorer *scorer);
   void Show();
   void Hide();
   void Delete();
   void Cleanup(); // Alias for Delete() for consistency
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPanelManager::CPanelManager()
{
   m_panelName = PREFIX_PANEL + "Breakdown";
   m_visible = true;
   m_xPos = 10;
   m_yPos = 450; // Bottom-left position
   m_width = 350;
   m_height = 300;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPanelManager::~CPanelManager()
{
   Delete();
}

//+------------------------------------------------------------------+
//| Initialize panel                                                 |
//+------------------------------------------------------------------+
void CPanelManager::Initialize()
{
   // Create background
   string bgName = m_panelName + "_BG";
   if(ObjectFind(0, bgName) < 0)
   {
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_xPos);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_yPos);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, m_height);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, C'30,30,30');
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Update panel content                                             |
//+------------------------------------------------------------------+
void CPanelManager::Update(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[], CSetupScorer *scorer)
{
   string breakdown = scorer.GetScoreBreakdown(symbol, signalType, categoryScores);
   string strengths = scorer.GetStrengthsAndWeaknesses(symbol, signalType, categoryScores);
   
   // Title
   string titleName = m_panelName + "_Title";
   if(ObjectFind(0, titleName) < 0)
   {
      ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, m_yPos - 20);
      ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
   }
   ObjectSetString(0, titleName, OBJPROP_TEXT, "📊 DETAILED ANALYSIS");
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
   
   // Content
   string contentName = m_panelName + "_Content";
   if(ObjectFind(0, contentName) < 0)
   {
      ObjectCreate(0, contentName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, contentName, OBJPROP_XDISTANCE, m_xPos + 10);
      ObjectSetInteger(0, contentName, OBJPROP_YDISTANCE, m_yPos - 50);
      ObjectSetInteger(0, contentName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, contentName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, contentName, OBJPROP_HIDDEN, true);
   }
   // Format content with proper line breaks
   string content = breakdown;
   if(StringLen(strengths) > 0)
   {
      if(StringLen(content) > 0)
         content += "\n\n";
      content += strengths;
   }
   
   // Limit content length to prevent display issues
   if(StringLen(content) > 500)
   {
      content = StringSubstr(content, 0, 500) + "...";
   }
   
   ObjectSetString(0, contentName, OBJPROP_TEXT, content);
   ObjectSetInteger(0, contentName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, contentName, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, contentName, OBJPROP_FONT, "Courier New");
   ObjectSetInteger(0, contentName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Show panel                                                       |
//+------------------------------------------------------------------+
void CPanelManager::Show()
{
   m_visible = true;
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_panelName) == 0)
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Hide panel                                                       |
//+------------------------------------------------------------------+
void CPanelManager::Hide()
{
   m_visible = false;
   int total = ObjectsTotal(0);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_panelName) == 0)
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete panel                                                     |
//+------------------------------------------------------------------+
void CPanelManager::Delete()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_panelName) == 0)
         ObjectDelete(0, name);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+

