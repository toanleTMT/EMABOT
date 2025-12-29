//+------------------------------------------------------------------+
//|                                          EMA_Perfect_Setup.mq5    |
//|                        EMA Perfect Setup Scanner EA v2.0         |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "EMA Perfect Setup EA"
#property version   "2.00"
#property description "Scans markets for EMA scalping setups and scores them 0-100 points"
#property description "ONLY alerts when setup scores ≥85 points (PERFECT quality)"
#property description "Does NOT auto-trade - trader manually decides to enter"

//--- Includes
#include "Include/Config.mqh"
#include "Include/Structs.mqh"
#include "Include/Indicators/EMA_Manager.mqh"
#include "Include/Indicators/RSI_Manager.mqh"
#include "Include/Scoring/Setup_Scorer.mqh"
#include "Include/Scoring/Setup_Analyzer.mqh"
#include "Include/Scoring/Score_Cache.mqh"
#include "Include/Visuals/Dashboard.mqh"
#include "Include/Visuals/Arrow_Manager.mqh"
#include "Include/Visuals/Label_Manager.mqh"
#include "Include/Visuals/Panel_Manager.mqh"
#include "Include/Alerts/Alert_Manager.mqh"
#include "Include/Journal/Journal_Manager.mqh"
#include "Include/Utilities/Time_Utils.mqh"
#include "Include/Utilities/Price_Utils.mqh"
#include "Include/Utilities/String_Utils.mqh"
#include "Include/Utilities/Error_Handler.mqh"
#include "Include/Utilities/Signal_Validator.mqh"
#include "Include/Utilities/Debug_Helper.mqh"
#include "Include/Utilities/Symbol_Utils.mqh"
#include "Include/Utilities/Input_Validator.mqh"
#include "Include/Utilities/Performance_Monitor.mqh"
#include "Include/Utilities/Scoring_Test.mqh"

//+------------------------------------------------------------------+
//| Expert Advisor Input Parameters                                   |
//+------------------------------------------------------------------+

//--- General Settings ---
input group "═══ GENERAL SETTINGS ═══"
input string   InpSymbols = "EURUSD,GBPUSD";              // Symbols to scan (comma-separated)
input ENUM_TIMEFRAMES InpSignalTF = PERIOD_M5;            // Signal Timeframe (M5 recommended)
input ENUM_TIMEFRAMES InpTrendTF = PERIOD_H1;             // Trend Timeframe (H1 recommended)
input int      InpScanInterval = 15;                      // Scan interval (seconds)
input int      InpMagicNumber = 987654;                   // Magic Number

//--- Scoring System ---
input group "═══ SCORING & FILTERING ═══"
input int      InpMinScoreAlert = 85;                     // Minimum score for alert (85=Perfect)
input bool     InpShowGoodSetups = false;                 // Show GOOD setups (70-84)?
input bool     InpShowWeakSetups = false;                 // Show WEAK setups (50-69)?
input bool     InpLogRejectedSetups = true;               // Log rejected setups to journal?

//--- EMA Settings ---
input group "═══ EMA SETTINGS ═══"
input int      InpEMA_Fast = 9;                           // Fast EMA Period
input int      InpEMA_Medium = 21;                        // Medium EMA Period
input int      InpEMA_Slow = 50;                          // Slow EMA Period
input ENUM_MA_METHOD InpEMA_Method = MODE_EMA;            // MA Method (EMA recommended)
input ENUM_APPLIED_PRICE InpEMA_Price = PRICE_CLOSE;      // Applied Price

//--- RSI Settings ---
input group "═══ RSI SETTINGS ═══"
input bool     InpUseRSI = true;                          // Use RSI filter?
input int      InpRSI_Period = 14;                        // RSI Period
input int      InpRSI_BuyLevel = 50;                      // RSI Buy threshold (>)
input int      InpRSI_SellLevel = 50;                     // RSI Sell threshold (<)

