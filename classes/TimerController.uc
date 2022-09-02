class TimerController extends Info;

struct TimerEntry {
    var string CallbackTopic;
    var int Interval;
    var bool bRepeat;
    var float ElapsesAt;
};

var array<TimerEntry> ActiveTimers;
var float NextTimerElapse;
// todo eventgrid

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

function CalculateNextTimerElapse()
{
    local int i;

    if(ActiveTimers.length == 0)
    {
        NextTimerElapse = -1;
        return;
    }

    for (i = 0; i < ActiveTimers.length; i++)
    {
        if(ActiveTimers[i].ElapsesAt < NextTimerElapse)
            NextTimerElapse = ActiveTimers[i].ElapsesAt;
    }
}

function Tick(float DeltaTime)
{
    local int i;

    Super.Tick(DeltaTime);

    if(NextTimerElapse != -1 && NextTimerElapse <= Level.TimeSeconds)
    {
        for(i = 0; i < ActiveTimers.length; i++)
        {
            if(ActiveTimers[i].ElapsesAt == NextTimerElapse)
            {
                if(ActiveTimers[i].bRepeat)
                    ActiveTimers[i].ElapsesAt = Level.TimeSeconds + ActiveTimers[i].Interval;
                else
                    ActiveTimers.Remove(i, 1);
                
                OnTimerElapsed(ActiveTimers[i].CallbackTopic);
            }
        }

        CalculateNextTimerElapse();
    }
}

function OnTimerElapsed(string CallbackTopic)
{
    log("Timer '" $ CallbackTopic $ "' elapsed", 'WormholeTimerController');

    // todo call eventgrid
}
