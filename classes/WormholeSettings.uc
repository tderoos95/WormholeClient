class WormholeSettings extends Object
    config(Wormhole);

var globalconfig bool bDebug;
var globalconfig bool bDebugDataFlow;
var globalconfig bool bAutoReconnect;
var globalconfig float ReconnectInterval;
var globalconfig float ConnectTimeout;

var globalconfig string HostName;
var globalconfig int Port;
var globalconfig string Token;

var globalconfig string ChatSpectatorName;
var globalconfig array<MutWormhole.GameHandlerRegistration> GameHandlers;

defaultproperties
{
    GameHandlers(0)=(GameTypeName="SkaarjPack.Invasion",GameHandler=class'GameHandler_Invasion');
}