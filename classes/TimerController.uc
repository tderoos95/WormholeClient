class TimerController extends Info;

struct TimerEntry {
    var string CallbackTopic;
    var int Interval;
    var bool bRepeat;
    var float ElapsesAt;
    var bool bHandled;
};

var array<TimerEntry> ActiveTimers;
var float NextTimerElapse;
var EventGrid EventGrid;
var WormholeSettings Settings;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    EventGrid = MutWormhole(Owner).EventGrid;
    Settings = MutWormhole(Owner).Settings;

    SetTimer(1, true);
}

function CreateTimer(string CallbackTopic, int Interval, optional bool bRepeat)
{
    local int NewIndex;

    if(TimerExists(CallbackTopic))
        return;

    NewIndex = ActiveTimers.length;
    ActiveTimers.length = NewIndex + 1;

    ActiveTimers[NewIndex].CallbackTopic = CallbackTopic;
    ActiveTimers[NewIndex].Interval = Interval;
    ActiveTimers[NewIndex].bRepeat = bRepeat;
    ActiveTimers[NewIndex].ElapsesAt = Level.TimeSeconds + Interval;
    CalculateNextTimerElapse();
}

function DestroyTimer(string CallbackTopic)
{
    local int i;

    for(i = 0; i < ActiveTimers.length; i++)
    {
        if(ActiveTimers[i].CallbackTopic ~= CallbackTopic)
        {
            ActiveTimers.Remove(i, 1);
            break;
        }
    }

    CalculateNextTimerElapse();
}

function bool TimerExists(string CallbackTopic)
{
    local int i;

    for(i = 0; i < ActiveTimers.length; i++)
    {
        if(ActiveTimers[i].CallbackTopic ~= CallbackTopic)
            return true;
    }
}

function Timer()
{
    if(NextTimerElapse != 0 && NextTimerElapse <= Level.TimeSeconds)
    {
        NextTimerElapse = 0;
        OnTimerElapsed();
    }
}

function OnTimerElapsed()
{
    local int i;

    for(i = 0; i < ActiveTimers.length; i++)
    {
        if(ActiveTimers[i].ElapsesAt <= Level.TimeSeconds && !ActiveTimers[i].bHandled)
        {
            ActiveTimers[i].bHandled = true;
            PerformCallback(ActiveTimers[i].CallbackTopic);

            if(ActiveTimers[i].bRepeat)
            {
                ActiveTimers[i].ElapsesAt = Level.TimeSeconds + ActiveTimers[i].Interval;
                ActiveTimers[i].bHandled = false;
            }
            else
            {
                ActiveTimers.Remove(i, 1);
            }
        }
    }

    CalculateNextTimerElapse();
}


function CalculateNextTimerElapse()
{
    local int i, NearestElapse;

    if(ActiveTimers.length == 0)
    {
        NextTimerElapse = 0;
        SendDebugDataToEventGrid("wormhole/debug/timer/nonextelapse_" $ NextTimerElapse, None);
        return;
    }

    NearestElapse = ActiveTimers[0].ElapsesAt;

    for (i = 0; i < ActiveTimers.length; i++)
    {
        if(ActiveTimers[i].ElapsesAt < NearestElapse)
            NearestElapse = ActiveTimers[i].ElapsesAt;
    }

    NextTimerElapse = NearestElapse;
    //SendDebugDataToEventGrid("wormhole/debug/timer/nextelapse_at_" $ string(NextTimerElapse), None);
}

function PerformCallback(string CallbackTopic)
{
    log("Timer '" $ CallbackTopic $ "' elapsed", 'WormholeTimerController');
    SendDebugDataToEventGrid("wormhole/debug/timer/elapsed/_" $ CallbackTopic, None);

    EventGrid.SendEvent(CallbackTopic, None);
}

function SendDebugDataToEventGrid(string Topic, JsonObject Json)
{
	if(Settings.bDebug)
		EventGrid.SendEvent(Topic, Json);
}