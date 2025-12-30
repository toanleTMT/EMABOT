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
   void LogRejectedSignal(string symbol, datetime time, int score,
                          string reason); // Overload for when categoryScores is NULL
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
      int error = GetLastError();
      Print("WARNING: Failed to write journal entry. Error: ", error, " | File: ", filename);
      
      // Try to create directory if it doesn't exist
      if(error == 5002) // File not found - directory might not exist
      {
         if(FolderCreate(m_journalPath, FILE_COMMON))
         {
            // Retry opening file after creating directory
            fileHandle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
            if(fileHandle != INVALID_HANDLE)
            {
               FileWriteString(fileHandle, text + "\n");
               FileClose(fileHandle);
               Print("Journal file created successfully: ", filename);
            }
            else
            {
               Print("ERROR: Still failed to create journal file after creating directory. Error: ", GetLastError());
            }
         }
         else
         {
            Print("ERROR: Failed to create journal directory: ", m_journalPath, " | Error: ", GetLastError());
         }
      }
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
   // OPTIMIZATION: Pre-format strings once to avoid repeated function calls
   string dateStr = FormatDate(time);
   string timeStr = FormatDateTime(time);
   string typeStr = GetSignalTypeString(signalType);
   string entryStr = FormatPrice(symbol, entryPrice);
   string slStr = FormatPrice(symbol, sl);
   string tp1Str = FormatPrice(symbol, tp1);
   string tp2Str = FormatPrice(symbol, tp2);
   
   // OPTIMIZATION: Use StringFormat for better performance with multiple concatenations
   string logText = StringFormat("%s %s | %s | M5\n", dateStr, timeStr, symbol);
   logText += StringFormat("Score: %d/100 🟢 PERFECT\n", score);
   logText += StringFormat("Type: %s Signal\n", typeStr);
   logText += StringFormat("Entry: %s | SL: %s | TP1: %s | TP2: %s\n\n", 
                          entryStr, slStr, tp1Str, tp2Str);
   
   logText += "CATEGORY SCORES:\n";
   logText += StringFormat("- Trend: %d/25\n", categoryScores[CATEGORY_TREND]);
   logText += StringFormat("- EMA Quality: %d/20\n", categoryScores[CATEGORY_EMA_QUALITY]);
   logText += StringFormat("- Signal: %d/20\n", categoryScores[CATEGORY_SIGNAL_STRENGTH]);
   logText += StringFormat("- Confirmation: %d/15\n", categoryScores[CATEGORY_CONFIRMATION]);
   logText += StringFormat("- Market: %d/10\n", categoryScores[CATEGORY_MARKET]);
   logText += StringFormat("- Context: %d/10\n\n", categoryScores[CATEGORY_CONTEXT]);
   
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
   if(m_enableCSV && m_csvExporter != NULL)
   {
      JournalEntry entry;
      entry.time = time;
      entry.symbol = symbol;
      entry.timeframe = PERIOD_M5;
      entry.type = signalType;
      entry.totalScore = score;
      
      // Copy category scores safely
      if(categoryScores != NULL && ArraySize(categoryScores) >= TOTAL_CATEGORIES)
      {
         ArrayCopy(entry.categoryScores, categoryScores);
      }
      else
      {
         ArrayInitialize(entry.categoryScores, 0);
      }
      
      entry.entry = entryPrice;
      entry.stopLoss = sl;
      entry.takeProfit1 = tp1;
      entry.takeProfit2 = tp2;
      entry.strengths = strengths;
      entry.weaknesses = weaknesses;
      entry.wasTraded = false;
      entry.wasSkipped = false;
      entry.actualResultWin = false;
      entry.actualResultLoss = false;
      entry.actualResultBreakeven = false;
      entry.actualPips = 0;
      entry.exitTime = 0;
      entry.notes = "";
      entry.rejectionReason = "";
      entry.userReason = "";
      
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
   // OPTIMIZATION: Pre-format strings once
   string dateStr = FormatDate(time);
   string timeStr = FormatDateTime(time);
   string scoreStr = FormatScore(score);
   
   // OPTIMIZATION: Use StringFormat for better performance
   string logText = StringFormat("%s %s | %s | M5\n", dateStr, timeStr, symbol);
   logText += StringFormat("Score: %s - CORRECTLY SKIPPED\n", scoreStr);
   
   // Add category scores breakdown (if available)
   if(categoryScores != NULL && ArraySize(categoryScores) >= TOTAL_CATEGORIES)
   {
      logText += "CATEGORY SCORES:\n";
      logText += StringFormat("- Trend: %d/25\n", categoryScores[CATEGORY_TREND]);
      logText += StringFormat("- EMA Quality: %d/20\n", categoryScores[CATEGORY_EMA_QUALITY]);
      logText += StringFormat("- Signal: %d/20\n", categoryScores[CATEGORY_SIGNAL_STRENGTH]);
      logText += StringFormat("- Confirmation: %d/15\n", categoryScores[CATEGORY_CONFIRMATION]);
      logText += StringFormat("- Market: %d/10\n", categoryScores[CATEGORY_MARKET]);
      logText += StringFormat("- Context: %d/10\n\n", categoryScores[CATEGORY_CONTEXT]);
   }
   else
   {
      logText += StringFormat("Score: %d/100\n\n", score);
   }
   
   logText += "WHY REJECTED:\n" + reason + "\n";
   logText += "DECISION: ✓ Correctly avoided weak setup\n";
   logText += "\n═══════════════════════════════════════\n\n";
   
   WriteJournalEntry(logText);
   
   // CSV export for rejected signals (if enabled)
   if(m_enableCSV && m_csvExporter != NULL)
   {
      JournalEntry entry;
      entry.time = time;
      entry.symbol = symbol;
      entry.timeframe = PERIOD_M5;
      entry.type = SIGNAL_NONE; // No signal type for rejected
      entry.totalScore = score;
      
      // Copy category scores if available
      if(categoryScores != NULL && ArraySize(categoryScores) >= TOTAL_CATEGORIES)
      {
         ArrayCopy(entry.categoryScores, categoryScores);
      }
      else
      {
         ArrayInitialize(entry.categoryScores, 0);
      }
      
      entry.entry = 0;
      entry.stopLoss = 0;
      entry.takeProfit1 = 0;
      entry.takeProfit2 = 0;
      entry.strengths = "";
      entry.weaknesses = reason;
      entry.wasTraded = false;
      entry.wasSkipped = true;
      entry.actualResultWin = false;
      entry.actualResultLoss = false;
      entry.actualResultBreakeven = false;
      entry.actualPips = 0;
      entry.exitTime = 0;
      entry.notes = "";
      
      if(!m_csvExporter.ExportEntry(entry))
      {
         Print("WARNING: Failed to export rejected signal to CSV");
      }
   }
}

