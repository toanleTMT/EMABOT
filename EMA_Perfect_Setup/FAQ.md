# EMA Perfect Setup Scanner - Frequently Asked Questions (FAQ)

## General Questions

### Q: What is this EA?
**A:** The EMA Perfect Setup Scanner is an educational trading tool that scans markets for high-quality EMA scalping setups, scores them from 0-100 points, and only alerts you when a setup scores ≥85 points (PERFECT quality). It does NOT auto-trade - you manually decide to enter.

### Q: Does this EA trade automatically?
**A:** No. This EA is a **signal scanner only**. It identifies and alerts you to perfect setups, but you must manually enter trades. This gives you full control and helps you learn to recognize quality setups.

### Q: What makes this EA different?
**A:** 
- **Scoring System**: Each setup is scored 0-100 across 6 categories
- **Quality Focus**: Only alerts on PERFECT (85+) setups
- **Educational**: Shows WHY setups are perfect/weak
- **Journal System**: Built-in learning tool
- **Transparency**: See all calculations and reasoning

### Q: Is this EA profitable?
**A:** The EA identifies high-quality setups, but profitability depends on:
- Your execution
- Risk management
- Market conditions
- Your trading skill
- **Past performance ≠ future results**

Always demo test minimum 3 months before going live.

---

## Scoring System Questions

### Q: Why only 85+ scores?
**A:** The 85+ threshold ensures only the highest quality setups trigger alerts. Lower scores have:
- Higher risk
- Lower probability
- More uncertainty
- Less favorable conditions

The philosophy is: **Better to miss an opportunity than take a bad trade.**

### Q: Can I trade 84 point setups?
**A:** Yes, but manually. The EA won't alert you, but you can see them on the chart. However, we **strongly recommend** sticking to 85+ for best results. The threshold exists for a reason.

### Q: What if I want more signals?
**A:** Options:
1. **Add more symbols** - Scan more pairs
2. **Lower thresholds** - But quality decreases
3. **Lower perfect threshold** - But risk increases
4. **Scan more frequently** - But CPU usage increases

**Warning**: More signals ≠ better results. Quality over quantity.

### Q: How accurate is the scoring?
**A:** The scoring system is based on:
- EMA alignment principles
- Price action analysis
- Market condition assessment
- Risk management factors

It's a **probability assessment**, not a guarantee. Higher scores = better conditions, but no setup is 100% guaranteed.

### Q: Can I change the scoring weights?
**A:** Yes, but it requires code modification. Only do this if you:
- Understand the scoring system
- Have tested thoroughly
- Know what you're changing and why

**Recommendation**: Use default weights unless you have a specific reason to change them.

---

## Signal Questions

### Q: How many perfect setups per day?
**A:** Typically 2-5 perfect setups per day per symbol, depending on:
- Market conditions
- Your settings
- Number of symbols scanned
- Trading sessions

**Note**: This is normal. Quality setups are rare - that's why they're valuable.

### Q: What if I miss a perfect setup?
**A:** **Don't chase it.** Wait for the next one. Chasing missed setups leads to:
- FOMO trading
- Poor entries
- Higher risk
- Emotional decisions

Quality setups come regularly if you're patient.

### Q: Can I see GOOD (70-84) setups?
**A:** Yes. They appear on the chart but:
- No alerts (unless enabled)
- Clearly marked as "GOOD"
- You can trade them manually if you want

**Recommendation**: Stick to PERFECT setups, especially when learning.

### Q: Why are some setups rejected?
**A:** Setups are rejected when:
- Score < 50 (INVALID)
- Spread too high
- Trend not aligned
- EMAs tangled
- Poor market conditions

The EA logs rejection reasons in the journal - review them to learn.

### Q: Do signals work in all market conditions?
**A:** No. The EA works best in:
- Trending markets
- London-NY overlap session
- Low spread conditions
- Clear EMA alignments

It may produce fewer signals in:
- Choppy/consolidating markets
- Asian session
- High volatility periods
- News events

---

## Technical Questions

### Q: How much CPU does this use?
**A:** Depends on:
- Number of symbols (more = more CPU)
- Scan interval (faster = more CPU)
- Visual elements enabled

**Typical**: 5-15% CPU for 2-4 symbols at 15-second intervals.

**Optimization tips**:
- Reduce symbols
- Increase scan interval
- Disable unnecessary visuals

### Q: Can I run multiple instances?
**A:** Yes, but:
- Each instance uses CPU
- May cause conflicts
- Not recommended

**Better**: Use one instance with multiple symbols.

### Q: What timeframes does it use?
**A:** 
- **H1**: For trend analysis (EMA50 alignment)
- **M5**: For signal generation (EMA crossovers)
- **M15**: For support/resistance levels

These are optimized for scalping. Don't change unless you understand the system.

### Q: Does it work on all brokers?
**A:** Yes, but:
- Spreads vary (adjust max spread setting)
- Some brokers have different pip values
- Execution quality varies

**Test on your broker's demo first.**

### Q: Can I use it on mobile?
**A:** Yes, if your broker supports:
- MT5 mobile app
- Push notifications (if enabled)
- Remote access to charts

**Note**: Full functionality requires desktop MT5.

---

## Journal Questions

### Q: Where is the journal stored?
**A:** `Files/EMA_Perfect_Setup/Journal/`

Contains:
- Text logs
- CSV exports
- Screenshots
- Statistics

### Q: How do I review the journal?
**A:** 
1. Open `Files` folder in MT5
2. Navigate to `EMA_Perfect_Setup/Journal/`
3. Open CSV files in Excel
4. Review screenshots
5. Analyze patterns

