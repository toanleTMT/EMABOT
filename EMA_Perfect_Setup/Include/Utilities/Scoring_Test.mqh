//+------------------------------------------------------------------+
//| Scoring_Test.mqh                                                  |
//| Test functions for scoring system verification                    |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Scoring/Setup_Scorer.mqh"
#include "../Scoring/Trend_Scorer.mqh"
#include "../Scoring/EMA_Quality_Scorer.mqh"
#include "../Scoring/Signal_Scorer.mqh"
#include "../Scoring/Confirmation_Scorer.mqh"
#include "../Scoring/Market_Scorer.mqh"
#include "../Scoring/Context_Scorer.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Indicators/RSI_Manager.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"
#include "../Utilities/Time_Utils.mqh"

//+------------------------------------------------------------------+
//| Scoring Test Class                                               |
//+------------------------------------------------------------------+
class CScoringTest
{
public:
   static void RunAllTests(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi);
   static void TestTrendScoring(CEMAManager *emaH1, string symbol);
   static void TestEMAQualityScoring(CEMAManager *emaM5, string symbol);
   static void TestSignalScoring(CEMAManager *emaM5, CEMAManager *emaH1, string symbol);
   static void TestConfirmationScoring(CRSIManager *rsi, string symbol);
   static void TestMarketScoring(string symbol);
   static void TestContextScoring();
   static void TestTotalScore(CSetupScorer *scorer, string symbol);
   static void TestScoreBreakdown(CSetupScorer *scorer, string symbol);
   static void TestStrengthsAndWeaknesses(CSetupScorer *scorer, string symbol);
   static void TestScoreValidation(CSetupScorer *scorer, string symbol);
   static void TestEdgeCases(CSetupScorer *scorer, string symbol);
};

