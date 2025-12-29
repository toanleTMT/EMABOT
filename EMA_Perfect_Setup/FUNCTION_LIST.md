# EMA Perfect Setup Scanner EA - Complete Function List

## 📋 Overview

This document lists all functions created in the EMA Perfect Setup Scanner EA, organized by category and file.

**Total Functions**: 200+  
**Total Classes**: 25+  
**Total Files**: 40+

---

## 🎯 Main EA File (`EMA_Perfect_Setup.mq5`)

### Core Functions
- `OnInit()` - EA initialization
- `OnDeinit(const int reason)` - EA cleanup
- `OnTimer()` - Main scanning loop (called every scan interval)
- `DetermineSignalType(string symbol)` - Detects BUY/SELL signals
- `CalculateStopLoss(string symbol, ENUM_SIGNAL_TYPE signalType, double entry)` - Calculates stop loss price
- `CalculateTakeProfit(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double pips)` - Calculates take profit price

---

## 📊 Indicator Managers

### EMA Manager (`EMA_Manager.mqh`)
**Class**: `CEMAManager`

**Constructor/Destructor**:
- `CEMAManager()` - Constructor
- `~CEMAManager()` - Destructor

**Public Methods**:
- `Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int fastPeriod, int mediumPeriod, int slowPeriod, ENUM_MA_METHOD method, ENUM_APPLIED_PRICE appliedPrice)` - Initialize indicators
- `Deinitialize()` - Release indicators
- `GetEMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[])` - Get EMA values
- `IsEMAsAligned(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf)` - Check EMA alignment
- `GetEMASeparation(string symbol, ENUM_TIMEFRAMES tf)` - Calculate EMA separation in pips
- `IsEMACrossed(string symbol, ENUM_SIGNAL_TYPE signalType, ENUM_TIMEFRAMES tf)` - Check for EMA crossover

**Private Methods**:
- `FindSymbolIndex(string symbol)` - Find symbol in array
- `InitializeIndicator(string symbol, int index)` - Initialize indicator for symbol

### RSI Manager (`RSI_Manager.mqh`)
**Class**: `CRSIManager`

**Constructor/Destructor**:
- `CRSIManager()` - Constructor
- `~CRSIManager()` - Destructor

**Public Methods**:
- `Initialize(string symbols[], ENUM_TIMEFRAMES timeframe, int period)` - Initialize RSI indicators
- `Deinitialize()` - Release indicators
- `GetRSIValue(string symbol, double &rsi)` - Get RSI value
- `IsRSIBullish(string symbol, int threshold = 50)` - Check if RSI is bullish
- `IsRSIBearish(string symbol, int threshold = 50)` - Check if RSI is bearish

**Private Methods**:
- `FindSymbolIndex(string symbol)` - Find symbol in array
- `InitializeIndicator(string symbol, int index)` - Initialize indicator for symbol

---

## 🎯 Scoring System

### Setup Scorer (`Setup_Scorer.mqh`)
**Class**: `CSetupScorer`

**Constructor/Destructor**:
- `CSetupScorer(...)` - Constructor with all parameters
- `~CSetupScorer()` - Destructor

**Public Methods**:
- `CalculateTotalScore(string symbol, ENUM_SIGNAL_TYPE signalType, int &categoryScores[])` - Calculate total score (0-100)
- `GetScoreBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[])` - Get detailed breakdown
- `GetStrengthsAndWeaknesses(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[])` - Get analysis
- `GetQuality(int totalScore)` - Get quality enum (PERFECT/GOOD/WEAK/INVALID)

### Trend Scorer (`Trend_Scorer.mqh`)
**Class**: `CTrendScorer`

