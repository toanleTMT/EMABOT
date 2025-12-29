# EMA Perfect Setup Scanner - Settings Guide

## Table of Contents
1. [Recommended Defaults](#recommended-defaults)
2. [When to Adjust Thresholds](#when-to-adjust-thresholds)
3. [Optimizing for Your Style](#optimizing-for-your-style)
4. [Advanced: Tweaking Weights](#advanced-tweaking-weights)
5. [Settings Reference](#settings-reference)

---

## Recommended Defaults

### Conservative Settings (Recommended for Beginners)
```
Symbols: EURUSD, GBPUSD
Scan Interval: 15 seconds
Min H1 Distance: 15 pips
Min EMA Separation: 5 pips
Min Candle Body: 50%
Max Spread: 2.5 pips
Perfect Threshold: 85
```

**Result**: 2-5 perfect setups per day, highest quality

### Balanced Settings (Recommended for Most Traders)
```
Symbols: EURUSD, GBPUSD, USDJPY, AUDUSD
Scan Interval: 15 seconds
Min H1 Distance: 12 pips
Min EMA Separation: 4 pips
Min Candle Body: 45%
Max Spread: 3.0 pips
Perfect Threshold: 85
```

**Result**: 3-7 perfect setups per day, good balance

### Aggressive Settings (Advanced Traders Only)
```
Symbols: EURUSD, GBPUSD, USDJPY, AUDUSD, NZDUSD, USDCAD
Scan Interval: 10 seconds
Min H1 Distance: 10 pips
Min EMA Separation: 3 pips
Min Candle Body: 40%
Max Spread: 3.5 pips
Perfect Threshold: 80
```

**Result**: 5-10 setups per day, but lower quality

---

## When to Adjust Thresholds

### Adjust Minimum H1 Distance

**Lower (10-12 pips)** when:
- Market is trending strongly
- You want more signals
- You're comfortable with tighter setups

**Raise (18-20 pips)** when:
- Market is choppy/consolidating
- You want only the cleanest setups
- You're new to the system

**Default**: 15 pips (balanced)

### Adjust Minimum EMA Separation

**Lower (3-4 pips)** when:
- Market is trending smoothly
- EMAs are naturally close together
- You want more opportunities

**Raise (6-8 pips)** when:
- Market is volatile
- You want cleaner separations
- You're avoiding choppy markets

**Default**: 5 pips (balanced)

### Adjust Maximum Spread

**Lower (1.5-2.0 pips)** when:
- Trading major pairs (EURUSD, GBPUSD)
- You want best execution
- Cost is important

**Raise (3.0-4.0 pips)** when:
- Trading exotic pairs
- Spreads are naturally wider
- You want more signals

**Default**: 2.5 pips (balanced)

### Adjust Perfect Threshold

**Lower (80-84)** when:
- You're experienced
- You want more signals
- You can filter manually

**Raise (88-90)** when:
- You want only the absolute best
- You're very conservative
- You're learning the system

**Default**: 85 (recommended)

---

## Optimizing for Your Style

### Scalper Style
```
Scan Interval: 10 seconds
Symbols: EURUSD, GBPUSD (major pairs only)
Min H1 Distance: 12 pips
Min EMA Separation: 4 pips
Max Spread: 2.0 pips
Perfect Threshold: 85
```
**Focus**: Quick entries, tight stops, fast profits

### Swing Trader Style
```
Scan Interval: 30 seconds
Symbols: All major pairs
Min H1 Distance: 18 pips
Min EMA Separation: 6 pips
Max Spread: 3.0 pips
Perfect Threshold: 85
```
**Focus**: Larger moves, wider stops, bigger profits

### Conservative Style
```
Scan Interval: 20 seconds
Symbols: EURUSD, GBPUSD only
Min H1 Distance: 20 pips
Min EMA Separation: 7 pips
Max Spread: 2.0 pips
Perfect Threshold: 88
```
**Focus**: Only the absolute best setups, patience

### Aggressive Style
```
Scan Interval: 10 seconds
Symbols: All available pairs
Min H1 Distance: 10 pips
Min EMA Separation: 3 pips
Max Spread: 3.5 pips
Perfect Threshold: 80
```
**Focus**: More opportunities, more risk, more action

---

## Advanced: Tweaking Weights

The scoring system uses 6 categories with different weights:

### Default Weights
```
Trend: 25 points (25%)
EMA Quality: 20 points (20%)
Signal Strength: 20 points (20%)
Confirmation: 15 points (15%)
Market: 10 points (10%)
Context: 10 points (10%)
```

### Adjusting Weights

**Note**: Changing weights requires modifying the EA code. Only do this if you understand the scoring system.

#### Example: Emphasize Trend
```
Trend: 30 points (30%)
EMA Quality: 20 points (20%)
Signal Strength: 18 points (18%)
Confirmation: 15 points (15%)
Market: 10 points (10%)
Context: 7 points (7%)
```
**Effect**: More emphasis on H1 trend alignment

#### Example: Emphasize Confirmation
```
Trend: 22 points (22%)
EMA Quality: 18 points (18%)
Signal Strength: 18 points (18%)
Confirmation: 22 points (22%)
Market: 10 points (10%)
Context: 10 points (10%)
```
**Effect**: More emphasis on RSI and candle confirmation

#### Example: Emphasize Market Conditions
```
Trend: 23 points (23%)
EMA Quality: 18 points (18%)
Signal Strength: 18 points (18%)
Confirmation: 13 points (13%)
Market: 18 points (18%)
Context: 10 points (10%)
```
**Effect**: More emphasis on spread and volume

**Warning**: Changing weights changes the entire scoring system. Test thoroughly before using in live trading.

---

## Settings Reference

### General Settings

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| Symbols | "EURUSD,GBPUSD" | Any | Comma-separated symbol list |
| Signal TF | PERIOD_M5 | M1-MN1 | Timeframe for signals |
| Trend TF | PERIOD_H1 | M1-MN1 | Timeframe for trend |
| Scan Interval | 15 | 5-60 | Seconds between scans |
| Magic Number | 987654 | Any | Unique identifier |

### Scoring Thresholds

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| Min H1 Distance | 15 | 5-30 | Minimum pips from EMA50 |
| Min EMA Separation | 5 | 2-10 | Minimum pips between EMAs |
| Min Candle Body | 50 | 30-80 | Minimum candle body % |
| Max Spread | 2.5 | 1.0-5.0 | Maximum spread in pips |
| Perfect Threshold | 85 | 75-95 | Minimum score for alerts |

### Visual Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| Show Dashboard | true | Display main dashboard |
| Show Arrows | true | Display arrow signals |
| Show Labels | true | Display detailed labels |
| Show Panel | false | Display score breakdown panel |
| Dashboard X | 20 | Dashboard X position |
| Dashboard Y | 30 | Dashboard Y position |

### Alert Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| Enable Alerts | true | Enable popup alerts |
| Enable Sound | true | Enable sound alerts |
| Sound File | "perfect_setup.wav" | Sound file name |
| Enable Push | false | Enable push notifications |
| Enable Email | false | Enable email alerts |
| Email Address | "" | Email for alerts |

### Journal Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| Enable Journal | true | Enable journal logging |
| Log Rejected | true | Log rejected setups |
| Auto Screenshot | true | Auto-capture screenshots |
| CSV Export | true | Auto-export to CSV |

### Risk Management

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| Risk Percent | 1.0 | 0.5-5.0 | Risk per trade (%) |
| Stop Loss Pips | 20 | 10-50 | Default stop loss |
| Take Profit 1 | 40 | 20-100 | First TP target |
| Take Profit 2 | 80 | 40-200 | Second TP target |

---

## Quick Setup Presets

### Preset 1: Ultra Conservative
```
Min H1 Distance: 20
Min EMA Separation: 7
Max Spread: 2.0
Perfect Threshold: 90
```
**Use When**: Learning, testing, very risk-averse

### Preset 2: Standard (Recommended)
```
Min H1 Distance: 15
Min EMA Separation: 5
Max Spread: 2.5
Perfect Threshold: 85
```
**Use When**: Normal trading, balanced approach

### Preset 3: More Signals
```
Min H1 Distance: 12
Min EMA Separation: 4
Max Spread: 3.0
Perfect Threshold: 82
```
**Use When**: Experienced, want more opportunities

### Preset 4: Maximum Quality
```
Min H1 Distance: 18
Min EMA Separation: 6
Max Spread: 2.0
Perfect Threshold: 88
```
**Use When**: Only want the absolute best setups

---

## Testing Your Settings

### Step 1: Demo Test
1. Apply settings to demo account
2. Run for minimum 1 week
3. Track results in journal
4. Analyze performance

### Step 2: Evaluate
- Are you getting enough signals?
- Are signals high quality?
- Are you comfortable with the frequency?
- Do signals match your trading style?

### Step 3: Adjust
- Too few signals? Lower thresholds slightly
- Too many signals? Raise thresholds
- Signals not good enough? Raise perfect threshold
- Signals too conservative? Lower perfect threshold

### Step 4: Repeat
- Continue testing
- Refine settings
- Build confidence
- Only then go live

---

## Common Mistakes

### ❌ Too Aggressive Too Soon
- Starting with low thresholds
- Lowering perfect threshold immediately
- Adding too many symbols

### ❌ Not Testing Enough
- Changing settings without testing
- Not tracking results
- Not reviewing journal

### ❌ Ignoring Defaults
- Defaults are tested and balanced
- Don't change without reason
- Understand why defaults exist

### ❌ Chasing More Signals
- More signals ≠ better results
- Quality over quantity
- Patience is key

---

## Final Recommendations

1. **Start with defaults** - They're balanced and tested
2. **Test thoroughly** - Minimum 1 week demo testing
3. **Track results** - Use the journal to analyze
4. **Adjust gradually** - Small changes, test again
5. **Be patient** - Quality setups come regularly
6. **Stick to 85+** - Don't lower perfect threshold easily
7. **Review regularly** - Check what's working

**Remember**: The best settings are the ones that work for YOUR trading style and risk tolerance. There's no "one size fits all" - find what works for you through testing and patience.

