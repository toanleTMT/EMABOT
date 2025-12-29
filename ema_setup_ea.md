# COMPLETE EA DEVELOPMENT PROMPT - MT5 EMA SCALPING "PERFECT SETUP ONLY"

Copy this entire document and paste into Cursor IDE Composer to generate the complete EA.

---

## 🎯 PROJECT MISSION

Create a MetaTrader 5 Expert Advisor that:
- Scans markets for EMA scalping setups and scores them 0-100 points
- ONLY alerts when setup scores ≥85 points (PERFECT quality)
- Displays visual signals (arrows + detailed labels) on charts
- Shows real-time dashboard with score breakdown
- Includes built-in trading journal for tracking
- Does NOT auto-trade - trader manually decides to enter
- Philosophy: "Quality over Quantity - Only Perfect Setups"

---

## 📊 CORE STRATEGY - EMA SCALPING

### Indicators Used:
```
- EMA 9 (Fast)
- EMA 21 (Medium)  
- EMA 50 (Slow)
- RSI 14 (Filter)
```

### Timeframes:
```
- H1: Trend identification
- M15: Context (optional)
- M5: Entry signals (PRIMARY)
```

### BUY Signal Conditions (All must be TRUE):
1. **H1:** Price > EMA 50
2. **H1:** EMAs aligned: EMA 9 > EMA 21 > EMA 50
3. **M5:** EMAs aligned: EMA 9 > EMA 21 > EMA 50
4. **M5:** EMA 9 crosses ABOVE EMA 21 (bullish crossover)
5. **M5:** Current candle closes ABOVE EMA 9
6. **M5:** Price, EMA 9, and EMA 21 ALL above EMA 50
7. **M5:** RSI(14) > 50
8. **M5:** EMAs have clear separation (not tangled/choppy)
9. Spread < MaxSpread setting
10. Only one signal per bar

### SELL Signal Conditions (All must be TRUE):
1. **H1:** Price < EMA 50
2. **H1:** EMAs aligned: EMA 9 < EMA 21 < EMA 50
3. **M5:** EMAs aligned: EMA 9 < EMA 21 < EMA 50
4. **M5:** EMA 9 crosses BELOW EMA 21 (bearish crossover)
5. **M5:** Current candle closes BELOW EMA 9
6. **M5:** Price, EMA 9, and EMA 21 ALL below EMA 50
7. **M5:** RSI(14) < 50
8. **M5:** EMAs have clear separation (not tangled/choppy)
9. Spread < MaxSpread setting
10. Only one signal per bar

---

## 🎯 SCORING SYSTEM (0-100 Points)

Each setup is scored across 6 categories. Only setups scoring ≥85 trigger alerts.

### Category 1: Trend Alignment (25 points max)

**H1 Price-EMA50 Distance:**
- ≥50 pips clear: 15 points
- 20-50 pips: 10 points
- <20 pips: 5 points
- Touching/crossing: 0 points

**H1 EMA Alignment:**
- Perfect order (9>21>50 or 9<21<50): 10 points
- Partial alignment: 5 points
- Tangled: 0 points

### Category 2: M5 EMA Quality (20 points max)

**EMA Alignment:**
- Perfect order with no tangles: 10 points
- Correct order but tight: 6 points
- Tangled: 0 points

**EMA Separation:**
- Wide separation (>15 pips average): 10 points
- Moderate (8-15 pips): 6 points
- Tight (<8 pips): 2 points
- Tangled: 0 points

### Category 3: Signal Strength (20 points max)

**EMA Crossover Quality:**
- Clean, decisive cross with momentum: 10 points
- Clean but weak momentum: 6 points
- Choppy cross: 2 points

**Price Position:**
- Price AND both EMAs 9,21 clearly correct side of EMA 50: 10 points
- Only price or only one EMA clear: 5 points
- Unclear: 0 points

### Category 4: Confirmation (15 points max)

**Candle Strength:**
- Strong body (>70% of candle): 8 points
- Moderate body (50-70%): 5 points
- Weak body (<50%): 2 points

