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
#include "Include/Utilities/Signal_Accuracy_Validator.mqh"
#include "Include/Utilities/Repaint_Checker.mqh"
#include "Include/Utilities/MAE_Tracker.mqh"
#include "Include/Utilities/Performance_Monitor_Enhanced.mqh"
#include "Include/Utilities/Debug_Helper.mqh"
#include "Include/Utilities/Symbol_Utils.mqh"
#include "Include/Utilities/Input_Validator.mqh"
#include "Include/Utilities/Performance_Monitor.mqh"
#include "Include/Utilities/Statistics_Tracker.mqh"
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

//--- Statistics Tracking ---
input group "═══ STATISTICS TRACKING ═══"
input bool     InpEnableStatistics = true;                   // Enable statistics tracking?
input int      InpStatsPrintInterval = 10;                   // Print stats every N signals (0 = only on request)

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
input color    InpBuyColor = clrBlue;                     // BUY signal color (mũi tên xanh)
input color    InpSellColor = clrRed;                     // SELL signal color (mũi tên đỏ)
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

//--- Signal Accuracy Validation ---
input group "═══ SIGNAL ACCURACY VALIDATION ═══"
input bool     InpEnableAccuracyValidation = true;           // Enable signal accuracy validation?
input int      InpValidationCandles = 5;                      // Candles to validate signal (3-5 recommended)
input double   InpMinPipsForValid = 10.0;                     // Min pips required for valid signal

//--- Repaint Detection ---
input group "═══ REPAINT DETECTION ═══"
input bool     InpEnableRepaintCheck = true;                  // Enable repaint detection?

//--- Maximum Adverse Excursion (MAE) Tracking ---
input group "═══ MAE TRACKING ═══"
input bool     InpEnableMAETracking = true;                   // Enable MAE tracking?
input int      InpMAEUpdateInterval = 5;                       // Update MAE every N seconds

//--- Enhanced Performance Monitoring ---
input group "═══ ENHANCED PERFORMANCE MONITOR ═══"
input bool     InpEnablePerfMonitor = true;                    // Enable enhanced performance monitor?
input int      InpQualityBars = 10;                            // Bars to evaluate signal quality (10 recommended)
input int      InpPerfUpdateInterval = 5;                       // Update performance data every N seconds
input bool     InpExportPerfCSV = true;                         // Export performance data to CSV?
input string   InpPerfCSVFilename = "Indicator_Score_Card.csv"; // CSV filename for performance data

//--- Advanced Scoring Weights (for experienced users) ---
input group "═══ ADVANCED: SCORING WEIGHTS ═══"
input int      InpWeight_Trend = 25;                      // Trend Alignment weight (default 25)
input int      InpWeight_EMAQuality = 20;                 // EMA Quality weight (default 20)
input int      InpWeight_SignalStrength = 20;             // Signal Strength weight (default 20)
input int      InpWeight_Confirmation = 15;               // Confirmation weight (default 15)
input int      InpWeight_Market = 10;                     // Market Conditions weight (default 10)
input int      InpWeight_Context = 10;                    // Context & Timing weight (default 10)

