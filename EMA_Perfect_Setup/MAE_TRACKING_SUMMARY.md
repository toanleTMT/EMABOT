# Maximum Adverse Excursion (MAE) Tracking - Implementation Summary

## ✅ Implementation Complete

**Date**: Current  
**Version**: 2.0  
**Feature**: MAE (Maximum Adverse Excursion) Tracking System

---

## 🎯 Overview

The EA now includes **MAE (Maximum Adverse Excursion) Tracking** that measures the maximum drawdown (paper loss) each signal experiences before it either hits Take Profit or Stop Loss. This helps evaluate if entry signals are too early and provides insights into trade entry timing.

---

## 🔍 MAE Explained

### What is MAE?

**Maximum Adverse Excursion (MAE)** is the maximum unfavorable price movement (drawdown) that a trade experiences from entry until it closes (hits TP or SL).

### Why Track MAE?

- **Evaluate Entry Timing**: High MAE indicates signals may be too early
- **Optimize Entries**: Use MAE data to improve entry timing
- **Risk Assessment**: Understand maximum drawdown before TP/SL
- **Strategy Improvement**: Identify if entries need adjustment

### MAE Calculation

```
MAE = Maximum drawdown (in pips) from entry price
     = Worst price movement against the trade
```

**Example**:
- BUY signal at 1.1000
- Price drops to 1.0985 (15 pips down) before recovering
- Price then rises to 1.1010 (TP hit)
- **MAE = 15 pips** (maximum drawdown)

---

## ⚙️ Input Parameters

### MAE Tracking Settings

```cpp
//--- Maximum Adverse Excursion (MAE) Tracking ---
input bool     InpEnableMAETracking = true;                   // Enable MAE tracking?
input int      InpMAEUpdateInterval = 5;                       // Update MAE every N seconds
```

### Parameters Explained

- **`InpEnableMAETracking`**: Enable/disable MAE tracking (default: `true`)
- **`InpMAEUpdateInterval`**: Update MAE every N seconds (default: `5`)
  - Lower = more frequent updates (more accurate, more CPU)
  - Higher = less frequent updates (less CPU, may miss some movements)
  - Recommended: 5-10 seconds

---

## 📊 Integration

### Signal Registration

**Automatic Registration**: Signals are automatically registered when perfect setup is found:
- Location: `ProcessSignalOnBarClose()` - When perfect setup is detected
- Records: Symbol, signal type, entry time, entry price, SL, TP1, TP2, timeframe

### MAE Updates

**Automatic Updates**: MAE is updated periodically:
- Location: `OnTimer()` - Every N seconds (configurable)
- Monitors: Current price vs. entry price
- Tracks: Maximum adverse movement (worst drawdown)
- Detects: When TP or SL is hit

### MAE Reporting

**Automatic Reporting**: MAE report printed:
- On EA shutdown (final MAE report)
- Shows average, max, min MAE
- Shows MAE for wins vs. losses
- Provides interpretation and recommendations

---

## 🔧 Technical Implementation

### MAE Tracker Class (`MAE_Tracker.mqh`)

**New Class**: `CMAETracker`

**Key Methods**:
- `RegisterSignal()` - Register signal for MAE tracking
- `UpdateMAE()` - Update MAE for all active trades
- `GetAverageMAE()` - Get average MAE for all closed trades
- `GetAverageMAE_Wins()` - Get average MAE for winning trades
- `GetAverageMAE_Losses()` - Get average MAE for losing trades
- `PrintMAEReport()` - Print formatted MAE report

**Data Structure**:
```cpp
struct MAETrack
{
   datetime signalTime;
   string symbol;
   ENUM_SIGNAL_TYPE signalType;
   double entryPrice;
   double stopLoss;
   double takeProfit1;
   double takeProfit2;
   ENUM_TIMEFRAMES timeframe;
   bool isActive;
   bool isClosed;
   double maxAdverseExcursion;  // Maximum drawdown in pips
   double maxFavorableExcursion;
   double currentPrice;
   double closePrice;
   bool closedAtTP;
   bool closedAtSL;
   int barsElapsed;
};
```

---

## 📈 MAE Report Format

### Example Output

