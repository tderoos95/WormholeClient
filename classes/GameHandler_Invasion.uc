class GameHandler_Invasion extends GameHandler;

var Invasion Invasion;
var int PreviousWave;
var bool bWaveInProgress;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    Invasion = Invasion(Level.Game);

    if(Invasion == None)
    {
        log("GameHandler_Invasion was unable to find the Invasion GameInfo. Destroying self.", 'Wormhole');
        Destroy();
    }
}

public function MonitorGame()
{
    Super.MonitorGame();

    if(Invasion.WaveNum != PreviousWave && bGameStarted)
    {
        PreviousWave = Invasion.WaveNum;
        bWaveInProgress = false;
        OnWaveCountdownStarted();
    }
    else if(!bWaveInProgress && Invasion.bWaveInProgress)
    {
        bWaveInProgress = true;
        OnWaveStarted();
    }
}

function OnWaveCountdownStarted()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddInt("WaveNumber", Invasion.WaveNum);
    EventGrid.SendEvent("match/invasion/wavecountdownstarted", Json);
}

function OnWaveStarted()
{
    local JsonObject Json;

    Json = new class'JsonObject';
    Json.AddInt("WaveNumber", Invasion.WaveNum);
    EventGrid.SendEvent("match/invasion/wavestarted", Json);
}

function HandleMatchEnded()
{
    local JsonObject Json;
    local bool bVictory;

    bVictory = IsMatchVictorious();

    Json = new class'JsonObject';
    Json.AddBool("Victory", bVictory);
    EventGrid.SendEvent("match/invasion/ended", Json);
}

function bool IsMatchVictorious()
{
    local Controller C;
    local int NumAlivePlayers;

    for(C = Level.ControllerList; C != None; C = C.NextController)
    {
        if(C.bIsPlayer && C.Pawn != None)
            NumAlivePlayers++;
    }

    return NumAlivePlayers > 0;
}

defaultproperties {
    PreviousWave=-1
    bIsCoopGame=True
}
