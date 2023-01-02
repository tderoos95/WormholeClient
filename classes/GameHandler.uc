class GameHandler extends Info;

var EventGrid EventGrid;
var bool bIsCoopGame;
var bool bGameStarted;
var bool bGameEnded;

var TriggerEventListener GameEndedListener;

public function PostInitialize()
{
    log("Initializing GameHandler...", 'Wormhole');
    SubscribeToGameInfoEvents();
    log("GameHandler initialized", 'Wormhole');
    PrepareSendMatchInfo();
}

function SubscribeToGameInfoEvents()
{
    GameEndedListener = Spawn(class'TriggerEventListener');
    GameEndedListener.Subscribe('EndGame');
    GameEndedListener.Callback = HandleMatchEnded;
}

function PrepareSendMatchInfo()
{
    SetTimer(0.1, false);
}

function Timer()
{
    if(Level.Game.GameReplicationInfo == None)
    {
        SetTimer(0.1, false);
        return;
    }

    SendMatchInfo();
}

public function SendMatchInfo()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("ServerIp", Level.GetAddressURL());
    Json.AddString("ServerName", class'Utils'.static.StripColorCodes(Level.Game.GameReplicationInfo.ServerName));
    Json.AddString("GameType", Level.Game.GameName);
    Json.AddString("MapName", Level.Title);
    Json.AddBool("IsTeamGame", Level.Game.bTeamGame);
    Json.AddBool("IsCoopGame", bIsCoopGame);
    EventGrid.SendEvent("match/info", Json);
}

public function MonitorGame()
{}

public function HandleMatchStarted()
{
    bGameStarted = true;
    EventGrid.SendEvent("match/started", None);
}

function HandleMatchEnded()
{
    EventGrid.SendEvent("match/ended", None);
}

defaultproperties {
    bIsCoopGame=false
}