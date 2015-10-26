public OnPluginStart()
{
  PrintToChatAll("[GAMERIST] Gamerist starting up...");
  PrintToServer("[GAMERIST] Gamerist starting up...");
  
  CreateTimer(2.0, RestartSocket);
  CreateTimer(10.0, HeartBeat);
  
  GetInitialData();
  
  PrintToChatAll(mapdata_names[1]);
  HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
  HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
  #if CURRENT_GAME == GAME_CSS
    HookEvent("round_end", Event_TeamplayRoundEnd, EventHookMode_Post);
    CreateTimer(10.0, ReportGameNotStarted);
    CreateTimer(250.0, ExpireWaitTime); 
    CreateTimer(1.0, MockeryFeature);
  #endif
  #if CURRENT_GAME == GAME_TF
    HookEvent("teamplay_round_win", Event_TeamplayRoundWin, EventHookMode_Post);
    CreateTimer(25.0, WaitingForPlayersReboot);
  #endif
}

public Action:MockeryFeature(Handle:event)
{
  new clhealth, finalhealth;
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i)) {
      clhealth = GetClientHealth(i);
      if(clhealth < 100) {
        finalhealth = clhealth + 25;
        if(finalhealth > 100) finalhealth = 100;
        SetClientHealth(i, finalhealth); } } }
  if(gameStarted == 0)
    CreateTimer(1.0, MockeryFeature);
  return Plugin_Handled;
}

