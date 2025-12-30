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
#include "Include/Indicators/ADX_Manager.mqh"
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
#include "Include/Utilities/Fakeout_Detector.mqh"
#include "Include/Utilities/Noise_Filter.mqh"
#include "Include/Utilities/Repaint_Preventer.mqh"
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

//--- Advanced Noise Reduction Filters ---
input group "═══ NOISE REDUCTION FILTERS ═══"
input bool     InpEnableNoiseFilters = true;              // Enable advanced noise filters?
input bool     InpUseMultiTimeframeFilter = true;          // Multi-TF filter: Align with higher TF trend?
input ENUM_TIMEFRAMES InpHigherTimeframe = PERIOD_H4;      // Higher timeframe for trend alignment (H4/D1)
input bool     InpUseMomentumFilter = true;                // Momentum filter: Filter low-volatility noise?
input bool     InpUseADXForMomentum = true;                // Use ADX (true) or RSI (false) for momentum?
input int      InpADX_Period = 14;                          // ADX Period
input double   InpMinADX = 20.0;                           // Min ADX for trending market (filter noise)
input double   InpMinRSI_Momentum = 55.0;                   // Min RSI for momentum (if not using ADX)
input bool     InpUseVolumeFilter = true;                   // Volume filter: Require above-average volume?
input int      InpVolumePeriod = 10;                         // Number of candles for average volume (10 recommended)

//--- Fakeout Detection ---
input group "═══ FAKEOUT DETECTION ═══"
input bool     InpEnableFakeoutDetection = true;          // Enable fakeout detection?
input int      InpConfirmationCandles = 2;                // Candles to confirm signal (2-3 recommended)
input double   InpMinMomentumPips = 3.0;                   // Min momentum for valid signal (pips)
input int      InpMaxRecentCrossovers = 3;                 // Max crossovers in 10 bars (choppy market filter)

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
input bool     InpRunScoringTest = false;                 // Run comprehensive scoring system test on startup?
input bool     InpRunQuickTest = false;                   // Run quick scoring verification test on startup?

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

// Indicator managers
CEMAManager *g_emaH1 = NULL;
CEMAManager *g_emaM5 = NULL;
CEMAManager *g_emaHigherTF = NULL;  // Higher TF for multi-timeframe filter
CRSIManager *g_rsi = NULL;
CADXManager *g_adx = NULL;          // ADX for momentum filter

// Performance optimization cache
CScoreCache *g_scoreCache = NULL;

// Scoring and visual components
CSetupScorer *g_scorer = NULL;
CSetupAnalyzer *g_analyzer = NULL;
CSignalValidator *g_validator = NULL;
CFakeoutDetector *g_fakeoutDetector = NULL;
CNoiseFilter *g_noiseFilter = NULL;
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