//--- Statistics Tracking ---
input group "═══ STATISTICS TRACKING ═══"
input bool     InpEnableStatistics = true;                   // Enable statistics tracking?
input int      InpStatsPrintInterval = 10;                   // Print stats every N signals (0 = only on request)

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
CSignalAccuracyValidator *g_accuracyValidator = NULL;
CRepaintChecker *g_repaintChecker = NULL;
CMAETracker *g_maeTracker = NULL;
CPerformanceMonitorEnhanced *g_perfMonitorEnhanced = NULL;
CDebugHelper *g_debug = NULL;
CDashboard *g_dashboard = NULL;
CArrowManager *g_arrowManager = NULL;
CLabelManager *g_labelManager = NULL;
CPanelManager *g_panelManager = NULL;
CAlertManager *g_alertManager = NULL;
CJournalManager *g_journal = NULL;
CPerformanceMonitor *g_perfMonitor = NULL;
CStatisticsTracker *g_statistics = NULL;

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
   
   // Initialize statistics tracker
   if(InpEnableStatistics)
   {
      g_statistics = new CStatisticsTracker();
      Print("Statistics tracking enabled");
   }
   
   // Initialize signal accuracy validator
   if(InpEnableAccuracyValidation)
   {
      g_accuracyValidator = new CSignalAccuracyValidator();
      Print("Signal accuracy validation enabled: ", InpValidationCandles, " candles, ", 
            InpMinPipsForValid, " pips minimum");
   }
   
   // Initialize repaint checker
   if(InpEnableRepaintCheck)
   {
      g_repaintChecker = new CRepaintChecker();
      Print("Repaint detection enabled - will monitor signal stability");
   }
   
   // Initialize MAE tracker
   if(InpEnableMAETracking)
   {
      g_maeTracker = new CMAETracker();
      Print("MAE tracking enabled - will monitor maximum drawdown for each signal");
   }
   
   // Initialize enhanced performance monitor
   if(InpEnablePerfMonitor)
   {
      g_perfMonitorEnhanced = new CPerformanceMonitorEnhanced();
      Print("Enhanced performance monitor enabled - tracking Win/Loss, Quality Score, and Drawdown");
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
   if(g_accuracyValidator != NULL)
   {
      // Print final accuracy report before cleanup
      if(InpEnableAccuracyValidation)
      {
         Print("\n═══════════════════════════════════════════════════════════");
         Print("FINAL SIGNAL ACCURACY REPORT");
         Print("═══════════════════════════════════════════════════════════");
         g_accuracyValidator.PrintAccuracyReport();
      }
      delete g_accuracyValidator;
      g_accuracyValidator = NULL;
   }
   if(g_repaintChecker != NULL)
   {
      // Print final repaint report before cleanup
      if(InpEnableRepaintCheck)
      {
         Print("\n═══════════════════════════════════════════════════════════");
         Print("FINAL REPAINT DETECTION REPORT");
         Print("═══════════════════════════════════════════════════════════");
         g_repaintChecker.PrintRepaintReport();
      }
      delete g_repaintChecker;
      g_repaintChecker = NULL;
   }
   if(g_maeTracker != NULL)
   {
      // Print final MAE report before cleanup
      if(InpEnableMAETracking)
      {
         Print("\n═══════════════════════════════════════════════════════════");
         Print("FINAL MAE (MAXIMUM ADVERSE EXCURSION) REPORT");
         Print("═══════════════════════════════════════════════════════════");
         g_maeTracker.PrintMAEReport();
      }
      delete g_maeTracker;
      g_maeTracker = NULL;
   }
   if(g_perfMonitorEnhanced != NULL)
   {
      // Print final performance report and export CSV before cleanup
      if(InpEnablePerfMonitor)
      {
         Print("\n═══════════════════════════════════════════════════════════");
         Print("FINAL ENHANCED PERFORMANCE MONITOR REPORT");
         Print("═══════════════════════════════════════════════════════════");
         g_perfMonitorEnhanced.PrintPerformanceReport();
         
         // Export final CSV
         if(InpExportPerfCSV)
         {
            if(g_perfMonitorEnhanced.ExportToCSV(InpPerfCSVFilename))
            {
               Print("Performance data exported to: ", InpPerfCSVFilename);
            }
         }
      }
      delete g_perfMonitorEnhanced;
      g_perfMonitorEnhanced = NULL;
   }
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
   // ANTI-REPAINT: Use closed bar close price as entry (bar 1)
   double entry = iClose(symbol, InpSignalTF, 1);  // Closed bar close price
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
      
      // Record signal in statistics tracker
      if(InpEnableStatistics && g_statistics != NULL)
      {
         g_statistics.RecordSignal(symbol, signalType, closedBarTime, entry, sl, tp1, tp2);
         
         // Print statistics periodically
         if(InpStatsPrintInterval > 0 && g_signalsToday % InpStatsPrintInterval == 0)
         {
            g_statistics.PrintStatistics();
         }
      }
      
      // Register signal for accuracy validation
      if(InpEnableAccuracyValidation && g_accuracyValidator != NULL)
      {
         g_accuracyValidator.RegisterSignal(symbol, signalType, closedBarTime, entry, sl, tp1,
                                           InpSignalTF, InpValidationCandles, InpMinPipsForValid);
      }
      
      // Record signal snapshot for repaint checking
      if(InpEnableRepaintCheck && g_repaintChecker != NULL)
      {
         g_repaintChecker.RecordSignalSnapshot(symbol, signalType, closedBarTime, closedBarTime,
                                              entry, sl, tp1, tp2, totalScore);
      }
      
      // Register signal for MAE tracking
      if(InpEnableMAETracking && g_maeTracker != NULL)
      {
         g_maeTracker.RegisterSignal(symbol, signalType, closedBarTime, entry, sl, tp1, tp2, InpSignalTF);
      }
      
      // Register signal for enhanced performance monitoring
      if(InpEnablePerfMonitor && g_perfMonitorEnhanced != NULL)
      {
         g_perfMonitorEnhanced.RegisterSignal(symbol, signalType, closedBarTime, entry, sl, tp1, tp2,
                                             InpSignalTF, InpQualityBars);
      }
      
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
   
   // Print statistics periodically (if enabled and interval set)
   if(InpEnableStatistics && g_statistics != NULL && InpStatsPrintInterval > 0)
   {
      static int lastStatsPrint = 0;
      if(g_signalsToday > 0 && g_signalsToday != lastStatsPrint && g_signalsToday % InpStatsPrintInterval == 0)
      {
         lastStatsPrint = g_signalsToday;
         Print("\n═══════════════════════════════════════════════════════════");
         Print("PERIODIC STATISTICS REPORT (Signal #", g_signalsToday, ")");
         Print("═══════════════════════════════════════════════════════════");
         g_statistics.PrintStatistics();
      }
   }
   
   // Check pending signal accuracy validations
   if(InpEnableAccuracyValidation && g_accuracyValidator != NULL)
   {
      g_accuracyValidator.CheckPendingSignals();
      
      // Log false/lagging signals to journal
      // Note: This would require tracking which signals were just validated
      // For now, accuracy is tracked internally and reported in accuracy report
      
      // Cleanup old signals periodically (every 10 cycles)
      static int cleanupCounter = 0;
      cleanupCounter++;
      if(cleanupCounter >= 10)
      {
         cleanupCounter = 0;
         g_accuracyValidator.CleanupOldSignals(24); // Keep last 24 hours
      }
   }
   
   // Check for repainting signals (after candles close)
   if(InpEnableRepaintCheck && g_repaintChecker != NULL)
   {
      // Check all symbols for closed bars that need repaint checking
      for(int i = 0; i < ArraySize(g_symbols); i++)
      {
         string symbol = g_symbols[i];
         
         // Get closed bar time (bar 1)
         datetime closedBarTime = CRepaintPreventer::GetClosedBarTime(symbol, InpSignalTF);
         if(closedBarTime == 0)
            continue;
         
         // Check if this bar needs repaint checking (wait 1 bar after close for stability)
         // Check bar that closed 2 bars ago (more stable)
         datetime checkBarTime = iTime(symbol, InpSignalTF, 2);
         if(checkBarTime > 0)
         {
            g_repaintChecker.CheckRepaint(symbol, checkBarTime);
         }
      }
      
      // Cleanup old snapshots periodically (every 10 cycles)
      static int repaintCleanupCounter = 0;
      repaintCleanupCounter++;
      if(repaintCleanupCounter >= 10)
      {
         repaintCleanupCounter = 0;
         g_repaintChecker.CleanupOldSnapshots(24); // Keep last 24 hours
      }
   }
   
   // Update MAE for all active trades
   if(InpEnableMAETracking && g_maeTracker != NULL)
   {
      static datetime lastMAEUpdate = 0;
      datetime currentTime = TimeCurrent();
      
      // Update MAE every N seconds (to avoid too frequent updates)
      if(currentTime - lastMAEUpdate >= InpMAEUpdateInterval)
      {
         lastMAEUpdate = currentTime;
         g_maeTracker.UpdateMAE();
      }
      
      // Cleanup old trades periodically (every 10 cycles)
      static int maeCleanupCounter = 0;
      maeCleanupCounter++;
      if(maeCleanupCounter >= 10)
      {
         maeCleanupCounter = 0;
         g_maeTracker.CleanupOldTrades(24); // Keep last 24 hours
      }
   }
   
   // Update enhanced performance monitor
   if(InpEnablePerfMonitor && g_perfMonitorEnhanced != NULL)
   {
      static datetime lastPerfUpdate = 0;
      datetime currentTime = TimeCurrent();
      
      // Update performance data every N seconds
      if(currentTime - lastPerfUpdate >= InpPerfUpdateInterval)
      {
         lastPerfUpdate = currentTime;
         g_perfMonitorEnhanced.UpdateTracks();
      }
      
      // Export to CSV periodically (every 20 cycles = ~5 minutes at 15s interval)
      static int csvExportCounter = 0;
      csvExportCounter++;
      if(InpExportPerfCSV && csvExportCounter >= 20)
      {
         csvExportCounter = 0;
         g_perfMonitorEnhanced.ExportToCSV(InpPerfCSVFilename);
      }
      
      // Cleanup old tracks periodically (every 10 cycles)
      static int perfCleanupCounter = 0;
      perfCleanupCounter++;
      if(perfCleanupCounter >= 10)
      {
         perfCleanupCounter = 0;
         g_perfMonitorEnhanced.CleanupOldTracks(24); // Keep last 24 hours
      }
   }
}

