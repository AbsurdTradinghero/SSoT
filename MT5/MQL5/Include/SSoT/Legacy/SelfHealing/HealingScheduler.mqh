//+------------------------------------------------------------------+
//| HealingScheduler.mqh                                             |
//| Small, contained class for scheduling healing operations        |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//--- Healing task structure
struct SHealingTask
{
    int                 task_id;
    string              task_type;
    string              target_resource;
    datetime            scheduled_time;
    datetime            last_execution;
    int                 priority;          // 1=highest, 5=lowest
    int                 max_retries;
    int                 current_retries;
    bool                is_recurring;
    int                 interval_seconds;
    bool                is_active;
    string              parameters;
};

//+------------------------------------------------------------------+
//| Healing Scheduler Class                                         |
//| Purpose: Schedule and manage healing task execution             |
//+------------------------------------------------------------------+
class CHealingScheduler
{
private:
    SHealingTask        m_tasks[50];       // Maximum 50 scheduled tasks
    int                 m_task_count;
    int                 m_next_task_id;
    datetime            m_last_cleanup;
    
    // Private methods
    bool                SortTasksByPriority();
    bool                IsTaskDue(const SHealingTask &task) const;
    bool                ShouldRetryTask(const SHealingTask &task) const;
    
public:
    //--- Constructor/Destructor
    CHealingScheduler();
    ~CHealingScheduler();
    
    //--- Task Management
    int                 ScheduleTask(const string task_type, const string target, 
                                   datetime scheduled_time, int priority = 3,
                                   bool recurring = false, int interval = 0);
    bool                CancelTask(int task_id);
    bool                UpdateTask(int task_id, const SHealingTask &updated_task);
    
    //--- Task Execution
    SHealingTask        GetNextDueTask();
    bool                MarkTaskCompleted(int task_id, bool success);
    bool                MarkTaskFailed(int task_id);
    
    //--- Task Queries
    int                 GetPendingTaskCount() const;
    int                 GetOverdueTaskCount() const;
    SHealingTask        GetTask(int task_id) const;
    bool                HasHighPriorityTasks() const;
    
    //--- Maintenance
    bool                CleanupCompletedTasks();
    bool                ProcessDueTasks();
    string              GetScheduleStatus() const;
    
