Data WORK.WLLRT_Austin_LRTDist Replace;
Set WORK.tabblcok2010Centroids;
/* Add distance between census tracts in miles;
Geodist works well, use options:
D since values in degrees
M to return distance in miles */
d12420001 = Geodist(w_lat,w_lon,30.265114,-97.739774,'DM');
d12420002 = Geodist(w_lat,w_lon,30.262179,-97.727578,'DM');
d12420003 = Geodist(w_lat,w_lon,30.279786,-97.709054,'DM');
d12420004 = Geodist(w_lat,w_lon,30.328611,-97.716224,'DM');
d12420005 = Geodist(w_lat,w_lon,30.338378,-97.719692,'DM');
d12420006 = Geodist(w_lat,w_lon,30.392808,-97.716427,'DM');
d12420007 = Geodist(w_lat,w_lon,30.439685,-97.700647,'DM');
d12420008 = Geodist(w_lat,w_lon,30.48097,-97.78656,'DM');
d12420009 = Geodist(w_lat,w_lon,30.58758,-97.856303,'DM');
RUN;
