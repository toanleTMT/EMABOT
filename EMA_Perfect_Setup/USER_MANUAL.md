# EMA Perfect Setup Scanner - User Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Understanding the Score System](#understanding-the-score-system)
3. [Reading the Dashboard](#reading-the-dashboard)
4. [Interpreting Signals](#interpreting-signals)
5. [Using the Journal](#using-the-journal)
6. [Customizing Settings](#customizing-settings)
7. [Best Practices](#best-practices)

---

## Introduction

The **EMA Perfect Setup Scanner** is an educational trading tool designed to help you identify high-quality EMA scalping setups. Unlike traditional Expert Advisors, this EA does **NOT** auto-trade. Instead, it scans markets, scores setups from 0-100 points, and only alerts you when a setup scores **≥85 points (PERFECT quality)**.

### Philosophy: Quality Over Quantity

This EA follows a "Perfect Setup Only" philosophy:
- **PERFECT (85-100 points)**: Only these setups trigger alerts
- **GOOD (70-84 points)**: Visible but no alerts (optional)
- **WEAK (50-69 points)**: Visible but clearly marked as weak
- **INVALID (<50 points)**: Rejected automatically

---

## Understanding the Score System

### The 6 Scoring Categories

Each setup is evaluated across 6 categories:

#### 1. Trend Alignment (25 points max)
- **H1 Price-EMA50 Distance** (15 points): How far price is from EMA50
  - ≥50 pips clear: 15 points
  - 20-50 pips: 10 points
  - <20 pips: 5 points
  - Touching/crossing: 0 points

- **H1 EMA Alignment** (10 points): How well EMAs are ordered
  - Perfect order (9>21>50 for BUY): 10 points
  - Partial alignment: 5 points
  - Tangled: 0 points

#### 2. M5 EMA Quality (20 points max)
- **EMA Alignment** (10 points): M5 EMAs properly ordered
- **EMA Separation** (10 points): EMAs have good spacing
  - Wide (>15 pips): 10 points
  - Moderate (8-15 pips): 6 points
  - Tight (<8 pips): 2 points

#### 3. Signal Strength (20 points max)
- **EMA Crossover Quality** (10 points): Clean crossover with momentum
- **Price Position** (10 points): Price and EMAs on correct side of EMA50

#### 4. Confirmation (15 points max)
- **Candle Strength** (8 points): Strong candle body (>70% = 8 points)
- **RSI Confirmation** (7 points): RSI supports the signal direction

#### 5. Market Conditions (10 points max)
- **Spread** (5 points): Low spread (<1.5 pips = 5 points)
- **Volume** (5 points): High volume on crossover

#### 6. Context & Timing (10 points max)
- **Trading Session** (5 points): London-NY overlap = 5 points
- **Support/Resistance** (5 points): Price at key S/R level

### Score Interpretation

- **85-100 points (PERFECT)**: Optimal conditions, highest probability setup
- **70-84 points (GOOD)**: Good setup but not perfect
- **50-69 points (WEAK)**: Weak setup, avoid trading
- **<50 points (INVALID)**: Rejected automatically

---

## Reading the Dashboard

The dashboard appears in the **top-right corner** of your chart and shows:

### Real-Time Information
- **Current Symbol**: Symbol being analyzed
- **Last Scan Time**: When the last scan occurred
- **Signals Today**: Number of perfect setups found today
- **Quality Rate**: Percentage of perfect setups vs total scans

### Score Breakdown
- **Total Score**: Overall setup quality (0-100)
- **Category Scores**: Individual scores for each of the 6 categories
- **Quality Level**: PERFECT / GOOD / WEAK / INVALID

### Recommendation Section (PERFECT setups only)
- **Entry Price**: Suggested entry point
- **Stop Loss**: Risk management level
- **Take Profit 1 & 2**: Profit targets
- **Risk:Reward**: Calculated R:R ratio
- **Suggested Lot Size**: Based on 1% risk

### Discipline Check (PERFECT setups only)
- **Score**: Current setup score
- **Threshold**: Minimum score (85)
- **Status**: PASS / FAIL
- **Message**: Encouragement or warning

---

## Interpreting Signals

### Visual Signals

#### Arrows
- **Green Up Arrow**: BUY signal (PERFECT setup)
- **Red Down Arrow**: SELL signal (PERFECT setup)
- **Arrow Size**: Larger = higher score
- **Arrow Color**: 
  - Bright green/red = PERFECT (85-100)
  - Medium = GOOD (70-84)
  - Dim = WEAK (50-69)

#### Detailed Labels
Each arrow has a detailed label showing:
- **Entry**: Exact entry price
- **SL**: Stop loss level
- **TP1/TP2**: Take profit targets
- **R:R**: Risk:Reward ratio
- **Score**: Total score (X/100)
- **Breakdown**: Category-by-category scores
- **Strengths**: Why this setup is perfect
- **Weaknesses**: Minor issues (if any)

### Alert Types

#### PERFECT Setups (85+ points)
- **Popup Alert**: Window appears on screen
- **Sound Alert**: Customizable sound file
- **Push Notification**: Sent to mobile device (if enabled)
- **Email Alert**: Sent to your email (if enabled)

#### GOOD Setups (70-84 points)
- **Optional Alerts**: Can be enabled in settings
- **Visual Only**: Always shown on chart

#### WEAK/INVALID Setups
- **No Alerts**: Only logged to journal
- **Visual Only**: Shown but clearly marked

---

## Using the Journal

The journal is your learning tool. It automatically logs:

### Perfect Setup Logs
- **Timestamp**: When the setup occurred
- **Symbol**: Trading pair
- **Signal Type**: BUY or SELL
- **Score**: Total score and breakdown
- **Entry/SL/TP**: Trading levels
- **Strengths/Weaknesses**: Analysis
- **Screenshot**: Chart image saved automatically

### Rejected Setup Logs
- **Reason**: Why setup was rejected
- **Category Scores**: What scored low
- **Learning Value**: Helps you understand what to avoid

### CSV Export
- **Individual Entries**: Exported automatically
- **Range Export**: Can export date ranges
- **Analysis**: Import into Excel for analysis

### Weekly/Monthly Summaries
- **Statistics**: Win rate, average score, etc.
- **Patterns**: Identify what works best
- **Improvement**: Track your progress

---

## Customizing Settings

### Basic Settings

#### Symbols to Scan
```
InpSymbols = "EURUSD,GBPUSD,USDJPY"
```
- Comma-separated list
- Add symbols to Market Watch first
- More symbols = more CPU usage

#### Scan Interval
```
InpScanInterval = 15  // seconds
```
- **Recommended**: 15-30 seconds
- Lower = more frequent scans (more CPU)
- Higher = less frequent scans (may miss setups)

### Scoring Thresholds

#### Minimum H1 Distance
```
InpMinH1Distance = 15  // pips
```
- Minimum distance price must be from EMA50
- Lower = more signals (but lower quality)
- Higher = fewer signals (but higher quality)

#### Minimum EMA Separation
```
InpMinEMASeparation = 5  // pips
```
- Minimum spacing between M5 EMAs
- Lower = more signals
- Higher = cleaner setups only

#### Maximum Spread
```
InpMaxSpread = 2.5  // pips
```
- Maximum acceptable spread
- Higher = more signals (but higher costs)
- Lower = fewer signals (but better execution)

### Alert Settings

#### Enable Alerts
```
InpEnableAlerts = true
InpEnableSound = true
InpEnablePush = false
InpEnableEmail = false
```
- Configure which alert types you want
- Sound file: Place `.wav` file in `Sounds` folder

### Visual Settings

#### Show Dashboard
```
InpShowDashboard = true
```
- Toggle main dashboard display

#### Show Arrows
```
InpShowArrows = true
```
- Toggle arrow signals

#### Show Labels
```
InpShowLabels = true
```
- Toggle detailed labels

#### Show Panel
```
InpShowPanel = false
```
- Toggle score breakdown panel

---

## Best Practices

### 1. Start Conservative
- Use default settings initially
- Only trade PERFECT setups (85+)
- Build confidence before adjusting

### 2. Review Journal Daily
- Check what setups worked
- Learn from rejected setups
- Identify patterns

### 3. Use Risk Management
- Always use stop loss
- Risk only 1-2% per trade
- Follow suggested lot sizes

### 4. Trade During Optimal Sessions
- London-NY overlap is best
- Avoid Asian session
- EA scores this automatically

### 5. Don't Chase Signals
- If you miss a setup, wait for the next
- Quality over quantity
- Better to miss than force a trade

### 6. Combine with Your Analysis
- EA provides signals, you provide judgment
- Consider news events
- Check higher timeframes manually

### 7. Demo Test First
- Test minimum 3 months
- Understand the system
- Build confidence

### 8. Keep Learning
- Review why setups scored high/low
- Understand the scoring logic
- Improve your pattern recognition

---

## Common Questions

### Q: Why only 85+ scores?
**A:** This ensures only the highest quality setups trigger alerts. Lower scores have higher risk and lower probability.

### Q: Can I trade 84 point setups?
**A:** Yes, but manually. The EA won't alert you, but you can see them on the chart. However, we recommend sticking to 85+ for best results.

### Q: How to increase signals?
**A:** 
- Add more symbols
- Lower minimum thresholds (but quality decreases)
- Scan more frequently
- Trade during optimal sessions

### Q: What if I miss a perfect setup?
**A:** Don't chase it. Wait for the next one. Quality setups come regularly if you're patient.

### Q: How to review journal?
**A:** 
- Check `Files/EMA_Perfect_Setup/Journal/` folder
- Open CSV files in Excel
- Review screenshots
- Analyze patterns

---

## Troubleshooting

### No Signals Appearing
- Check if symbols are in Market Watch
- Verify scan interval is reasonable
- Ensure market is open
- Check if thresholds are too strict

### Dashboard Not Showing
- Enable `InpShowDashboard = true`
- Check chart is not minimized
- Verify EA is attached to chart

### Alerts Not Working
- Check alert settings are enabled
- Verify sound file exists (if using sound)
- Check MT5 alert settings
- Test with a known perfect setup

### High CPU Usage
- Reduce number of symbols
- Increase scan interval
- Disable unnecessary visuals
- Close other EAs/indicators

---

## Support

For issues or questions:
1. Check this manual first
2. Review the FAQ
3. Check the journal for clues
4. Review EA logs in Experts tab

---

**Remember**: This EA is a tool to assist your trading, not replace your judgment. Always use proper risk management and trade responsibly.

**Good luck and happy trading!**