//+------------------------------------------------------------------+
//| Run all scoring tests                                            |
//+------------------------------------------------------------------+
void CScoringTest::RunAllTests(CEMAManager *emaH1, CEMAManager *emaM5, CRSIManager *rsi)
{
   Print("\n╔═══════════════════════════════════════════════════════════╗");
   Print("║          SCORING SYSTEM TEST SUITE                        ║");
   Print("╚═══════════════════════════════════════════════════════════╝\n");
   
   // Get first available symbol for testing
   string testSymbol = Symbol();
   if(StringLen(testSymbol) == 0)
   {
      Print("ERROR: No symbol available for testing!");
      return;
   }
   
   Print("Testing with symbol: ", testSymbol, "\n");
   
   // Test individual categories
   Print("═══════════════════════════════════════════════════════════");
   Print("TEST 1: Trend Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestTrendScoring(emaH1, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 2: EMA Quality Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestEMAQualityScoring(emaM5, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 3: Signal Strength Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestSignalScoring(emaM5, emaH1, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 4: Confirmation Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestConfirmationScoring(rsi, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 5: Market Conditions Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestMarketScoring(testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 6: Context & Timing Scoring");
   Print("═══════════════════════════════════════════════════════════");
   TestContextScoring();
   
   // Test complete scoring system
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 7: Complete Scoring System");
   Print("═══════════════════════════════════════════════════════════");
   
   // Create scorer with default parameters
   CSetupScorer *testScorer = new CSetupScorer(emaH1, emaM5, rsi,
                                               50, 15, 70, 2.5,
                                               25, 20, 20, 15, 10, 10);
   
   TestTotalScore(testScorer, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 8: Score Breakdown");
   Print("═══════════════════════════════════════════════════════════");
   TestScoreBreakdown(testScorer, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 9: Strengths and Weaknesses Analysis");
   Print("═══════════════════════════════════════════════════════════");
   TestStrengthsAndWeaknesses(testScorer, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 10: Score Validation");
   Print("═══════════════════════════════════════════════════════════");
   TestScoreValidation(testScorer, testSymbol);
   
   Print("\n═══════════════════════════════════════════════════════════");
   Print("TEST 11: Edge Cases");
   Print("═══════════════════════════════════════════════════════════");
   TestEdgeCases(testScorer, testSymbol);
   
   delete testScorer;
   
   Print("\n╔═══════════════════════════════════════════════════════════╗");
   Print("║          ALL TESTS COMPLETED                             ║");
   Print("╚═══════════════════════════════════════════════════════════╝\n");
}

//+------------------------------------------------------------------+
//| Test trend scoring                                               |
//+------------------------------------------------------------------+
void CScoringTest::TestTrendScoring(CEMAManager *emaH1, string symbol)
{
   if(emaH1 == NULL)
   {
      Print("ERROR: EMA H1 manager is NULL");
      return;
   }
   
   // Get EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!emaH1.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
   {
      Print("ERROR: Failed to get EMA data for ", symbol);
      return;
   }
   
   double price = iClose(symbol, PERIOD_H1, 0);
   
   Print("H1 Price: ", FormatPrice(symbol, price));
   Print("EMA 9: ", FormatPrice(symbol, emaFast[0]));
   Print("EMA 21: ", FormatPrice(symbol, emaMedium[0]));
   Print("EMA 50: ", FormatPrice(symbol, emaSlow[0]));
   
   // Test BUY scenario
   if(price > emaSlow[0] && emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0])
   {
      CTrendScorer trendScorer(emaH1, 50);
      int score = trendScorer.CalculateScore(symbol, SIGNAL_BUY);
      Print("\nBUY Signal Trend Score: ", score, "/25");
      
      if(score >= 20)
         Print("✓ PASS: Trend score is good (≥20)");
      else if(score >= 15)
         Print("⚠ WARNING: Trend score is moderate (15-19)");
      else
         Print("✗ FAIL: Trend score is weak (<15)");
   }
   
   // Test SELL scenario
   if(price < emaSlow[0] && emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0])
   {
      CTrendScorer trendScorer(emaH1, 50);
      int score = trendScorer.CalculateScore(symbol, SIGNAL_SELL);
      Print("\nSELL Signal Trend Score: ", score, "/25");
      
      if(score >= 20)
         Print("✓ PASS: Trend score is good (≥20)");
      else if(score >= 15)
         Print("⚠ WARNING: Trend score is moderate (15-19)");
      else
         Print("✗ FAIL: Trend score is weak (<15)");
   }
}

//+------------------------------------------------------------------+
//| Test EMA quality scoring                                         |
//+------------------------------------------------------------------+
void CScoringTest::TestEMAQualityScoring(CEMAManager *emaM5, string symbol)
{
   if(emaM5 == NULL)
   {
      Print("ERROR: EMA M5 manager is NULL");
      return;
   }
   
   // Get EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
   {
      Print("ERROR: Failed to get EMA data for ", symbol);
      return;
   }
   
   Print("M5 EMA 9: ", FormatPrice(symbol, emaFast[0]));
   Print("M5 EMA 21: ", FormatPrice(symbol, emaMedium[0]));
   Print("M5 EMA 50: ", FormatPrice(symbol, emaSlow[0]));
   
   // Check alignment
   bool aligned = (emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]) ||
                  (emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]);
   
   Print("EMAs Aligned: ", aligned ? "Yes" : "No");
   
   // Calculate separation
   double sep1 = PriceToPips(symbol, MathAbs(emaFast[0] - emaMedium[0]));
   double sep2 = PriceToPips(symbol, MathAbs(emaMedium[0] - emaSlow[0]));
   double avgSep = (sep1 + sep2) / 2.0;
   
   Print("Average EMA Separation: ", FormatPips(avgSep));
   
   CEMAQualityScorer emaScorer(emaM5, 15);
   int score = emaScorer.CalculateScore(symbol, SIGNAL_BUY);
   Print("\nEMA Quality Score: ", score, "/20");
   
   if(score >= 18)
      Print("✓ PASS: EMA quality is excellent (≥18)");
   else if(score >= 15)
      Print("✓ PASS: EMA quality is good (15-17)");
   else if(score >= 10)
      Print("⚠ WARNING: EMA quality is moderate (10-14)");
   else
      Print("✗ FAIL: EMA quality is poor (<10)");
}

