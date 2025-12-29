//+------------------------------------------------------------------+
//| Setup_Analyzer.mqh                                               |
//| Analyzes setup quality and provides rejection reasons            |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"

//+------------------------------------------------------------------+
//| Setup Analyzer Class                                             |
//+------------------------------------------------------------------+
class CSetupAnalyzer
{
private:
   int m_minScoreAlert;
   
public:
   CSetupAnalyzer(int minScoreAlert);
   
   bool IsPerfectSetup(int score);
   bool IsGoodSetup(int score);
   bool IsWeakSetup(int score);
   bool IsInvalid(int score);
   
   ENUM_SETUP_QUALITY GetQuality(int score);
   string GetQualityLabel(int score);
   string GetRejectionReason(string symbol, int score, int categoryScores[]);
   string GetQualityEmoji(int score);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSetupAnalyzer::CSetupAnalyzer(int minScoreAlert)
{
   m_minScoreAlert = minScoreAlert;
}

//+------------------------------------------------------------------+
//| Check if setup is perfect                                        |
//+------------------------------------------------------------------+
bool CSetupAnalyzer::IsPerfectSetup(int score)
{
   return score >= m_minScoreAlert;
}

//+------------------------------------------------------------------+
//| Check if setup is good                                           |
//+------------------------------------------------------------------+
bool CSetupAnalyzer::IsGoodSetup(int score)
{
   return score >= 70 && score < m_minScoreAlert;
}

//+------------------------------------------------------------------+
//| Check if setup is weak                                           |
//+------------------------------------------------------------------+
bool CSetupAnalyzer::IsWeakSetup(int score)
{
   return score >= 50 && score < 70;
}

//+------------------------------------------------------------------+
//| Check if setup is invalid                                        |
//+------------------------------------------------------------------+
bool CSetupAnalyzer::IsInvalid(int score)
{
   return score < 50;
}

//+------------------------------------------------------------------+
//| Get quality level                                                |
//+------------------------------------------------------------------+
ENUM_SETUP_QUALITY CSetupAnalyzer::GetQuality(int score)
{
   if(score >= m_minScoreAlert)
      return QUALITY_PERFECT;
   else if(score >= 70)
      return QUALITY_GOOD;
   else if(score >= 50)
      return QUALITY_WEAK;
   else
      return QUALITY_INVALID;
}

//+------------------------------------------------------------------+
//| Get quality label                                                |
//+------------------------------------------------------------------+
string CSetupAnalyzer::GetQualityLabel(int score)
{
   return GetQualityLabel(score);
}

//+------------------------------------------------------------------+
//| Get quality emoji                                                |
//+------------------------------------------------------------------+
string CSetupAnalyzer::GetQualityEmoji(int score)
{
   if(score >= m_minScoreAlert)
      return "🟢";
   else if(score >= 70)
      return "🟡";
   else if(score >= 50)
      return "⚪";
   else
      return "🔴";
}

//+------------------------------------------------------------------+
//| Get rejection reason                                             |
//+------------------------------------------------------------------+
string CSetupAnalyzer::GetRejectionReason(string symbol, int score, int categoryScores[])
{
   string reason = "";
   
   if(score < 50)
   {
      reason = "INVALID setup (score: " + IntegerToString(score) + " < 50)\n";
      reason += "Reasons:\n";
      
      if(categoryScores[CATEGORY_TREND] < 15)
         reason += "• Weak H1 trend (" + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25)\n";
      
      if(categoryScores[CATEGORY_EMA_QUALITY] < 10)
         reason += "• Poor EMA quality (" + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20)\n";
      
      if(categoryScores[CATEGORY_SIGNAL_STRENGTH] < 10)
         reason += "• Weak signal strength (" + IntegerToString(categoryScores[CATEGORY_SIGNAL_STRENGTH]) + "/20)\n";
      
      if(categoryScores[CATEGORY_CONFIRMATION] < 8)
         reason += "• Weak confirmation (" + IntegerToString(categoryScores[CATEGORY_CONFIRMATION]) + "/15)\n";
      
      if(categoryScores[CATEGORY_MARKET] < 5)
         reason += "• Poor market conditions (" + IntegerToString(categoryScores[CATEGORY_MARKET]) + "/10)\n";
      
      if(categoryScores[CATEGORY_CONTEXT] < 5)
         reason += "• Poor timing/context (" + IntegerToString(categoryScores[CATEGORY_CONTEXT]) + "/10)\n";
   }
   else if(score < 70)
   {
      reason = "WEAK setup (score: " + IntegerToString(score) + " < 70)\n";
      reason += "Main weaknesses:\n";
      
      if(categoryScores[CATEGORY_TREND] < 20)
         reason += "• Trend not strong enough (" + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25)\n";
      
      if(categoryScores[CATEGORY_EMA_QUALITY] < 15)
         reason += "• EMA quality below optimal (" + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20)\n";
      
      if(categoryScores[CATEGORY_SIGNAL_STRENGTH] < 15)
         reason += "• Signal strength insufficient (" + IntegerToString(categoryScores[CATEGORY_SIGNAL_STRENGTH]) + "/20)\n";
   }
   else if(score < m_minScoreAlert)
   {
      reason = "GOOD setup but below perfect threshold (score: " + IntegerToString(score) + " < " + IntegerToString(m_minScoreAlert) + ")\n";
      reason += "Minor weaknesses:\n";
      
      if(categoryScores[CATEGORY_TREND] < 23)
         reason += "• Trend could be stronger (" + IntegerToString(categoryScores[CATEGORY_TREND]) + "/25)\n";
      
      if(categoryScores[CATEGORY_EMA_QUALITY] < 18)
         reason += "• EMA quality could be better (" + IntegerToString(categoryScores[CATEGORY_EMA_QUALITY]) + "/20)\n";
      
      if(categoryScores[CATEGORY_CONFIRMATION] < 12)
         reason += "• Confirmation could be stronger (" + IntegerToString(categoryScores[CATEGORY_CONFIRMATION]) + "/15)\n";
   }
   
   return reason;
}

//+------------------------------------------------------------------+

