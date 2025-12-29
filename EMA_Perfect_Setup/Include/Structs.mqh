//+------------------------------------------------------------------+
//| Structs.mqh                                                      |
//| Data structures for EA operations                                |
//+------------------------------------------------------------------+

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Setup Score Structure                                            |
//+------------------------------------------------------------------+
struct SetupScore
{
   int totalScore;                    // Total score (0-100)
   int categoryScores[TOTAL_CATEGORIES]; // Individual category scores
   ENUM_SETUP_QUALITY quality;        // Quality level
   string strengths;                  // Strengths description
   string weaknesses;                 // Weaknesses description
   string rejectionReason;            // Why rejected (if applicable)
};

//+------------------------------------------------------------------+
//| Signal Data Structure                                            |
//+------------------------------------------------------------------+
struct SignalData
{
   string symbol;                     // Symbol name
   datetime time;                     // Signal time
   ENUM_SIGNAL_TYPE type;             // BUY or SELL
   double entry;                      // Entry price
   double stopLoss;                   // Stop loss price
   double takeProfit1;                // First take profit
   double takeProfit2;                // Second take profit
   double riskReward;                 // Risk/Reward ratio
   double suggestedLot;                // Suggested lot size
   double spread;                     // Current spread in pips
   SetupScore score;                  // Complete score breakdown
};

//+------------------------------------------------------------------+
//| Indicator Data Structure                                         |
//+------------------------------------------------------------------+
struct IndicatorData
{
   double emaFast[3];                 // EMA 9: [0]=current, [1]=previous, [2]=before
   double emaMedium[3];               // EMA 21: [0]=current, [1]=previous, [2]=before
   double emaSlow[3];                 // EMA 50: [0]=current, [1]=previous, [2]=before
   double rsi;                        // RSI current value
   double price;                      // Current price (close)
   double high;                       // Current high
   double low;                        // Current low
   double bodySize;                   // Candle body size
   double bodyPercent;                // Body as % of candle
   long volume;                       // Current volume
   double spread;                     // Current spread in pips
};

//+------------------------------------------------------------------+
//| Trend Data Structure                                             |
//+------------------------------------------------------------------+
struct TrendData
{
   bool isUptrend;                    // H1 uptrend?
   bool isDowntrend;                  // H1 downtrend?
   double priceDistance;              // Price distance from EMA50 (pips)
   bool emasAligned;                  // EMAs properly aligned?
   bool emasPerfectOrder;             // Perfect order (9>21>50 or reverse)
   int alignmentScore;                // Alignment quality score
};

//+------------------------------------------------------------------+
//| Journal Entry Structure                                          |
//+------------------------------------------------------------------+
struct JournalEntry
{
   datetime time;                     // Entry time
   string symbol;                     // Symbol
   ENUM_TIMEFRAMES timeframe;         // Timeframe
   ENUM_SIGNAL_TYPE type;             // Signal type
   int totalScore;                    // Total score
   int categoryScores[TOTAL_CATEGORIES]; // Category scores
   double entry;                      // Entry price
   double stopLoss;                   // Stop loss
   double takeProfit1;                // TP1
   double takeProfit2;                // TP2
   string strengths;                  // Strengths
   string weaknesses;                 // Weaknesses
   string rejectionReason;            // Rejection reason
   bool wasTraded;                    // User traded it?
   bool wasSkipped;                   // User skipped it?
   string userReason;                 // User's reason
   bool actualResultWin;              // Actual result
   bool actualResultLoss;
   bool actualResultBreakeven;
   double actualPips;                 // Actual pips
   datetime exitTime;                 // Exit time
   string notes;                      // User notes
};

//+------------------------------------------------------------------+
//| Daily Statistics Structure                                       |
//+------------------------------------------------------------------+
struct DailyStats
{
   datetime date;                     // Date
   int perfectSetups;                 // Perfect setups found
   int goodSetups;                     // Good setups found
   int weakSetups;                     // Weak setups found
   int invalidSetups;                 // Invalid setups
   int perfectTraded;                 // Perfect setups traded
   int perfectSkipped;                // Perfect setups skipped
   int perfectWins;                   // Perfect setup wins
   int perfectLosses;                 // Perfect setup losses
   double totalPips;                  // Total pips
   double avgWinPips;                 // Average win pips
   double avgLossPips;                // Average loss pips
   double profitFactor;               // Profit factor
   int disciplineScore;               // Discipline score (0-100)
};

//+------------------------------------------------------------------+

