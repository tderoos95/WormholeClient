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
var globalconfig class<RemoteProcessingEventBusSubscriber> RemoteProcessingEventBusSubscriberClass;
var globalconfig array<MutWormhole.GameHandlerRegistration> GameHandlers;
var globalconfig array<class<WormholePlugin> > Plugins;

defaultproperties
{
    bDebug=false
    bDebugDataFlow=false
    ChatSpectatorName="Discord"
    bAutoReconnect=false
    ConnectTimeout=10
    ReconnectInterval=10

    HostName="gateway.wormhole.unrealuniverse.net"
    Port=13000

    RemoteProcessingEventBusSubscriberClass=class'Wormhole.RemoteProcessingEventBusSubscriber'
    GameHandlers(0)=(GameTypeName="SkaarjPack.Invasion",GameHandler=class'GameHandler_Invasion');
    GameHandlers(1)=(GameTypeName="UnrealGame.ASGameInfo",GameHandler=class'GameHandler_Assault');
}