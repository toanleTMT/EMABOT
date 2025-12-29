//+------------------------------------------------------------------+
//| CSV_Exporter.mqh                                                 |
//| Exports journal entries to CSV                                   |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"

//+------------------------------------------------------------------+
//| CSV Exporter Class                                               |
//+------------------------------------------------------------------+
class CCSVExporter
{
private:
   string m_journalPath;
   
public:
   CCSVExporter(string journalPath);
   
   bool ExportEntry(JournalEntry &entry);
   bool ExportRange(datetime startDate, datetime endDate, JournalEntry &entries[]);
   bool CreateCSVFile(string filename);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCSVExporter::CCSVExporter(string journalPath)
{
   m_journalPath = journalPath;
}

//+------------------------------------------------------------------+
//| Export single entry to CSV                                       |
//+------------------------------------------------------------------+
bool CCSVExporter::ExportEntry(JournalEntry &entry)
{
   // Build filename with path
   string filename = m_journalPath + "\\" + CSV_FILENAME_PREFIX + FormatDate(entry.time) + ".csv";
   
   // Check if file exists by trying to open in read mode
   bool fileExists = false;
   int testHandle = FileOpen(filename, FILE_READ | FILE_CSV | FILE_COMMON, ',');
   if(testHandle != INVALID_HANDLE)
   {
      fileExists = true;
      FileClose(testHandle);
   }
   
   // Open file for writing (append if exists, create if not)
   int fileHandle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_CSV | FILE_COMMON, ',');
   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to open CSV file: ", filename, " | Error: ", GetLastError());
      return false;
   }
   
   // If file is new, write header first
   if(!fileExists)
   {
      FileWrite(fileHandle, "Time", "Symbol", "Timeframe", "Type", "Score", 
                "Trend", "EMA Quality", "Signal", "Confirmation", "Market", "Context",
                "Entry", "SL", "TP1", "TP2", "Strengths", "Weaknesses", 
                "Traded", "Skipped", "Result", "Pips", "Exit Time", "Notes");
   }
   
   // Move to end of file for appending
   FileSeek(fileHandle, 0, SEEK_END);
   
   // Write entry
   string typeStr = (entry.type == SIGNAL_BUY) ? "BUY" : "SELL";
   string resultStr = "";
   if(entry.actualResultWin) resultStr = "WIN";
   else if(entry.actualResultLoss) resultStr = "LOSS";
   else if(entry.actualResultBreakeven) resultStr = "BREAKEVEN";
   
   FileWrite(fileHandle, 
             FormatDate(entry.time) + " " + FormatDateTime(entry.time),
             entry.symbol,
             EnumToString(entry.timeframe),
             typeStr,
             IntegerToString(entry.totalScore),
             IntegerToString(entry.categoryScores[0]),
             IntegerToString(entry.categoryScores[1]),
             IntegerToString(entry.categoryScores[2]),
             IntegerToString(entry.categoryScores[3]),
             IntegerToString(entry.categoryScores[4]),
             IntegerToString(entry.categoryScores[5]),
             DoubleToString(entry.entry, 5),
             DoubleToString(entry.stopLoss, 5),
             DoubleToString(entry.takeProfit1, 5),
             DoubleToString(entry.takeProfit2, 5),
             entry.strengths,
             entry.weaknesses,
             entry.wasTraded ? "Yes" : "No",
             entry.wasSkipped ? "Yes" : "No",
             resultStr,
             DoubleToString(entry.actualPips, 2),
             entry.exitTime > 0 ? (FormatDate(entry.exitTime) + " " + FormatDateTime(entry.exitTime)) : "",
             entry.notes);
   
   FileClose(fileHandle);
   return true;
}

//+------------------------------------------------------------------+
//| Export date range to CSV                                         |
//+------------------------------------------------------------------+
bool CCSVExporter::ExportRange(datetime startDate, datetime endDate, JournalEntry &entries[])
{
   if(ArraySize(entries) == 0) return false;
   
   // Create filename based on date range
   string filename = m_journalPath + "\\" + CSV_FILENAME_PREFIX + 
                     FormatDate(startDate) + "_to_" + FormatDate(endDate) + ".csv";
   
   // Create file with header
   if(!CreateCSVFile(filename))
      return false;
   
   // Open file for appending
   int fileHandle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_COMMON, ',');
   if(fileHandle == INVALID_HANDLE)
      return false;
   
   // Write all entries
   for(int i = 0; i < ArraySize(entries); i++)
   {
      // Filter by date range
      if(entries[i].time < startDate || entries[i].time > endDate)
         continue;
      
      string typeStr = (entries[i].type == SIGNAL_BUY) ? "BUY" : "SELL";
      string resultStr = "";
      if(entries[i].actualResultWin) resultStr = "WIN";
      else if(entries[i].actualResultLoss) resultStr = "LOSS";
      else if(entries[i].actualResultBreakeven) resultStr = "BREAKEVEN";
      
      FileWrite(fileHandle, 
                FormatDate(entries[i].time) + " " + FormatDateTime(entries[i].time),
                entries[i].symbol,
                EnumToString(entries[i].timeframe),
                typeStr,
                IntegerToString(entries[i].totalScore),
                IntegerToString(entries[i].categoryScores[0]),
                IntegerToString(entries[i].categoryScores[1]),
                IntegerToString(entries[i].categoryScores[2]),
                IntegerToString(entries[i].categoryScores[3]),
                IntegerToString(entries[i].categoryScores[4]),
                IntegerToString(entries[i].categoryScores[5]),
                DoubleToString(entries[i].entry, 5),
                DoubleToString(entries[i].stopLoss, 5),
                DoubleToString(entries[i].takeProfit1, 5),
                DoubleToString(entries[i].takeProfit2, 5),
                entries[i].strengths,
                entries[i].weaknesses,
                entries[i].wasTraded ? "Yes" : "No",
                entries[i].wasSkipped ? "Yes" : "No",
                resultStr,
                DoubleToString(entries[i].actualPips, 2),
                entries[i].exitTime > 0 ? (FormatDate(entries[i].exitTime) + " " + FormatDateTime(entries[i].exitTime)) : "",
                entries[i].notes);
   }
   
   FileClose(fileHandle);
   return true;
}

//+------------------------------------------------------------------+
//| Create CSV file with header                                      |
//+------------------------------------------------------------------+
bool CCSVExporter::CreateCSVFile(string filename)
{
   // Check if file already exists
   int testHandle = FileOpen(filename, FILE_READ | FILE_CSV | FILE_COMMON, ',');
   if(testHandle != INVALID_HANDLE)
   {
      FileClose(testHandle);
      // File exists, don't overwrite - return true to allow appending
      return true;
   }
   
   // Create new file with header
   int fileHandle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_COMMON, ',');
   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create CSV file: ", filename, " | Error: ", GetLastError());
      return false;
   }
   
   FileWrite(fileHandle, "Time", "Symbol", "Timeframe", "Type", "Score", 
             "Trend", "EMA Quality", "Signal", "Confirmation", "Market", "Context",
             "Entry", "SL", "TP1", "TP2", "Strengths", "Weaknesses", 
             "Traded", "Skipped", "Result", "Pips", "Exit Time", "Notes");
   
   FileClose(fileHandle);
   return true;
}

//+------------------------------------------------------------------+

