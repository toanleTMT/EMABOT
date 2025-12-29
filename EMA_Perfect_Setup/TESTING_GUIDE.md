# Testing Guide - Scoring System Verification

## Overview

The EMA Perfect Setup Scanner EA includes a comprehensive built-in test suite to verify the scoring system works correctly. This guide explains how to use the testing functionality.

## Enabling Tests

### Step 1: Enable Test Mode
1. Open EA inputs in MetaTrader 5
2. Navigate to "═══ DEBUG SETTINGS ═══" section
3. Set `InpRunScoringTest = true`
4. Click OK to apply

### Step 2: Attach EA to Chart
1. Attach the EA to any chart (symbol doesn't matter for testing)
2. The test will run automatically during initialization
3. Check the Experts tab for test results

## Test Suite Contents

The test suite includes **11 comprehensive tests**:

### Test 1: Trend Scoring
- Tests Category 1: Trend Alignment (25 points max)
- Validates H1 price-EMA50 distance scoring
- Validates H1 EMA alignment scoring
- Tests both BUY and SELL scenarios

### Test 2: EMA Quality Scoring
- Tests Category 2: M5 EMA Quality (20 points max)
- Validates EMA alignment scoring
- Validates EMA separation scoring
- Checks for proper separation calculations

### Test 3: Signal Strength Scoring
- Tests Category 3: Signal Strength (20 points max)
- Validates EMA crossover detection
- Validates price position scoring
- Tests crossover quality assessment

### Test 4: Confirmation Scoring
- Tests Category 4: Confirmation (15 points max)
- Validates candle body strength scoring
- Validates RSI confirmation scoring
- Tests both BUY and SELL RSI conditions

### Test 5: Market Conditions Scoring
- Tests Category 5: Market Conditions (10 points max)
- Validates spread scoring
- Validates volume/momentum scoring
- Checks market condition assessment

### Test 6: Context & Timing Scoring
- Tests Category 6: Context & Timing (10 points max)
- Validates trading session detection
- Validates support/resistance scoring
- Tests session-based scoring

### Test 7: Complete Scoring System
- Tests the complete scoring system end-to-end
- Validates total score calculation
- Tests score normalization to 0-100
- Tests both BUY and SELL signals

### Test 8: Score Breakdown
- Tests score breakdown generation
- Validates detailed category information
- Tests breakdown formatting

### Test 9: Strengths and Weaknesses Analysis
- Tests strengths/weaknesses generation
- Validates analysis accuracy
- Tests formatting and content

### Test 10: Score Validation **[NEW]**
- Validates score ranges (0-100)
- Validates category score ranges
- Tests score normalization
- Checks for invalid scores

### Test 11: Edge Cases **[NEW]**
- Tests invalid symbol handling
- Tests SIGNAL_NONE handling
- Tests zero score scenarios
- Tests boundary conditions

## Test Output Format

Each test provides:
- **✓ PASS**: Test passed successfully
- **⚠ WARNING**: Test passed but with warnings
- **✗ FAIL**: Test failed - indicates an issue

### Example Output:
```
╔═══════════════════════════════════════════════════════════╗
║          SCORING SYSTEM TEST SUITE                        ║
╚═══════════════════════════════════════════════════════════╝

Testing with symbol: EURUSD

═══════════════════════════════════════════════════════════
TEST 1: Trend Scoring
═══════════════════════════════════════════════════════════
H1 Price: 1.08750
EMA 9: 1.08720
EMA 21: 1.08680
EMA 50: 1.08600

BUY Signal Trend Score: 23/25
✓ PASS: Trend score is good (≥20)
```

## Interpreting Results

### Perfect Setup (85-100 points)
- ✓✓✓ PERFECT SETUP (≥85) ✓✓✓
- All systems working correctly
- Ready for trading

### Good Setup (70-84 points)
- ✓✓ GOOD SETUP (70-84) ✓✓
- System working but not perfect conditions
- May need market conditions improvement

### Weak Setup (50-69 points)
- ✓ WEAK SETUP (50-69) ✓
- System working but setup quality is low
- Expected behavior - correctly rejected

### Invalid Setup (<50 points)
- ✗ INVALID SETUP (<50) ✗
- System correctly identifying invalid setups
- Expected behavior

## Troubleshooting

### Test Fails to Run
- **Issue**: Test doesn't execute
- **Solution**: Ensure `InpRunScoringTest = true` is set
- **Check**: Verify EA compiled without errors

### All Scores Are Zero
- **Issue**: All test scores return 0
- **Possible Causes**:
  - Symbol not available in Market Watch
  - Insufficient historical data
  - Indicators not initialized
- **Solution**: Add symbol to Market Watch, wait for data

### Category Scores Out of Range
- **Issue**: Category scores exceed maximum
- **Solution**: Check score normalization logic
- **Action**: Review scoring formulas

### Invalid Symbol Errors
- **Issue**: Tests fail with invalid symbol
- **Solution**: This is expected behavior - test validates error handling
- **Note**: Edge case test intentionally uses invalid symbols

## Best Practices

1. **Run Tests Regularly**: Test after any code changes
2. **Check All Categories**: Ensure all 6 categories score correctly
3. **Verify Edge Cases**: Confirm error handling works
4. **Monitor Scores**: Ensure scores stay within 0-100 range
5. **Compare Results**: Compare test results across different symbols

## Test Coverage

- ✅ All 6 scoring categories tested
- ✅ BUY and SELL signals tested
- ✅ Score normalization tested
- ✅ Edge cases tested
- ✅ Error handling tested
- ✅ Breakdown generation tested
- ✅ Analysis generation tested

## Next Steps

After running tests:
1. Review all test results
2. Verify all tests pass (✓)
3. Check for any warnings (⚠)
4. Investigate any failures (✗)
5. Proceed with EA usage if all tests pass

---

**Note**: The test suite is designed to verify the scoring system works correctly. It does not test actual trading signals or market conditions - it validates the mathematical and logical correctness of the scoring algorithms.