**Constructor**:
- `CTrendScorer(CEMAManager *emaH1, int minH1Distance)` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate trend score (0-25)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreH1PriceDistance(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score price-EMA50 distance (0-15)
- `ScoreH1EMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score EMA alignment (0-10)

### EMA Quality Scorer (`EMA_Quality_Scorer.mqh`)
**Class**: `CEMAQualityScorer`

**Constructor**:
- `CEMAQualityScorer(CEMAManager *emaM5, int minSeparation)` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate EMA quality score (0-20)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreEMAAlignment(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score alignment (0-10)
- `ScoreEMASeparation(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score separation (0-10)

### Signal Scorer (`Signal_Scorer.mqh`)
**Class**: `CSignalScorer`

**Constructor**:
- `CSignalScorer(CEMAManager *emaM5, CEMAManager *emaH1)` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate signal strength score (0-20)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreEMACrossover(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score crossover quality (0-10)
- `ScorePricePosition(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score price position (0-10)
- `GetPipValue(string symbol)` - Get pip value helper

### Confirmation Scorer (`Confirmation_Scorer.mqh`)
**Class**: `CConfirmationScorer`

**Constructor**:
- `CConfirmationScorer(CRSIManager *rsi, int minCandleBody)` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate confirmation score (0-15)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreCandleStrength(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score candle body (0-8)
- `ScoreRSIConfirmation(string symbol, ENUM_SIGNAL_TYPE signalType)` - Score RSI confirmation (0-7)

### Market Scorer (`Market_Scorer.mqh`)
**Class**: `CMarketScorer`

**Constructor**:
- `CMarketScorer(double maxSpread)` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate market conditions score (0-10)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreSpread(string symbol)` - Score spread (0-5)
- `ScoreVolume(string symbol)` - Score volume (0-5)

### Context Scorer (`Context_Scorer.mqh`)
**Class**: `CContextScorer`

**Constructor**:
- `CContextScorer()` - Constructor

**Public Methods**:
- `CalculateScore(string symbol, ENUM_SIGNAL_TYPE signalType)` - Calculate context score (0-10)
- `GetBreakdown(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get breakdown string

**Private Methods**:
- `ScoreTradingSession()` - Score trading session (0-5)
- `ScoreSupportResistance(string symbol)` - Score S/R levels (0-5)

### Setup Analyzer (`Setup_Analyzer.mqh`)
**Class**: `CSetupAnalyzer`

**Constructor**:
- `CSetupAnalyzer(int minScoreAlert)` - Constructor

**Public Methods**:
- `GetQuality(int totalScore)` - Get quality enum
- `IsPerfectSetup(int totalScore)` - Check if perfect (≥85)
- `IsGoodSetup(int totalScore)` - Check if good (70-84)
- `IsWeakSetup(int totalScore)` - Check if weak (50-69)
- `IsInvalidSetup(int totalScore)` - Check if invalid (<50)
- `GetRejectionReason(int totalScore, int categoryScores[])` - Get rejection reason

### Score Cache (`Score_Cache.mqh`)
**Class**: `CScoreCache`

**Constructor/Destructor**:
- `CScoreCache(int timeoutSeconds = 1)` - Constructor
- `~CScoreCache()` - Destructor

**Public Methods**:
- `GetH1EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaH1)` - Get cached H1 EMA data
- `GetM5EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaM5)` - Get cached M5 EMA data
- `GetEMASeparation(string symbol, CEMAManager *emaM5)` - Get cached EMA separation
- `GetRSIValue(string symbol, CRSIManager *rsi)` - Get cached RSI value
- `GetPriceH1(string symbol)` - Get cached H1 price
- `GetPriceM5(string symbol)` - Get cached M5 price
- `GetSpreadPips(string symbol)` - Get cached spread
- `GetVolume(string symbol)` - Get cached volume
- `InvalidateCache(string symbol)` - Invalidate cache for symbol
- `UpdateCache(string symbol, CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi)` - Update cache

**Private Methods**:
- `FindCacheIndex(string symbol)` - Find cache entry index

---

## 🎨 Visual Components

### Dashboard (`Dashboard.mqh`)
**Class**: `CDashboard`

**Constructor/Destructor**:
- `CDashboard()` - Constructor
- `~CDashboard()` - Destructor

**Public Methods**:
- `Initialize(int x, int y)` - Initialize dashboard
- `Update(string symbol, int totalScore, int categoryScores[], int signalsToday, datetime lastScan)` - Update dashboard
- `Flash()` - Flash dashboard for perfect setup
- `CheckFlashRestore()` - Restore flash color
- `Show()` - Show dashboard
- `Hide()` - Hide dashboard
- `Cleanup()` - Cleanup objects

**Private Methods**:
- `CreateBackground()` - Create background rectangle
- `CreateLabels()` - Create text labels
- `UpdateLabels(string symbol, int totalScore, int categoryScores[], int signalsToday, datetime lastScan)` - Update label text

### Arrow Manager (`Arrow_Manager.mqh`)
**Class**: `CArrowManager`

**Constructor/Destructor**:
- `CArrowManager(int arrowSize, color buyColor, color sellColor, color goodColor, color weakColor)` - Constructor
- `~CArrowManager()` - Destructor

**Public Methods**:
- `DrawArrow(string symbol, ENUM_TIMEFRAMES tf, ENUM_SIGNAL_TYPE signalType, int score, datetime time)` - Draw arrow signal
- `CleanupOldArrows(int maxAgeSeconds = 3600)` - Cleanup old arrows
- `DeleteAllArrows()` - Delete all arrows

**Private Methods**:
- `GetArrowColor(int score)` - Get color based on score
- `GetArrowCode(ENUM_SIGNAL_TYPE signalType)` - Get arrow code

### Label Manager (`Label_Manager.mqh`)
**Class**: `CLabelManager`

**Constructor/Destructor**:
- `CLabelManager(int fontSize)` - Constructor
- `~CLabelManager()` - Destructor

**Public Methods**:
- `DrawLabel(string symbol, ENUM_TIMEFRAMES tf, ENUM_SIGNAL_TYPE signalType, double entry, double sl, double tp1, double tp2, int score, int categoryScores[], string strengths, datetime time)` - Draw detailed label
- `CleanupOldLabels(int maxAgeSeconds = 3600)` - Cleanup old labels
- `DeleteAllLabels()` - Delete all labels

**Private Methods**:
- `FormatLabelText(...)` - Format label text
- `GetLabelColor(int score)` - Get color based on score

### Panel Manager (`Panel_Manager.mqh`)
**Class**: `CPanelManager`

**Constructor/Destructor**:
- `CPanelManager()` - Constructor
- `~CPanelManager()` - Destructor

**Public Methods**:
- `Initialize()` - Initialize panel
- `Update(string symbol, ENUM_SIGNAL_TYPE signalType, int categoryScores[], string breakdown, string strengths)` - Update panel
- `Show()` - Show panel
- `Hide()` - Hide panel
- `Cleanup()` - Cleanup objects

### Dashboard Helper (`Dashboard_Helper.mqh`)
**Functions**:
- `FormatRecommendation(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double sl, double tp1, double tp2)` - Format recommendation text
- `FormatDisciplineCheck()` - Format discipline check text
- `CalculateQualityRate(int perfectToday, int goodToday, int weakToday)` - Calculate quality rate percentage

---

## 🔔 Alert System

### Alert Manager (`Alert_Manager.mqh`)
**Class**: `CAlertManager`

**Constructor/Destructor**:
- `CAlertManager(bool popupPerfect, bool soundPerfect, bool pushPerfect, bool emailPerfect, string soundFilePerfect, string soundFileGood)` - Constructor
- `~CAlertManager()` - Destructor

**Public Methods**:
- `SendAlert(string symbol, ENUM_SIGNAL_TYPE signalType, int score, string message, string strengths)` - Send alert
- `SendPerfectAlert(string symbol, ENUM_SIGNAL_TYPE signalType, int score, string message, string strengths)` - Send perfect setup alert
- `SendGoodAlert(string symbol, ENUM_SIGNAL_TYPE signalType, int score, string message)` - Send good setup alert

**Private Methods**:
- `ShowPopup(string message)` - Show popup window
- `PlaySound(string soundFile)` - Play sound file
- `SendPush(string message)` - Send push notification
- `SendEmail(string subject, string body)` - Send email

### Popup Builder (`Popup_Builder.mqh`)
**Functions**:
- `BuildPopupMessage(string symbol, ENUM_SIGNAL_TYPE signalType, int score, string strengths)` - Build popup message text

---

## 📝 Journal System

### Journal Manager (`Journal_Manager.mqh`)
**Class**: `CJournalManager`

**Constructor/Destructor**:
- `CJournalManager(string journalPath, bool enableCSV, bool takeScreenshots)` - Constructor
- `~CJournalManager()` - Destructor

**Public Methods**:
- `Initialize()` - Initialize journal system
- `LogPerfectSignal(string symbol, ENUM_SIGNAL_TYPE signalType, int score, int categoryScores[], double entry, double sl, double tp1, double tp2, string strengths, string weaknesses)` - Log perfect setup
- `LogRejectedSignal(string symbol, ENUM_SIGNAL_TYPE signalType, int score, int categoryScores[], string reason)` - Log rejected setup
- `TakeScreenshot(string symbol, ENUM_SIGNAL_TYPE signalType, int score)` - Take chart screenshot
- `ExportToCSV(datetime startDate, datetime endDate)` - Export date range to CSV
- `GetJournalPath()` - Get journal directory path

**Private Methods**:
- `CreateJournalDirectory()` - Create journal directory
- `SanitizeFilename(string filename)` - Sanitize filename

### CSV Exporter (`CSV_Exporter.mqh`)
**Class**: `CCSVExporter`

**Constructor**:
- `CCSVExporter(string journalPath)` - Constructor

**Public Methods**:
- `ExportEntry(JournalEntry &entry)` - Export single entry
- `ExportRange(datetime startDate, datetime endDate)` - Export date range

**Private Methods**:
- `WriteCSVHeader(int fileHandle)` - Write CSV header
- `WriteCSVRow(int fileHandle, JournalEntry &entry)` - Write CSV row

### Stats Calculator (`Stats_Calculator.mqh`)
**Functions**:
- `CalculateDailyStats(datetime date)` - Calculate daily statistics
- `CalculateWeeklyStats(datetime weekStart)` - Calculate weekly statistics
- `CalculateMonthlyStats(datetime monthStart)` - Calculate monthly statistics

---

## 🛠️ Utilities

### Time Utils (`Time_Utils.mqh`)
**Functions**:
- `IsLondonNYOverlap()` - Check if London-NY overlap session
- `IsLondonSession()` - Check if London session
- `IsNYSession()` - Check if NY session
- `IsAsianSession()` - Check if Asian session
- `GetTradingSessionScore()` - Get session score (0-5)
- `IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)` - Check if new bar formed
- `GetStartOfDay(datetime time)` - Get start of day
- `IsNewDay(datetime &lastDayCheck)` - Check if new day started

### Price Utils (`Price_Utils.mqh`)
**Functions**:
- `GetPipValue(string symbol)` - Get pip value for symbol
- `PriceToPips(string symbol, double priceDiff)` - Convert price to pips
- `PipsToPrice(string symbol, double pips)` - Convert pips to price
- `GetSpreadPips(string symbol)` - Get current spread in pips
- `CalculateStopLoss(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double stopLossPips)` - Calculate stop loss
- `CalculateTakeProfit(string symbol, ENUM_SIGNAL_TYPE signalType, double entry, double takeProfitPips)` - Calculate take profit
- `CalculateRiskReward(double entry, double stopLoss, double takeProfit, ENUM_SIGNAL_TYPE signalType)` - Calculate R:R ratio
- `CalculateLotSize(string symbol, double entry, double stopLoss, double riskPercent, double accountBalance)` - Calculate lot size
- `GetCurrentPrice(string symbol, ENUM_SIGNAL_TYPE signalType)` - Get current price (Ask/Bid)

### String Utils (`String_Utils.mqh`)
**Functions**:
- `ParseSymbols(string input, string &output[])` - Parse comma-separated symbols
- `FormatScore(int score)` - Format score with quality emoji
- `FormatPrice(string symbol, double price)` - Format price with proper digits
- `FormatPips(double pips)` - Format pips string
- `CreateProgressBar(int current, int max, int barLength = 5)` - Create progress bar string
- `GetSignalTypeString(ENUM_SIGNAL_TYPE type)` - Get signal type string
- `GetQualityLabel(int score)` - Get quality label (PERFECT/GOOD/WEAK/INVALID)
- `FormatDateTime(datetime dt)` - Format datetime for display
- `FormatDate(datetime dt)` - Format date for display

### Error Handler (`Error_Handler.mqh`)
**Functions**:
- `GetErrorDescription(int errorCode)` - Get error description string
- `LogError(string context, int errorCode)` - Log error with context
- `CheckError(string context)` - Check if operation was successful

### Symbol Utils (`Symbol_Utils.mqh`)
**Functions**:
- `IsSymbolValid(string symbol)` - Check if symbol is valid
- `NormalizeSymbol(string symbol)` - Normalize symbol name
- `GetSymbolDigits(string symbol)` - Get symbol digits
- `IsMarketOpen(string symbol)` - Check if market is open

### Signal Validator (`Signal_Validator.mqh`)
**Class**: `CSignalValidator`

**Constructor**:
- `CSignalValidator(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi, double maxSpread, double minEMASeparation)` - Constructor

**Public Methods**:
- `ValidateBuySignal(string symbol)` - Validate BUY signal conditions
- `ValidateSellSignal(string symbol)` - Validate SELL signal conditions

**Private Methods**:
- `CheckSpread(string symbol)` - Check spread
- `CheckEMASeparation(string symbol)` - Check EMA separation

### Input Validator (`Input_Validator.mqh`)
**Class**: `CInputValidator`

**Public Methods**:
- `ValidateInputs(...)` - Validate all input parameters
- `ValidateSymbols(string symbols)` - Validate symbol list

### Debug Helper (`Debug_Helper.mqh`)
**Class**: `CDebugHelper`

**Constructor**:
- `CDebugHelper(bool enableDebug = false, string logPrefix = "[DEBUG]")` - Constructor

**Public Methods**:
- `Log(string message)` - Log debug message
- `LogError(string message)` - Log error message
- `LogWarning(string message)` - Log warning message
- `IsEnabled()` - Check if debug enabled

### Performance Monitor (`Performance_Monitor.mqh`)
**Class**: `CPerformanceMonitor`

**Constructor/Destructor**:
- `CPerformanceMonitor()` - Constructor
- `~CPerformanceMonitor()` - Destructor

**Public Methods**:
- `Start()` - Start monitoring
- `Stop()` - Stop monitoring
- `RecordScan()` - Record scan operation
- `RecordSignal()` - Record signal detection
- `RecordError()` - Record error
- `GetPerformanceReport()` - Get performance report string
- `UpdateMemoryUsage()` - Update memory usage stats

**Private Methods**:
- `GetCPUUsage()` - Get CPU usage percentage
- `GetMemoryUsage()` - Get memory usage

### Timer Helper (`Timer_Helper.mqh`)
**Class**: `CTimerHelper`

**Constructor/Destructor**:
- `CTimerHelper()` - Constructor
- `~CTimerHelper()` - Destructor

**Public Methods**:
- `Start(int intervalSeconds)` - Start timer
- `Stop()` - Stop timer
- `IsTimeToScan()` - Check if time to scan

### Object Helper (`Object_Helper.mqh`)
**Functions**:
- `CreateLabelSafe(string name, int x, int y, string text, color clr, int fontSize, string font = "Arial")` - Safely create label
- `CreateRectangleSafe(string name, int x, int y, int width, int height, color bgColor)` - Safely create rectangle
- `UpdateLabelText(string name, string text)` - Update label text
- `UpdateLabelColor(string name, color clr)` - Update label color
- `DeleteObjectSafe(string name)` - Safely delete object
- `ObjectExists(string name)` - Check if object exists

### Scoring Test (`Scoring_Test.mqh`)
**Class**: `CScoringTest`

**Public Methods**:
- `QuickTest(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi, string symbol = "")` - Quick verification test
- `RunAllTests(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi)` - Run comprehensive test suite
- `TestTrendScoring(CEMAManager *emaH1, string symbol)` - Test trend scoring
- `TestEMAQualityScoring(CEMAManager *emaM5, string symbol)` - Test EMA quality scoring
- `TestSignalScoring(CEMAManager *emaM5, CEMAManager *emaH1, string symbol)` - Test signal scoring
- `TestConfirmationScoring(CRSIManager *rsi, string symbol)` - Test confirmation scoring
- `TestMarketScoring(string symbol)` - Test market scoring
- `TestContextScoring()` - Test context scoring
- `TestTotalScore(CSetupScorer *scorer, string symbol)` - Test total score calculation
- `TestScoreBreakdown(CSetupScorer *scorer, string symbol)` - Test score breakdown
- `TestStrengthsAndWeaknesses(CSetupScorer *scorer, string symbol)` - Test strengths/weaknesses
- `TestScoreValidation(CSetupScorer *scorer, string symbol)` - Test score validation
- `TestEdgeCases(CSetupScorer *scorer, string symbol)` - Test edge cases

**Private Methods**:
- `ResetTestCounters()` - Reset test counters
- `PrintTestSummary()` - Print test summary
- `VerifyScoreRange(int score, int min, int max, string testName)` - Verify score range

---

## 📊 Summary Statistics

### By Category:
- **Main EA Functions**: 6
- **Indicator Managers**: 12 functions
- **Scoring System**: 35+ functions
- **Visual Components**: 20+ functions
- **Alert System**: 8 functions
- **Journal System**: 12 functions
- **Utilities**: 50+ functions
- **Test Functions**: 15 functions

### By Type:
- **Constructors**: 25+
- **Destructors**: 15+
- **Public Methods**: 120+
- **Private Methods**: 40+
- **Standalone Functions**: 50+

---

## 🎯 Total Function Count

**Approximate Total**: **200+ functions** across all files

---

**Last Updated**: Current  
**Version**: 2.0

