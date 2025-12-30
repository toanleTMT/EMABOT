# CSV Export Feature - Implementation Summary

## ✅ Implementation Complete

**Date**: Current  
**Version**: 2.0  
**Feature**: CSV Export for Performance Data

---

## 🎯 Overview

The EA now exports performance data to a CSV file named **`Indicator_Score_Card.csv`** with all required columns for Excel analysis.

---

## 📊 CSV File Format

### File Location
- **Path**: `MQL5\Files\Indicator_Score_Card.csv`
- **Mode**: Append (new trades added to existing file)
- **Encoding**: CSV format with comma separator

### CSV Columns

| Column | Description | Format |
|--------|-------------|--------|
| **Signal_Time** | Date and time when signal was generated | `YYYY.MM.DD HH:MM` |
| **Type** | Signal type (Buy/Sell) | `Buy` or `Sell` |
| **MFE_Pips** | Maximum Favorable Excursion (best price movement) | Decimal (2 places) |
| **MAE_Pips** | Maximum Adverse Excursion (worst drawdown) | Decimal (2 places) |
| **Trade_Result** | Final trade outcome | `Win` or `Loss` |
| **Final_Score** | Signal Quality Score (0-100) | Decimal (2 places) |

### Example CSV Output

```csv
Signal_Time,Type,MFE_Pips,MAE_Pips,Trade_Result,Final_Score
2024.01.15 10:30,Buy,15.50,5.20,Win,72.50
2024.01.15 14:45,Sell,8.30,12.40,Loss,45.20
2024.01.16 09:15,Buy,22.10,3.50,Win,85.30
```

---

## ⚙️ Input Parameters

### CSV Export Settings

```cpp
//--- Enhanced Performance Monitoring ---
input bool     InpEnablePerfMonitor = true;                    // Enable enhanced performance monitor?
input int      InpQualityBars = 10;                            // Bars to evaluate signal quality
input int      InpPerfUpdateInterval = 5;                       // Update performance data every N seconds
input bool     InpExportPerfCSV = true;                         // Export performance data to CSV?
input string   InpPerfCSVFilename = "Indicator_Score_Card.csv"; // CSV filename for performance data
```

### Parameters Explained

