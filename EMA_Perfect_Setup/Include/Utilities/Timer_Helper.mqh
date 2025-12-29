//+------------------------------------------------------------------+
//| Timer_Helper.mqh                                                 |
//| Timer-based utilities for delayed actions                         |
//+------------------------------------------------------------------+

#include "../Config.mqh"

//+------------------------------------------------------------------+
//| Timer Helper Class for delayed actions                           |
//+------------------------------------------------------------------+
class CTimerHelper
{
private:
   struct TimerAction
   {
      datetime executeTime;
      string actionName;
      bool executed;
   };
   
   TimerAction m_actions[];
   int m_actionCount;
   
public:
   CTimerHelper();
   ~CTimerHelper();
   
   void AddDelayedAction(string actionName, int delayMs);
   void ProcessActions();
   void Clear();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTimerHelper::CTimerHelper()
{
   ArrayResize(m_actions, 0);
   m_actionCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTimerHelper::~CTimerHelper()
{
   Clear();
}

//+------------------------------------------------------------------+
//| Add delayed action                                               |
//+------------------------------------------------------------------+
void CTimerHelper::AddDelayedAction(string actionName, int delayMs)
{
   TimerAction action;
   action.executeTime = TimeCurrent() + delayMs / 1000;
   action.actionName = actionName;
   action.executed = false;
   
   ArrayResize(m_actions, m_actionCount + 1);
   m_actions[m_actionCount] = action;
   m_actionCount++;
}

//+------------------------------------------------------------------+
//| Process pending actions                                          |
//+------------------------------------------------------------------+
void CTimerHelper::ProcessActions()
{
   datetime current = TimeCurrent();
   
   for(int i = 0; i < m_actionCount; i++)
   {
      if(!m_actions[i].executed && current >= m_actions[i].executeTime)
      {
         // Action time reached - execute it
         // This is a framework - actual execution would be handled by callback
         m_actions[i].executed = true;
      }
   }
   
   // Remove executed actions
   int newCount = 0;
   TimerAction newActions[];
   ArrayResize(newActions, m_actionCount);
   
   for(int i = 0; i < m_actionCount; i++)
   {
      if(!m_actions[i].executed)
      {
         newActions[newCount] = m_actions[i];
         newCount++;
      }
   }
   
   ArrayResize(m_actions, newCount);
   ArrayCopy(m_actions, newActions, 0, 0, newCount);
   m_actionCount = newCount;
}

//+------------------------------------------------------------------+
//| Clear all actions                                                |
//+------------------------------------------------------------------+
void CTimerHelper::Clear()
{
   ArrayResize(m_actions, 0);
   m_actionCount = 0;
}

//+------------------------------------------------------------------+