    //--- Predefined Task Templates
    int                 ScheduleDataIntegrityCheck(datetime when, bool recurring = true);
    int                 ScheduleConnectionHealth(datetime when, bool recurring = true);
    int                 ScheduleGapDetection(datetime when, bool recurring = true);
    int                 ScheduleEmergencyHealing(const string target);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHealingScheduler::CHealingScheduler()
{
    m_task_count = 0;
    m_next_task_id = 1;
    m_last_cleanup = TimeCurrent();
    
    // Initialize task array
    for(int i = 0; i < 50; i++)
    {
        m_tasks[i].task_id = 0;
        m_tasks[i].task_type = "";
        m_tasks[i].target_resource = "";
        m_tasks[i].scheduled_time = 0;
        m_tasks[i].last_execution = 0;
        m_tasks[i].priority = 3;
        m_tasks[i].max_retries = 3;
        m_tasks[i].current_retries = 0;
        m_tasks[i].is_recurring = false;
        m_tasks[i].interval_seconds = 0;
        m_tasks[i].is_active = false;
        m_tasks[i].parameters = "";
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CHealingScheduler::~CHealingScheduler()
{
    // Nothing to clean up for this simple class
}

//+------------------------------------------------------------------+
//| Schedule a new healing task                                     |
//+------------------------------------------------------------------+
int CHealingScheduler::ScheduleTask(const string task_type, const string target,
                                   datetime scheduled_time, int priority = 3,
                                   bool recurring = false, int interval = 0)
{
    if(m_task_count >= 50)
    {
        Print("[SCHEDULER] ERROR: Maximum tasks reached (50)");
        return -1;
    }
    
    // Find empty slot
    int slot = -1;
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == 0)
        {
            slot = i;
            break;
        }
    }
    
    if(slot == -1)
    {
        Print("[SCHEDULER] ERROR: No available task slots");
        return -1;
    }
    
    // Create new task
    m_tasks[slot].task_id = m_next_task_id++;
    m_tasks[slot].task_type = task_type;
    m_tasks[slot].target_resource = target;
    m_tasks[slot].scheduled_time = scheduled_time;
    m_tasks[slot].last_execution = 0;
    m_tasks[slot].priority = MathMax(1, MathMin(5, priority));
    m_tasks[slot].max_retries = 3;
    m_tasks[slot].current_retries = 0;
    m_tasks[slot].is_recurring = recurring;
    m_tasks[slot].interval_seconds = interval;
    m_tasks[slot].is_active = true;
    m_tasks[slot].parameters = "";
    
    m_task_count++;
    
    Print(StringFormat("[SCHEDULER] Task %d scheduled: %s for %s at %s",
          m_tasks[slot].task_id, task_type, target, TimeToString(scheduled_time)));
    
    return m_tasks[slot].task_id;
}

//+------------------------------------------------------------------+
//| Cancel a scheduled task                                         |
//+------------------------------------------------------------------+
bool CHealingScheduler::CancelTask(int task_id)
{
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == task_id)
        {
            m_tasks[i].task_id = 0;
            m_tasks[i].is_active = false;
            m_task_count--;
            Print(StringFormat("[SCHEDULER] Task %d cancelled", task_id));
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get next due task for execution                                 |
//+------------------------------------------------------------------+
SHealingTask CHealingScheduler::GetNextDueTask()
{
    SHealingTask empty_task = {0};
    SHealingTask best_task = {0};
    int best_priority = 6;
    datetime current_time = TimeCurrent();
    
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == 0 || !m_tasks[i].is_active) continue;
        
        if(IsTaskDue(m_tasks[i]) && m_tasks[i].priority < best_priority)
        {
            best_task = m_tasks[i];
            best_priority = m_tasks[i].priority;
        }
    }
    
    return best_task.task_id > 0 ? best_task : empty_task;
}

