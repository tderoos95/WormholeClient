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

    if(Invasion.WaveNum != PreviousWave)
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



defaultproperties {
    PreviousWave=-1
}
