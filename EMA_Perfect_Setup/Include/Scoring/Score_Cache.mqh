//+------------------------------------------------------------------+
//| Score_Cache.mqh                                                   |
//| Caching system for scoring calculations to reduce CPU usage       |
//+------------------------------------------------------------------+

#include "../Config.mqh"
#include "../Structs.mqh"
#include "../Utilities/Price_Utils.mqh"

//+------------------------------------------------------------------+
//| Cached indicator data structure                                  |
//+------------------------------------------------------------------+
struct CachedIndicatorData
{
   datetime lastUpdate;
   string symbol;
   
   // H1 EMA data
   double emaFastH1[];
   double emaMediumH1[];
   double emaSlowH1[];
   bool h1DataValid;
   
   // M5 EMA data
   double emaFastM5[];
   double emaMediumM5[];
   double emaSlowM5[];
   bool m5DataValid;
   
   // M5 EMA separation (cached)
   double emaSeparationM5;
   bool separationValid;
   
   // RSI data
   double rsiValue;
   bool rsiValid;
   
   // Price data
   double priceH1;
   double priceM5;
   bool priceValid;
   
   // Spread (cached)
   double spreadPips;
   bool spreadValid;
   
   // Market data
   long volume;
   bool volumeValid;
};

//+------------------------------------------------------------------+
//| Score Cache Class                                                 |
//+------------------------------------------------------------------+
class CScoreCache
{
private:
   CachedIndicatorData m_cache[];
   int m_cacheSize;
   datetime m_cacheTimeout; // Cache timeout in seconds
   static const int MAX_CACHE_SIZE = 10; // OPTIMIZATION: Limit cache size to prevent O(n) lookup degradation
   
   int FindCacheIndex(string symbol);
   void InvalidateCache(int index);
   void TrimCache(); // OPTIMIZATION: Remove oldest entries when cache is full
   
public:
   CScoreCache(int timeoutSeconds = 1);
   ~CScoreCache();
   
