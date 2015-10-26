//
// Shut down the server, game is done
//
PreGracefulShutdown(winteam)
{
  #if CURRENT_GAME == GAME_CSS
  if(winteam == TEAM_RED) PrintToChatAll("[GAMERIST] Game over! Terrorists win");
  else PrintToChatAll("[GAMERIST] Game over! Counter-Terrorists win");
  #endif
  #if CURRENT_GAME == GAME_TF
  if(winteam == TEAM_RED) PrintToChatAll("[GAMERIST] Game over! Red team wins");
  else PrintToChatAll("[GAMERIST] Game over! Blue team wins");
  #endif
  CreateTimer(30.0, GracefulShutdown);
}

//
// Tell handlr who won
//
PushAllPlayerScores()
{
  new String:playerScores[2048];
  playerScores[0] = 'D'; playerScores[1] = 'P';
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
    {
      new String:oneplayer[48];
      
      new String:stid[MAXIDSIZE];
      GetClientAuthId(i, AuthId_Steam2, stid, MAXIDSIZE)
      Format(oneplayer, 48, "%s|%d|", stid, GetClientFrags(i));
      StrCat(playerScores, 2048, oneplayer);
    }
  }
  StrCat(playerScores, 2048, "&|"); // If fewer than playercount players are connected
  PushMessage(playerScores);
}

DeclareWinners(winningTeam)
{
  PushAllPlayerScores();
  new losingTeam;
  if(winningTeam == TEAM_RED)
    losingTeam = TEAM_BLU;
  else
    losingTeam = TEAM_RED;
  PushMessage("DT%d%d", winningTeam, losingTeam); // DT23 or DT32
  PreGracefulShutdown(winningTeam);
}

public Action:GracefulShutdown(Handle:timer)
{
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
      KickClient(i, "Game has ended")
  }
  KillServer(ERROR_GRACEFUL_SHUTDOWN);
}