//--- Scoring Thresholds ---
input group "═══ QUALITY THRESHOLDS ═══"
input int      InpMinH1Distance = 20;                     // Min H1 price-EMA50 distance (pips)
input int      InpMinEMASeparation = 8;                   // Min M5 EMA separation (pips)
input int      InpMinCandleBody = 50;                     // Min candle body percentage (%)
input double   InpMaxSpread = 2.5;                        // Max spread for signals (pips)

//--- Risk Management ---
input group "═══ RISK MANAGEMENT ═══"
input double   InpStopLossPips = 25;                      // Stop Loss (pips)
input double   InpTakeProfit1Pips = 25;                   // Take Profit 1 (pips) - 50% close
input double   InpTakeProfit2Pips = 50;                   // Take Profit 2 (pips) - 50% close
input bool     InpAutoLotSize = true;                     // Auto calculate lot size?
input double   InpRiskPercent = 1.0;                      // Risk per trade (% of account)
input double   InpFixedLot = 0.01;                        // Fixed lot size (if auto=false)
input int      InpMaxSignalsPerDay = 10;                  // Max signals per day (0=unlimited)

//--- Visual Settings ---
input group "═══ VISUAL SETTINGS ═══"
input bool     InpShowArrows = true;                      // Show arrow signals?
input bool     InpShowLabels = true;                      // Show detailed labels?
input bool     InpShowDashboard = true;                   // Show main dashboard?
input bool     InpShowBreakdownPanel = true;              // Show score breakdown panel?
input int      InpArrowSize = 3;                          // Arrow size (1-5)
input color    InpBuyColor = clrLime;                     // BUY signal color
input color    InpSellColor = clrRed;                     // SELL signal color
input color    InpGoodColor = clrYellow;                  // GOOD setup color
input color    InpWeakColor = clrGray;                    // WEAK setup color
input int      InpLabelFontSize = 8;                      // Label font size

//--- Alert Settings ---
input group "═══ ALERT SETTINGS ═══"
input bool     InpAlert_Perfect = true;                   // Alert on PERFECT setups (85+)?
input bool     InpAlert_Good = false;                     // Alert on GOOD setups (70-84)?
input bool     InpAlert_Weak = false;                     // Alert on WEAK setups (50-69)?

input bool     InpPopup_Perfect = true;                   // Popup for perfect?
input bool     InpSound_Perfect = true;                   // Sound for perfect?
input bool     InpPush_Perfect = false;                   // Push notification for perfect?
input bool     InpEmail_Perfect = false;                  // Email for perfect?

input string   InpSoundFile_Perfect = "alert2.wav";       // Perfect setup sound file
input string   InpSoundFile_Good = "alert.wav";           // Good setup sound file

//--- Journal Settings ---
input group "═══ TRADING JOURNAL ═══"
input bool     InpEnableJournal = true;                   // Enable trading journal?
input bool     InpExportCSV = true;                       // Export journal to CSV?
input bool     InpTakeScreenshots = false;                // Take screenshots on perfect setup?
input string   InpJournalPath = "EMA_Journal";            // Journal folder name

//--- Advanced Scoring Weights (for experienced users) ---
input group "═══ ADVANCED: SCORING WEIGHTS ═══"
input int      InpWeight_Trend = 25;                      // Trend Alignment weight (default 25)
input int      InpWeight_EMAQuality = 20;                 // EMA Quality weight (default 20)
input int      InpWeight_SignalStrength = 20;             // Signal Strength weight (default 20)
input int      InpWeight_Confirmation = 15;               // Confirmation weight (default 15)
input int      InpWeight_Market = 10;                     // Market Conditions weight (default 10)
input int      InpWeight_Context = 10;                    // Context & Timing weight (default 10)

//--- Debug Settings ---
input group "═══ DEBUG SETTINGS ═══"
input bool     InpEnableDebug = false;                    // Enable debug logging?
input bool     InpRunScoringTest = false;                 // Run scoring system test on startup?

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

// Indicator managers
CEMAManager *g_emaH1 = NULL;
CEMAManager *g_emaM5 = NULL;
CRSIManager *g_rsi = NULL;

// Performance optimization cache
CScoreCache *g_scoreCache = NULL;

