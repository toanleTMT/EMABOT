//+------------------------------------------------------------------+
//| Noise_Filter.mqh                                                  |
//| Advanced noise reduction filters                                  |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Indicators/EMA_Manager.mqh"
#include "../Indicators/ADX_Manager.mqh"
#include "../Indicators/RSI_Manager.mqh"

//+------------------------------------------------------------------+
//| Noise Filter Class                                               |
//+------------------------------------------------------------------+
class CNoiseFilter
{
private:
   CEMAManager *m_emaHigherTF;      // Higher timeframe EMA manager
   CADXManager *m_adxManager;       // ADX manager for momentum
   CRSIManager *m_rsiManager;       // RSI manager (alternative momentum)
   ENUM_TIMEFRAMES m_higherTF;      // Higher timeframe for multi-TF filter
   double m_minADX;                 // Minimum ADX for trending market
   double m_minRSI_Momentum;        // Minimum RSI for momentum (alternative)
   bool m_useADX;                   // Use ADX or RSI for momentum
   bool m_useVolumeFilter;          // Enable volume filter
   int m_volumePeriod;              // Number of candles for average volume
   ENUM_TIMEFRAMES m_volumeTF;      // Timeframe for volume check
   
   bool CheckMultiTimeframeTrend(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckMomentumFilter(string symbol, ENUM_SIGNAL_TYPE signalType);
   bool CheckVolumeFilter(string symbol);
   
public:
   CNoiseFilter(CEMAManager *emaHigherTF, CADXManager *adxManager, CRSIManager *rsiManager,
                ENUM_TIMEFRAMES higherTF, double minADX, double minRSI_Momentum, bool useADX,
                bool useVolumeFilter, int volumePeriod, ENUM_TIMEFRAMES volumeTF);
   
   bool PassesNoiseFilters(string symbol, ENUM_SIGNAL_TYPE signalType);
   string GetFilterRejectionReason(string symbol, ENUM_SIGNAL_TYPE signalType);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNoiseFilter::CNoiseFilter(CEMAManager *emaHigherTF, CADXManager *adxManager, CRSIManager *rsiManager,
                           ENUM_TIMEFRAMES higherTF, double minADX, double minRSI_Momentum, bool useADX,
                           bool useVolumeFilter, int volumePeriod, ENUM_TIMEFRAMES volumeTF)
{
   m_emaHigherTF = emaHigherTF;
   m_adxManager = adxManager;
   m_rsiManager = rsiManager;
   m_higherTF = higherTF;
   m_minADX = minADX;
   m_minRSI_Momentum = minRSI_Momentum;
   m_useADX = useADX;
   m_useVolumeFilter = useVolumeFilter;
   m_volumePeriod = volumePeriod;
   m_volumeTF = volumeTF;
}

//+------------------------------------------------------------------+
//| Check if signal passes all noise filters                         |
//+------------------------------------------------------------------+
bool CNoiseFilter::PassesNoiseFilters(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   // 1. Multi-Timeframe Filter: Entry must align with higher TF trend
   if(!CheckMultiTimeframeTrend(symbol, signalType))
      return false;
   
   // 2. Momentum Filter: Ensure not trading in low-volatility noise zone
   if(!CheckMomentumFilter(symbol, signalType))
      return false;
   
   // 3. Volume Filter: Ensure move is backed by real market activity
   if(m_useVolumeFilter)
   {
      if(!CheckVolumeFilter(symbol))
         return false;
   }
   
   return true;  // All filters passed
}

//+------------------------------------------------------------------+
//| Check multi-timeframe trend alignment                           |
//| Entry must align with the trend of higher timeframe             |
//+------------------------------------------------------------------+
bool CNoiseFilter::CheckMultiTimeframeTrend(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(m_emaHigherTF == NULL)
      return true;  // Filter disabled if no higher TF manager
   
   // Get higher timeframe EMA data (from closed bar)
   double emaFast[], emaMedium[], emaSlow[];
   if(!m_emaHigherTF.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;  // Can't check - reject for safety
   
   // Get higher timeframe price (closed bar)
   double priceHigherTF = iClose(symbol, m_higherTF, 1);
   
   if(signalType == SIGNAL_BUY)
   {
      // BUY: Higher TF must be in uptrend
      // Price > EMA50 and EMAs aligned (9 > 21 > 50)
      if(priceHigherTF <= emaSlow[0])
         return false;  // Price below EMA50 on higher TF
      
      if(!(emaFast[0] > emaMedium[0] && emaMedium[0] > emaSlow[0]))
         return false;  // EMAs not aligned on higher TF
   }
   else if(signalType == SIGNAL_SELL)
   {
      // SELL: Higher TF must be in downtrend
      // Price < EMA50 and EMAs aligned (9 < 21 < 50)
      if(priceHigherTF >= emaSlow[0])
         return false;  // Price above EMA50 on higher TF
      
      if(!(emaFast[0] < emaMedium[0] && emaMedium[0] < emaSlow[0]))
         return false;  // EMAs not aligned on higher TF
   }
   
   return true;  // Higher TF trend aligns with signal
}

//+------------------------------------------------------------------+
//| Check momentum filter (ADX or RSI)                              |
//| Ensures we are not trading in low-volatility 'noise' zone       |
//+------------------------------------------------------------------+
bool CNoiseFilter::CheckMomentumFilter(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   if(m_useADX && m_adxManager != NULL)
   {
      // Use ADX for momentum filter
      double adx;
      if(!m_adxManager.GetADXValue(symbol, adx))
         return false;  // Can't get ADX - reject for safety
      
      // ADX must be above threshold to indicate trending (not noise)
      if(adx < m_minADX)
         return false;  // Low ADX = low volatility noise zone
      
      // Additional check: For BUY, DI+ should be stronger; for SELL, DI- should be stronger
      if(signalType == SIGNAL_BUY)
      {
         double diPlus, diMinus;
         if(m_adxManager.GetDIValues(symbol, diPlus, diMinus))
         {
            if(diPlus <= diMinus)
               return false;  // Bearish momentum on higher TF
         }
      }
      else if(signalType == SIGNAL_SELL)
      {
         double diPlus, diMinus;
         if(m_adxManager.GetDIValues(symbol, diPlus, diMinus))
         {
            if(diMinus <= diPlus)
               return false;  // Bullish momentum on higher TF
         }
      }
   }
   else if(!m_useADX && m_rsiManager != NULL)
   {
      // Use RSI as alternative momentum filter
      double rsi;
      if(!m_rsiManager.GetRSIValue(symbol, rsi))
         return false;  // Can't get RSI - reject for safety
      
      if(signalType == SIGNAL_BUY)
      {
         // BUY: RSI should show bullish momentum (above threshold)
         if(rsi < m_minRSI_Momentum)
            return false;  // Weak momentum - noise zone
      }
      else if(signalType == SIGNAL_SELL)
      {
         // SELL: RSI should show bearish momentum (below threshold)
         // For SELL, we check if RSI is below (100 - threshold)
         double maxRSI = 100.0 - m_minRSI_Momentum;
         if(rsi > maxRSI)
            return false;  // Weak momentum - noise zone
      }
   }
   else
   {
      // No momentum filter available - allow signal (filter disabled)
      return true;
   }
   
   return true;  // Momentum filter passed
}

//+------------------------------------------------------------------+
//| Get rejection reason for noise filters                          |
//+------------------------------------------------------------------+
string CNoiseFilter::GetFilterRejectionReason(string symbol, ENUM_SIGNAL_TYPE signalType)
{
   // Check multi-timeframe filter
   if(!CheckMultiTimeframeTrend(symbol, signalType))
   {
      string tfStr = EnumToString(m_higherTF);
      if(signalType == SIGNAL_BUY)
         return StringFormat("Higher TF (%s) not in uptrend", tfStr);
      else
         return StringFormat("Higher TF (%s) not in downtrend", tfStr);
   }
   
   // Check momentum filter
   if(!CheckMomentumFilter(symbol, signalType))
   {
      if(m_useADX && m_adxManager != NULL)
      {
         double adx;
         if(m_adxManager.GetADXValue(symbol, adx))
         {
            return StringFormat("Low momentum (ADX: %.1f, min: %.1f) - noise zone", adx, m_minADX);
         }
         else
         {
            return "ADX unavailable - low volatility noise zone";
         }
      }
      else if(!m_useADX && m_rsiManager != NULL)
      {
         double rsi;
         if(m_rsiManager.GetRSIValue(symbol, rsi))
         {
            if(signalType == SIGNAL_BUY)
               return StringFormat("Weak bullish momentum (RSI: %.1f, min: %.1f)", rsi, m_minRSI_Momentum);
            else
               return StringFormat("Weak bearish momentum (RSI: %.1f, max: %.1f)", rsi, 100.0 - m_minRSI_Momentum);
         }
         else
         {
            return "RSI unavailable - low momentum noise zone";
         }
      }
   }
   
   // Check volume filter
   if(m_useVolumeFilter && !CheckVolumeFilter(symbol))
   {
      long currentVolume = iVolume(symbol, m_volumeTF, 1);  // Closed bar volume
      long volumes[];
      if(CopyTickVolume(symbol, m_volumeTF, 2, m_volumePeriod, volumes) >= m_volumePeriod)
      {
         long sumVolume = 0;
         for(int i = 0; i < m_volumePeriod; i++)
            sumVolume += volumes[i];
         long avgVolume = sumVolume / m_volumePeriod;
         
         if(avgVolume > 0)
         {
            double volumeRatio = (double)currentVolume / (double)avgVolume;
            return StringFormat("Low volume: %.2fx average (current: %lld, avg: %lld)", 
                             volumeRatio, currentVolume, avgVolume);
         }
      }
      return "Volume data unavailable";
   }
   
   return "Unknown filter rejection";
}

//+------------------------------------------------------------------+
//| Check volume filter                                              |
//| Only trigger signal if current candle's volume is higher than   |
//| the average volume of the last N candles                        |
//+------------------------------------------------------------------+
bool CNoiseFilter::CheckVolumeFilter(string symbol)
{
   if(!m_useVolumeFilter)
      return true;  // Filter disabled
   
   // ANTI-REPAINT: Get volume from closed bar (bar 1)
   long currentVolume = iVolume(symbol, m_volumeTF, 1);  // Closed bar volume
   
   // Get volumes for last N candles (excluding current closed bar)
   // We need volumes from bars 2 to (1 + volumePeriod) to calculate average
   long volumes[];
   int copied = CopyTickVolume(symbol, m_volumeTF, 2, m_volumePeriod, volumes);
   
   if(copied < m_volumePeriod)
   {
      // Not enough data - allow signal (filter disabled if insufficient data)
      return true;
   }
   
   // Calculate average volume of last N candles
   long sumVolume = 0;
   for(int i = 0; i < m_volumePeriod; i++)
   {
      sumVolume += volumes[i];
   }
   long avgVolume = sumVolume / m_volumePeriod;
   
   if(avgVolume == 0)
      return true;  // Avoid division by zero - allow signal
   
   // Check if current volume is higher than average
   // This ensures the move is backed by real market activity
   return (currentVolume > avgVolume);
}

//+------------------------------------------------------------------+