//+------------------------------------------------------------------+
//| Test signal strength scoring                                     |
//+------------------------------------------------------------------+
void CScoringTest::TestSignalScoring(CEMAManager *emaM5, CEMAManager *emaH1, string symbol)
{
   if(emaM5 == NULL)
   {
      Print("ERROR: EMA M5 manager is NULL");
      return;
   }
   
   // Get EMA data
   double emaFast[], emaMedium[], emaSlow[];
   if(!emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
   {
      Print("ERROR: Failed to get EMA data for ", symbol);
      return;
   }
   
   double price = iClose(symbol, PERIOD_M5, 0);
   
   Print("M5 Price: ", FormatPrice(symbol, price));
   Print("EMA 9: ", FormatPrice(symbol, emaFast[0]));
   Print("EMA 21: ", FormatPrice(symbol, emaMedium[0]));
   Print("EMA 50: ", FormatPrice(symbol, emaSlow[0]));
   
   // Check crossover
   bool crossover = false;
   ENUM_SIGNAL_TYPE signalType = SIGNAL_NONE;
   
   if(emaFast[0] > emaMedium[0] && emaFast[1] <= emaMedium[1])
   {
      crossover = true;
      signalType = SIGNAL_BUY;
      Print("✓ BUY Crossover detected");
   }
   else if(emaFast[0] < emaMedium[0] && emaFast[1] >= emaMedium[1])
   {
      crossover = true;
      signalType = SIGNAL_SELL;
      Print("✓ SELL Crossover detected");
   }
   else
   {
      Print("✗ No crossover detected");
   }
   
   if(crossover)
   {
      CSignalScorer signalScorer(emaM5, emaH1);
      int score = signalScorer.CalculateScore(symbol, signalType);
      Print("\nSignal Strength Score: ", score, "/20");
      
      if(score >= 18)
         Print("✓ PASS: Signal strength is excellent (≥18)");
      else if(score >= 15)
         Print("✓ PASS: Signal strength is good (15-17)");
      else if(score >= 10)
         Print("⚠ WARNING: Signal strength is moderate (10-14)");
      else
         Print("✗ FAIL: Signal strength is weak (<10)");
   }
}

//+------------------------------------------------------------------+
//| Test confirmation scoring                                        |
//+------------------------------------------------------------------+
void CScoringTest::TestConfirmationScoring(CRSIManager *rsi, string symbol)
{
   if(rsi == NULL)
   {
      Print("WARNING: RSI manager is NULL - skipping RSI tests");
      return;
   }
   
   double rsiValue = rsi.GetRSIValue(symbol, 0);
   Print("RSI(14): ", DoubleToString(rsiValue, 2));
   
   // Get candle data
   double open = iOpen(symbol, PERIOD_M5, 0);
   double close = iClose(symbol, PERIOD_M5, 0);
   double high = iHigh(symbol, PERIOD_M5, 0);
   double low = iLow(symbol, PERIOD_M5, 0);
   
   double candleRange = high - low;
   double bodySize = MathAbs(close - open);
   double bodyPercent = (candleRange > 0) ? (bodySize / candleRange * 100.0) : 0;
   
   Print("Candle Body: ", DoubleToString(bodyPercent, 1), "%");
   
   CConfirmationScorer confScorer(rsi, 70);
   int scoreBuy = confScorer.CalculateScore(symbol, SIGNAL_BUY);
   int scoreSell = confScorer.CalculateScore(symbol, SIGNAL_SELL);
   
   Print("\nConfirmation Score (BUY): ", scoreBuy, "/15");
   Print("Confirmation Score (SELL): ", scoreSell, "/15");
   
   int maxScore = MathMax(scoreBuy, scoreSell);
   if(maxScore >= 12)
      Print("✓ PASS: Confirmation is strong (≥12)");
   else if(maxScore >= 8)
      Print("⚠ WARNING: Confirmation is moderate (8-11)");
   else
      Print("✗ FAIL: Confirmation is weak (<8)");
}

//+------------------------------------------------------------------+
//| Test market conditions scoring                                   |
//+------------------------------------------------------------------+
void CScoringTest::TestMarketScoring(string symbol)
{
   double spread = GetSpreadPips(symbol);
   Print("Spread: ", FormatPips(spread), " pips");
   
   // Get volume data
   long volume = iVolume(symbol, PERIOD_M5, 0);
   Print("Volume: ", IntegerToString(volume));
   
   CMarketScorer marketScorer(2.5);
   int score = marketScorer.CalculateScore(symbol, SIGNAL_BUY);
   Print("\nMarket Conditions Score: ", score, "/10");
   
   if(score >= 8)
      Print("✓ PASS: Market conditions are excellent (≥8)");
   else if(score >= 5)
      Print("⚠ WARNING: Market conditions are moderate (5-7)");
   else
      Print("✗ FAIL: Market conditions are poor (<5)");
}

//+------------------------------------------------------------------+
//| Test context scoring                                             |
//+------------------------------------------------------------------+
void CScoringTest::TestContextScoring()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;
   
   Print("Current Hour (Vietnam Time): ", IntegerToString(hour));
   
   bool isLondonNY = IsLondonNYOverlap();
   bool isLondon = IsLondonSession();
   bool isNY = IsNYSession();
   
   Print("London-NY Overlap: ", isLondonNY ? "Yes" : "No");
   Print("London Session: ", isLondon ? "Yes" : "No");
   Print("NY Session: ", isNY ? "Yes" : "No");
   
   CContextScorer contextScorer;
   int score = contextScorer.CalculateScore(Symbol(), SIGNAL_BUY);
   Print("\nContext & Timing Score: ", score, "/10");
   
   if(score >= 8)
      Print("✓ PASS: Context timing is excellent (≥8)");
   else if(score >= 5)
      Print("⚠ WARNING: Context timing is moderate (5-7)");
   else
      Print("✗ FAIL: Context timing is poor (<5)");
}

