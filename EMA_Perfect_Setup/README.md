# EMA Perfect Setup Scanner EA v2.0

## Overview

This MetaTrader 5 Expert Advisor scans markets for EMA scalping setups and scores them on a 0-100 point scale. It ONLY alerts when setup scores ≥85 points (PERFECT quality), helping traders focus on the highest-quality trading opportunities.

**Key Philosophy:** Quality over Quantity - Only Perfect Setups

## Features

- ✅ **6-Category Scoring System** - Comprehensive evaluation across trend, EMA quality, signal strength, confirmation, market conditions, and context
- ✅ **Visual Dashboard** - Real-time display of setup scores and statistics
- ✅ **Detailed Labels** - Shows entry, SL, TP, R:R ratio, and score breakdown on chart
- ✅ **Complete Alert System** - Popup, sound, push notifications, and email alerts
- ✅ **Trading Journal** - Automatic logging with CSV export capability
- ✅ **Multi-Symbol Scanning** - Monitor multiple pairs simultaneously
- ✅ **No Auto-Trading** - Trader manually decides to enter (educational tool)

## File Structure

```
EMA_Perfect_Setup/
├── EMA_Perfect_Setup.mq5 (main EA file)
│
├── Include/
│   ├── Config.mqh (configuration constants)
│   ├── Structs.mqh (data structures)
│   │
│   ├── Indicators/
│   │   ├── EMA_Manager.mqh (EMA indicator management)
│   │   └── RSI_Manager.mqh (RSI indicator management)
│   │
│   ├── Scoring/
│   │   ├── Setup_Scorer.mqh (main scoring orchestrator)
│   │   ├── Trend_Scorer.mqh (Category 1: Trend Alignment)
│   │   ├── EMA_Quality_Scorer.mqh (Category 2: EMA Quality)
│   │   ├── Signal_Scorer.mqh (Category 3: Signal Strength)
│   │   ├── Confirmation_Scorer.mqh (Category 4: Confirmation)
│   │   ├── Market_Scorer.mqh (Category 5: Market Conditions)
│   │   └── Context_Scorer.mqh (Category 6: Context & Timing)
│   │
│   ├── Visuals/
│   │   ├── Dashboard.mqh (main dashboard display)
│   │   ├── Arrow_Manager.mqh (arrow signals)
│   │   ├── Label_Manager.mqh (detailed labels)
│   │   └── Panel_Manager.mqh (score breakdown panel)
│   │
│   ├── Alerts/
│   │   ├── Alert_Manager.mqh (alert management)
│   │   └── Popup_Builder.mqh (popup windows)
│   │
│   ├── Journal/
│   │   ├── Journal_Manager.mqh (journal logging)
│   │   ├── CSV_Exporter.mqh (CSV export)
│   │   └── Stats_Calculator.mqh (statistics calculation)
│   │
│   └── Utilities/
│       ├── Time_Utils.mqh (time utilities)
│       ├── Price_Utils.mqh (price calculations)
│       ├── String_Utils.mqh (string formatting)
│       └── Error_Handler.mqh (error handling)
```

## Installation

1. Copy the entire `EMA_Perfect_Setup` folder to your MetaTrader 5 `MQL5/Experts` directory
2. Open MetaEditor and compile `EMA_Perfect_Setup.mq5`
3. Attach the EA to any chart (recommended: M5 timeframe)
4. Configure settings in the EA inputs
5. Enable AutoTrading

## Scoring System

The EA evaluates each setup across 6 categories:

### Category 1: Trend Alignment (25 points max)
- H1 Price-EMA50 Distance: 0-15 points
- H1 EMA Alignment: 0-10 points

### Category 2: EMA Quality (20 points max)
- EMA Alignment: 0-10 points
- EMA Separation: 0-10 points

### Category 3: Signal Strength (20 points max)
- EMA Crossover Quality: 0-10 points
- Price Position: 0-10 points

### Category 4: Confirmation (15 points max)
- Candle Strength: 0-8 points
- RSI Confirmation: 0-7 points

### Category 5: Market Conditions (10 points max)
- Spread: 0-5 points
- Volume/Momentum: 0-5 points

### Category 6: Context & Timing (10 points max)
- Trading Session: 0-5 points
- Support/Resistance: 0-5 points

**Total Score:** 0-100 points
- **85-100:** PERFECT (alerts triggered)
- **70-84:** GOOD (optional display)
- **50-69:** WEAK (filtered out)
- **<50:** INVALID (ignored)

## Signal Conditions

### BUY Signal (All must be TRUE):
1. H1: Price > EMA 50
2. H1: EMAs aligned (EMA 9 > EMA 21 > EMA 50)
3. M5: EMAs aligned (EMA 9 > EMA 21 > EMA 50)
4. M5: EMA 9 crosses ABOVE EMA 21
5. M5: Current candle closes ABOVE EMA 9
6. M5: Price, EMA 9, and EMA 21 ALL above EMA 50
7. M5: RSI(14) > 50
8. M5: EMAs have clear separation
9. Spread < MaxSpread setting
10. Only one signal per bar

### SELL Signal (All must be TRUE):
1. H1: Price < EMA 50
2. H1: EMAs aligned (EMA 9 < EMA 21 < EMA 50)
3. M5: EMAs aligned (EMA 9 < EMA 21 < EMA 50)
4. M5: EMA 9 crosses BELOW EMA 21
5. M5: Current candle closes BELOW EMA 9
6. M5: Price, EMA 9, and EMA 21 ALL below EMA 50
7. M5: RSI(14) < 50
8. M5: EMAs have clear separation
9. Spread < MaxSpread setting
10. Only one signal per bar

## Usage

1. **Setup**: Configure symbols to scan (comma-separated, e.g., "EURUSD,GBPUSD")
2. **Monitor**: Watch the dashboard for real-time scoring
3. **Alerts**: Perfect setups (85+) trigger full alerts
4. **Review**: Check journal for detailed analysis of all setups
5. **Trade**: Manually enter trades based on perfect setup signals

## Important Notes

- ⚠️ This EA does NOT auto-trade - you manually enter trades
- ⚠️ Score 85+ does NOT guarantee a win - it means optimal conditions
- ⚠️ Always use proper risk management
- ⚠️ Demo test for at least 3 months before live trading
- ⚠️ Trading involves risk of loss

## Customization

All parameters are configurable through EA inputs:
- EMA periods (default: 9, 21, 50)
- RSI period (default: 14)
- Scoring thresholds
- Visual settings
- Alert preferences
- Journal options

## Support

For issues or questions, refer to the detailed specification document (`ema_setup_ea.md`).

---

**Version:** 2.00  
**Last Updated:** 2024  
**License:** Use at your own risk