//+------------------------------------------------------------------+
//| Get Entry Signal - Returns signal type as integer               |
//| Returns: 0 = No signal, 1 = BUY signal, -1 = SELL signal        |
//| Logic được comment rõ ràng từng điều kiện kiểm tra              |
//+------------------------------------------------------------------+
int GetEntrySignal(string symbol)
{
   // ============================================================
   // BƯỚC 1: LẤY DỮ LIỆU EMA CHO M5 (Timeframe tín hiệu)
   // ============================================================
   double emaFast[], emaMedium[], emaSlow[];
   // Kiểm tra: Nếu không lấy được dữ liệu EMA M5 thì không có tín hiệu
   if(!g_emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return 0; // Không có tín hiệu
   
   // ============================================================
   // BƯỚC 2: LẤY DỮ LIỆU EMA CHO H1 (Timeframe xu hướng)
   // ============================================================
   double emaFastH1[], emaMediumH1[], emaSlowH1[];
   // Kiểm tra: Nếu không lấy được dữ liệu EMA H1 thì không có tín hiệu
   if(!g_emaH1.GetEMAData(symbol, emaFastH1, emaMediumH1, emaSlowH1))
      return 0; // Không có tín hiệu
   
   // ============================================================
   // BƯỚC 3: LẤY GIÁ ĐÓNG CỬA CỦA NẾN ĐÃ ĐÓNG (Bar 1)
   // ANTI-REPAINT: Sử dụng bar 1 (nến đã đóng) để tránh repaint
   // Bar 0 = nến đang hình thành (có thể thay đổi - repaint!)
   // Bar 1 = nến đã đóng (không thay đổi - không repaint)
   // ============================================================
   double price = iClose(symbol, InpSignalTF, 1);  // Giá đóng cửa của nến đã đóng
   
   // ============================================================
   // BƯỚC 4: LẤY GIÁ TRỊ RSI (nếu bật sử dụng RSI)
   // ============================================================
   double rsi = 50; // Giá trị mặc định nếu không dùng RSI
   // Kiểm tra: Nếu bật sử dụng RSI và RSI manager tồn tại
   if(InpUseRSI && g_rsi != NULL)
   {
      // Lấy giá trị RSI hiện tại
      g_rsi.GetRSIValue(symbol, rsi);
   }
   
   // ============================================================
   // BƯỚC 5: KIỂM TRA ĐIỀU KIỆN TÍN HIỆU BUY
   // ============================================================
   bool buyConditions = true; // Bắt đầu với giả định tất cả điều kiện đều đúng
   
   // ĐIỀU KIỆN BUY 1: H1 - Giá phải ở trên EMA 50 (xu hướng tăng trên H1)
   // Kiểm tra: Nếu giá <= EMA 50 H1 thì không phải tín hiệu BUY
   if(price <= emaSlowH1[0]) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 2: H1 - Các EMA phải sắp xếp theo thứ tự tăng (9 > 21 > 50)
   // Kiểm tra: EMA 9 H1 phải > EMA 21 H1 và EMA 21 H1 phải > EMA 50 H1
   if(!(emaFastH1[0] > emaMediumH1[0] && emaMediumH1[0] > emaSlowH1[0])) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 3: M5 - Các EMA phải sắp xếp theo thứ tự tăng (9 > 21 > 50)
   // Kiểm tra: EMA 9 M5 phải > EMA 21 M5 và EMA 21 M5 phải > EMA 50 M5
   if(!(emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0])) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 4: M5 - EMA 9 phải cắt lên trên EMA 21 (tín hiệu mua)
   // Kiểm tra: EMA 9 hiện tại > EMA 21 hiện tại VÀ EMA 9 nến trước <= EMA 21 nến trước
   // emaFast[0] = EMA 9 của nến đã đóng, emaFast[1] = EMA 9 của nến trước đó
   if(!(emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1])) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 5: M5 - Nến đã đóng phải đóng trên EMA 9
   // Kiểm tra: Giá đóng cửa phải > EMA 9 M5
   if(price <= emaFast[0]) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 6: M5 - Giá, EMA 9, và EMA 21 đều phải ở trên EMA 50
   // Kiểm tra: Giá > EMA 50 VÀ EMA 9 > EMA 50 VÀ EMA 21 > EMA 50
   if(!(price > emaSlow[0] && emaFast[0] > emaSlow[0] && emaMedium[0] > emaSlow[0])) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 7: M5 - RSI phải > ngưỡng mua (mặc định 50)
   // Kiểm tra: Nếu bật RSI và RSI <= ngưỡng mua thì không phải tín hiệu BUY
   if(InpUseRSI && rsi <= InpRSI_BuyLevel) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // ĐIỀU KIỆN BUY 8: M5 - Các EMA phải có khoảng cách tách biệt rõ ràng
   // Kiểm tra: Khoảng cách giữa các EMA phải >= khoảng cách tối thiểu
   double separation = g_emaM5.GetEMASeparation(symbol, InpSignalTF);
   if(separation < InpMinEMASeparation) 
      buyConditions = false; // Vi phạm điều kiện BUY
   
   // Nếu tất cả điều kiện BUY đều đúng, trả về tín hiệu BUY
   if(buyConditions)
      return 1; // Tín hiệu BUY
   
   // ============================================================
   // BƯỚC 6: KIỂM TRA ĐIỀU KIỆN TÍN HIỆU SELL
   // ============================================================
   bool sellConditions = true; // Bắt đầu với giả định tất cả điều kiện đều đúng
   
   // ĐIỀU KIỆN SELL 1: H1 - Giá phải ở dưới EMA 50 (xu hướng giảm trên H1)
   // Kiểm tra: Nếu giá >= EMA 50 H1 thì không phải tín hiệu SELL
   if(price >= emaSlowH1[0]) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 2: H1 - Các EMA phải sắp xếp theo thứ tự giảm (9 < 21 < 50)
   // Kiểm tra: EMA 9 H1 phải < EMA 21 H1 và EMA 21 H1 phải < EMA 50 H1
   if(!(emaFastH1[0] < emaMediumH1[0] && emaMediumH1[0] < emaSlowH1[0])) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 3: M5 - Các EMA phải sắp xếp theo thứ tự giảm (9 < 21 < 50)
   // Kiểm tra: EMA 9 M5 phải < EMA 21 M5 và EMA 21 M5 phải < EMA 50 M5
   if(!(emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0])) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 4: M5 - EMA 9 phải cắt xuống dưới EMA 21 (tín hiệu bán)
   // Kiểm tra: EMA 9 hiện tại < EMA 21 hiện tại VÀ EMA 9 nến trước >= EMA 21 nến trước
   // emaFast[0] = EMA 9 của nến đã đóng, emaFast[1] = EMA 9 của nến trước đó
   if(!(emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1])) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 5: M5 - Nến đã đóng phải đóng dưới EMA 9
   // Kiểm tra: Giá đóng cửa phải < EMA 9 M5
   if(price >= emaFast[0]) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 6: M5 - Giá, EMA 9, và EMA 21 đều phải ở dưới EMA 50
   // Kiểm tra: Giá < EMA 50 VÀ EMA 9 < EMA 50 VÀ EMA 21 < EMA 50
   if(!(price < emaSlow[0] && emaFast[0] < emaSlow[0] && emaMedium[0] < emaSlow[0])) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 7: M5 - RSI phải < ngưỡng bán (mặc định 50)
   // Kiểm tra: Nếu bật RSI và RSI >= ngưỡng bán thì không phải tín hiệu SELL
   if(InpUseRSI && rsi >= InpRSI_SellLevel) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // ĐIỀU KIỆN SELL 8: M5 - Các EMA phải có khoảng cách tách biệt rõ ràng
   // Kiểm tra: Khoảng cách giữa các EMA phải >= khoảng cách tối thiểu
   // (Sử dụng lại giá trị separation đã tính ở trên)
   if(separation < InpMinEMASeparation) 
      sellConditions = false; // Vi phạm điều kiện SELL
   
   // Nếu tất cả điều kiện SELL đều đúng, trả về tín hiệu SELL
   if(sellConditions)
      return -1; // Tín hiệu SELL
   
   // ============================================================
   // BƯỚC 7: KHÔNG CÓ TÍN HIỆU
   // ============================================================
   // Nếu không thỏa mãn điều kiện BUY hoặc SELL, trả về không có tín hiệu
   return 0; // Không có tín hiệu
}