//+------------------------------------------------------------------+
//| Test total score calculation                                     |
//+------------------------------------------------------------------+
void CScoringTest::TestTotalScore(CSetupScorer *scorer, string symbol)
{
   if(scorer == NULL)
   {
      Print("ERROR: Scorer is NULL");
      return;
   }
   
   // Test BUY signal
   int categoryScores[];
   int totalScoreBuy = scorer.CalculateTotalScore(symbol, SIGNAL_BUY, categoryScores);
   
   Print("BUY Signal Total Score: ", totalScoreBuy, "/100");
   Print("Category Breakdown:");
   Print("  Trend: ", categoryScores[CATEGORY_TREND], "/25");
   Print("  EMA Quality: ", categoryScores[CATEGORY_EMA_QUALITY], "/20");
   Print("  Signal Strength: ", categoryScores[CATEGORY_SIGNAL_STRENGTH], "/20");
   Print("  Confirmation: ", categoryScores[CATEGORY_CONFIRMATION], "/15");
   Print("  Market: ", categoryScores[CATEGORY_MARKET], "/10");
   Print("  Context: ", categoryScores[CATEGORY_CONTEXT], "/10");
   
   if(totalScoreBuy >= 85)
      Print("\n✓✓✓ PERFECT SETUP (≥85) ✓✓✓");
   else if(totalScoreBuy >= 70)
      Print("\n✓✓ GOOD SETUP (70-84) ✓✓");
   else if(totalScoreBuy >= 50)
      Print("\n✓ WEAK SETUP (50-69) ✓");
   else
      Print("\n✗ INVALID SETUP (<50) ✗");
   
   // Test SELL signal
   int categoryScoresSell[];
   int totalScoreSell = scorer.CalculateTotalScore(symbol, SIGNAL_SELL, categoryScoresSell);
   
   Print("\nSELL Signal Total Score: ", totalScoreSell, "/100");
   Print("Category Breakdown:");
   Print("  Trend: ", categoryScoresSell[CATEGORY_TREND], "/25");
   Print("  EMA Quality: ", categoryScoresSell[CATEGORY_EMA_QUALITY], "/20");
   Print("  Signal Strength: ", categoryScoresSell[CATEGORY_SIGNAL_STRENGTH], "/20");
   Print("  Confirmation: ", categoryScoresSell[CATEGORY_CONFIRMATION], "/15");
   Print("  Market: ", categoryScoresSell[CATEGORY_MARKET], "/10");
   Print("  Context: ", categoryScoresSell[CATEGORY_CONTEXT], "/10");
   
   if(totalScoreSell >= 85)
      Print("\n✓✓✓ PERFECT SETUP (≥85) ✓✓✓");
   else if(totalScoreSell >= 70)
      Print("\n✓✓ GOOD SETUP (70-84) ✓✓");
   else if(totalScoreSell >= 50)
      Print("\n✓ WEAK SETUP (50-69) ✓");
   else
      Print("\n✗ INVALID SETUP (<50) ✗");
}

//+------------------------------------------------------------------+
//| Test score breakdown                                             |
//+------------------------------------------------------------------+
void CScoringTest::TestScoreBreakdown(CSetupScorer *scorer, string symbol)
{
   if(scorer == NULL)
   {
      Print("ERROR: Scorer is NULL");
      return;
   }
   
   int categoryScores[];
   int totalScore = scorer.CalculateTotalScore(symbol, SIGNAL_BUY, categoryScores);
   
   string breakdown = scorer.GetScoreBreakdown(symbol, SIGNAL_BUY, categoryScores);
   Print(breakdown);
}

//+------------------------------------------------------------------+
//| Test strengths and weaknesses                                    |
//+------------------------------------------------------------------+
void CScoringTest::TestStrengthsAndWeaknesses(CSetupScorer *scorer, string symbol)
{
   if(scorer == NULL)
   {
      Print("ERROR: Scorer is NULL");
      return;
   }
   
   int categoryScores[];
   int totalScore = scorer.CalculateTotalScore(symbol, SIGNAL_BUY, categoryScores);
   
   string analysis = scorer.GetStrengthsAndWeaknesses(symbol, SIGNAL_BUY, categoryScores);
   Print(analysis);
}