   bool GetH1EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaH1);
   bool GetM5EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaM5);
   double GetEMASeparation(string symbol, CEMAManager *emaM5);
   double GetRSIValue(string symbol, CRSIManager *rsi);
   double GetPriceH1(string symbol);
   double GetPriceM5(string symbol);
   double GetSpreadPips(string symbol);
   long GetVolume(string symbol);
   
   void ClearCache();
   void ClearSymbolCache(string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CScoreCache::CScoreCache(int timeoutSeconds = 1)
{
   ArrayResize(m_cache, 0);
   m_cacheSize = 0;
   m_cacheTimeout = timeoutSeconds;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CScoreCache::~CScoreCache()
{
   ClearCache();
}

//+------------------------------------------------------------------+
//| Find cache index for symbol (optimized with early exit)          |
//+------------------------------------------------------------------+
int CScoreCache::FindCacheIndex(string symbol)
{
   // OPTIMIZATION: Early exit if cache is empty
   if(m_cacheSize == 0) return -1;
   
   // OPTIMIZATION: Linear search with early exit (O(n) but n is limited to MAX_CACHE_SIZE)
   // Most common case: symbol found at beginning of array
   for(int i = 0; i < m_cacheSize; i++)
   {
      // OPTIMIZATION: String comparison is fast in MQL5
      if(m_cache[i].symbol == symbol)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Trim cache to prevent excessive growth                          |
//+------------------------------------------------------------------+
void CScoreCache::TrimCache()
{
   // OPTIMIZATION: Remove oldest entries when cache exceeds MAX_CACHE_SIZE
   if(m_cacheSize <= MAX_CACHE_SIZE) return;
   
   // Find oldest entry (lowest lastUpdate)
   int oldestIndex = 0;
   datetime oldestTime = m_cache[0].lastUpdate;
   for(int i = 1; i < m_cacheSize; i++)
   {
      if(m_cache[i].lastUpdate < oldestTime)
      {
         oldestTime = m_cache[i].lastUpdate;
         oldestIndex = i;
      }
   }
   
   // Remove oldest entry by shifting array
   for(int i = oldestIndex; i < m_cacheSize - 1; i++)
   {
      m_cache[i] = m_cache[i + 1];
   }
   m_cacheSize--;
   ArrayResize(m_cache, m_cacheSize);
}

//+------------------------------------------------------------------+
//| Invalidate cache entry                                           |
//+------------------------------------------------------------------+
void CScoreCache::InvalidateCache(int index)
{
   if(index >= 0 && index < m_cacheSize)
   {
      m_cache[index].h1DataValid = false;
      m_cache[index].m5DataValid = false;
      m_cache[index].separationValid = false;
      m_cache[index].rsiValid = false;
      m_cache[index].priceValid = false;
      m_cache[index].spreadValid = false;
      m_cache[index].volumeValid = false;
   }
}

//+------------------------------------------------------------------+
//| Get H1 EMA data (cached)                                        |
//+------------------------------------------------------------------+
bool CScoreCache::GetH1EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaH1)
{
   if(emaH1 == NULL) return false;
   
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // OPTIMIZATION: Check cache validity first (fast path)
   if(index >= 0)
   {
      datetime timeDiff = current - m_cache[index].lastUpdate;
      if(m_cache[index].h1DataValid && timeDiff < m_cacheTimeout && timeDiff >= 0)
      {
         // Return cached data (fast path - no API calls)
         int cacheSize = ArraySize(m_cache[index].emaFastH1);
         if(cacheSize > 0)
         {
            ArrayResize(emaFast, cacheSize);
            ArrayResize(emaMedium, cacheSize);
            ArrayResize(emaSlow, cacheSize);
            ArrayCopy(emaFast, m_cache[index].emaFastH1, 0, 0, WHOLE_ARRAY);
            ArrayCopy(emaMedium, m_cache[index].emaMediumH1, 0, 0, WHOLE_ARRAY);
            ArrayCopy(emaSlow, m_cache[index].emaSlowH1, 0, 0, WHOLE_ARRAY);
            return true;
         }
      }
   }
   
   // Cache miss or expired - fetch new data (slow path)
   if(!emaH1.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   // OPTIMIZATION: Update cache efficiently
   if(index < 0)
   {
      // OPTIMIZATION: Trim cache if it's getting too large
      if(m_cacheSize >= MAX_CACHE_SIZE)
         TrimCache();
      
      // Create new cache entry
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   // OPTIMIZATION: Resize arrays only if needed
   int dataSize = ArraySize(emaFast);
   if(ArraySize(m_cache[index].emaFastH1) != dataSize)
   {
      ArrayResize(m_cache[index].emaFastH1, dataSize);
      ArrayResize(m_cache[index].emaMediumH1, dataSize);
      ArrayResize(m_cache[index].emaSlowH1, dataSize);
   }
   
   // Copy data efficiently
   ArrayCopy(m_cache[index].emaFastH1, emaFast, 0, 0, WHOLE_ARRAY);
   ArrayCopy(m_cache[index].emaMediumH1, emaMedium, 0, 0, WHOLE_ARRAY);
   ArrayCopy(m_cache[index].emaSlowH1, emaSlow, 0, 0, WHOLE_ARRAY);
   
   m_cache[index].h1DataValid = true;
   m_cache[index].lastUpdate = current;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get M5 EMA data (cached)                                        |
//+------------------------------------------------------------------+
bool CScoreCache::GetM5EMAData(string symbol, double &emaFast[], double &emaMedium[], double &emaSlow[], CEMAManager *emaM5)
{
   if(emaM5 == NULL) return false;
   
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // OPTIMIZATION: Check cache validity first (fast path)
   if(index >= 0)
   {
      datetime timeDiff = current - m_cache[index].lastUpdate;
      if(m_cache[index].m5DataValid && timeDiff < m_cacheTimeout && timeDiff >= 0)
      {
         // Return cached data (fast path - no API calls)
         int cacheSize = ArraySize(m_cache[index].emaFastM5);
         if(cacheSize > 0)
         {
            ArrayResize(emaFast, cacheSize);
            ArrayResize(emaMedium, cacheSize);
            ArrayResize(emaSlow, cacheSize);
            ArrayCopy(emaFast, m_cache[index].emaFastM5, 0, 0, WHOLE_ARRAY);
            ArrayCopy(emaMedium, m_cache[index].emaMediumM5, 0, 0, WHOLE_ARRAY);
            ArrayCopy(emaSlow, m_cache[index].emaSlowM5, 0, 0, WHOLE_ARRAY);
            return true;
         }
      }
   }
   
   // Cache miss or expired - fetch new data (slow path)
   if(!emaM5.GetEMAData(symbol, emaFast, emaMedium, emaSlow))
      return false;
   
   // OPTIMIZATION: Update cache efficiently
   if(index < 0)
   {
      // OPTIMIZATION: Trim cache if it's getting too large
      if(m_cacheSize >= MAX_CACHE_SIZE)
         TrimCache();
      
      // Create new cache entry
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   // OPTIMIZATION: Resize arrays only if needed
   int dataSize = ArraySize(emaFast);
   if(ArraySize(m_cache[index].emaFastM5) != dataSize)
   {
      ArrayResize(m_cache[index].emaFastM5, dataSize);
      ArrayResize(m_cache[index].emaMediumM5, dataSize);
      ArrayResize(m_cache[index].emaSlowM5, dataSize);
   }
   
   // Copy data efficiently
   ArrayCopy(m_cache[index].emaFastM5, emaFast, 0, 0, WHOLE_ARRAY);
   ArrayCopy(m_cache[index].emaMediumM5, emaMedium, 0, 0, WHOLE_ARRAY);
   ArrayCopy(m_cache[index].emaSlowM5, emaSlow, 0, 0, WHOLE_ARRAY);
   
   m_cache[index].m5DataValid = true;
   m_cache[index].lastUpdate = current;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get EMA separation (cached)                                      |
//+------------------------------------------------------------------+
double CScoreCache::GetEMASeparation(string symbol, CEMAManager *emaM5)
{
   if(emaM5 == NULL) return 0.0;
   
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // Check if cache exists and is valid
   if(index >= 0)
   {
      if(m_cache[index].separationValid && 
         (current - m_cache[index].lastUpdate) < m_cacheTimeout)
      {
         return m_cache[index].emaSeparationM5;
      }
   }
   
   // Cache miss or expired - calculate new value
   double separation = emaM5.GetEMASeparation(symbol, PERIOD_M5);
   
   // Update cache
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].emaSeparationM5 = separation;
   m_cache[index].separationValid = true;
   m_cache[index].lastUpdate = current;
   
   return separation;
}

//+------------------------------------------------------------------+
//| Get RSI value (cached)                                          |
//+------------------------------------------------------------------+
double CScoreCache::GetRSIValue(string symbol, CRSIManager *rsi)
{
   if(rsi == NULL) return 50.0; // Neutral default
   
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // Check if cache exists and is valid
   if(index >= 0)
   {
      if(m_cache[index].rsiValid && 
         (current - m_cache[index].lastUpdate) < m_cacheTimeout)
      {
         return m_cache[index].rsiValue;
      }
   }
   
   // Cache miss or expired - fetch new value
   double rsiValue = 50.0; // Default neutral value
   if(rsi != NULL)
   {
      if(!rsi.GetRSIValue(symbol, rsiValue))
         rsiValue = 50.0; // Default if failed
   }
   
   // Update cache
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].rsiValue = rsiValue;
   m_cache[index].rsiValid = true;
   m_cache[index].lastUpdate = current;
   
   return rsiValue;
}

//+------------------------------------------------------------------+
//| Get H1 price (cached)                                           |
//+------------------------------------------------------------------+
double CScoreCache::GetPriceH1(string symbol)
{
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // OPTIMIZATION: Check cache validity first (fast path)
   if(index >= 0)
   {
      datetime timeDiff = current - m_cache[index].lastUpdate;
      if(m_cache[index].priceValid && timeDiff < m_cacheTimeout && timeDiff >= 0)
      {
         return m_cache[index].priceH1; // Fast path - return cached value
      }
   }
   
   // Cache miss or expired - fetch new value (slow path)
   double price = iClose(symbol, PERIOD_H1, 0);
   
   // OPTIMIZATION: Update cache efficiently
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].priceH1 = price;
   m_cache[index].priceValid = true;
   m_cache[index].lastUpdate = current;
   
   return price;
}

//+------------------------------------------------------------------+
//| Get M5 price (cached)                                           |
//+------------------------------------------------------------------+
double CScoreCache::GetPriceM5(string symbol)
{
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // Check if cache exists and is valid
   if(index >= 0)
   {
      if(m_cache[index].priceValid && 
         (current - m_cache[index].lastUpdate) < m_cacheTimeout)
      {
         return m_cache[index].priceM5;
      }
   }
   
   // Cache miss or expired - fetch new value
   double price = iClose(symbol, PERIOD_M5, 0);
   
   // Update cache
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].priceM5 = price;
   m_cache[index].priceValid = true;
   m_cache[index].lastUpdate = current;
   
   return price;
}

//+------------------------------------------------------------------+
//| Get spread in pips (cached)                                     |
//+------------------------------------------------------------------+
double CScoreCache::GetSpreadPips(string symbol)
{
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // Check if cache exists and is valid
   if(index >= 0)
   {
      if(m_cache[index].spreadValid && 
         (current - m_cache[index].lastUpdate) < m_cacheTimeout)
      {
         return m_cache[index].spreadPips;
      }
   }
   
   // Cache miss or expired - calculate new value (slow path)
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(ask == 0 || bid == 0) return 0.0; // Invalid data
   double spread = MathAbs(ask - bid);
   spread = PriceToPips(symbol, spread); // Convert to pips
   
   // Update cache
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].spreadPips = spread;
   m_cache[index].spreadValid = true;
   m_cache[index].lastUpdate = current;
   
   return spread;
}

//+------------------------------------------------------------------+
//| Get volume (cached)                                              |
//+------------------------------------------------------------------+
long CScoreCache::GetVolume(string symbol)
{
   int index = FindCacheIndex(symbol);
   datetime current = TimeCurrent();
   
   // OPTIMIZATION: Check cache validity first (fast path)
   if(index >= 0)
   {
      datetime timeDiff = current - m_cache[index].lastUpdate;
      if(m_cache[index].volumeValid && timeDiff < m_cacheTimeout && timeDiff >= 0)
      {
         return m_cache[index].volume; // Fast path - return cached value
      }
   }
   
   // Cache miss or expired - fetch new value (slow path)
   long volume = iVolume(symbol, PERIOD_M5, 0);
   
   // OPTIMIZATION: Update cache efficiently
   if(index < 0)
   {
      index = m_cacheSize;
      ArrayResize(m_cache, m_cacheSize + 1);
      m_cache[index].symbol = symbol;
      m_cacheSize++;
   }
   
   m_cache[index].volume = volume;
   m_cache[index].volumeValid = true;
   m_cache[index].lastUpdate = current;
   
   return volume;
}

//+------------------------------------------------------------------+
//| Clear all cache                                                  |
//+------------------------------------------------------------------+
void CScoreCache::ClearCache()
{
   ArrayResize(m_cache, 0);
   m_cacheSize = 0;
}

//+------------------------------------------------------------------+
//| Clear cache for specific symbol                                 |
//+------------------------------------------------------------------+
void CScoreCache::ClearSymbolCache(string symbol)
{
   int index = FindCacheIndex(symbol);
   if(index >= 0)
   {
      InvalidateCache(index);
   }
}

//+------------------------------------------------------------------+

