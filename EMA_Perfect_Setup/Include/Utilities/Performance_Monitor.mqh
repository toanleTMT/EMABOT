//+------------------------------------------------------------------+
//| Performance_Monitor.mqh                                          |
//| Monitors EA performance and resource usage                        |
//+------------------------------------------------------------------+

#include "../Config.mqh"

//+------------------------------------------------------------------+
//| Performance Monitor Class                                         |
//+------------------------------------------------------------------+
class CPerformanceMonitor
{
private:
   datetime m_startTime;
   int m_scanCount;
   int m_signalCount;
   int m_errorCount;
   double m_maxMemoryUsage;
   
public:
   CPerformanceMonitor();
   
   void Start();
   void RecordScan();
   void RecordSignal();
   void RecordError();
   void UpdateMemoryUsage();
   string GetPerformanceReport();
   void Reset();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPerformanceMonitor::CPerformanceMonitor()
{
   m_startTime = 0;
   m_scanCount = 0;
   m_signalCount = 0;
   m_errorCount = 0;
   m_maxMemoryUsage = 0; // Object count
}

//+------------------------------------------------------------------+
//| Start monitoring                                                 |
//+------------------------------------------------------------------+
void CPerformanceMonitor::Start()
{
   m_startTime = TimeCurrent();
   m_scanCount = 0;
   m_signalCount = 0;
   m_errorCount = 0;
   m_maxMemoryUsage = 0;
}

//+------------------------------------------------------------------+
//| Record scan operation                                            |
//+------------------------------------------------------------------+
void CPerformanceMonitor::RecordScan()
{
   m_scanCount++;
   UpdateMemoryUsage();
}

//+------------------------------------------------------------------+
//| Record signal detection                                          |
//+------------------------------------------------------------------+
void CPerformanceMonitor::RecordSignal()
{
   m_signalCount++;
}

//+------------------------------------------------------------------+
//| Record error                                                     |
//+------------------------------------------------------------------+
void CPerformanceMonitor::RecordError()
{
   m_errorCount++;
}

//+------------------------------------------------------------------+
//| Update memory usage                                              |
//+------------------------------------------------------------------+
void CPerformanceMonitor::UpdateMemoryUsage()
{
   // Track maximum memory usage
   // Note: MQL5 doesn't provide direct memory usage APIs, but we can track object counts
   int objectCount = ObjectsTotal(0);
   // Store as a simple metric (object count as proxy for memory usage)
   if(objectCount > m_maxMemoryUsage)
      m_maxMemoryUsage = objectCount;
}

//+------------------------------------------------------------------+
//| Get performance report                                            |
//+------------------------------------------------------------------+
string CPerformanceMonitor::GetPerformanceReport()
{
   datetime elapsed = TimeCurrent() - m_startTime;
   int hours = (int)(elapsed / 3600);
   int minutes = (int)((elapsed % 3600) / 60);
   int seconds = (int)(elapsed % 60);
   
   string report = "";
   report += "╔═══════════════════════════════════════╗\n";
   report += "║ PERFORMANCE REPORT                     ║\n";
   report += "╠═══════════════════════════════════════╣\n";
   report += "║ Runtime: " + IntegerToString(hours) + "h " + IntegerToString(minutes) + "m " + IntegerToString(seconds) + "s\n";
   report += "║ Scans performed: " + IntegerToString(m_scanCount) + "\n";
   report += "║ Signals detected: " + IntegerToString(m_signalCount) + "\n";
   report += "║ Errors encountered: " + IntegerToString(m_errorCount) + "\n";
   report += "║ Max chart objects: " + IntegerToString(m_maxMemoryUsage) + "\n";
   
   if(m_scanCount > 0)
   {
      double avgTimePerScan = (double)elapsed / m_scanCount;
      report += "║ Avg time per scan: " + DoubleToString(avgTimePerScan, 2) + "s\n";
      
      if(m_signalCount > 0)
      {
         double signalRate = (double)m_signalCount / m_scanCount * 100.0;
         report += "║ Signal detection rate: " + DoubleToString(signalRate, 2) + "%\n";
      }
   }
   
   report += "╚═══════════════════════════════════════╝\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Reset counters                                                   |
//+------------------------------------------------------------------+
void CPerformanceMonitor::Reset()
{
   Start();
}

//+------------------------------------------------------------------+