// ANTI-LAG: Track last processed bar time per symbol for OnTick detection
datetime g_lastProcessedBarTime[];

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
   
   // Initialize higher timeframe EMA manager for multi-timeframe filter
   if(InpEnableNoiseFilters && InpUseMultiTimeframeFilter)
   {
      // OPTIMIZATION: Reuse H1 EMA manager if higher TF is H1
      if(InpHigherTimeframe == InpTrendTF)
      {
         g_emaHigherTF = g_emaH1;  // Reuse existing H1 manager
         Print("Higher timeframe filter using existing H1 EMA manager: ", EnumToString(InpHigherTimeframe));
      }
      else
      {
         g_emaHigherTF = new CEMAManager();
         if(!g_emaHigherTF.Initialize(g_symbols, InpHigherTimeframe, InpEMA_Fast, InpEMA_Medium, InpEMA_Slow, InpEMA_Method, InpEMA_Price))
         {
            Print("WARNING: Failed to initialize higher TF EMA manager! Multi-TF filter disabled.");
            g_emaHigherTF = NULL;  // Don't fail - continue without multi-TF filter
         }
         else
         {
            Print("Higher timeframe EMA manager initialized: ", EnumToString(InpHigherTimeframe));
         }
      }
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
   
   // Initialize ADX manager for momentum filter
   if(InpEnableNoiseFilters && InpUseMomentumFilter && InpUseADXForMomentum)
   {
      g_adx = new CADXManager();
      if(!g_adx.Initialize(g_symbols, InpSignalTF, InpADX_Period))
      {
         Print("WARNING: Failed to initialize ADX manager! ADX momentum filter disabled.");
         // Don't fail - continue without ADX filter
      }
      else
      {
         Print("ADX manager initialized: Period ", InpADX_Period, ", Min ADX: ", InpMinADX);
      }
   }
   
   // Initialize performance optimization cache
   g_scoreCache = new CScoreCache(1); // 1 second cache timeout
   
   // Initialize scorer (with shared cache for performance)
   g_scorer = new CSetupScorer(g_emaH1, g_emaM5, g_rsi,
                               InpMinH1Distance, InpMinEMASeparation, InpMinCandleBody,
                               InpMaxSpread,
                               InpWeight_Trend, InpWeight_EMAQuality, InpWeight_SignalStrength,
                               InpWeight_Confirmation, InpWeight_Market, InpWeight_Context,
                               g_scoreCache); // Pass shared cache for performance
   
   // Initialize analyzer
   g_analyzer = new CSetupAnalyzer(InpMinScoreAlert);
   
   // Initialize validator
   g_validator = new CSignalValidator(g_emaH1, g_emaM5, g_rsi,
                                     InpMaxSpread, InpMinEMASeparation,
                                     InpUseRSI, InpRSI_BuyLevel, InpRSI_SellLevel);
   
   // Initialize fakeout detector
   if(InpEnableFakeoutDetection)
   {
      g_fakeoutDetector = new CFakeoutDetector(g_emaM5, InpConfirmationCandles,
                                               InpMinMomentumPips, InpMaxRecentCrossovers);
      Print("Fakeout detection enabled: ", InpConfirmationCandles, " confirmation candles, ",
            InpMinMomentumPips, " pips min momentum");
   }
   
   // Initialize noise filter (advanced noise reduction)
   if(InpEnableNoiseFilters)
   {
      g_noiseFilter = new CNoiseFilter(g_emaHigherTF, g_adx, g_rsi,
                                      InpHigherTimeframe, InpMinADX, InpMinRSI_Momentum, InpUseADXForMomentum,
                                      InpUseVolumeFilter, InpVolumePeriod, InpSignalTF);
      Print("Noise filters enabled:");
      if(InpUseMultiTimeframeFilter)
         Print("  - Multi-Timeframe Filter: ", EnumToString(InpHigherTimeframe), " trend alignment");
      if(InpUseMomentumFilter)
      {
         if(InpUseADXForMomentum)
            Print("  - Momentum Filter: ADX (Period: ", InpADX_Period, ", Min: ", InpMinADX, ")");
         else
            Print("  - Momentum Filter: RSI (Min: ", InpMinRSI_Momentum, ")");
      }
      if(InpUseVolumeFilter)
         Print("  - Volume Filter: Require volume > average of last ", InpVolumePeriod, " candles");
   }
   
   // Initialize debug helper
   g_debug = new CDebugHelper(InpEnableDebug, "[EMA_EA]");
   
   // Initialize performance monitor
   g_perfMonitor = new CPerformanceMonitor();
   g_perfMonitor.Start();
   
   // Run quick test if enabled (faster verification)
   if(InpRunQuickTest)
   {
      Print("\n═══════════════════════════════════════════════════════════");
      Print("RUNNING QUICK SCORING VERIFICATION TEST...");
      Print("═══════════════════════════════════════════════════════════\n");
      
      bool testPassed = CScoringTest::QuickTest(g_emaH1, g_emaM5, g_rsi, "");
      if(!testPassed)
      {
         Print("\n⚠ WARNING: Quick test failed! Please review errors above.");
         Print("Consider running comprehensive test (InpRunScoringTest) for detailed analysis.");
      }
      
      Print("\n═══════════════════════════════════════════════════════════");
      Print("QUICK TEST COMPLETE - Continuing with EA initialization...");
      Print("═══════════════════════════════════════════════════════════\n");
   }
   
   // Run comprehensive scoring system test if enabled
   if(InpRunScoringTest)
   {
      Print("\n═══════════════════════════════════════════════════════════");
      Print("RUNNING COMPREHENSIVE SCORING SYSTEM TEST...");
      Print("═══════════════════════════════════════════════════════════\n");
      
      CScoringTest::RunAllTests(g_emaH1, g_emaM5, g_rsi);
      
      Print("\n═══════════════════════════════════════════════════════════");
      Print("COMPREHENSIVE TEST COMPLETE - Continuing with EA initialization...");
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
   
   // ANTI-LAG: Initialize last processed bar time array for OnTick detection
   ArrayResize(g_lastProcessedBarTime, ArraySize(g_symbols));
   ArrayInitialize(g_lastProcessedBarTime, 0);
   
   // Set timer for periodic maintenance (scan interval)
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
   if(g_emaH1 != NULL) { g_emaH1.Deinitialize(); delete g_emaH1; g_emaH1 = NULL; }
   if(g_emaM5 != NULL) { g_emaM5.Deinitialize(); delete g_emaM5; g_emaM5 = NULL; }
   // Only delete higher TF manager if it's not the same as H1 manager
   if(g_emaHigherTF != NULL && g_emaHigherTF != g_emaH1) 
   { 
      g_emaHigherTF.Deinitialize(); 
      delete g_emaHigherTF; 
      g_emaHigherTF = NULL; 
   }
   if(g_rsi != NULL) { g_rsi.Deinitialize(); delete g_rsi; g_rsi = NULL; }
   if(g_adx != NULL) { g_adx.Deinitialize(); delete g_adx; g_adx = NULL; }
   if(g_scorer != NULL) delete g_scorer;
   if(g_analyzer != NULL) delete g_analyzer;
   if(g_validator != NULL) { delete g_validator; g_validator = NULL; }
   if(g_fakeoutDetector != NULL) { delete g_fakeoutDetector; g_fakeoutDetector = NULL; }
   if(g_noiseFilter != NULL) { delete g_noiseFilter; g_noiseFilter = NULL; }
   if(g_debug != NULL) { delete g_debug; g_debug = NULL; }
   if(g_perfMonitor != NULL)
   {
      if(InpEnableDebug)
         Print(g_perfMonitor.GetPerformanceReport());
      delete g_perfMonitor;
   }
   // OPTIMIZATION: Cleanup in reverse order of initialization
   // Cleanup visual components first (they depend on managers)
   if(g_dashboard != NULL) 
   {
      g_dashboard.Cleanup();
      delete g_dashboard;
      g_dashboard = NULL;
   }
   
   if(g_arrowManager != NULL) 
   {
      g_arrowManager.DeleteAllArrows();
      delete g_arrowManager;
      g_arrowManager = NULL;
   }
   
   if(g_labelManager != NULL) 
   {
      g_labelManager.DeleteAllLabels();
      delete g_labelManager;
      g_labelManager = NULL;
   }
   
   if(g_panelManager != NULL) 
   {
      g_panelManager.Cleanup();
      delete g_panelManager;
      g_panelManager = NULL;
   }
   
   // Cleanup cache (after scorers)
   if(g_scoreCache != NULL)
   {
      delete g_scoreCache;
      g_scoreCache = NULL;
   }
   
   if(g_alertManager != NULL) 
   {
      delete g_alertManager;
      g_alertManager = NULL;
   }
   
   if(g_journal != NULL) 
   {
      delete g_journal;
      g_journal = NULL;
   }
   
   Print("=== EMA Perfect Setup Scanner EA v2.0 Stopped ===");
}

//+------------------------------------------------------------------+
//| Tick function - ANTI-LAG: Detect bar close immediately           |
//+------------------------------------------------------------------+
void OnTick()
{
   // ANTI-LAG: Process signals immediately when bar closes (not wait for timer)
   // This reduces signal lag from up to 15 seconds to near-instant
   
   // Check all symbols for new closed bars
   for(int i = 0; i < ArraySize(g_symbols); i++)
   {
      string symbol = g_symbols[i];
      
      // Get closed bar time (bar 1)
      datetime closedBarTime = CRepaintPreventer::GetClosedBarTime(symbol, InpSignalTF);
      if(closedBarTime == 0)
         continue;  // No closed bar yet
      
      // Check if this bar was already processed
      if(g_lastProcessedBarTime[i] == closedBarTime)
         continue;  // Already processed
      
      // Verify bar is actually closed
      if(!CRepaintPreventer::IsBarClosed(symbol, InpSignalTF))
         continue;  // Bar not closed yet
      
      // Mark as processed
      g_lastProcessedBarTime[i] = closedBarTime;
      
      // Process signal immediately (reuse existing processing logic)
      ProcessSignalOnBarClose(symbol, i, closedBarTime);
   }
}

//+------------------------------------------------------------------+
//| Process signal when bar closes (shared by OnTick and OnTimer)   |
//+------------------------------------------------------------------+
void ProcessSignalOnBarClose(string symbol, int symbolIndex, datetime closedBarTime)
{
   // Skip if max signals reached
   if(InpMaxSignalsPerDay > 0 && g_signalsToday >= InpMaxSignalsPerDay)
      return;
   
   // OPTIMIZATION: Check spread early (before expensive calculations)
   double spread = GetSpreadPips(symbol);
   if(spread > InpMaxSpread)
   {
      if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
      {
         string spreadStr = FormatPips(spread);
         string maxSpreadStr = FormatPips(InpMaxSpread);
         string reason = StringFormat("Spread too high: %s (max: %s)", spreadStr, maxSpreadStr);
         g_journal.LogRejectedSignal(symbol, closedBarTime, 0, reason);
      }
      return;
   }
   
   // Determine signal type (uses closed bar data - no repaint)
   ENUM_SIGNAL_TYPE signalType = DetermineSignalType(symbol);
   if(signalType == SIGNAL_NONE)
      return;
   
   // ANTI-REPAINT: Check if we already signaled on this closed bar
   if(g_lastSignalTime[symbolIndex] == closedBarTime)
      return; // Already processed this closed bar
   
   // Validate signal using validator (before expensive scoring)
   bool isValidSignal = false;
   if(signalType == SIGNAL_BUY)
      isValidSignal = g_validator.ValidateBuySignal(symbol);
   else if(signalType == SIGNAL_SELL)
      isValidSignal = g_validator.ValidateSellSignal(symbol);
   
   if(!isValidSignal)
   {
      string errors = "";
      if(InpEnableDebug && g_debug != NULL || (InpLogRejectedSetups && InpEnableJournal && g_journal != NULL))
      {
         errors = g_validator.GetValidationErrors(symbol, signalType);
      }
      
      if(InpEnableDebug && g_debug != NULL)
      {
         g_debug.Log("Signal validation failed for " + symbol + ": " + errors);
      }
      if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
      {
         g_journal.LogRejectedSignal(symbol, closedBarTime, 0, "Validation failed: " + errors);
      }
      return;
   }
   
   // ADVANCED NOISE REDUCTION: Check noise filters (before expensive scoring)
   // 1. Multi-Timeframe Filter: Entry must align with higher TF trend
   // 2. Momentum Filter: Ensure not trading in low-volatility noise zone
   if(InpEnableNoiseFilters && g_noiseFilter != NULL)
   {
      if(!g_noiseFilter.PassesNoiseFilters(symbol, signalType))
      {
         string filterReason = g_noiseFilter.GetFilterRejectionReason(symbol, signalType);
         
         if(InpEnableDebug && g_debug != NULL)
         {
            g_debug.Log("Noise filter rejected " + symbol + ": " + filterReason);
         }
         if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
         {
            g_journal.LogRejectedSignal(symbol, closedBarTime, 0, "Noise filter: " + filterReason);
         }
         return;  // Signal rejected by noise filter
      }
   }
   
   // OPTIMIZATION: Check for fakeouts (before expensive scoring)
   if(InpEnableFakeoutDetection && g_fakeoutDetector != NULL)
   {
      if(g_fakeoutDetector.IsFakeout(symbol, signalType))
      {
         string fakeoutReason = g_fakeoutDetector.GetFakeoutReason(symbol, signalType);
         
         if(InpEnableDebug && g_debug != NULL)
         {
            g_debug.Log("Fakeout detected for " + symbol + ": " + fakeoutReason);
         }
         if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
         {
            g_journal.LogRejectedSignal(symbol, closedBarTime, 0, "Fakeout: " + fakeoutReason);
         }
         return;  // Skip this signal - it's a fakeout
      }
   }
   
   // Calculate score (most expensive operation - done last)
   int categoryScores[];
   int totalScore = g_scorer.CalculateTotalScore(symbol, signalType, categoryScores);
   
   // Debug logging (only if debug enabled)
   if(InpEnableDebug && g_debug != NULL)
   {
      g_debug.LogSignal(symbol, signalType, totalScore);
      g_debug.LogScoreBreakdown(symbol, totalScore, categoryScores);
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
      g_lastSignalTime[symbolIndex] = closedBarTime;  // ANTI-REPAINT: Use closed bar time
      
      // OPTIMIZATION: Get strengths/weaknesses once and reuse
      string analysis = g_scorer.GetStrengthsAndWeaknesses(symbol, signalType, categoryScores);
      string strengths = "";
      string weaknesses = "";
      
      // OPTIMIZATION: Parse analysis efficiently - cache StringFind results
      int strengthsPos = StringFind(analysis, "STRENGTHS:");
      if(strengthsPos >= 0)
      {
         int strengthsStart = strengthsPos + 10; // "STRENGTHS:" = 10 chars
         int weaknessesPos = StringFind(analysis, "MINOR WEAKNESSES:");
         if(weaknessesPos >= 0)
         {
            strengths = StringSubstr(analysis, strengthsStart, weaknessesPos - strengthsStart);
            weaknesses = StringSubstr(analysis, weaknessesPos + 17); // "MINOR WEAKNESSES:" = 17 chars
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
      
      // OPTIMIZATION: Visual updates (only if enabled)
      // ANTI-REPAINT: Use closed bar time for visual objects
      if(InpShowArrows && g_arrowManager != NULL)
         g_arrowManager.DrawArrow(symbol, closedBarTime, entry, totalScore, signalType);
      
      if(InpShowLabels && g_labelManager != NULL)
      {
         // OPTIMIZATION: Reuse strengths already calculated above
         g_labelManager.DrawDetailedLabel(symbol, closedBarTime, entry, totalScore, categoryScores, 
                                         signalType, entry, sl, tp1, tp2, strengths);
      }
      
      // OPTIMIZATION: Dashboard update once (removed duplicate)
      if(InpShowDashboard && g_dashboard != NULL)
      {
         g_dashboard.Update(symbol, totalScore, categoryScores, signalType, entry, sl, tp1, tp2,
                           g_perfectToday, g_goodToday, g_weakToday, spread);
         g_dashboard.Flash(InpBuyColor, 5000);
      }
      
      // OPTIMIZATION: Panel update doesn't need breakdown string (it generates internally)
      if(InpShowBreakdownPanel && g_panelManager != NULL)
      {
         g_panelManager.Update(symbol, signalType, categoryScores, g_scorer);
      }
      
      // Alerts
      if(InpAlert_Perfect && g_alertManager != NULL)
      {
         g_alertManager.SendPerfectSetupAlert(symbol, totalScore, signalType, entry, sl, tp1, tp2, 
                                              strengths, weaknesses);
      }
      
      // Journal
      // ANTI-REPAINT: Use closed bar time for journal entries
      if(InpEnableJournal && g_journal != NULL)
      {
         g_journal.LogPerfectSignal(symbol, closedBarTime, totalScore, categoryScores, signalType,
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
      // Good setup (70-84 points)
      g_goodToday++;
      
      // OPTIMIZATION: Visual updates only if enabled
      // ANTI-REPAINT: Use closed bar time
      if(InpShowArrows && g_arrowManager != NULL)
         g_arrowManager.DrawArrow(symbol, closedBarTime, entry, totalScore, signalType);
      
      if(InpAlert_Good && g_alertManager != NULL)
         g_alertManager.SendGoodSetupAlert(symbol, totalScore, signalType);
      
      if(InpEnableJournal && g_journal != NULL)
      {
         // OPTIMIZATION: Use StringFormat for better performance
         string reason = StringFormat("GOOD but below threshold (score: %d)", totalScore);
         g_journal.LogRejectedSignal(symbol, closedBarTime, totalScore, categoryScores, reason);
      }
   }
   else if(g_analyzer.IsWeakSetup(totalScore) && InpShowWeakSetups)
   {
      // Weak setup (50-69 points)
      g_weakToday++;
      
      // OPTIMIZATION: Visual updates only if enabled
      // ANTI-REPAINT: Use closed bar time
      if(InpShowArrows && g_arrowManager != NULL)
         g_arrowManager.DrawArrow(symbol, closedBarTime, entry, totalScore, signalType);
      
      if(InpEnableJournal && InpLogRejectedSetups && g_journal != NULL)
      {
         // OPTIMIZATION: Use StringFormat for better performance
         string reason = StringFormat("WEAK setup (score: %d)", totalScore);
         g_journal.LogRejectedSignal(symbol, closedBarTime, totalScore, categoryScores, reason);
      }
   }
   else
   {
      // Invalid - rejected (<50 points)
      // ANTI-REPAINT: Use closed bar time
      if(InpLogRejectedSetups && InpEnableJournal && g_journal != NULL)
      {
         string reason = g_analyzer.GetRejectionReason(symbol, totalScore, categoryScores);
         g_journal.LogRejectedSignal(symbol, closedBarTime, totalScore, categoryScores, reason);
      }
   }
}

//+------------------------------------------------------------------+
//| Timer function - Periodic maintenance and cleanup               |
//+------------------------------------------------------------------+
void OnTimer()
{
   // OPTIMIZATION: Cache TimeCurrent() once per timer cycle
   datetime currentTime = TimeCurrent();
   
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
   
   // ANTI-LAG: Timer now only does periodic maintenance
   // Signal processing is done immediately in OnTick() when bar closes
   // This reduces lag from up to 15 seconds to near-instant
   
   // Scan all symbols (backup check - OnTick handles immediate processing)
   for(int i = 0; i < ArraySize(g_symbols); i++)
   {
      string symbol = g_symbols[i];
      
      // Check if new closed bar available (backup check)
      datetime closedBarTime = CRepaintPreventer::GetClosedBarTime(symbol, InpSignalTF);
      if(closedBarTime == 0)
         continue;
      
      // Check if already processed by OnTick
      if(g_lastProcessedBarTime[i] == closedBarTime)
         continue;  // Already processed by OnTick
      
      // Verify bar is closed
      if(!CRepaintPreventer::IsBarClosed(symbol, InpSignalTF))
         continue;
      
      // Process signal (backup - in case OnTick missed it)
      ProcessSignalOnBarClose(symbol, i, closedBarTime);
   }
   
   // OPTIMIZATION: Cleanup operations (done once per timer cycle, not per symbol)
   // Cleanup old visual objects periodically (every 10 cycles = ~2.5 minutes at 15s interval)
   static int cleanupCounter = 0;
   cleanupCounter++;
   if(cleanupCounter >= 10)
   {
      cleanupCounter = 0;
      if(g_arrowManager != NULL)
         g_arrowManager.CleanupOldArrows(3600); // Cleanup arrows older than 1 hour
      if(g_labelManager != NULL)
         g_labelManager.CleanupOldLabels(3600); // Cleanup labels older than 1 hour
   }
   
   // OPTIMIZATION: Dashboard flash restoration (check once per cycle)
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
   
   // ANTI-REPAINT: Use closed bar (bar 1) for all price and indicator data
   // Bar 0 = current forming bar (repaints!)
   // Bar 1 = last closed bar (no repaint)
   double price = iClose(symbol, InpSignalTF, 1);  // Closed bar price
   double rsi = 50;
   if(InpUseRSI && g_rsi != NULL)
   {
      // Note: RSI GetRSIValue gets bar 0, but RSI repainting is less critical than price
      // For full anti-repaint, would need to modify RSI manager to support bar offset
      g_rsi.GetRSIValue(symbol, rsi);
   }
   
   // Check BUY conditions (using closed bar data)
   bool buyConditions = true;
   
   // H1: Price > EMA 50 (using closed bar)
   if(price <= emaSlowH1[0]) buyConditions = false;
   
   // H1: EMAs aligned (9 > 21 > 50)
   if(!(emaFastH1[0] > emaMediumH1[0] && emaMediumH1[0] > emaSlowH1[0])) buyConditions = false;
   
   // M5: EMAs aligned (9 > 21 > 50) - using closed bar values
   if(!(emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0])) buyConditions = false;
   
   // M5: EMA 9 crosses above EMA 21 (check closed bar [0] vs previous [1])
   // emaFast[0] = closed bar, emaFast[1] = bar before closed bar
   if(!(emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1])) buyConditions = false;
   
   // M5: Closed candle closes above EMA 9
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
   
   // M5: EMA 9 crosses below EMA 21 (check closed bar [0] vs previous [1])
   // emaFast[0] = closed bar, emaFast[1] = bar before closed bar
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