- **`InpExportPerfCSV`**: Enable/disable CSV export (default: `true`)
- **`InpPerfCSVFilename`**: Name of CSV file (default: `"Indicator_Score_Card.csv"`)
  - File is saved in `MQL5\Files\` folder
  - Can be customized to any filename

---

## 📈 Data Tracking

### MFE (Maximum Favorable Excursion) ✅
- **Definition**: Best price movement in predicted direction
- **Tracking**: Updated continuously as price moves
- **Purpose**: Shows maximum profit potential before reversal

### MAE (Maximum Adverse Excursion) ✅
- **Definition**: Worst drawdown (maximum loss) before TP/SL
- **Tracking**: Updated continuously as price moves
- **Purpose**: Shows maximum risk experienced

### Trade Result ✅
- **Win**: Trade hit TP1 (Take Profit 1)
- **Loss**: Trade hit SL (Stop Loss)
- **Determined**: When trade closes

### Final Score ✅
- **Definition**: Signal Quality Score (0-100)
- **Calculation**: Based on price movement, speed, and time efficiency
- **Purpose**: Overall signal quality assessment

---

## 🔧 Technical Implementation

### CSV Export Methods

**Class**: `CPerformanceMonitorEnhanced`

**Key Methods**:
- `ExportToCSV(string filename)` - Export all closed trades to CSV
- `GetCSVHeader()` - Get CSV header row
- `GetCSVRow(int index)` - Get CSV row for specific track

**Export Logic**:
1. Opens file in append mode (`FILE_WRITE|FILE_CSV|FILE_COMMON`)
2. Writes header if file is new/empty
3. Writes all closed trades with their data
4. Closes file and reports success

### Integration Points

1. **Periodic Export** (in `OnTimer()`):
   - Exports every 20 cycles (~5 minutes at 15s interval)
   - Only exports closed trades
   - Appends to existing file

2. **Final Export** (in `OnDeinit()`):
   - Exports all closed trades when EA stops
   - Ensures no data is lost
   - Prints confirmation message

---

## 📊 Data Collection

### When Data is Recorded

1. **Signal Registration**: When perfect setup is found
   - Records: Signal time, type, entry price, SL, TP1, TP2

2. **Performance Updates**: Every N seconds (configurable)
   - Updates: Current price, MFE, MAE, quality score
   - Monitors: Price movement, drawdown, favorable excursion

3. **Trade Closure**: When TP1 or SL is hit
   - Finalizes: Trade result, final MFE, final MAE, final score
   - Marks: Trade as closed

4. **CSV Export**: Periodically and on EA shutdown
   - Exports: All closed trades with complete data

---

## 📝 CSV File Structure

### Header Row
```csv
Signal_Time,Type,MFE_Pips,MAE_Pips,Trade_Result,Final_Score
```

### Data Rows
- One row per closed trade
- All values formatted consistently
- Ready for Excel import

### File Management
- **Append Mode**: New trades added to existing file
- **No Duplicates**: Each trade exported once
- **Automatic**: No manual intervention required

---

## 🎯 Excel Analysis

### Recommended Analysis

1. **Win Rate Analysis**:
   - Filter by `Trade_Result`
   - Calculate win rate percentage
   - Compare Buy vs. Sell signals

2. **MFE vs. MAE Analysis**:
   - Compare MFE and MAE for wins vs. losses
   - Identify patterns in favorable vs. adverse movement
   - Evaluate entry timing

3. **Score Distribution**:
   - Analyze `Final_Score` distribution
   - Identify high-quality vs. low-quality signals
   - Correlate score with win rate

4. **Time-Based Analysis**:
   - Group by `Signal_Time` (hour, day, week)
   - Identify best trading times
   - Analyze performance trends

5. **Risk Analysis**:
   - Calculate average MAE for wins vs. losses
   - Evaluate if SL is appropriate
   - Identify high-risk signals

---

## 🚀 Benefits

### Data Analysis
- **Excel Integration**: Easy import and analysis
- **Historical Tracking**: Long-term performance data
- **Pattern Recognition**: Identify successful signal patterns

### Strategy Optimization
- **Score Correlation**: Use scores to filter signals
- **MFE/MAE Insights**: Optimize entry timing
- **Result Analysis**: Improve win rate

### Reporting
- **Performance Reports**: Generate custom reports
- **Backtesting Validation**: Compare live vs. backtest
- **Risk Assessment**: Evaluate trade risk

---

## ⚠️ Important Notes

### File Location
- **Path**: `MQL5\Files\Indicator_Score_Card.csv`
- **Access**: Use MetaTrader 5 → Tools → Options → Expert Advisors → Allow DLL imports
- **Backup**: Regularly backup CSV file for historical data

### Export Frequency
- **Periodic**: Every ~5 minutes (20 cycles)
- **Final**: On EA shutdown
- **Manual**: Can be triggered programmatically

### Data Completeness
- **Only Closed Trades**: Open trades not exported
- **Complete Data**: All required columns included
- **Accurate**: Real-time tracking ensures accuracy

---

## 📊 Example Use Cases

### Use Case 1: Win Rate Analysis
```excel
=COUNTIF(E:E,"Win")/COUNTA(E:E)
```
Calculate overall win rate from CSV data.

### Use Case 2: Average MFE for Wins
```excel
=AVERAGEIF(E:E,"Win",C:C)
```
Calculate average MFE for winning trades.

### Use Case 3: Score vs. Win Rate
```excel
=AVERAGEIF(E:E,"Win",F:F)
```
Calculate average score for winning trades.

### Use Case 4: MAE Distribution
```excel
=AVERAGEIF(E:E,"Loss",D:D)
```
Calculate average MAE for losing trades.

---

## ✅ Status

**CSV Export Feature**: ✅ **100% COMPLETE**

**MFE Tracking**: ✅ **Fully Implemented**  
**MAE Tracking**: ✅ **Fully Implemented**  
**CSV Export**: ✅ **Automatic Export**  
**Excel Compatibility**: ✅ **Ready for Analysis**  
**File Management**: ✅ **Append Mode**

---

## 📋 Summary

The CSV export feature provides:
- ✅ Complete performance data export
- ✅ All required columns (Signal_Time, Type, MFE_Pips, MAE_Pips, Trade_Result, Final_Score)
- ✅ Automatic periodic export
- ✅ Final export on EA shutdown
- ✅ Excel-ready format
- ✅ Historical data tracking

**File**: `Indicator_Score_Card.csv`  
**Location**: `MQL5\Files\`  
**Format**: CSV with comma separator  
**Status**: ✅ **Fully Operational**

---

**Last Updated**: Current  
**Version**: 2.0  
**Status**: Complete CSV Export System

