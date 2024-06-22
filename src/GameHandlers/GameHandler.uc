class GameHandler extends Info;

enum TimerModeType
{
    AwaitGameInitialized,
    AwaitMatchEnded
};

var TimerModeType TimerMode;
var EventGrid EventGrid;
var bool bIsCoopGame;
var bool bGameStarted;
var bool bGameEnded;

var TriggerEventListener GameEndedListener;

public function OnInitialize()
{
    log("Initializing GameHandler...", 'Wormhole');
    SubscribeToGameInfoEvents();
    log("GameHandler initialized.", 'Wormhole');
    PrepareSendMatchInfo();
}

function SubscribeToGameInfoEvents()
{
    GameEndedListener = Spawn(class'TriggerEventListener');
    GameEndedListener.Subscribe('EndGame');
    GameEndedListener.Callback = AwaitMatchEnded;
}

function PrepareSendMatchInfo()
{
    TimerMode = TimerModeType.AwaitGameInitialized;
    SetTimer(0.1, false);
}

function Timer()
{
    if(TimerMode == AwaitGameInitialized)
    {
        if(Level.Game.GameReplicationInfo == None)
        {
            SetTimer(0.1, false);
            return;
        }

        SendMatchInfo();
    }

    if(TimerMode == AwaitMatchEnded)
    {
        if(!Level.Game.bGameEnded)
        {
            SetTimer(0.1, false);
            return;
        }

        HandleMatchEnded();
    }
}

public function SendMatchInfo()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("ServerIp", Level.GetAddressURL());
    Json.AddString("ServerName", class'Utils'.static.StripColorCodes(Level.Game.GameReplicationInfo.ServerName));
    Json.AddString("GameType", class'Utils'.static.StripColorCodes(Level.Game.GameName));
    Json.AddString("MapName", class'Utils'.static.StripColorCodes(Level.Title));
    Json.AddBool("IsTeamGame", Level.Game.bTeamGame);
    Json.AddBool("IsCoopGame", bIsCoopGame);
    EventGrid.SendEvent("match/info", Json);
}

public function MonitorGame()
{ }

public function HandleMatchStarted()
{
    bGameStarted = true;
    EventGrid.SendEvent("match/started", None);
}

function AwaitMatchEnded()
{
    TimerMode = AwaitMatchEnded;
    SetTimer(0.1, false);
}

function HandleMatchEnded()
{
    GameEndedListener.Destroy();
    EventGrid.SendEvent("match/ended", None);
}

function HandleActorSpawned(Actor Other)
{ }

defaultproperties {
    bIsCoopGame=false
}