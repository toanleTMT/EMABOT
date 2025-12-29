# Quick Reference Guide - EMA Perfect Setup Scanner EA

## Quick Start Checklist

- [ ] Copy EA folder to MT5 Experts directory
- [ ] Compile EA in MetaEditor (F7)
- [ ] Attach to chart (M5 recommended)
- [ ] Configure symbols to scan
- [ ] Enable AutoTrading (Ctrl+E)
- [ ] Verify dashboard appears
- [ ] Wait for perfect setup (85+ score)

## Key Settings

### Essential Settings
```
Symbols: "EURUSD,GBPUSD"
Min Score Alert: 85
Signal TF: M5
Trend TF: H1
```

### Risk Management
```
Stop Loss: 25 pips
TP1: 25 pips (50% close)
TP2: 50 pips (50% close)
Risk: 1.0% per trade
```

### Visual Settings
```
Show Dashboard: ✓
Show Arrows: ✓
Show Labels: ✓
```

## Scoring System Quick Reference

| Score Range | Quality | Action |
|------------|---------|--------|
| 85-100 | 🟢 PERFECT | Alert & Trade |
| 70-84 | 🟡 GOOD | Optional |
| 50-69 | ⚪ WEAK | Skip |
| <50 | 🔴 INVALID | Ignore |

## Category Weights

| Category | Max Points | Weight |
|----------|------------|--------|
| Trend Alignment | 25 | High |
| EMA Quality | 20 | High |
| Signal Strength | 20 | High |
| Confirmation | 15 | Medium |
| Market Conditions | 10 | Low |
| Context & Timing | 10 | Low |

## Signal Requirements (BUY)

✓ H1: Price > EMA 50  
✓ H1: EMAs aligned (9>21>50)  
✓ M5: EMAs aligned (9>21>50)  
✓ M5: EMA 9 crosses above EMA 21  
✓ M5: Candle closes above EMA 9  
✓ M5: Price & EMAs above EMA 50  
✓ M5: RSI > 50  
✓ M5: EMAs separated  
✓ Spread < MaxSpread  

## Dashboard Elements

**Top-Right Dashboard:**
- Current status
- Setup score
- Category breakdown
- Daily statistics

**Chart Elements:**
- Arrows (color-coded by quality)
- Labels (entry/SL/TP info)
- Score breakdown panel (optional)

## Alert Types

**Perfect Setup (85+):**
- ✅ Popup window
- ✅ Sound alert
- ✅ Push notification (optional)
- ✅ Email (optional)
- ✅ Dashboard flash

**Good Setup (70-84):**
- Optional (if enabled)

**Weak Setup (50-69):**
- None (filtered out)

## Journal Features

**Auto-Logging:**
- All perfect setups
- Rejected setups (if enabled)
- Score breakdown
- Strengths/weaknesses

**Export Options:**
- Text files (daily)
- CSV files (for Excel)
- Screenshots (optional)

## Common Issues

**No Signals:**
- Check symbols are correct
- Verify market is open
- Check spread values
- Perfect setups are rare (by design)

**Dashboard Not Showing:**
- Enable in EA inputs
- Check chart has space
- Try reattaching EA

**Alerts Not Working:**
- Check alert settings
- Verify sound files exist
- Check MT5 notification settings

## File Locations

**Journal Files:**
```
MT5 Data Folder > Common > Files > EMA_Journal
```

**CSV Exports:**
```
EMA_Journal > EMA_Journal_YYYY.MM.DD.csv
```

**Screenshots:**
```
EMA_Journal > EMA_Setup_Symbol_Date_Time.png
```

## Keyboard Shortcuts

- **F4**: Open MetaEditor
- **F7**: Compile EA
- **Ctrl+E**: Toggle AutoTrading
- **F9**: Open Navigator

## Important Reminders

⚠️ **This EA does NOT auto-trade**  
⚠️ **Score 85+ doesn't guarantee win**  
⚠️ **Always use stop loss**  
⚠️ **Test on demo first**  
⚠️ **Use proper risk management**  

## Support Files

- `README.md` - Full documentation
- `INSTALLATION_GUIDE.txt` - Step-by-step setup
- `USAGE_EXAMPLES.md` - Configuration examples
- `CHANGELOG.md` - Version history

---

**Version:** 2.00  
**Last Updated:** 2024