### Q: Can I export journal data?
**A:** Yes:
- **Individual entries**: Auto-exported to CSV
- **Range export**: Use journal manager function
- **Screenshots**: Saved automatically

### Q: How long are logs kept?
**A:** Indefinitely (until you delete them). The EA doesn't auto-delete logs.

**Recommendation**: Archive old logs monthly to save disk space.

---

## Settings Questions

### Q: What are the best settings?
**A:** There's no "best" - it depends on:
- Your trading style
- Risk tolerance
- Experience level
- Market conditions

**Start with defaults**, test, then adjust based on results.

### Q: Should I lower the perfect threshold?
**A:** **Generally no.** The 85 threshold is:
- Tested and balanced
- Based on probability analysis
- Designed for quality over quantity

Only lower if:
- You're very experienced
- You've tested thoroughly
- You understand the risks

### Q: How many symbols should I scan?
**A:** 
- **Beginners**: 2-3 symbols (EURUSD, GBPUSD)
- **Intermediate**: 3-5 symbols
- **Advanced**: 5-8 symbols

**More symbols = more CPU usage.** Start small, add gradually.

### Q: What scan interval is best?
**A:** 
- **Recommended**: 15 seconds
- **Faster (10s)**: More responsive, more CPU
- **Slower (30s)**: Less CPU, may miss some setups

**15 seconds is balanced** - good responsiveness without excessive CPU.

---

## Trading Questions

### Q: Should I use the suggested lot size?
**A:** The suggested lot size is based on 1% risk. **Always**:
- Verify it matches your risk tolerance
- Adjust if needed
- Never risk more than you can afford
- Use proper position sizing

### Q: Should I use the suggested SL/TP?
**A:** The EA suggests levels based on:
- ATR calculations
- Support/resistance
- Risk management principles

**You can adjust** based on:
- Your analysis
- Market conditions
- Your risk tolerance

### Q: Can I trade partial TP?
**A:** Yes. The EA suggests TP1 and TP2:
- **TP1**: First target (smaller, higher probability)
- **TP2**: Second target (larger, lower probability)

You can:
- Close partial at TP1
- Let rest run to TP2
- Adjust based on market

### Q: What if price hits SL?
**A:** That's trading. Even perfect setups can fail because:
- Markets are unpredictable
- Nothing is 100% guaranteed
- Risk management is essential

**Key**: Use proper risk management, and losses are part of trading.

### Q: Should I trade every perfect setup?
**A:** **Not necessarily.** Consider:
- Your analysis
- News events
- Market conditions
- Your confidence level

The EA provides signals - **you provide judgment.**

---

## Troubleshooting

### Q: No signals appearing
**A:** Check:
- Symbols in Market Watch?
- Scan interval reasonable?
- Market open?
- Thresholds too strict?
- EA attached to chart?

### Q: Dashboard not showing
**A:** Check:
- `InpShowDashboard = true`?
- Chart not minimized?
- EA attached to chart?
- Check Experts tab for errors

### Q: Alerts not working
**A:** Check:
- Alert settings enabled?
- Sound file exists (if using sound)?
- MT5 alert settings?
- Test with known perfect setup

### Q: High CPU usage
**A:** Try:
- Reduce symbols
- Increase scan interval
- Disable unnecessary visuals
- Close other EAs/indicators

### Q: EA not scanning
**A:** Check:
- EA attached to chart?
- Timer running?
- No errors in Experts tab?
- Market data available?

---

## Risk Disclaimer

### Q: Is this EA guaranteed to be profitable?
**A:** **No.** No EA guarantees profit. Trading involves risk of loss. Past performance does not equal future results.

### Q: Should I risk real money?
**A:** Only after:
- Minimum 3 months demo testing
- Understanding the system
- Building confidence
- Proper risk management
- You can afford to lose

### Q: What's the maximum risk?
**A:** **Never risk more than you can afford to lose.** The EA suggests 1% risk per trade - adjust based on your situation.

### Q: Can I lose money?
**A:** **Yes.** Trading involves risk. Even perfect setups can fail. Always use:
- Stop losses
- Proper position sizing
- Risk management
- Demo testing first

---

## Support

### Q: Where can I get help?
**A:** 
1. Check this FAQ
2. Review User Manual
3. Check Settings Guide
4. Review EA logs in Experts tab
5. Check journal for clues

### Q: How do I report bugs?
**A:** 
1. Check Experts tab for errors
2. Note the error message
3. Check journal for context
4. Document steps to reproduce

### Q: Can I request features?
**A:** The EA is designed to be educational and focused. Feature requests should align with the core philosophy: **Quality over Quantity, Education over Automation.**

---

## Final Thoughts

### Q: What's the most important thing to remember?
**A:** 
- **Quality over quantity** - Better to miss than force
- **Education** - Learn from every setup
- **Patience** - Perfect setups come regularly
- **Risk management** - Always use stops
- **Demo test** - Minimum 3 months

### Q: How do I succeed with this EA?
**A:** 
1. **Understand the system** - Read all documentation
2. **Demo test thoroughly** - Minimum 3 months
3. **Review journal daily** - Learn from every setup
4. **Stick to 85+** - Don't lower threshold easily
5. **Be patient** - Quality setups come regularly
6. **Use risk management** - Always use stops
7. **Keep learning** - Review why setups scored high/low

### Q: What makes a good trader?
**A:** 
- **Discipline** - Stick to your rules
- **Patience** - Wait for quality setups
- **Risk management** - Protect your capital
- **Continuous learning** - Always improving
- **Emotional control** - No FOMO, no revenge trading

**Remember**: This EA is a tool to help you become a better trader, not a replacement for thinking. Use it wisely, trade responsibly, and always prioritize risk management.

---

**Good luck and happy trading!**