**RSI Confirmation:**
- Strongly favorable (>60 BUY, <40 SELL): 7 points
- Moderately favorable (50-60 or 40-50): 4 points
- Neutral (45-55): 0 points

### Category 5: Market Conditions (10 points max)

**Spread:**
- <1.5 pips: 5 points
- 1.5-2.5 pips: 3 points
- >2.5 pips: 0 points (reject signal)

**Volume/Momentum:**
- High volume on crossover: 5 points
- Average volume: 3 points
- Low volume: 0 points

### Category 6: Context & Timing (10 points max)

**Trading Session:**
- London-NY overlap (19:00-23:00 Vietnam time): 5 points
- London or NY session alone: 3 points
- Asian session: 0 points

**M15 S/R Level:**
- At key support/resistance: 5 points
- No clear level: 2 points

---

## 🎨 VISUAL SYSTEM

### 1. Arrow Signals

**PERFECT (85-100 points):**
- Large arrow (size 3)
- Color: Bright Lime (#00FF00) for BUY, Bright Red (#FF0000) for SELL
- Position: Clear of candle (below low for BUY, above high for SELL)

**GOOD (70-84 points) - Optional:**
- Medium arrow (size 2)
- Color: Yellow (#FFD700)
- Only shown if user enables "ShowGoodSetups"

**WEAK (50-69 points) - Optional:**
- Small arrow (size 1)
- Color: Gray (#808080)
- Only shown if user enables "ShowWeakSetups"

### 2. Detailed Labels

Display near each arrow:
```
PERFECT SETUP 🟢 87/100

BUY Signal
Entry: 1.0875
SL: 1.0850 (-25 pips)
TP1: 1.0900 (+25 pips) [50%]
TP2: 1.0925 (+50 pips) [50%]
R:R = 1:2.0

SCORE BREAKDOWN:
✓ Trend: 23/25
✓ EMA Quality: 18/20
✓ Signal: 19/20
✓ Confirmation: 13/15
✓ Market: 9/10
~ Context: 5/10

WHY PERFECT:
• Strong H1 uptrend
• Excellent EMA separation
• Clean crossover
• London-NY session
```

### 3. Main Dashboard (Top-Right Corner)

```
╔═══════════════════════════════════════╗
║ EMA PERFECT SETUP SCANNER v2.0        ║
║ Status: 🟢 PERFECT SETUP FOUND!       ║
║ Pair: EUR/USD | TF: M5                ║
║ Time: 20:15:30 | Spread: 1.2 pips     ║
║───────────────────────────────────────║
║ 🎯 SETUP SCORE: 87/100 🟢 PERFECT!   ║
║───────────────────────────────────────║
║ SCORING DETAILS:                      ║
║ ✓ Trend Alignment:    23/25 [████░]  ║
║ ✓ EMA Quality:        18/20 [████░]  ║
║ ✓ Signal Strength:    19/20 [████▓]  ║
║ ✓ Confirmation:       13/15 [███░░]  ║
║ ✓ Market Conditions:   9/10 [████░]  ║
║ ~ Context & Timing:    5/10 [██░░░]  ║
║───────────────────────────────────────║
║ 📈 RECOMMENDATION: BUY                ║
║ Entry: 1.0875 | SL: 1.0850            ║
║ TP1: 1.0900 (+25p) | TP2: 1.0925      ║
║ R:R = 1:2.0 | Risk: $25 (1%)          ║
║───────────────────────────────────────║
║ 📊 TODAY'S STATS:                     ║
║ Perfect Setups: 2                     ║
║ Good Setups: 3 (not alerted)          ║
║ Weak Setups: 5 (skipped)              ║
║ Quality Rate: 40% (2/5 valid)         ║
║───────────────────────────────────────║
║ ⚠️ DISCIPLINE CHECK:                  ║
║ □ All conditions verified?            ║
║ □ Feeling confident?                  ║
║ □ Not revenge trading?                ║
║ □ Risk calculated?                    ║
╚═══════════════════════════════════════╝
```

**Dashboard Requirements:**
- Semi-transparent background (rgba: 30,30,30,0.9)
- White text, green for positive, red for warnings
- Fixed at top-right, 10px margin from edges
- Auto-hide option in settings
- Show progress bars for each category
- Update in real-time as new data comes

### 4. Score Breakdown Panel (Optional, Bottom-Left)

```
╔═══════════════════════════════════════╗
║ 📊 DETAILED ANALYSIS                  ║
║───────────────────────────────────────║
║ H1 TREND:                             ║
║ ✓ Price 45 pips above EMA50: +15     ║
║ ✓ EMAs aligned perfectly: +10        ║
║                                       ║
║ M5 EMA QUALITY:                       ║
║ ✓ Perfect alignment: +10              ║
║ ~ Moderate separation (12p): +6       ║
║                                       ║
║ SIGNAL STRENGTH:                      ║
║ ✓ Clean decisive cross: +10           ║
║ ✓ All above EMA50: +10                ║
║                                       ║
║ CONFIRMATION:                         ║
║ ✓ Strong candle (75% body): +8       ║
║ ~ RSI moderate (55): +4               ║
║                                       ║
║ MARKET:                               ║
║ ✓ Low spread (1.2): +5                ║
║ ✓ High volume: +5                     ║
║                                       ║
║ CONTEXT:                              ║
║ ✓ NY session: +3                      ║
║ ~ No key S/R: +2                      ║
║───────────────────────────────────────║
║ STRENGTHS:                            ║
║ • Very clear trend on H1              ║
║ • Clean EMA structure                 ║
║ • Strong momentum                     ║
║                                       ║
║ MINOR WEAKNESSES:                     ║
║ • RSI not extremely strong            ║
║ • Not at major S/R level              ║
╚═══════════════════════════════════════╝
```

---

## 🔔 ALERT SYSTEM

### Alert Levels Based on Score:

**PERFECT (85-100 points):**
- ✅ Large popup window with full details
- ✅ Loud alert sound (alert2.wav or custom)
- ✅ Push notification to mobile
- ✅ Email alert (if configured)
- ✅ Dashboard flashes GREEN for 5 seconds
- Message: "🟢 PERFECT SETUP! Score: 87/100 - Check EUR/USD chart NOW!"

**GOOD (70-84 points) - Optional:**
- ~ Small popup (only if enabled in settings)
- ~ Soft sound
- ~ No push/email
- ~ Dashboard shows YELLOW
- Message: "🟡 Good setup (Score: 78) but not perfect - Consider carefully"

**WEAK (50-69 points):**
- ❌ NO alerts at all
- ❌ Only logged silently in journal
- Dashboard shows GRAY briefly

**INVALID (<50 points):**
- ❌ Completely ignored
- ❌ Not even logged

### Popup Alert Format:

```
╔══════════════════════════════════════╗
║   🎯 PERFECT SETUP ALERT! 🎯         ║
╠══════════════════════════════════════╣
║                                      ║
║  Symbol: EUR/USD                     ║
║  Direction: BUY 📈                   ║
║  Quality: 🟢 PERFECT (87/100)        ║
║                                      ║
║  ─────────────────────────────────── ║
║                                      ║
║  Entry: 1.0875 (Market)              ║
║  Stop Loss: 1.0850 (25 pips)         ║
║  Take Profit 1: 1.0900 (25 pips)     ║
║  Take Profit 2: 1.0925 (50 pips)     ║
║                                      ║
║  Risk/Reward: 1:2.0 ⭐⭐             ║
║  Suggested Risk: $25 (1% account)    ║
║                                      ║
║  ─────────────────────────────────── ║
║                                      ║
║  WHY THIS IS PERFECT:                ║
║  ✓ H1 trend very strong (45p gap)    ║
║  ✓ Clean EMA crossover with momentum ║
║  ✓ Excellent EMA separation          ║
║  ✓ London-NY session (high volume)   ║
║  ✓ Low spread (1.2 pips)             ║
║                                      ║
║  Only Minor Weakness:                ║
║  • RSI moderate (55, not >60)        ║
║                                      ║
║  [  View Chart  ] [  Trade Now  ]    ║
║  [  Skip Setup  ] [  More Info  ]    ║
║                                      ║
╚══════════════════════════════════════╝
```

---

## 📝 TRADING JOURNAL SYSTEM

### Auto-Logging Features:

**Every signal (even rejected) is logged:**

```
2024.01.15 20:15:30 | EUR/USD | M5
Score: 87/100 🟢 PERFECT
Type: BUY Signal
Entry: 1.0875 | SL: 1.0850 | TP1: 1.0900 | TP2: 1.0925

CATEGORY SCORES:
- Trend: 23/25 (excellent)
- EMA Quality: 18/20 (excellent)
- Signal: 19/20 (excellent)
- Confirmation: 13/15 (good)
- Market: 9/10 (excellent)
- Context: 5/10 (fair)

STRENGTHS:
• Strong H1 uptrend (45 pips clear)
• Perfect EMA alignment
• Clean crossover with momentum
• London-NY session

WEAKNESSES:
• RSI not extremely strong (55)
• Not at key S/R level

USER DECISION: [ ] Traded [ ] Skipped
REASON: _________________________________

ACTUAL RESULT (fill after):
[ ] Win [ ] Loss [ ] Breakeven
Pips: _______ | Exit Time: _______
Notes: _________________________________

═══════════════════════════════════════

2024.01.15 15:30:00 | GBP/USD | M5
Score: 68/100 🔴 WEAK - CORRECTLY SKIPPED
Type: SELL Signal
Entry: 1.2650 | SL: 1.2675 | TP: 1.2625

WHY REJECTED:
• Asian session (low volume) - 0 points
• EMAs too close together (6 pips) - 2 points
• Spread too high (3.2 pips) - 0 points
• Weak candle confirmation (40% body) - 2 points

DECISION: ✓ Correctly avoided weak setup
```

**Journal Features:**
- Export to CSV for Excel analysis
- Weekly/monthly performance summaries
- Pattern recognition: which perfect setups win most?
- Discipline tracking: how many perfects were traded vs skipped?
- Screenshot capture on perfect setups (optional)

**Weekly Summary Example:**
```
╔═══════════════════════════════════════╗
║ 📊 WEEK 3 SUMMARY (Jan 15-21, 2024)  ║
╠═══════════════════════════════════════╣
║                                       ║
║ SETUPS DETECTED:                      ║
║ • Perfect (85+): 12                   ║
║ • Good (70-84): 18                    ║
║ • Weak (50-69): 25                    ║
║ • Invalid (<50): 47                   ║
║                                       ║
║ TRADING ACTIVITY:                     ║
║ • Perfect setups traded: 9/12 (75%)   ║
║ • Perfect setups skipped: 3 (reasons) ║
║   - 2 conflicted with news            ║
║   - 1 personal doubt                  ║
║                                       ║
║ RESULTS (Perfect Setups Only):        ║
║ • Wins: 6 (67% winrate) ✅            ║
║ • Losses: 3 (33%)                     ║
║ • Total Pips: +85 pips                ║
║ • Avg Win: +22 pips                   ║
║ • Avg Loss: -8 pips                   ║
║ • Profit Factor: 2.75                 ║
║                                       ║
║ DISCIPLINE SCORE: 92/100 🟢           ║
║ • Traded only perfect setups ✓       ║
║ • Avoided all weak setups ✓          ║
║ • 3 good setups were traded ⚠        ║
║   (should focus on perfect only)      ║
║                                       ║
║ BEST PERFORMING PATTERNS:             ║
║ 1. London open breakouts (5W-0L)      ║
║ 2. H1 trend + wide EMA gap (4W-1L)   ║
║                                       ║
║ IMPROVEMENT AREAS:                    ║
║ • Asian session setups = 3 losses     ║
║   → Avoid Asian even if score 85+     ║
║                                       ║
╚═══════════════════════════════════════╝
```

---

## ⚙️ INPUT PARAMETERS (Complete List)

```cpp
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
input double   InpStopLossPips = 5;                       // Stop Loss (pips)
input double   InpTakeProfit1Pips = 10;                   // Take Profit 1 (pips) - 50% close
input double   InpTakeProfit2Pips = 20;                   // Take Profit 2 (pips) - 50% close
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
```

---

## 🔧 TECHNICAL IMPLEMENTATION GUIDE

### Code Structure Overview:

```cpp
//+------------------------------------------------------------------+
//| Main EA Structure                                                 |
//+------------------------------------------------------------------+

// 1. GLOBAL VARIABLES
int g_emaFastHandle[], g_emaMediumHandle[], g_emaSlowHandle[], g_rsiHandle[];
double g_emaFast[], g_emaMedium[], g_emaSlow[], g_rsi[];
datetime g_lastSignalTime[];
int g_signalsToday = 0;
datetime g_lastDayCheck = 0;

// 2. CLASSES

//--- Scoring Engine ---
class CSetupScorer {
private:
    int CalculateTrendScore(string symbol);        // H1 trend + alignment
    int CalculateEMAQualityScore(string symbol);   // M5 EMA quality
    int CalculateSignalStrengthScore(string symbol); // Crossover + position
    int CalculateConfirmationScore(string symbol);  // Candle + RSI
    int CalculateMarketScore(string symbol);        // Spread + volume
    int CalculateContextScore(string symbol);       // Session + S/R
    
public:
    int CalculateTotalScore(string symbol, int &categoryScores[6]);
    string GetScoreBreakdown(string symbol, int categoryScores[6]);
    string GetStrengthsAndWeaknesses(int categoryScores[6]);
};

//--- Setup Analyzer ---
class CSetupAnalyzer {
public:
    bool IsPerfectSetup(int score) { return score >= InpMinScoreAlert; }
    bool IsGoodSetup(int score) { return score >= 70 && score < InpMinScoreAlert; }
    bool IsWeakSetup(int score) { return score >= 50 && score < 70; }
    bool IsInvalid(int score) { return score < 50; }
    
    string GetQualityLabel(int score);
    string GetRejectionReason(string symbol, int score, int categoryScores[6]);
};

//--- Visual Manager ---
class CVisualManager {
private:
    void CreateDashboardPanel();
    void CreateBreakdownPanel();
    
public:
    void DrawArrow(string symbol, datetime time, double price, int score, int signalType);
    void DrawDetailedLabel(string symbol, datetime time, double price, 
                          int score, int categoryScores[6], int signalType,
                          double entry, double sl, double tp1, double tp2);
    void UpdateMainDashboard(string symbol, int score, int categoryScores[6], int signalType);
    void UpdateBreakdownPanel(string symbol, int categoryScores[6]);
    void FlashDashboard(color flashColor, int durationMs);
    void CleanupOldObjects(int keepLastN);
};

//--- Journal Manager ---
class CJournalManager {
private:
    string m_journalPath;
    int m_fileHandle;
    
public:
    bool Initialize();
    void LogPerfectSignal(string symbol, datetime time, int score, 
                         int categoryScores[6], int signalType,
                         double entry, double sl, double tp1, double tp2,
                         string strengths, string weaknesses);
    void LogRejectedSignal(string symbol, datetime time, int score,
                          int categoryScores[6], string reason);
    void ExportToCSV(datetime startDate, datetime endDate);
    void TakeScreenshot(string symbol, datetime time);
    void GenerateWeeklySummary();
};

//--- Alert Manager ---
class CAlertManager {
public:
    void SendPerfectSetupAlert(string symbol, int score, int signalType,
                              double entry, double sl, double tp1, double tp2,
                              string strengths, string weaknesses);
    void SendGoodSetupAlert(string symbol, int score, int signalType);
    void ShowPopup(string message, string title);
    void PlaySound(string soundFile);
    void SendPushNotification(string message);
    void SendEmail(string subject, string body);
};

// 3. MAIN EA FUNCTIONS

//--- OnInit ---
int OnInit() {
    // Parse symbols from input string
    // Initialize indicator handles for each symbol
    // Create visual objects (dashboard, panels)
    // Initialize journal system
    // Set timer for scanning
    return INIT_SUCCEEDED;
}

//--- OnDeinit ---
void OnDeinit(const int reason) {
    // Release all indicator handles
    // Delete all visual objects
    // Close journal files
    // Kill timer
}

//--- OnTimer (Main Scanning Loop) ---
void OnTimer() {
    // Check if new day (reset daily counter)
    CheckNewDay();
    
    // Loop through all symbols
    string symbols[];
    ParseSymbols(InpSymbols, symbols);
    
    for(int i=0; i<ArraySize(symbols); i++) {
        string symbol = symbols[i];
        
        // Skip if max signals reached
        if(InpMaxSignalsPerDay > 0 && g_signalsToday >= InpMaxSignalsPerDay)
            continue;
        
        // Check if new bar formed
        if(!IsNewBar(symbol, InpSignalTF))
            continue;
        
        // Calculate score
        int categoryScores[6];
        CSetupScorer scorer;
        int totalScore = scorer.CalculateTotalScore(symbol, categoryScores);
        
        // Determine signal type
        int signalType = DetermineSignalType(symbol);
        if(signalType == 0) continue; // No valid signal
        
        // Calculate entry/SL/TP
        double entry = GetCurrentPrice(symbol, signalType);
        double sl = CalculateSL(symbol, signalType, entry);
        double tp1 = CalculateTP1(symbol, signalType, entry);
        double tp2 = CalculateTP2(symbol, signalType, entry);
        
        // Analyze setup quality
        CSetupAnalyzer analyzer;
        
        if(analyzer.IsPerfectSetup(totalScore)) {
            // PERFECT SETUP FOUND!
            string strengths = scorer.GetStrengthsAndWeaknesses(categoryScores);
            
            // Visual
            if(InpShowArrows) visual.DrawArrow(symbol, time, entry, totalScore, signalType);
            if(InpShowLabels) visual.DrawDetailedLabel(symbol, time, entry, totalScore, 
                                                       categoryScores, signalType, 
                                                       entry, sl, tp1, tp2);
            if(InpShowDashboard) visual.UpdateMainDashboard(symbol, totalScore, 
                                                           categoryScores, signalType);
            if(InpShowBreakdownPanel) visual.UpdateBreakdownPanel(symbol, categoryScores);
            visual.FlashDashboard(InpBuyColor, 5000);
            
            // Alerts
            if(InpAlert_Perfect) {
                alerts.SendPerfectSetupAlert(symbol, totalScore, signalType, 
                                            entry, sl, tp1, tp2, strengths, "");
            }
            
            // Journal
            if(InpEnableJournal) {
                journal.LogPerfectSignal(symbol, time, totalScore, categoryScores,
                                        signalType, entry, sl, tp1, tp2, 
                                        strengths, "");
                if(InpTakeScreenshots) journal.TakeScreenshot(symbol, time);
            }
            
            g_signalsToday++;
        }
        else if(InpShowGoodSetups && analyzer.IsGoodSetup(totalScore)) {
            // Good setup
            if(InpShowArrows) visual.DrawArrow(symbol, time, entry, totalScore, signalType);
            if(InpAlert_Good) alerts.SendGoodSetupAlert(symbol, totalScore, signalType);
            if(InpEnableJournal) journal.LogRejectedSignal(symbol, time, totalScore, 
                                                          categoryScores, "GOOD but below threshold");
        }
        else if(InpShowWeakSetups && analyzer.IsWeakSetup(totalScore)) {
            // Weak setup
            if(InpShowArrows) visual.DrawArrow(symbol, time, entry, totalScore, signalType);
            if(InpEnableJournal) journal.LogRejectedSignal(symbol, time, totalScore,
                                                          categoryScores, "WEAK setup");
        }
        else {
            // Invalid - rejected
            if(InpLogRejectedSetups && InpEnableJournal) {
                string reason = analyzer.GetRejectionReason(symbol, totalScore, categoryScores);
                journal.LogRejectedSignal(symbol, time, totalScore, categoryScores, reason);
            }
        }
    }
}

// 4. HELPER FUNCTIONS

bool IsNewBar(string symbol, ENUM_TIMEFRAMES tf) {
    static datetime lastBarTime[];
    // Implementation
}

int DetermineSignalType(string symbol) {
    // Check all BUY conditions
    // Check all SELL conditions
    // Return: 1=BUY, -1=SELL, 0=None
}

double GetCurrentPrice(string symbol, int signalType) {
    return signalType == 1 ? SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                            SymbolInfoDouble(symbol, SYMBOL_BID);
}

double CalculateSL(string symbol, int signalType, double entry) {
    double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
    return signalType == 1 ? entry - (InpStopLossPips * pipValue) :
                            entry + (InpStopLossPips * pipValue);
}

double CalculateTP1(string symbol, int signalType, double entry) {
    double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
    return signalType == 1 ? entry + (InpTakeProfit1Pips * pipValue) :
                            entry - (InpTakeProfit1Pips * pipValue);
}

double CalculateTP2(string symbol, int signalType, double entry) {
    double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
    return signalType == 1 ? entry + (InpTakeProfit2Pips * pipValue) :
                            entry - (InpTakeProfit2Pips * pipValue);
}

void CheckNewDay() {
    datetime currentDay = TimeCurrent() - TimeCurrent() % 86400;
    if(currentDay != g_lastDayCheck) {
        g_signalsToday = 0;
        g_lastDayCheck = currentDay;
    }
}

void ParseSymbols(string input, string &output[]) {
    // Parse comma-separated symbols
    // Implementation
}

//+------------------------------------------------------------------+
```

---

## 🧪 TESTING & VALIDATION REQUIREMENTS

Before deployment, the EA MUST pass these tests:

### Functional Tests:
- [ ] EA loads without errors on EUR/USD M5
- [ ] All 6 scoring categories calculate correctly
- [ ] Total score = sum of categories
- [ ] Perfect setup (85+) triggers full alerts
- [ ] Good setup (70-84) behaves per settings
- [ ] Weak setup (50-69) properly filtered
- [ ] Invalid setup (<50) completely ignored
- [ ] Dashboard displays correctly and updates in real-time
- [ ] Score breakdown panel shows accurate details
- [ ] Arrows and labels appear correctly
- [ ] Only one signal per bar
- [ ] Multi-symbol scanning works (test EUR/USD + GBP/USD)
- [ ] H1 trend filter works correctly
- [ ] RSI filter works (test with enabled/disabled)
- [ ] Spread filter rejects high-spread setups
- [ ] Max signals per day limit works
- [ ] Journal logs all events correctly
- [ ] CSV export works
- [ ] Screenshots saved (if enabled)
- [ ] All alerts (popup, sound, push, email) work

### Score Accuracy Tests:
Create test scenarios:
- [ ] Perfect trend (H1 50+ pips, aligned) = 25/25 points
- [ ] Moderate trend (H1 30 pips) = ~18/25 points
- [ ] Perfect EMAs (wide separation) = 20/20 points
- [ ] Tight EMAs (8 pips) = ~8/20 points
- [ ] Clean crossover = 10/10 points
- [ ] Weak crossover = 6/10 points
- [ ] Strong candle (80% body) = 8/8 points
- [ ] Weak candle (40% body) = 2/8 points
- [ ] RSI >60 (BUY) = 7/7 points
- [ ] RSI 55 (BUY) = 4/7 points
- [ ] Spread 1.0 pips = 5/5 points
- [ ] Spread 2.0 pips = 3/5 points
- [ ] London-NY session = 5/5 points
- [ ] Asian session = 0/5 points

### Edge Cases:
- [ ] Handle market closed
- [ ] Handle symbol not available
- [ ] Handle no indicator data
- [ ] Handle rapid EMA crosses (choppy)
- [ ] Handle EA restart mid-day (counters preserved?)
- [ ] Handle multiple perfect setups same time

### Performance:
- [ ] CPU usage < 5% with 2 symbols scanning
- [ ] Memory usage stable (no leaks)
- [ ] Dashboard updates smoothly without lag
- [ ] Object creation/deletion efficient

---

## 📚 CODE QUALITY REQUIREMENTS

The code MUST have:

1. **Comprehensive Comments:**
   - Every function explained
   - Complex logic documented
   - Formula explanations

2. **Error Handling:**
   - All API calls wrapped in error checks
   - Graceful degradation if indicator fails
   - User-friendly error messages

3. **Modular Design:**
   - Each class has single responsibility
   - Functions are small and focused
   - Easy to modify/extend

4. **Naming Conventions:**
   - Classes: CCapitalCase
   - Functions: CapitalCase()
   - Variables: g_ for global, m_ for member
   - Input params: Inp prefix

5. **Performance:**
   - Efficient buffer copying
   - Minimal object creation
   - Smart caching where possible

---

## 📖 DOCUMENTATION TO INCLUDE

Create these documents in code comments:

### 1. Installation Guide:
```
How to:
- Copy EA to Experts folder
- Compile in MetaEditor
- Attach to chart
- Configure basic settings
```

### 2. User Manual:
```
- Understanding the score system
- Reading the dashboard
- Interpreting signals
- Using the journal
- Customizing settings
```

### 3. Settings Guide:
```
- Recommended defaults
- When to adjust thresholds
- Optimizing for your style
- Advanced: tweaking weights
```

### 4. FAQ:
```
- Why only 85+ scores?
- Can I trade 84 point setups?
- How to increase signals?
- What if I miss a perfect setup?
- How to review journal?
```

### 5. Risk Disclaimer:
```
- No EA guarantees profit
- Past performance ≠ future results
- Always use proper risk management
- Demo test minimum 3 months
- Trading involves risk of loss
```

---

## 🎯 SUCCESS CRITERIA

The EA is considered successful if it:

✅ Identifies 2-5 PERFECT (85+) setups per trading day  
✅ Shows clear score breakdown for each setup  
✅ User understands WHY each setup is perfect/weak  
✅ Journal provides actionable insights  
✅ User feels CONFIDENT with perfect setups  
✅ User easily avoids weak setups (no FOMO)  
✅ Operates smoothly without crashes/lag  
✅ Code is clean, documented, maintainable  

---

## 💡 FINAL NOTES FOR DEVELOPER

**Philosophy:**
This is NOT a regular EA. It's an **educational tool** that teaches perfect setup recognition while providing high-quality signals.

**Priorities:**
1. Score accuracy (most important)
2. Visual clarity (user must understand everything)
3. Journal insights (learning tool)
4. Performance (smooth operation)
5. Features (don't add unnecessary complexity)

**Key Principles:**
- Conservative by design (better miss opportunity than give bad signal)
- Transparency (user sees all calculations)
- Educational (explains why/why not)
- Disciplined (only perfect setups matter)

**What Makes This Special:**
- Not just signals, but scored quality assessment
- Built-in journal for improvement tracking
- Dashboard shows real-time analysis
- Teaches user to recognize patterns
- Prevents emotional/FOMO trading

---

## 🚀 DELIVERABLES

Please provide:

1. **EMA_Perfect_Setup_EA.mq5** - Complete source code
2. **Installation_Guide.txt** - Step by step setup
3. **User_Manual.pdf** - How to use effectively
4. **Settings_Guide.txt** - Recommended configurations
5. **Default_Settings.set** - Optimized default parameters
6. **Test_Report.txt** - Confirmation all tests passed
7. **FAQ.txt** - Common questions answered

---

## ❗ CRITICAL REMINDERS

1. This EA does NOT auto-trade - user manually enters
2. Score 85+ does NOT guarantee win - it means optimal conditions
3. User must still use judgment and risk management
4. EA is tool for assistance, not replacement for thinking
5. Focus on QUALITY of signals over QUANTITY
6. Better to show 2 perfect setups than 20 mediocre ones

---

**END OF COMPLETE SPECIFICATION**

When you generate this EA, prioritize:
- Scoring accuracy
- Visual clarity
- User education
- Code quality
- Reliable operation

Create a tool that helps traders become BETTER traders, not just signal followers.

Good luck! 🚀