//+------------------------------------------------------------------+
//| Mark task as completed                                          |
//+------------------------------------------------------------------+
bool CHealingScheduler::MarkTaskCompleted(int task_id, bool success)
{
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == task_id)
        {
            m_tasks[i].last_execution = TimeCurrent();
            
            if(success)
            {
                m_tasks[i].current_retries = 0;
                
                if(m_tasks[i].is_recurring)
                {
                    // Schedule next execution
                    m_tasks[i].scheduled_time = TimeCurrent() + m_tasks[i].interval_seconds;
                }
                else
                {
                    // Remove one-time task
                    m_tasks[i].task_id = 0;
                    m_tasks[i].is_active = false;
                    m_task_count--;
                }
                
                Print(StringFormat("[SCHEDULER] Task %d completed successfully", task_id));
                return true;
            }
            else
            {
                return MarkTaskFailed(task_id);
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Mark task as failed and handle retry logic                     |
//+------------------------------------------------------------------+
bool CHealingScheduler::MarkTaskFailed(int task_id)
{
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == task_id)
        {
            m_tasks[i].current_retries++;
            
            if(m_tasks[i].current_retries >= m_tasks[i].max_retries)
            {
                // Max retries reached
                Print(StringFormat("[SCHEDULER] Task %d failed after %d retries", 
                      task_id, m_tasks[i].max_retries));
                m_tasks[i].task_id = 0;
                m_tasks[i].is_active = false;
                m_task_count--;
            }
            else
            {
                // Schedule retry in 5 minutes
                m_tasks[i].scheduled_time = TimeCurrent() + 300;
                Print(StringFormat("[SCHEDULER] Task %d failed, retry %d/%d scheduled",
                      task_id, m_tasks[i].current_retries, m_tasks[i].max_retries));
            }
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if task is due for execution                             |
//+------------------------------------------------------------------+
bool CHealingScheduler::IsTaskDue(const SHealingTask &task) const
{
    return (task.is_active && TimeCurrent() >= task.scheduled_time);
}

//+------------------------------------------------------------------+
//| Get count of pending tasks                                      |
//+------------------------------------------------------------------+
int CHealingScheduler::GetPendingTaskCount() const
{
    return m_task_count;
}

//+------------------------------------------------------------------+
//| Get count of overdue tasks                                      |
//+------------------------------------------------------------------+
int CHealingScheduler::GetOverdueTaskCount() const
{
    int overdue = 0;
    datetime current_time = TimeCurrent();
    
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id > 0 && m_tasks[i].is_active &&
           current_time > m_tasks[i].scheduled_time + 300) // 5 minutes overdue
        {
            overdue++;
        }
    }
    
    return overdue;
}

//+------------------------------------------------------------------+
//| Check if there are high priority tasks                         |
//+------------------------------------------------------------------+
bool CHealingScheduler::HasHighPriorityTasks() const
{
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id > 0 && m_tasks[i].is_active && 
           m_tasks[i].priority <= 2 && IsTaskDue(m_tasks[i]))
        {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cleanup completed tasks                                         |
//+------------------------------------------------------------------+
bool CHealingScheduler::CleanupCompletedTasks()
{
    if(TimeCurrent() - m_last_cleanup < 3600) return true; // Cleanup once per hour
    
    int cleaned = 0;
    for(int i = 0; i < 50; i++)
    {
        if(m_tasks[i].task_id == 0) continue;
        
        // Remove old completed non-recurring tasks
        if(!m_tasks[i].is_active && !m_tasks[i].is_recurring &&
           TimeCurrent() - m_tasks[i].last_execution > 86400) // 24 hours old
        {
            m_tasks[i].task_id = 0;
            cleaned++;
        }
    }
    
    m_last_cleanup = TimeCurrent();
    
    if(cleaned > 0)
    {
        Print(StringFormat("[SCHEDULER] Cleaned up %d old tasks", cleaned));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get scheduler status report                                     |
//+------------------------------------------------------------------+
string CHealingScheduler::GetScheduleStatus() const
{
    string status = "=== HEALING SCHEDULER STATUS ===\n";
    status += StringFormat("Active Tasks: %d/50\n", m_task_count);
    status += StringFormat("Overdue Tasks: %d\n", GetOverdueTaskCount());
    status += StringFormat("High Priority Pending: %s\n", HasHighPriorityTasks() ? "YES" : "NO");
    
    return status;
}

//+------------------------------------------------------------------+
//| Schedule data integrity check                                   |
//+------------------------------------------------------------------+
int CHealingScheduler::ScheduleDataIntegrityCheck(datetime when, bool recurring = true)
{
    return ScheduleTask("DataIntegrityCheck", "ALL_DATABASES", when, 2, recurring, 3600);
}

//+------------------------------------------------------------------+
//| Schedule connection health check                                |
//+------------------------------------------------------------------+
int CHealingScheduler::ScheduleConnectionHealth(datetime when, bool recurring = true)
{
    return ScheduleTask("ConnectionHealth", "ALL_CONNECTIONS", when, 2, recurring, 1800);
}

//+------------------------------------------------------------------+
//| Schedule gap detection                                          |
//+------------------------------------------------------------------+
int CHealingScheduler::ScheduleGapDetection(datetime when, bool recurring = true)
{
    return ScheduleTask("GapDetection", "ALL_SYMBOLS", when, 3, recurring, 900);
}

//+------------------------------------------------------------------+
//| Schedule emergency healing (highest priority)                  |
//+------------------------------------------------------------------+
int CHealingScheduler::ScheduleEmergencyHealing(const string target)
{
    return ScheduleTask("EmergencyHeal", target, TimeCurrent(), 1, false, 0);
}
