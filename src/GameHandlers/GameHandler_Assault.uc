//=============================================================================
// GameHandler_Assault
// Coded by DW>Ant - 2023.
//=============================================================================
class GameHandler_Assault extends GameHandler;

var ASGameInfo Assault;
var GameObjective CompletedObjective;

function PreBeginPlay()
{
    Super.PreBeginPlay();

    Assault = ASGameInfo(Level.Game);
    if (Assault == None)
    {
        Log("GameHandler_Assault is unable to find the ASGameInfo. Destroying self.", 'Wormhole');
        Destroy();
    }
}

public function MonitorGame()
{
    Super.MonitorGame();

    if (Assault != None && Assault.LastDisabledObjective != CompletedObjective)
    {
        CompletedObjective = Assault.LastDisabledObjective;
        OnObjectiveCompleted();
    }
}

function OnObjectiveCompleted()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("CompletedObjectiveName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(CompletedObjective.Objective_Info_Attacker));

    if (CompletedObjective.Instigator != None && CompletedObjective.Instigator.PlayerReplicationInfo != None)
        Json.AddString("ObjectiveInstigator", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(CompletedObjective.Instigator.PlayerReplicationInfo.PlayerName));

    EventGrid.SendEvent("match/assault/objective/completed", Json);
}

function HandleMatchEnded()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddString("WinnerTeamName", TeamInfo(Assault.GameReplicationInfo.Winner).TeamName);
    Json.AddInt("CompletionTime", Level.Game.GameReplicationInfo.ElapsedTime);
    EventGrid.SendEvent("match/assault/ended", Json);
    GameEndedListener.Destroy();
}

defaultproperties
{ }