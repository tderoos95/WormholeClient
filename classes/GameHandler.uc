class GameHandler extends Info;

var EventGrid EventGrid;
var bool bGameStarted;
var bool bGameEnded;

// Called every 0.1 seconds by WormholeMutator
public function MonitorGame()
{
    CheckEndGame();
}

function CheckEndGame()
{
    if(!bGameEnded && Level.Game.bGameEnded)
    {
        bGameEnded = true;
        EventGrid.SendEvent("match/ended", None);
    }
}