//+------------------------------------------------------------------+
//| Determine signal type (BUY/SELL/NONE) - Wrapper function       |
//| Sử dụng GetEntrySignal() để lấy tín hiệu                        |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE DetermineSignalType(string symbol)
{
   // Gọi hàm GetEntrySignal() để lấy tín hiệu
   int signal = GetEntrySignal(symbol);
   
   // Chuyển đổi từ int sang ENUM_SIGNAL_TYPE
   if(signal == 1)
      return SIGNAL_BUY;  // Tín hiệu BUY
   else if(signal == -1)
      return SIGNAL_SELL; // Tín hiệu SELL
   else
      return SIGNAL_NONE; // Không có tín hiệu
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
//| Record trade result in statistics (call manually after trade)   |
//+------------------------------------------------------------------+
void RecordTradeResult(string symbol, datetime entryTime, double exitPrice, bool isWin)
{
   if(InpEnableStatistics && g_statistics != NULL)
   {
      g_statistics.RecordResult(symbol, entryTime, exitPrice, isWin);
      Print("Trade result recorded: ", symbol, " | Entry: ", TimeToString(entryTime), 
            " | Exit: ", DoubleToString(exitPrice, 5), " | Result: ", (isWin ? "WIN" : "LOSS"));
   }
}

//+------------------------------------------------------------------+
//| Print current statistics to log                                  |
//+------------------------------------------------------------------+
void PrintStatistics()
{
   if(InpEnableStatistics && g_statistics != NULL)
   {
      Print("\n═══════════════════════════════════════════════════════════");
      Print("CURRENT STATISTICS REPORT");
      Print("═══════════════════════════════════════════════════════════");
      g_statistics.PrintStatistics();
   }
   else
   {
      Print("Statistics tracking is disabled. Enable InpEnableStatistics to track statistics.");
   }
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                              |
//| All code generation complete - EA ready for compilation          |
//+------------------------------------------------------------------+
