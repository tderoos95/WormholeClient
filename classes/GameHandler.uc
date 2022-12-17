class GameHandler extends Info;

var EventGrid EventGrid;
var bool bIsCoopGame;
var bool bGameStarted;
var bool bGameEnded;

public function PostInitialize()
{
    log("GameHandler initialized", 'Wormhole');
    SendMatchInfo();
}

public function SendMatchInfo()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("GameType", Level.Game.GameName);
    Json.AddString("MapName", Level.Title);
    Json.AddString("ServerName", class'Utils'.static.StripColorCodes(Level.Game.GameReplicationInfo.ServerName));
    Json.AddBool("IsTeamGame", Level.Game.bTeamGame);
    Json.AddBool("IsCoopGame", bIsCoopGame);
    EventGrid.SendEvent("match/info", Json);
}

// Called every 0.1 seconds by WormholeMutator
public function MonitorGame()
{
    CheckEndGame();
}

public function HandleMatchStarted()
{
    bGameStarted = true;
    EventGrid.SendEvent("match/started", None);
}

function CheckEndGame()
{
    if(!bGameEnded && Level.Game.bGameEnded)
    {
        bGameEnded = true;
        HandleMatchEnded();
    }
}

function HandleMatchEnded()
{
    EventGrid.SendEvent("match/ended", None);
}

defaultproperties {
    bIsCoopGame=false
}