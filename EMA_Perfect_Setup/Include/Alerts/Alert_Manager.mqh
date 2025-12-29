//+------------------------------------------------------------------+
//| Alert_Manager.mqh                                                |
//| Manages all alert types                                          |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "Popup_Builder.mqh"
#include "../Utilities/String_Utils.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Alert Manager Class                                              |
//+------------------------------------------------------------------+
class CAlertManager
{
private:
   bool m_popupPerfect;
   bool m_soundPerfect;
   bool m_pushPerfect;
   bool m_emailPerfect;
   string m_soundFilePerfect;
   string m_soundFileGood;
   
public:
   CAlertManager(bool popupPerfect, bool soundPerfect, bool pushPerfect, bool emailPerfect,
                 string soundFilePerfect, string soundFileGood);
   
   void SendPerfectSetupAlert(string symbol, int score, ENUM_SIGNAL_TYPE signalType,
                              double entry, double sl, double tp1, double tp2,
                              string strengths, string weaknesses);
   void SendGoodSetupAlert(string symbol, int score, ENUM_SIGNAL_TYPE signalType);
   void PlaySound(string soundFile);
   void SendPushNotification(string message);
   void SendEmail(string subject, string body);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAlertManager::CAlertManager(bool popupPerfect, bool soundPerfect, bool pushPerfect, bool emailPerfect,
                            string soundFilePerfect, string soundFileGood)
{
   m_popupPerfect = popupPerfect;
   m_soundPerfect = soundPerfect;
   m_pushPerfect = pushPerfect;
   m_emailPerfect = emailPerfect;
   m_soundFilePerfect = soundFilePerfect;
   m_soundFileGood = soundFileGood;
}

//+------------------------------------------------------------------+
//| Send perfect setup alert                                         |
//+------------------------------------------------------------------+
void CAlertManager::SendPerfectSetupAlert(string symbol, int score, ENUM_SIGNAL_TYPE signalType,
                                         double entry, double sl, double tp1, double tp2,
                                         string strengths, string weaknesses)
{
   // Popup
   if(m_popupPerfect)
   {
      CPopupBuilder::ShowPerfectSetupPopup(symbol, score, signalType, entry, sl, tp1, tp2, strengths, weaknesses);
   }
   
   // Sound
   if(m_soundPerfect)
   {
      PlaySound(m_soundFilePerfect);
   }
   
   // Push notification
   if(m_pushPerfect)
   {
      string message = "🟢 PERFECT SETUP! Score: " + IntegerToString(score) + "/100 - Check " + symbol + " chart NOW!";
      SendPushNotification(message);
   }
   
   // Email
   if(m_emailPerfect)
   {
      string subject = "PERFECT SETUP ALERT - " + symbol;
      string body = "Perfect setup detected!\n\n";
      body += "Symbol: " + symbol + "\n";
      body += "Direction: " + GetSignalTypeString(signalType) + "\n";
      body += "Score: " + IntegerToString(score) + "/100\n";
      body += "Entry: " + FormatPrice(symbol, entry) + "\n";
      body += "Stop Loss: " + FormatPrice(symbol, sl) + "\n";
      body += "Take Profit 1: " + FormatPrice(symbol, tp1) + "\n";
      body += "Take Profit 2: " + FormatPrice(symbol, tp2) + "\n\n";
      body += "Strengths:\n" + strengths + "\n";
      if(StringLen(weaknesses) > 0)
         body += "\nWeaknesses:\n" + weaknesses;
      
      SendEmail(subject, body);
   }
}

//+------------------------------------------------------------------+
//| Send good setup alert                                            |
//+------------------------------------------------------------------+
void CAlertManager::SendGoodSetupAlert(string symbol, int score, ENUM_SIGNAL_TYPE signalType)
{
   string message = "🟡 Good setup (Score: " + IntegerToString(score) + ") but not perfect - Consider carefully";
   
   if(m_popupPerfect) // Use perfect settings for good if enabled
   {
      CPopupBuilder::ShowGoodSetupPopup(symbol, score, signalType);
   }
   
   if(m_soundPerfect)
   {
      PlaySound(m_soundFileGood);
   }
}

//+------------------------------------------------------------------+
//| Play sound file                                                  |
//+------------------------------------------------------------------+
void CAlertManager::PlaySound(string soundFile)
{
   if(StringLen(soundFile) > 0)
   {
      // Use MQL5 PlaySound() function
      ::PlaySound(soundFile);
   }
   else
   {
      // Default alert sound
      ::PlaySound("alert.wav");
   }
}

//+------------------------------------------------------------------+
//| Send push notification                                           |
//+------------------------------------------------------------------+
void CAlertManager::SendPushNotification(string message)
{
   SendNotification(message);
}

//+------------------------------------------------------------------+
//| Send email                                                       |
//+------------------------------------------------------------------+
void CAlertManager::SendEmail(string subject, string body)
{
   SendMail(subject, body);
}

//+------------------------------------------------------------------+