// Scoring and visual components
CSetupScorer *g_scorer = NULL;
CSetupAnalyzer *g_analyzer = NULL;
CSignalValidator *g_validator = NULL;
CDebugHelper *g_debug = NULL;
CDashboard *g_dashboard = NULL;
CArrowManager *g_arrowManager = NULL;
CLabelManager *g_labelManager = NULL;
CPanelManager *g_panelManager = NULL;
CAlertManager *g_alertManager = NULL;
CJournalManager *g_journal = NULL;
CPerformanceMonitor *g_perfMonitor = NULL;

// Symbol arrays
string g_symbols[];
int g_signalsToday = 0;
datetime g_lastDayCheck = 0;
datetime g_lastSignalTime[];

// Statistics
int g_perfectToday = 0;
int g_goodToday = 0;
int g_weakToday = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== EMA Perfect Setup Scanner EA v2.0 Initializing ===");
   
   // Validate input parameters
   int validationErrors[];
   if(!CInputValidator::ValidateInputs(InpSymbols, InpMinScoreAlert, InpMaxSpread,
                                       (int)InpStopLossPips, (int)InpTakeProfit1Pips, (int)InpTakeProfit2Pips,
                                       InpRiskPercent, validationErrors))
   {
      string errorMsg = CInputValidator::GetValidationErrors(validationErrors);
      Print("VALIDATION ERRORS:\n", errorMsg);
      Print("Please fix input parameters and restart EA.");
      Alert("EA Initialization Failed: Invalid input parameters. Check Experts tab for details.");
      return INIT_FAILED;
   }
   
   // Validate and parse symbols
   if(!CInputValidator::ValidateSymbols(InpSymbols, g_symbols))
   {
      Print("ERROR: No valid symbols found after validation!");
      Print("Please check that symbols are available in Market Watch.");
      return INIT_FAILED;
   }
   
   Print("Symbols to scan: ", ArraySize(g_symbols));
   for(int i = 0; i < ArraySize(g_symbols); i++)
   {
      Print("  - ", g_symbols[i]);
   }
   
   // Initialize indicator managers
   g_emaH1 = new CEMAManager();
   if(!g_emaH1.Initialize(g_symbols, InpTrendTF, InpEMA_Fast, InpEMA_Medium, InpEMA_Slow, InpEMA_Method, InpEMA_Price))
   {
      Print("ERROR: Failed to initialize H1 EMA manager!");
      return INIT_FAILED;
   }
   
   g_emaM5 = new CEMAManager();
   if(!g_emaM5.Initialize(g_symbols, InpSignalTF, InpEMA_Fast, InpEMA_Medium, InpEMA_Slow, InpEMA_Method, InpEMA_Price))
   {
      Print("ERROR: Failed to initialize M5 EMA manager!");
      return INIT_FAILED;
   }
   
   if(InpUseRSI)
   {
      g_rsi = new CRSIManager();
      if(!g_rsi.Initialize(g_symbols, InpSignalTF, InpRSI_Period))
      {
         Print("ERROR: Failed to initialize RSI manager!");
         return INIT_FAILED;
      }
   }
   else
   {
      // Create dummy RSI manager (won't be used but needed for scorer)
      g_rsi = new CRSIManager();
      g_rsi.Initialize(g_symbols, InpSignalTF, InpRSI_Period);
   }
   
   // Initialize scorer
   g_scorer = new CSetupScorer(g_emaH1, g_emaM5, g_rsi,
                               InpMinH1Distance, InpMinEMASeparation, InpMinCandleBody,
                               InpMaxSpread,
                               InpWeight_Trend, InpWeight_EMAQuality, InpWeight_SignalStrength,
                               InpWeight_Confirmation, InpWeight_Market, InpWeight_Context);
   
   // Initialize analyzer
   g_analyzer = new CSetupAnalyzer(InpMinScoreAlert);
   
   // Initialize validator
   g_validator = new CSignalValidator(g_emaH1, g_emaM5, g_rsi,
                                     InpMaxSpread, InpMinEMASeparation,
                                     InpUseRSI, InpRSI_BuyLevel, InpRSI_SellLevel);
   
   // Initialize debug helper
   g_debug = new CDebugHelper(InpEnableDebug, "[EMA_EA]");
   
   // Initialize performance monitor
   g_perfMonitor = new CPerformanceMonitor();
   g_perfMonitor.Start();
   
   // Run scoring system test if enabled
   if(InpRunScoringTest)
   {
      Print("\n═══════════════════════════════════════════════════════════");
      Print("RUNNING SCORING SYSTEM TEST...");
      Print("═══════════════════════════════════════════════════════════\n");
      
      CScoringTest::RunAllTests(g_emaH1, g_emaM5, g_rsi);
      
      Print("\n═══════════════════════════════════════════════════════════");
      Print("TEST COMPLETE - Continuing with EA initialization...");
      Print("═══════════════════════════════════════════════════════════\n");
   }
   
   // Initialize visual components
   if(InpShowDashboard)
   {
      g_dashboard = new CDashboard();
      g_dashboard.Initialize();
      g_dashboard.Show();
   }
   
   if(InpShowArrows)
   {
      g_arrowManager = new CArrowManager(InpArrowSize, InpBuyColor, InpSellColor, InpGoodColor, InpWeakColor);
   }
   
   if(InpShowLabels)
   {
      g_labelManager = new CLabelManager(InpLabelFontSize);
   }
   
   if(InpShowBreakdownPanel)
   {
      g_panelManager = new CPanelManager();
      g_panelManager.Initialize();
      g_panelManager.Show();
   }
   
   // Initialize alert manager
   g_alertManager = new CAlertManager(InpPopup_Perfect, InpSound_Perfect, InpPush_Perfect, InpEmail_Perfect,
                                      InpSoundFile_Perfect, InpSoundFile_Good);
   
   // Initialize journal
   if(InpEnableJournal)
   {
      g_journal = new CJournalManager(InpJournalPath, InpExportCSV, InpTakeScreenshots);
      if(!g_journal.Initialize())
      {
         Print("WARNING: Failed to initialize journal system!");
      }
   }
   
   // Initialize last signal time array
   ArrayResize(g_lastSignalTime, ArraySize(g_symbols));
   ArrayInitialize(g_lastSignalTime, 0);
   
   // Set timer
   EventSetTimer(InpScanInterval);
   
   Print("=== Initialization Complete ===");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   
   // Cleanup all components
   if(g_emaH1 != NULL) { g_emaH1.Deinitialize(); delete g_emaH1; }
   if(g_emaM5 != NULL) { g_emaM5.Deinitialize(); delete g_emaM5; }
   if(g_rsi != NULL) { g_rsi.Deinitialize(); delete g_rsi; }
   if(g_scorer != NULL) delete g_scorer;
   if(g_analyzer != NULL) delete g_analyzer;
   if(g_validator != NULL) delete g_validator;
   if(g_debug != NULL) delete g_debug;
   if(g_perfMonitor != NULL)
   {
      if(InpEnableDebug)
         Print(g_perfMonitor.GetPerformanceReport());
      delete g_perfMonitor;
   }
   if(g_dashboard != NULL) { g_dashboard.Delete(); delete g_dashboard; }
   if(g_arrowManager != NULL) { g_arrowManager.DeleteAllArrows(); delete g_arrowManager; }
   if(g_labelManager != NULL) { g_labelManager.DeleteAllLabels(); delete g_labelManager; }
   if(g_panelManager != NULL) { g_panelManager.Delete(); delete g_panelManager; }
   if(g_alertManager != NULL) delete g_alertManager;
   if(g_journal != NULL) delete g_journal;
   
   Print("=== EMA Perfect Setup Scanner EA Stopped ===");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Check if new day
   if(IsNewDay(g_lastDayCheck))
   {
      g_signalsToday = 0;
      g_perfectToday = 0;
      g_goodToday = 0;
      g_weakToday = 0;
      Print("New day started - resetting counters");
   }
   
   // Skip if max signals reached
   if(InpMaxSignalsPerDay > 0 && g_signalsToday >= InpMaxSignalsPerDay)
      return;
   
   // Record scan
   if(g_perfMonitor != NULL)
      g_perfMonitor.RecordScan();
   
   // Scan all symbols
   for(int i = 0; i < ArraySize(g_symbols); i++)
   {
      string symbol = g_symbols[i];
      
      // Check if new bar formed
      if(!IsNewBar(symbol, InpSignalTF))
         continue;
      
      // Determine signal type
      ENUM_SIGNAL_TYPE signalType = DetermineSignalType(symbol);
      if(signalType == SIGNAL_NONE)
         continue;
      
      // Validate signal using validator
      bool isValidSignal = false;
      if(signalType == SIGNAL_BUY)
         isValidSignal = g_validator.ValidateBuySignal(symbol);
      else if(signalType == SIGNAL_SELL)
         isValidSignal = g_validator.ValidateSellSignal(symbol);
      
      if(!isValidSignal)
      {
         if(InpEnableDebug && g_debug != NULL)
         {
            string errors = g_validator.GetValidationErrors(symbol, signalType);
            g_debug.Log("Signal validation failed for " + symbol + ": " + errors);
         }
         continue;
      }
      
      // Check if we already signaled on this bar
      datetime currentBarTime = iTime(symbol, InpSignalTF, 0);
      if(g_lastSignalTime[i] == currentBarTime)
         continue; // Already processed this bar
      
      // Calculate score
      int categoryScores[];
      int totalScore = g_scorer.CalculateTotalScore(symbol, signalType, categoryScores);
      
      // Debug logging
      if(InpEnableDebug && g_debug != NULL)
      {
         g_debug.LogSignal(symbol, signalType, totalScore);
         g_debug.LogScoreBreakdown(symbol, totalScore, categoryScores);
      }
      
      // Check spread filter (additional check)
      double spread = GetSpreadPips(symbol);
      if(spread > InpMaxSpread)
      {
         if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
         {
            string reason = "Spread too high: " + FormatPips(spread) + " (max: " + FormatPips(InpMaxSpread) + ")";
            g_journal.LogRejectedSignal(symbol, TimeCurrent(), totalScore, categoryScores, reason);
         }
         continue;
      }
      
      // Calculate entry/SL/TP
      double entry = GetCurrentPrice(symbol, signalType);
      double sl = CalculateStopLoss(symbol, signalType, entry);
      double tp1 = CalculateTakeProfit(symbol, signalType, entry, InpTakeProfit1Pips);
      double tp2 = CalculateTakeProfit(symbol, signalType, entry, InpTakeProfit2Pips);
      
      // Get quality level using analyzer
      ENUM_SETUP_QUALITY quality = g_analyzer.GetQuality(totalScore);
      
      // Process based on quality
      if(g_analyzer.IsPerfectSetup(totalScore))
      {
         // PERFECT SETUP FOUND!
         g_perfectToday++;
         g_signalsToday++;
         g_lastSignalTime[i] = currentBarTime;
         
         // Get strengths and weaknesses analysis
         string analysis = g_scorer.GetStrengthsAndWeaknesses(symbol, signalType, categoryScores);
         string strengths = "";
         string weaknesses = "";
         
         // Parse analysis to extract strengths and weaknesses
         // Format: "STRENGTHS:\n...\nMINOR WEAKNESSES:\n..." or just strengths
         if(StringFind(analysis, "STRENGTHS:") >= 0)
         {
            int strengthsStart = StringFind(analysis, "STRENGTHS:") + 10;
            int weaknessesStart = StringFind(analysis, "MINOR WEAKNESSES:");
            if(weaknessesStart >= 0)
            {
               strengths = StringSubstr(analysis, strengthsStart, weaknessesStart - strengthsStart);
               weaknesses = StringSubstr(analysis, weaknessesStart + 17); // "MINOR WEAKNESSES:" = 17 chars
            }
            else
            {
               strengths = StringSubstr(analysis, strengthsStart);
            }
         }
         else
         {
            strengths = analysis; // If no format, use entire string as strengths
         }
         
         // Visual
         if(InpShowArrows && g_arrowManager != NULL)
            g_arrowManager.DrawArrow(symbol, currentBarTime, entry, totalScore, signalType);
         
         if(InpShowLabels && g_labelManager != NULL)
         {
            string strengths = g_scorer.GetStrengthsAndWeaknesses(symbol, signalType, categoryScores);
            g_labelManager.DrawDetailedLabel(symbol, currentBarTime, entry, totalScore, categoryScores, 
                                            signalType, entry, sl, tp1, tp2, strengths);
         }
         
         if(InpShowDashboard && g_dashboard != NULL)
            g_dashboard.Update(symbol, totalScore, categoryScores, signalType, entry, sl, tp1, tp2,
                              g_perfectToday, g_goodToday, g_weakToday, spread);
         
         if(InpShowBreakdownPanel && g_panelManager != NULL)
            g_panelManager.Update(symbol, signalType, categoryScores, g_scorer);
         
         if(InpShowDashboard && g_dashboard != NULL)
            g_dashboard.Flash(InpBuyColor, 5000);
         
         // Alerts
         if(InpAlert_Perfect && g_alertManager != NULL)
         {
            g_alertManager.SendPerfectSetupAlert(symbol, totalScore, signalType, entry, sl, tp1, tp2, 
                                                 strengths, weaknesses);
         }
         
         // Journal
         if(InpEnableJournal && g_journal != NULL)
         {
            g_journal.LogPerfectSignal(symbol, currentBarTime, totalScore, categoryScores, signalType,
                                      entry, sl, tp1, tp2, strengths, weaknesses);
         }
         
         Print("🟢 PERFECT SETUP FOUND! ", symbol, " | Score: ", totalScore, "/100 | Type: ", 
               GetSignalTypeString(signalType));
         
         // Record signal
         if(g_perfMonitor != NULL)
            g_perfMonitor.RecordSignal();
      }
      else if(g_analyzer.IsGoodSetup(totalScore) && InpShowGoodSetups)
      {
         // Good setup
         g_goodToday++;
         
         if(InpShowArrows && g_arrowManager != NULL)
            g_arrowManager.DrawArrow(symbol, currentBarTime, entry, totalScore, signalType);
         
         if(InpAlert_Good && g_alertManager != NULL)
            g_alertManager.SendGoodSetupAlert(symbol, totalScore, signalType);
         
         if(InpEnableJournal && g_journal != NULL)
         {
            string reason = "GOOD but below threshold (score: " + IntegerToString(totalScore) + ")";
            g_journal.LogRejectedSignal(symbol, currentBarTime, totalScore, categoryScores, reason);
         }
      }
      else if(g_analyzer.IsWeakSetup(totalScore) && InpShowWeakSetups)
      {
         // Weak setup
         g_weakToday++;
         
         if(InpShowArrows && g_arrowManager != NULL)
            g_arrowManager.DrawArrow(symbol, currentBarTime, entry, totalScore, signalType);
         
         if(InpEnableJournal && InpLogRejectedSetups && g_journal != NULL)
         {
            string reason = "WEAK setup (score: " + IntegerToString(totalScore) + ")";
            g_journal.LogRejectedSignal(symbol, currentBarTime, totalScore, categoryScores, reason);
         }
      }
      else
      {
         // Invalid - rejected
         if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
         {
            string reason = g_analyzer.GetRejectionReason(symbol, totalScore, categoryScores);
            g_journal.LogRejectedSignal(symbol, currentBarTime, totalScore, categoryScores, reason);
         }
      }
      
      // Update dashboard periodically
      if(InpShowDashboard && g_dashboard != NULL)
      {
         g_dashboard.Update(symbol, totalScore, categoryScores, signalType, entry, sl, tp1, tp2,
                           g_perfectToday, g_goodToday, g_weakToday, spread);
      }
   }
   
   // Cleanup old visual objects periodically
   if(g_arrowManager != NULL)
      g_arrowManager.CleanupOldArrows(50);
   if(g_labelManager != NULL)
      g_labelManager.CleanupOldLabels(20);
   
   // Check dashboard flash restoration
   if(InpShowDashboard && g_dashboard != NULL)
      g_dashboard.CheckFlashRestore();
}

