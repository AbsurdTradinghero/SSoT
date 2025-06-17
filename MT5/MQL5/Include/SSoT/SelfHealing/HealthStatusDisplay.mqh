//+------------------------------------------------------------------+
//| HealthStatusDisplay.mqh                                          |
//| Small, contained class for displaying health status on panel    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include "HealthStatus.mqh"

//+------------------------------------------------------------------+
//| Health Status Display Class                                     |
//| Purpose: Lightweight visual health status display               |
//+------------------------------------------------------------------+
class CHealthStatusDisplay
{
private:
    string              m_panel_prefix;
    int                 m_base_x;
    int                 m_base_y;
    bool                m_visible;
    color               m_status_colors[6];
    
    // Display elements
    string              m_status_label;
    string              m_uptime_label;
    string              m_gaps_label;
    string              m_healing_label;
    
public:
    //--- Constructor/Destructor
    CHealthStatusDisplay();
    ~CHealthStatusDisplay();
    
    //--- Display Management
    bool                Initialize(const string panel_prefix, int x, int y);
    bool                CreateDisplay();
    bool                UpdateDisplay(const SHealthMetrics &metrics);
    bool                HideDisplay();
    bool                ShowDisplay();
    void                Cleanup();
    
    //--- Position and Style
    void                SetPosition(int x, int y);
    void                SetColors(color excellent, color good, color warning, color critical, color failed);
    
private:
    //--- Internal helpers
    color               GetStatusColor(HEALTH_STATUS_TYPE status);
    string              FormatHealthStatus(const SHealthMetrics &metrics);
    bool                CreateLabel(const string name, const string text, int x, int y, color clr);
    bool                UpdateLabel(const string name, const string text, color clr);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHealthStatusDisplay::CHealthStatusDisplay()
{
    m_panel_prefix = "SSoT_Health_";
    m_base_x = 10;
    m_base_y = 200;
    m_visible = false;
    
    // Initialize default colors
    m_status_colors[HEALTH_EXCELLENT] = clrLimeGreen;
    m_status_colors[HEALTH_GOOD] = clrGreen;
    m_status_colors[HEALTH_WARNING] = clrOrange;
    m_status_colors[HEALTH_CRITICAL] = clrRed;
    m_status_colors[HEALTH_FAILED] = clrDarkRed;
    m_status_colors[HEALTH_UNKNOWN] = clrGray;
    
    m_status_label = m_panel_prefix + "Status";
    m_uptime_label = m_panel_prefix + "Uptime";
    m_gaps_label = m_panel_prefix + "Gaps";
    m_healing_label = m_panel_prefix + "Healing";
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CHealthStatusDisplay::~CHealthStatusDisplay()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the display                                          |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::Initialize(const string panel_prefix, int x, int y)
{
    m_panel_prefix = panel_prefix + "_Health_";
    m_base_x = x;
    m_base_y = y;
    
    // Update label names with new prefix
    m_status_label = m_panel_prefix + "Status";
    m_uptime_label = m_panel_prefix + "Uptime";
    m_gaps_label = m_panel_prefix + "Gaps";
    m_healing_label = m_panel_prefix + "Healing";
    
    return CreateDisplay();
}

//+------------------------------------------------------------------+
//| Create display elements                                         |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::CreateDisplay()
{
    // Create status labels
    if(!CreateLabel(m_status_label, "Health: UNKNOWN", m_base_x, m_base_y, clrGray)) return false;
    if(!CreateLabel(m_uptime_label, "Uptime: --", m_base_x, m_base_y + 15, clrGray)) return false;
    if(!CreateLabel(m_gaps_label, "Gaps: --", m_base_x, m_base_y + 30, clrGray)) return false;
    if(!CreateLabel(m_healing_label, "Healing: --", m_base_x, m_base_y + 45, clrGray)) return false;
    
    m_visible = true;
    return true;
}

//+------------------------------------------------------------------+
//| Update display with new metrics                                |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::UpdateDisplay(const SHealthMetrics &metrics)
{
    if(!m_visible) return false;
    
    // Update status
    string status_text = "Health: " + StatusToString(metrics.overall_status);
    color status_color = GetStatusColor(metrics.overall_status);
    UpdateLabel(m_status_label, status_text, status_color);
    
    // Update uptime
    string uptime_text = StringFormat("Uptime: %.1f%%", metrics.uptime_percentage);
    color uptime_color = metrics.uptime_percentage >= 95.0 ? clrGreen : 
                        metrics.uptime_percentage >= 90.0 ? clrOrange : clrRed;
    UpdateLabel(m_uptime_label, uptime_text, uptime_color);
    
    // Update gaps
    string gaps_text = StringFormat("Gaps: %d", metrics.gaps_detected);
    color gaps_color = metrics.gaps_detected == 0 ? clrGreen :
                      metrics.gaps_detected <= 5 ? clrOrange : clrRed;
    UpdateLabel(m_gaps_label, gaps_text, gaps_color);
    
    // Update healing success rate
    int healing_rate = metrics.healing_attempts > 0 ? 
                      (int)((double)metrics.successful_heals / metrics.healing_attempts * 100.0) : 100;
    string healing_text = StringFormat("Healing: %d%% (%d/%d)", 
                                     healing_rate, metrics.successful_heals, metrics.healing_attempts);
    color healing_color = healing_rate >= 90 ? clrGreen :
                         healing_rate >= 70 ? clrOrange : clrRed;
    UpdateLabel(m_healing_label, healing_text, healing_color);
    
    return true;
}

//+------------------------------------------------------------------+
//| Hide display                                                    |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::HideDisplay()
{
    if(!m_visible) return true;
    
    ObjectSetInteger(0, m_status_label, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    ObjectSetInteger(0, m_uptime_label, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    ObjectSetInteger(0, m_gaps_label, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    ObjectSetInteger(0, m_healing_label, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    
    return true;
}

//+------------------------------------------------------------------+
//| Show display                                                    |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::ShowDisplay()
{
    if(!m_visible) return CreateDisplay();
    
    ObjectSetInteger(0, m_status_label, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    ObjectSetInteger(0, m_uptime_label, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    ObjectSetInteger(0, m_gaps_label, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    ObjectSetInteger(0, m_healing_label, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup all display elements                                   |
//+------------------------------------------------------------------+
void CHealthStatusDisplay::Cleanup()
{
    if(m_visible) {
        ObjectDelete(0, m_status_label);
        ObjectDelete(0, m_uptime_label);
        ObjectDelete(0, m_gaps_label);
        ObjectDelete(0, m_healing_label);
        m_visible = false;
    }
}

//+------------------------------------------------------------------+
//| Set display position                                            |
//+------------------------------------------------------------------+
void CHealthStatusDisplay::SetPosition(int x, int y)
{
    m_base_x = x;
    m_base_y = y;
    
    if(m_visible) {
        ObjectSetInteger(0, m_status_label, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, m_status_label, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, m_uptime_label, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, m_uptime_label, OBJPROP_YDISTANCE, y + 15);
        ObjectSetInteger(0, m_gaps_label, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, m_gaps_label, OBJPROP_YDISTANCE, y + 30);
        ObjectSetInteger(0, m_healing_label, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, m_healing_label, OBJPROP_YDISTANCE, y + 45);
    }
}

//+------------------------------------------------------------------+
//| Get status color                                               |
//+------------------------------------------------------------------+
color CHealthStatusDisplay::GetStatusColor(HEALTH_STATUS_TYPE status)
{
    if(status >= 0 && status < 6) {
        return m_status_colors[status];
    }
    return clrGray;
}

//+------------------------------------------------------------------+
//| Create a label                                                  |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::CreateLabel(const string name, const string text, int x, int y, color clr)
{
    if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial");
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Update a label                                                  |
//+------------------------------------------------------------------+
bool CHealthStatusDisplay::UpdateLabel(const string name, const string text, color clr)
{
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    return true;
}

//+------------------------------------------------------------------+
//| Convert status to string (helper method)                       |
//+------------------------------------------------------------------+
string StatusToString(HEALTH_STATUS_TYPE status)
{
    switch(status)
    {
        case HEALTH_EXCELLENT: return "EXCELLENT";
        case HEALTH_GOOD: return "GOOD";
        case HEALTH_WARNING: return "WARNING";
        case HEALTH_CRITICAL: return "CRITICAL";
        case HEALTH_FAILED: return "FAILED";
        default: return "UNKNOWN";
    }
}
