# Usage Examples - EMA Perfect Setup Scanner EA

## Example 1: Basic Setup (Single Symbol)

**Configuration:**
```
Symbols to scan: EURUSD
Signal Timeframe: M5
Trend Timeframe: H1
Minimum score for alert: 85
Show dashboard: true
Show arrows: true
Show labels: true
```

**What to Expect:**
- EA scans EUR/USD every 15 seconds
- Dashboard appears in top-right corner
- When perfect setup (85+) found:
  - Large green/red arrow on chart
  - Detailed label with entry/SL/TP
  - Popup alert
  - Sound alert
  - Journal entry created

## Example 2: Multi-Symbol Scanning

**Configuration:**
```
Symbols to scan: EURUSD,GBPUSD,USDJPY,AUDUSD
Signal Timeframe: M5
Trend Timeframe: H1
Minimum score for alert: 85
Max signals per day: 10
```

**What to Expect:**
- EA monitors 4 currency pairs simultaneously
- Each symbol scanned independently
- Maximum 10 perfect setups per day across all symbols
- Dashboard shows current symbol being analyzed
- Journal tracks all symbols separately

## Example 3: Conservative Trading (Higher Threshold)

**Configuration:**
```
Minimum score for alert: 90
Min H1 distance: 30 pips
Min EMA separation: 10 pips
Max spread: 2.0 pips
```

**What to Expect:**
- Only highest quality setups (90+) trigger alerts
- Fewer signals but higher quality
- Better win rate potential
- More selective approach

## Example 4: Learning Mode (Show All Setups)

**Configuration:**
```
Minimum score for alert: 85
Show GOOD setups: true
Show WEAK setups: true
Log rejected setups: true
Show breakdown panel: true
```

**What to Expect:**
- See all setups (Perfect, Good, Weak)
- Learn why setups score high/low
- Compare different quality levels
- Educational value for pattern recognition

## Example 5: Aggressive Risk Management

**Configuration:**
```
Stop Loss: 20 pips
Take Profit 1: 40 pips
Take Profit 2: 80 pips
Risk per trade: 2.0%
Auto lot size: true
```

**What to Expect:**
- Larger position sizes
- Wider TP targets
- Higher risk/reward ratio (1:2.0)
- More aggressive approach

## Example 6: Conservative Risk Management

**Configuration:**
```
Stop Loss: 15 pips
Take Profit 1: 20 pips
Take Profit 2: 30 pips
Risk per trade: 0.5%
Auto lot size: true
```

**What to Expect:**
- Smaller position sizes
- Tighter TP targets
- Lower risk per trade
- More conservative approach

## Example 7: Full Alert System

**Configuration:**
```
Alert on PERFECT: true
Popup for perfect: true
Sound for perfect: true
Push notification: true
Email: true
```

**What to Expect:**
- Multiple alert types for perfect setups
- Never miss a perfect setup
- Mobile notifications if MT5 mobile app configured
- Email alerts for review later

## Example 8: Journal-Only Mode

**Configuration:**
```
Show arrows: false
Show labels: false
Show dashboard: false
Enable journal: true
Export CSV: true
Take screenshots: true
```

**What to Expect:**
- Silent operation (no visual clutter)
- All setups logged to journal
- CSV files for analysis
- Screenshots for review
- Clean chart for manual analysis

## Example 9: Custom EMA Periods

**Configuration:**
```
Fast EMA Period: 8
Medium EMA Period: 21
Slow EMA Period: 55
```

**What to Expect:**
- Faster response with EMA 8
- Different sensitivity
- May generate more/fewer signals
- Test to find optimal periods

## Example 10: RSI Filter Disabled

**Configuration:**
```
Use RSI filter: false
```

**What to Expect:**
- Signals based purely on EMA structure
- No RSI confirmation required
- More signals potentially
- May have lower quality without RSI filter

## Common Scenarios

### Scenario A: No Signals Appearing
**Possible Causes:**
- Market conditions not meeting criteria
- Spread too high
- EMAs not aligned properly
- Wrong trading session

**Solution:**
- Check dashboard for "Scanning..." status
- Verify symbols are correct
- Check spread values
- Wait for better market conditions

### Scenario B: Too Many Signals
**Solution:**
- Increase minimum score threshold (e.g., 90)
- Increase H1 distance requirement
- Increase EMA separation requirement
- Reduce max signals per day

### Scenario C: Signals Appear But Don't Work
**Remember:**
- Perfect setup (85+) doesn't guarantee win
- Still need proper risk management
- Market can change after signal
- Use stop loss always
- Review journal to learn patterns

## Best Practices

1. **Start Conservative**
   - Use default settings first
   - Test on demo account
   - Learn the scoring system

2. **Review Journal Regularly**
   - Analyze which setups win/lose
   - Identify patterns
   - Adjust settings based on results

3. **Don't Trade Every Signal**
   - Use EA as tool, not replacement for judgment
   - Consider market context
   - Check news events
   - Verify with your own analysis

4. **Monitor Dashboard**
   - Watch score breakdown
   - Understand why setup is perfect
   - Check category scores

5. **Risk Management**
   - Always use stop loss
   - Never risk more than 1-2% per trade
   - Use position sizing
   - Follow your trading plan

---

**Remember:** This EA is an educational tool to help identify high-quality setups. Success requires discipline, proper risk management, and continuous learning.