//+------------------------------------------------------------------+
//| Test score validation                                            |
//+------------------------------------------------------------------+
void CScoringTest::TestScoreValidation(CSetupScorer *scorer, string symbol)
{
   if(scorer == NULL)
   {
      Print("ERROR: Scorer is NULL");
      return;
   }
   
   Print("Testing score validation and normalization...\n");
   
   // Test with BUY signal
   int categoryScores[];
   int totalScore = scorer.CalculateTotalScore(symbol, SIGNAL_BUY, categoryScores);
   
   // Validate score is within expected range
   Print("Total Score: ", totalScore, "/100");
   
   if(totalScore < 0)
   {
      Print("✗ FAIL: Score is negative!");
   }
   else if(totalScore > 100)
   {
      Print("✗ FAIL: Score exceeds 100!");
   }
   else
   {
      Print("✓ PASS: Score is within valid range (0-100)");
   }
   
   // Validate category scores
   Print("\nCategory Score Validation:");
   int categoryMax[] = {25, 20, 20, 15, 10, 10};
   string categoryNames[] = {"Trend", "EMA Quality", "Signal Strength", "Confirmation", "Market", "Context"};
   bool allValid = true;
   
   for(int i = 0; i < TOTAL_CATEGORIES; i++)
   {
      if(categoryScores[i] < 0)
      {
         Print("✗ FAIL: ", categoryNames[i], " score is negative (", categoryScores[i], ")");
         allValid = false;
      }
      else if(categoryScores[i] > categoryMax[i])
      {
         Print("✗ FAIL: ", categoryNames[i], " score exceeds maximum (", categoryScores[i], " > ", categoryMax[i], ")");
         allValid = false;
      }
      else
      {
         Print("✓ ", categoryNames[i], ": ", categoryScores[i], "/", categoryMax[i], " - Valid");
      }
   }
   
   if(allValid)
      Print("\n✓✓✓ ALL CATEGORY SCORES VALID ✓✓✓");
   else
      Print("\n✗✗✗ SOME CATEGORY SCORES INVALID ✗✗✗");
   
   // Test score normalization
   Print("\nTesting score normalization...");
   int sumOfCategories = 0;
   for(int i = 0; i < TOTAL_CATEGORIES; i++)
      sumOfCategories += categoryScores[i];
   
   Print("Sum of category scores: ", sumOfCategories);
   Print("Normalized total score: ", totalScore);
   
   if(totalScore == sumOfCategories)
      Print("⚠ NOTE: Score not normalized (sum = total)");
   else
      Print("✓ Score is normalized to 0-100 scale");
}

//+------------------------------------------------------------------+
//| Test edge cases                                                  |
//+------------------------------------------------------------------+
void CScoringTest::TestEdgeCases(CSetupScorer *scorer, string symbol)
{
   if(scorer == NULL)
   {
      Print("ERROR: Scorer is NULL");
      return;
   }
   
   Print("Testing edge cases and boundary conditions...\n");
   
   // Test with invalid symbol
   Print("Test 1: Invalid symbol handling");
   int categoryScores[];
   int scoreInvalid = scorer.CalculateTotalScore("INVALID_SYMBOL_XYZ", SIGNAL_BUY, categoryScores);
   Print("  Score for invalid symbol: ", scoreInvalid);
   if(scoreInvalid == 0)
      Print("  ✓ PASS: Invalid symbol returns 0");
   else
      Print("  ⚠ WARNING: Invalid symbol returned non-zero score");
   
   // Test with SIGNAL_NONE
   Print("\nTest 2: SIGNAL_NONE handling");
   int scoreNone = scorer.CalculateTotalScore(symbol, SIGNAL_NONE, categoryScores);
   Print("  Score for SIGNAL_NONE: ", scoreNone);
   if(scoreNone == 0)
      Print("  ✓ PASS: SIGNAL_NONE returns 0");
   else
      Print("  ⚠ WARNING: SIGNAL_NONE returned non-zero score");
   
   // Test score breakdown with zero score
   Print("\nTest 3: Zero score breakdown");
   string breakdown = scorer.GetScoreBreakdown(symbol, SIGNAL_BUY, categoryScores);
   if(StringLen(breakdown) > 0)
      Print("  ✓ PASS: Breakdown generated even with zero score");
   else
      Print("  ⚠ WARNING: No breakdown generated");
   
   // Test strengths/weaknesses with zero score
   Print("\nTest 4: Zero score analysis");
   string analysis = scorer.GetStrengthsAndWeaknesses(symbol, SIGNAL_BUY, categoryScores);
   if(StringLen(analysis) > 0)
      Print("  ✓ PASS: Analysis generated");
   else
      Print("  ⚠ WARNING: No analysis generated");
   
   Print("\n✓ Edge case testing complete");
}

//+------------------------------------------------------------------+

