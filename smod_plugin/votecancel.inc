new voteCancelAvailable = 1;
new votedToCancel[32];

//
// Allow the players to vote cancel
//

CountVoteCancels()
{
  new total = 0;
  for(new i = 0; i < 32; i++)
  {
    if(votedToCancel[i] == 1)
      total++;
  }
  return total;
}

public Action:VoteCancelSucceeds(Handle:timer)
{
  KillServer(ERROR_VOTECANCEL);
}

public Action:DisableVoteCancel(Handle:timer)
{
  PrintToChatAll("[GAMERIST] !votecancel is now disabled");
  voteCancelAvailable = 0;
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new String:text[12];
  GetEventString(event, "text", text, 12);
  if(strcmp(text, "!votecancel") == 0)
    if(voteCancelAvailable == 1)
    {
      #if TEST_ALONE == 0
      votedToCancel[ClientListIndexI(client)] = 1;
      #endif
      #if TEST_ALONE == 1
      votedToCancel[0] = 1;
      #endif
      new count = CountVoteCancels();
      PrintToChatAll("[GAMERIST] Number of votes to cancel game: %d/4", count); // TODO: ensure 4 is a good number
      if(count >= 4)
      {
        PrintToChatAll("[GAMERIST] Voted to cancel game!!");
        DeclareError(ERROR_VOTECANCEL);
        killingServer = 1;
        CreateTimer(7.0, VoteCancelSucceeds);
      }
    }
}
