//
// Are there enough players?
// Should we keep waiting for them?
//
public Action:NotEnoughPlayers(Handle:timer)
{
  PrintToServer("NOT ENOUGH PLAYERS");
  KillServer(ERROR_NOT_ENOUGH_PLAYERS);
}

//
// Is the client in the whitelist?
//
public OnClientAuthorized(client, const String:auth[])
{
  new String:sid[MAXIDSIZE];
  PrintToServer("[GAMERIST] Client %d has SteamID %s", client, auth);
  GetClientAuthId(client, AuthId_Steam2, sid, MAXIDSIZE);
  PrintToServer("SourceMod reports SteamID of %s", sid)
  if(serverKilled != 0)
    KickClient(client, "Game canceled due to error %d", serverKilled);
  else
    if(ClientListIndex(auth) == -1 && TEST_ALONE == 0)
      KickClient(client, "You are not in the whitelist!");
  CheckPlayerCount(0);
}

//
// Move the user to their team
//
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
  new String:sid[MAXIDSIZE];
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new team   = GetClientTeam(client);
  
  GetClientAuthId(client, AuthId_Steam2, sid, MAXIDSIZE);
  new ind = ClientListIndex(sid);
  if(ind == -1 && TEST_ALONE == 0){
    KickClient(client, "Client not in list somehow!");
    return 0;
  }
  // if(ind != -1) PrintToServer("%d has joined team %d, should be team %d", client, team, teamnumbers[ind]);
  if(ind != -1 && teamnumbers[ind] != team)
    ChangeClientTeam(client, teamnumbers[ind]);
  return Plugin_Handled;
}

CheckPlayerCount(fatalmode)
{
  if(gameStarted == 0)
  {
    if(AreEnoughPlayers())
    {
      PrintToChatAll("[GAMERIST] Enough players have joined!");
      PrintToChatAll("[GAMERIST] The game will start soon");
      PrintToChatAll("[GAMERIST] !votecancel will be available for 2 minutes");
      #if CURRENT_GAME == GAME_CSS
        SetTeamScore(2, 0);
        SetTeamScore(3, 0);
        ServerCommand("mp_restartgame");
      #endif
      gameStarted = 1;
      CreateTimer(120.0, DisableVoteCancel);
    }
    else if(fatalmode)
    {
      PrintToChatAll("[GAMERIST] Not enough players joined the game!");
      PrintToChatAll("[GAMERIST] Server shutting down!");
      CreateTimer(6.0, NotEnoughPlayers);
    }
  }
}

// Returns 1 or 0 based on whether or not the number of players is sufficient right now
AreEnoughPlayers()
{
  new ccount = 0;
  for(new i = 0; i < GetMaxClients(); i++)
  {
    if(IsClientConnected(i+1) && !IsFakeClient(i+1))
      ccount++;
  }
  new maxplayers = GetMaxClients();
  // PrintToServer("ccount vs maxplayers: %d/%d", ccount, maxplayers);
  if(ccount >= (maxplayers - MISSING_PLAYERS_ALLOWANCE)) // TODO: ensure this makes sense
    return 1;
  else
    return 0;
}

public Action:ReportGameNotStarted(Handle:timer)
{
  if(gameStarted == 0) {
    PrintCenterTextAll("The game has not started yet!");
    CreateTimer(2.0, ReportGameNotStarted);
  }
}

public Action:ExpireWaitTime(Handle:timer)
{
  CheckPlayerCount(1);
}