//+------------------------------------------------------------------+
//| Determine signal type (BUY/SELL/NONE)                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE DetermineSignalType(string symbol)
{
   // Get M5 EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!g_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return SIGNAL_NONE;
   
   // Get H1 EMA data
   double emaFastH1[], emaMediumH1[], emaSlowH1[];
   if(!g_emaH1.GetEMAData(symbol, emaFastH1, emaMediumH1, emaSlowH1))
      return SIGNAL_NONE;
   
   // Get current price and RSI
   double price = iClose(symbol, InpSignalTF, 0);
   double rsi = 50;
   if(InpUseRSI && g_rsi != NULL)
      g_rsi.GetRSIValue(symbol, rsi);
   
   // Check BUY conditions
   bool buyConditions = true;
   
   // H1: Price > EMA 50
   if(price <= emaSlowH1[0]) buyConditions = false;
   
   // H1: EMAs aligned (9 > 21 > 50)
   if(!(emaFastH1[0] > emaMediumH1[0] && emaMediumH1[0] > emaSlowH1[0])) buyConditions = false;
   
   // M5: EMAs aligned (9 > 21 > 50)
   if(!(emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0])) buyConditions = false;
   
   // M5: EMA 9 crosses above EMA 21
   if(!(emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1])) buyConditions = false;
   
   // M5: Current candle closes above EMA 9
   if(price <= emaFast[0]) buyConditions = false;
   
   // M5: Price, EMA 9, and EMA 21 all above EMA 50
   if(!(price > emaSlow[0] && emaFast[0] > emaSlow[0] && emaMedium[0] > emaSlow[0])) buyConditions = false;
   
   // M5: RSI > 50
   if(InpUseRSI && rsi <= InpRSI_BuyLevel) buyConditions = false;
   
   // M5: EMAs have clear separation
   double separation = g_emaM5.GetEMASeparation(symbol, InpSignalTF);
   if(separation < InpMinEMASeparation) buyConditions = false;
   
   if(buyConditions)
      return SIGNAL_BUY;
   
   // Check SELL conditions
   bool sellConditions = true;
   
   // H1: Price < EMA 50
   if(price >= emaSlowH1[0]) sellConditions = false;
   
   // H1: EMAs aligned (9 < 21 < 50)
   if(!(emaFastH1[0] < emaMediumH1[0] && emaMediumH1[0] < emaSlowH1[0])) sellConditions = false;
   
   // M5: EMAs aligned (9 < 21 < 50)
   if(!(emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0])) sellConditions = false;
   
   // M5: EMA 9 crosses below EMA 21
   if(!(emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1])) sellConditions = false;
   
   // M5: Current candle closes below EMA 9
   if(price >= emaFast[0]) sellConditions = false;
   
   // M5: Price, EMA 9, and EMA 21 all below EMA 50
   if(!(price < emaSlow[0] && emaFast[0] < emaSlow[0] && emaMedium[0] < emaSlow[0])) sellConditions = false;
   
   // M5: RSI < 50
   if(InpUseRSI && rsi >= InpRSI_SellLevel) sellConditions = false;
   
   // M5: EMAs have clear separation
   if(separation < InpMinEMASeparation) sellConditions = false;
   
   if(sellConditions)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                              |
//+------------------------------------------------------------------+
double CalculateStopLoss(string symbol, ENUM_SIGNAL_TYPE signalType, double entry)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return entry - (InpStopLossPips * pipValue);
   else if(signalType == SIGNAL_SELL)
      return entry + (InpStopLossPips * pipValue);
   
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate take profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double pips)
{
   double pipValue = GetPipValue(symbol);
   
   if(signalType == SIGNAL_BUY)
      return entry + (pips * pipValue);
   else if(signalType == SIGNAL_SELL)
      return entry - (pips * pipValue);
   
   return 0;
}

//+------------------------------------------------------------------+

