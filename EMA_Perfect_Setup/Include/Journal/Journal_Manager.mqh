//+------------------------------------------------------------------+
//| Journal_Manager.mqh                                              |
//| Manages trading journal                                          |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"
#include "../Utilities/Time_Utils.mqh"
#include "CSV_Exporter.mqh"
#include "Stats_Calculator.mqh"

//+------------------------------------------------------------------+
//| Journal Manager Class                                            |
//+------------------------------------------------------------------+
class CJournalManager
{
private:
   string m_journalPath;
   bool m_enableCSV;
   bool m_takeScreenshots;
   CCSVExporter *m_csvExporter;
   
   string GetJournalFilePath();
   void WriteJournalEntry(string text);
   
public:
   CJournalManager(string journalPath, bool enableCSV, bool takeScreenshots);
   ~CJournalManager();
   
   bool Initialize();
   void LogPerfectSignal(string symbol, datetime time, int score, 
                        int categoryScores[], ENUM_SIGNAL_TYPE signalType,
                        double entryPrice, double sl, double tp1, double tp2,
                        string strengths, string weaknesses);
   void LogRejectedSignal(string symbol, datetime time, int score,
                          int categoryScores[], string reason);
   void TakeScreenshot(string symbol, datetime time);
   void ExportToCSV(datetime startDate, datetime endDate);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CJournalManager::CJournalManager(string journalPath, bool enableCSV, bool takeScreenshots)
{
   m_journalPath = journalPath;
   m_enableCSV = enableCSV;
   m_takeScreenshots = takeScreenshots;
   m_csvExporter = new CCSVExporter(journalPath);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CJournalManager::~CJournalManager()
{
   delete m_csvExporter;
}

//+------------------------------------------------------------------+
//| Initialize journal system                                        |
//+------------------------------------------------------------------+
bool CJournalManager::Initialize()
{
   // Create journal directory if it doesn't exist
   if(!FolderCreate(m_journalPath, FILE_COMMON))
   {
      int error = GetLastError();
      if(error != 5019) // Not "folder already exists"
      {
         Print("ERROR: Failed to create journal folder: ", m_journalPath, " | Error: ", error);
         return false;
      }
   }
   
   Print("Journal system initialized. Path: ", m_journalPath);
   Print("CSV Export: ", m_enableCSV ? "Enabled" : "Disabled");
   Print("Screenshots: ", m_takeScreenshots ? "Enabled" : "Disabled");
   
   return true;
}

//+------------------------------------------------------------------+
//| Get journal file path                                            |
//+------------------------------------------------------------------+
string CJournalManager::GetJournalFilePath()
{
   datetime current = TimeCurrent();
   string filename = m_journalPath + "\\" + "Journal_" + FormatDate(current) + ".txt";
   return filename;
}

//+------------------------------------------------------------------+
//| Write text to journal file                                       |
//+------------------------------------------------------------------+
void CJournalManager::WriteJournalEntry(string text)
{
   string filename = GetJournalFilePath();
   
   // Open file for appending (FILE_WRITE | FILE_READ allows appending)
   int fileHandle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
   
   if(fileHandle != INVALID_HANDLE)
   {
      // Move to end of file for appending
      FileSeek(fileHandle, 0, SEEK_END);
      FileWriteString(fileHandle, text + "\n");
      FileClose(fileHandle);
   }
   else
   {
      Print("WARNING: Failed to write journal entry. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Log perfect signal                                                |
//+------------------------------------------------------------------+
void CJournalManager::LogPerfectSignal(string symbol, datetime time, int score, 
                                       int categoryScores[], ENUM_SIGNAL_TYPE signalType,
                                       double entryPrice, double sl, double tp1, double tp2,
                                       string strengths, string weaknesses)
{
   string logText = "";
   logText += FormatDate(time) + " " + FormatDateTime(time) + " | " + symbol + " | M5\n";
   logText += "Score: " + IntegerToString(score) + "/100 🟢 PERFECT\n";
   logText += "Type: " + GetSignalTypeString(signalType) + " Signal\n";
   logText += "Entry: " + FormatPrice(symbol, entryPrice) + " | SL: " + FormatPrice(symbol, sl);
   logText += " | TP1: " + FormatPrice(symbol, tp1) + " | TP2: " + FormatPrice(symbol, tp2) + "\n\n";
   
   logText += "CATEGORY SCORES:\n";
   logText += "- Trend: " + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25\n";
   logText += "- EMA Quality: " + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20\n";
   logText += "- Signal: " + IntegerToString(categoryScores[CATEGORY_SIGNAL_STRENGTH]) + "/20\n";
   logText += "- Confirmation: " + IntegerToString(categoryScores[CATEGORY_CONFIRMATION]) + "/15\n";
   logText += "- Market: " + IntegerToString(categoryScores[CATEGORY_MARKET]) + "/10\n";
   logText += "- Context: " + IntegerToString(categoryScores[CATEGORY_CONTEXT]) + "/10\n\n";
   
   if(StringLen(strengths) > 0)
   {
      logText += "STRENGTHS:\n" + strengths + "\n\n";
   }
   if(StringLen(weaknesses) > 0)
   {
      logText += "WEAKNESSES:\n" + weaknesses + "\n\n";
   }
   
   logText += "USER DECISION: [ ] Traded [ ] Skipped\n";
   logText += "REASON: _________________________________\n\n";
   logText += "ACTUAL RESULT (fill after):\n";
   logText += "[ ] Win [ ] Loss [ ] Breakeven\n";
   logText += "Pips: _______ | Exit Time: _______\n";
   logText += "Notes: _________________________________\n";
   logText += "\n═══════════════════════════════════════\n\n";
   
   WriteJournalEntry(logText);
   
   // CSV export
   if(m_enableCSV)
   {
      JournalEntry entry;
      entry.time = time;
      entry.symbol = symbol;
      entry.timeframe = PERIOD_M5;
      entry.type = signalType;
      entry.totalScore = score;
      ArrayCopy(entry.categoryScores, categoryScores);
      entry.entry = entryPrice;
      entry.stopLoss = sl;
      entry.takeProfit1 = tp1;
      entry.takeProfit2 = tp2;
      entry.strengths = strengths;
      entry.weaknesses = weaknesses;
      entry.wasTraded = false;
      entry.wasSkipped = false;
      
      if(!m_csvExporter.ExportEntry(entry))
      {
         Print("WARNING: Failed to export entry to CSV");
      }
   }
   
   // Screenshot
   if(m_takeScreenshots)
   {
      TakeScreenshot(symbol, time);
   }
   
   Print("Journal entry logged for ", symbol, " | Score: ", score, "/100");
}

//+------------------------------------------------------------------+
//| Log rejected signal                                              |
//+------------------------------------------------------------------+
void CJournalManager::LogRejectedSignal(string symbol, datetime time, int score,
                                        int categoryScores[], string reason)
{
   string logText = "";
   logText += FormatDate(time) + " " + FormatDateTime(time) + " | " + symbol + " | M5\n";
   logText += "Score: " + FormatScore(score) + " - CORRECTLY SKIPPED\n";
   
   // Add category scores breakdown
   logText += "CATEGORY SCORES:\n";
   logText += "- Trend: " + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25\n";
   logText += "- EMA Quality: " + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20\n";
   logText += "- Signal: " + IntegerToString(categoryScores[CATEGORY_SIGNAL_STRENGTH]) + "/20\n";
   logText += "- Confirmation: " + IntegerToString(categoryScores[CATEGORY_CONFIRMATION]) + "/15\n";
   logText += "- Market: " + IntegerToString(categoryScores[CATEGORY_MARKET]) + "/10\n";
   logText += "- Context: " + IntegerToString(categoryScores[CATEGORY_CONTEXT]) + "/10\n\n";
   
   logText += "WHY REJECTED:\n" + reason + "\n";
   logText += "DECISION: ✓ Correctly avoided weak setup\n";
   logText += "\n═══════════════════════════════════════\n\n";
   
   WriteJournalEntry(logText);
   
   // CSV export for rejected signals (if enabled)
   if(m_enableCSV)
   {
      JournalEntry entry;
      entry.time = time;
      entry.symbol = symbol;
      entry.timeframe = PERIOD_M5;
      entry.type = SIGNAL_NONE; // No signal type for rejected
      entry.totalScore = score;
      ArrayCopy(entry.categoryScores, categoryScores);
      entry.entry = 0;
      entry.stopLoss = 0;
      entry.takeProfit1 = 0;
      entry.takeProfit2 = 0;
      entry.strengths = "";
      entry.weaknesses = reason;
      entry.wasTraded = false;
      entry.wasSkipped = true;
      
      if(!m_csvExporter.ExportEntry(entry))
      {
         Print("WARNING: Failed to export rejected signal to CSV");
      }
   }
}

//+------------------------------------------------------------------+
//| Take screenshot                                                  |
//+------------------------------------------------------------------+
void CJournalManager::TakeScreenshot(string symbol, datetime time)
{
   string filename = SCREENSHOT_PREFIX + symbol + "_" + FormatDate(time) + "_" + FormatDateTime(time);
   filename = StringReplace(filename, ":", "");
   filename = StringReplace(filename, " ", "_");
   
   ChartScreenShot(0, m_journalPath + "\\" + filename + ".png", 800, 600, ALIGN_LEFT);
}

//+------------------------------------------------------------------+
//| Export to CSV                                                    |
//+------------------------------------------------------------------+
void CJournalManager::ExportToCSV(datetime startDate, datetime endDate)
{
   if(m_csvExporter == NULL) return;
   
   Print("CSV Export requested for date range: ", FormatDate(startDate), " to ", FormatDate(endDate));
   
   // Read journal files in date range
   JournalEntry entries[];
   int entryCount = 0;
   
   // Iterate through dates in range
   datetime currentDate = startDate;
   while(currentDate <= endDate)
   {
      string filename = GetJournalFilePath();
      string dateStr = FormatDate(currentDate);
      filename = m_journalPath + "\\" + "Journal_" + dateStr + ".txt";
      
      // Try to read journal file (simplified - would need proper parsing)
      int fileHandle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
      if(fileHandle != INVALID_HANDLE)
      {
         // Note: Full implementation would parse journal entries from text file
         // For now, CSV export happens automatically when entries are logged
         FileClose(fileHandle);
      }
      
      // Move to next day
      currentDate += 86400; // Add one day
   }
   
   Print("CSV export complete. Check CSV files in journal folder.");
   Print("Note: Individual entries are exported automatically when logged.");
}

//+------------------------------------------------------------------+