```
╔═══════════════════════════════════════════════════════════════╗
║              MAXIMUM ADVERSE EXCURSION (MAE) REPORT            ║
╠═══════════════════════════════════════════════════════════════╣
║ Total Signals Tracked: 25                                    ║
║ Active Trades: 3                                             ║
║ Closed Trades: 22                                            ║
╠═══════════════════════════════════════════════════════════════╣
║ MAE STATISTICS (Maximum Drawdown Before TP/SL)                ║
╠═══════════════════════════════════════════════════════════════╣
║ Average MAE: 12.50 pips                                      ║
║ Maximum MAE: 28.00 pips                                      ║
║ Minimum MAE: 2.00 pips                                       ║
╠═══════════════════════════════════════════════════════════════╣
║ MAE BY TRADE OUTCOME                                            ║
╠═══════════════════════════════════════════════════════════════╣
║ Average MAE (Wins): 15.20 pips (18 trades)                  ║
║ Average MAE (Losses): 8.50 pips (4 trades)                  ║
╠═══════════════════════════════════════════════════════════════╣
║ INTERPRETATION                                                  ║
╠═══════════════════════════════════════════════════════════════╣
║ ⚠ Moderate MAE (10-20 pips): Consider entry timing optimization║
║ ⚠ Winning trades have higher MAE - may indicate early entries ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🎯 Usage Examples

### Default Settings

```cpp
InpEnableMAETracking = true
InpMAEUpdateInterval = 5
```

**Result**: MAE tracked for all signals, updated every 5 seconds

### More Frequent Updates

```cpp
InpEnableMAETracking = true
InpMAEUpdateInterval = 2
```

**Result**: More accurate MAE tracking (updates every 2 seconds)

### Less Frequent Updates (Save CPU)

```cpp
InpEnableMAETracking = true
InpMAEUpdateInterval = 10
```

**Result**: Less CPU usage (updates every 10 seconds)

---

## 📝 MAE Interpretation

### Low MAE (< 10 pips) ✅
- **Meaning**: Signals have good entry timing
- **Action**: No changes needed
- **Result**: Trades don't experience much drawdown before TP/SL

### Moderate MAE (10-20 pips) ⚠️
- **Meaning**: Signals may be slightly early
- **Action**: Consider entry timing optimization
- **Result**: Some drawdown before recovery

### High MAE (> 20 pips) ⚠️
- **Meaning**: Signals are too early
- **Action**: Review entry logic, consider waiting for confirmation
- **Result**: Significant drawdown before TP/SL

### MAE Comparison: Wins vs. Losses

- **Wins have higher MAE**: May indicate early entries that eventually recover
- **Losses have lower MAE**: May indicate entries closer to SL
- **Similar MAE**: Consistent entry timing

---

## 🚀 Benefits

### Entry Timing Evaluation
- **Identify Early Entries**: High MAE indicates signals too early
- **Optimize Timing**: Use MAE data to improve entry logic
- **Reduce Drawdown**: Lower MAE = better entry timing

### Risk Assessment
- **Maximum Drawdown**: Know worst-case drawdown before TP/SL
- **Risk Management**: Use MAE to set appropriate SL levels
- **Strategy Tuning**: Adjust entries based on MAE patterns

### Performance Analysis
- **Win vs. Loss MAE**: Compare MAE for different outcomes
- **Pattern Recognition**: Identify MAE patterns
- **Strategy Improvement**: Use MAE insights to optimize strategy

---

## ⚠️ Important Notes

### MAE vs. Actual Loss

- **MAE is Paper Loss**: Maximum drawdown experienced (not actual loss)
- **May Recover**: High MAE doesn't mean trade will lose
- **Timing Indicator**: MAE indicates entry timing, not trade outcome

### Update Frequency

- **More Frequent**: More accurate MAE (catches all movements)
- **Less Frequent**: Less CPU usage (may miss some movements)
- **Balance**: 5-10 seconds is good balance

### Active vs. Closed Trades

- **Active Trades**: MAE updates in real-time
- **Closed Trades**: MAE is final (no more updates)
- **Statistics**: Only closed trades included in statistics

---

## 📊 Example Scenarios

### Scenario 1: Low MAE ✅
- **Signal**: BUY at 1.1000
- **Price Movement**: Drops to 1.0995 (5 pips), then rises to 1.1010 (TP)
- **MAE**: 5 pips
- **Interpretation**: Good entry timing

### Scenario 2: High MAE ⚠️
- **Signal**: BUY at 1.1000
- **Price Movement**: Drops to 1.0975 (25 pips), then rises to 1.1010 (TP)
- **MAE**: 25 pips
- **Interpretation**: Signal too early, consider waiting for confirmation

### Scenario 3: MAE Before SL Hit
- **Signal**: BUY at 1.1000
- **Price Movement**: Drops to 1.0985 (15 pips), continues down to 1.0975 (SL)
- **MAE**: 15 pips
- **Interpretation**: Entry timing could be improved

---

## 🎯 Optimization Tips

1. **Monitor Average MAE**: Target < 15 pips for good entry timing
2. **Compare Win/Loss MAE**: If wins have much higher MAE, entries may be early
3. **Review High MAE Trades**: Analyze trades with MAE > 20 pips
4. **Adjust Entry Logic**: Use MAE data to optimize entry conditions
5. **Consider Confirmation**: If MAE is high, wait for additional confirmation

---

## ✅ Status

**MAE Tracking**: ✅ **100% COMPLETE**

**Signal Registration**: ✅ **Automatic**  
**MAE Updates**: ✅ **Periodic (Configurable)**  
**TP/SL Detection**: ✅ **Automatic**  
**MAE Reporting**: ✅ **Formatted Log Output**  
**Statistics**: ✅ **Average, Max, Min, Win/Loss Comparison**

---

**Last Updated**: Current  
**Version**: 2.0  
**Status**: Complete MAE Tracking System

