ClientListIndex(const String:auth[])
{
  PrintToServer("Looking for steamid %s", auth);
  for(new i = 0; i < IDLIMIT; i++)
  {
    if(strcmp(auth, allowedids[i]) == 0) {
      PrintToServer("Found at %d, teamnumber is %d", i, teamnumbers[i]);
      return i; }
  }
  // if(TEST_ALONE == 1) return 0;
  return -1;
}

ClientListIndexI(client)
{
  new String:sid[MAXIDSIZE];
  GetClientAuthId(client, AuthId_Steam2, sid, MAXIDSIZE);
  return ClientListIndex(sid);
}

//
// Get the rules for this map
//
MapListEnum()
{
  new String:curmap[MAPNAME_MAXSIZE];
  GetCurrentMap(curmap, MAPNAME_MAXSIZE);
  for(new i = 0; i < MAPS_NUMBER; i++)
  {
    if(strcmp(curmap, mapdata_names[i]) == 0) {
      return mapdata_rulesets[i]; }
  }
  return 0;
}

