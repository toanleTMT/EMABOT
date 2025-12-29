//+------------------------------------------------------------------+
//| Config.mqh                                                       |
//| Configuration constants and enums                                |
//+------------------------------------------------------------------+

#property copyright "EMA Perfect Setup EA"
#property version   "2.00"

//--- Signal Types
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY = 1,
   SIGNAL_SELL = -1
};

//--- Setup Quality Levels
enum ENUM_SETUP_QUALITY
{
   QUALITY_INVALID = 0,    // < 50 points
   QUALITY_WEAK = 1,       // 50-69 points
   QUALITY_GOOD = 2,       // 70-84 points
   QUALITY_PERFECT = 3     // 85-100 points
};

//--- Scoring Category Indices
#define CATEGORY_TREND           0
#define CATEGORY_EMA_QUALITY     1
#define CATEGORY_SIGNAL_STRENGTH 2
#define CATEGORY_CONFIRMATION    3
#define CATEGORY_MARKET          4
#define CATEGORY_CONTEXT         5

#define TOTAL_CATEGORIES         6

//--- Default Scoring Weights
#define DEFAULT_WEIGHT_TREND           25
#define DEFAULT_WEIGHT_EMA_QUALITY     20
#define DEFAULT_WEIGHT_SIGNAL_STRENGTH 20
#define DEFAULT_WEIGHT_CONFIRMATION    15
#define DEFAULT_WEIGHT_MARKET          10
#define DEFAULT_WEIGHT_CONTEXT         10

//--- Visual Object Prefixes
#define PREFIX_ARROW      "EMA_Arrow_"
#define PREFIX_LABEL      "EMA_Label_"
#define PREFIX_DASHBOARD  "EMA_Dashboard_"
#define PREFIX_PANEL      "EMA_Panel_"
#define PREFIX_LINE       "EMA_Line_"

//--- Journal Constants
#define JOURNAL_FOLDER_NAME      "EMA_Journal"
#define CSV_FILENAME_PREFIX      "EMA_Journal_"
#define SCREENSHOT_PREFIX        "EMA_Setup_"

//--- Time Constants (Vietnam Time UTC+7)
#define LONDON_NY_OVERLAP_START  19  // 19:00 Vietnam time
#define LONDON_NY_OVERLAP_END    23  // 23:00 Vietnam time
#define LONDON_SESSION_START     15  // 15:00 Vietnam time
#define LONDON_SESSION_END       24   // 24:00 Vietnam time
#define NY_SESSION_START         20   // 20:00 Vietnam time
#define NY_SESSION_END           4    // 04:00 Vietnam time (next day)

//--- Scoring Thresholds
#define MIN_H1_DISTANCE_EXCELLENT  50  // pips
#define MIN_H1_DISTANCE_GOOD       20  // pips
#define MIN_EMA_SEPARATION_WIDE    15  // pips
#define MIN_EMA_SEPARATION_MODERATE 8  // pips
#define MIN_CANDLE_BODY_STRONG     70  // percentage
#define MIN_CANDLE_BODY_MODERATE   50  // percentage
#define MAX_SPREAD_EXCELLENT       1.5 // pips
#define MAX_SPREAD_GOOD            2.5 // pips

//--- RSI Levels
#define RSI_STRONG_BUY     60
#define RSI_MODERATE_BUY   50
#define RSI_STRONG_SELL    40
#define RSI_MODERATE_SELL  50

//+------------------------------------------------------------------+

