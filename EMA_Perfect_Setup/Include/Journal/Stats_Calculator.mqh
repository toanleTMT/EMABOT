//+------------------------------------------------------------------+
//| Stats_Calculator.mqh                                             |
//| Calculates trading statistics                                     |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/String_Utils.mqh"

//+------------------------------------------------------------------+
//| Stats Calculator Class                                           |
//+------------------------------------------------------------------+
class CStatsCalculator
{
public:
   static void CalculateDailyStats(DailyStats &stats, JournalEntry &entries[]);
   static int CalculateDisciplineScore(int perfectTraded, int perfectSkipped, int goodTraded);
   static string GenerateWeeklySummary(DailyStats &stats[]);
};

//+------------------------------------------------------------------+
//| Calculate daily statistics                                       |
//+------------------------------------------------------------------+
void CStatsCalculator::CalculateDailyStats(DailyStats &stats, JournalEntry &entries[])
{
   int perfectWins = 0, perfectLosses = 0;
   double totalPips = 0, winPips = 0, lossPips = 0;
   int winCount = 0, lossCount = 0;
   
   for(int i = 0; i < ArraySize(entries); i++)
   {
      if(entries[i].totalScore >= 85)
      {
         stats.perfectSetups++;
         if(entries[i].wasTraded)
         {
            stats.perfectTraded++;
            if(entries[i].actualResultWin)
            {
               perfectWins++;
               stats.perfectWins++;
               totalPips += entries[i].actualPips;
               winPips += entries[i].actualPips;
               winCount++;
            }
            else if(entries[i].actualResultLoss)
            {
               perfectLosses++;
               stats.perfectLosses++;
               totalPips += entries[i].actualPips;
               lossPips += entries[i].actualPips;
               lossCount++;
            }
         }
         else if(entries[i].wasSkipped)
         {
            stats.perfectSkipped++;
         }
      }
      else if(entries[i].totalScore >= 70)
      {
         stats.goodSetups++;
      }
      else if(entries[i].totalScore >= 50)
      {
         stats.weakSetups++;
      }
      else
      {
         stats.invalidSetups++;
      }
   }
   
   stats.totalPips = totalPips;
   if(winCount > 0)
      stats.avgWinPips = winPips / winCount;
   if(lossCount > 0)
      stats.avgLossPips = lossPips / lossCount;
   
   if(lossPips != 0)
      stats.profitFactor = MathAbs(winPips / lossPips);
   else if(winPips > 0)
      stats.profitFactor = 999; // Infinite profit factor
   else
      stats.profitFactor = 0;
   
   stats.disciplineScore = CalculateDisciplineScore(stats.perfectTraded, stats.perfectSkipped, 0);
}

//+------------------------------------------------------------------+
//| Calculate discipline score                                       |
//+------------------------------------------------------------------+
int CStatsCalculator::CalculateDisciplineScore(int perfectTraded, int perfectSkipped, int goodTraded)
{
   int totalPerfect = perfectTraded + perfectSkipped;
   if(totalPerfect == 0) return 100;
   
   // Base score: percentage of perfect setups that were traded
   int baseScore = (int)((double)perfectTraded / totalPerfect * 100);
   
   // Penalty for trading good setups (should only trade perfect)
   int penalty = goodTraded * 5; // -5 points per good setup traded
   
   int finalScore = baseScore - penalty;
   if(finalScore < 0) finalScore = 0;
   if(finalScore > 100) finalScore = 100;
   
   return finalScore;
}

