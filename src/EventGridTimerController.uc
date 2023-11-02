// Todo outsource to EventGrid library
class EventGridTimerController extends Info;

struct TimerEntry {
    var string CallbackTopic;
    var int Interval;
    var bool bRepeat;
    var float ElapsesAt;
};

var array<TimerEntry> ActiveTimers;
var float NextTimerElapse;
var EventGrid EventGrid;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    EventGrid = MutWormhole(Owner).EventGrid;

    SetTimer(0.1, true);
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

    NextTimerElapse = GetSoonestTimerElapse();
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

    NextTimerElapse = GetSoonestTimerElapse();
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
        if(ActiveTimers[i].ElapsesAt <= Level.TimeSeconds)
        {
            Callback(ActiveTimers[i].CallbackTopic);

            if(ActiveTimers[i].bRepeat)
                ActiveTimers[i].ElapsesAt = Level.TimeSeconds + ActiveTimers[i].Interval;
            else
                ActiveTimers.Remove(i, 1);
        }
    }

    NextTimerElapse = GetSoonestTimerElapse();
}

function Callback(string CallbackTopic)
{
    EventGrid.SendEvent(CallbackTopic, None);
}

function float GetSoonestTimerElapse()
{
    local float SoonestElapse;
    local int i;

    if(ActiveTimers.length == 0)
        return 0;

    SoonestElapse = ActiveTimers[0].ElapsesAt;

    for (i = 1; i < ActiveTimers.length; i++)
    {
        // Try to find timer that ends sooner than the current soonest
        if(ActiveTimers[i].ElapsesAt < SoonestElapse)
            SoonestElapse = ActiveTimers[i].ElapsesAt;
    }

    return SoonestElapse;
}