//+------------------------------------------------------------------+
//| Log rejected signal (overload without category scores)           |
//+------------------------------------------------------------------+
void CJournalManager::LogRejectedSignal(string symbol, datetime time, int score, string reason)
{
   // Call main function with NULL category scores
   LogRejectedSignal(symbol, time, score, NULL, reason);
}

//+------------------------------------------------------------------+
//| Take screenshot                                                  |
//+------------------------------------------------------------------+
void CJournalManager::TakeScreenshot(string symbol, datetime time)
{
   // Sanitize filename - remove invalid characters
   string filename = SCREENSHOT_PREFIX + symbol + "_" + FormatDate(time) + "_" + FormatDateTime(time);
   filename = StringReplace(filename, ":", "");
   filename = StringReplace(filename, " ", "_");
   filename = StringReplace(filename, "/", "-");
   filename = StringReplace(filename, "\\", "-");
   
   // Build full path
   string fullPath = m_journalPath + "\\" + filename + ".png";
   
   // Take screenshot
   if(ChartScreenShot(0, fullPath, 800, 600, ALIGN_LEFT))
   {
      Print("Screenshot saved: ", fullPath);
   }
   else
   {
      int error = GetLastError();
      Print("WARNING: Failed to take screenshot. Error: ", error, " | Path: ", fullPath);
   }
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