//+------------------------------------------------------------------+
//| Generate weekly summary text                                      |
//+------------------------------------------------------------------+
string CStatsCalculator::GenerateWeeklySummary(DailyStats &stats[])
{
   if(ArraySize(stats) == 0) return "";
   
   // Aggregate weekly stats
   int totalPerfect = 0, totalGood = 0, totalWeak = 0, totalInvalid = 0;
   int totalPerfectTraded = 0, totalPerfectSkipped = 0;
   int totalPerfectWins = 0, totalPerfectLosses = 0;
   double totalPips = 0, totalWinPips = 0, totalLossPips = 0;
   int winCount = 0, lossCount = 0;
   
   for(int i = 0; i < ArraySize(stats); i++)
   {
      totalPerfect += stats[i].perfectSetups;
      totalGood += stats[i].goodSetups;
      totalWeak += stats[i].weakSetups;
      totalInvalid += stats[i].invalidSetups;
      totalPerfectTraded += stats[i].perfectTraded;
      totalPerfectSkipped += stats[i].perfectSkipped;
      totalPerfectWins += stats[i].perfectWins;
      totalPerfectLosses += stats[i].perfectLosses;
      totalPips += stats[i].totalPips;
      
      if(stats[i].avgWinPips > 0 && stats[i].perfectWins > 0)
      {
         totalWinPips += stats[i].avgWinPips * stats[i].perfectWins;
         winCount += stats[i].perfectWins;
      }
      if(stats[i].avgLossPips > 0 && stats[i].perfectLosses > 0)
      {
         totalLossPips += MathAbs(stats[i].avgLossPips) * stats[i].perfectLosses;
         lossCount += stats[i].perfectLosses;
      }
   }
   
   // Build summary text
   string summary = "";
   summary += "╔═══════════════════════════════════════╗\n";
   summary += "║ 📊 WEEKLY SUMMARY                     ║\n";
   summary += "╠═══════════════════════════════════════╣\n";
   summary += "║                                       ║\n";
   summary += "║ SETUPS DETECTED:                      ║\n";
   summary += "║ • Perfect (85+): " + IntegerToString(totalPerfect) + "\n";
   summary += "║ • Good (70-84): " + IntegerToString(totalGood) + "\n";
   summary += "║ • Weak (50-69): " + IntegerToString(totalWeak) + "\n";
   summary += "║ • Invalid (<50): " + IntegerToString(totalInvalid) + "\n";
   summary += "║                                       ║\n";
   summary += "║ TRADING ACTIVITY:                     ║\n";
   summary += "║ • Perfect setups traded: " + IntegerToString(totalPerfectTraded) + "/" + IntegerToString(totalPerfect) + "\n";
   summary += "║ • Perfect setups skipped: " + IntegerToString(totalPerfectSkipped) + "\n";
   summary += "║                                       ║\n";
   
   if(totalPerfectTraded > 0)
   {
      summary += "║ RESULTS (Perfect Setups Only):        ║\n";
      double winRate = (double)totalPerfectWins / totalPerfectTraded * 100.0;
      summary += "║ • Wins: " + IntegerToString(totalPerfectWins) + " (" + DoubleToString(winRate, 1) + "% winrate) ✅\n";
      summary += "║ • Losses: " + IntegerToString(totalPerfectLosses) + "\n";
      summary += "║ • Total Pips: " + DoubleToString(totalPips, 1) + " pips\n";
      
      if(winCount > 0)
         summary += "║ • Avg Win: " + DoubleToString(totalWinPips / winCount, 1) + " pips\n";
      if(lossCount > 0)
         summary += "║ • Avg Loss: " + DoubleToString(totalLossPips / lossCount, 1) + " pips\n";
      
      double pf = (totalLossPips > 0) ? MathAbs(totalWinPips / totalLossPips) : 999;
      summary += "║ • Profit Factor: " + DoubleToString(pf, 2) + "\n";
      summary += "║                                       ║\n";
   }
   
   int avgDiscipline = 0;
   for(int i = 0; i < ArraySize(stats); i++)
      avgDiscipline += stats[i].disciplineScore;
   if(ArraySize(stats) > 0)
      avgDiscipline = avgDiscipline / ArraySize(stats);
   
   summary += "║ DISCIPLINE SCORE: " + IntegerToString(avgDiscipline) + "/100 ";
   if(avgDiscipline >= 90) summary += "🟢\n";
   else if(avgDiscipline >= 70) summary += "🟡\n";
   else summary += "🔴\n";
   summary += "║                                       ║\n";
   summary += "╚═══════════════════════════════════════╝\n";
   
   return summary;
}

//+------------------------------------------------------------------+

