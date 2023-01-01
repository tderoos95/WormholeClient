//=============================================================================
// GameInfoTriggerListener
//   This is a simple trigger listener that can be used to subscribe to
//   triggered events. It is intended to be used by the GameHandler to
//   subscribe to events that are triggered in the context of GameInfo.
//=============================================================================
class TriggerEventListener extends Info;

public delegate Callback();

function Subscribe(name TriggerName)
{
    Tag = TriggerName;
}

event Trigger(Actor Other, Pawn EventInstigator)
{
    Callback();
}