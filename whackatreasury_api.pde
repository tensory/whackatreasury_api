import simpleML.*;
import org.json.*;
import java.util.Map;

/* 
  Request types:
  findAllGamesRequest: called to determine next game to run
  getGameRequest: called to get listings for current game
*/
HTMLRequest findAllGamesRequest, getGameRequest, listRequest;


// Game world variables
Game g;
int gameID = 0;
int lastGameID = 0;
 // Set up origins of rectangles on the board   
Coord[] origins = new Coord[9];
Coord curPos;
int curPosKey = 0;
int offset = 25;

// Label board
PFont font = createFont(PFont.list()[1], 32);
PFont mcHugeLarge = createFont(PFont.list()[1], 60);

Timer timer;
Timer fontTimer;
boolean endImageDisplay = false;


String source = "";
color back = color(0, 255, 100);    // Background brightness

void setup() {
  size(400,400);
  background(0);
 //listRequest = new HTMLRequest(this,"http://api.alacenski.ny4dev.etsy.com/v2/makerfaire/");
 //listRequest.makeRequest();
  // set up target origins
  origins[0] = new Coord(0, 0);
  origins[1] = new Coord(1, 0);
  origins[2] = new Coord(2, 0);
  origins[3] = new Coord(0, 1);
  origins[4] = new Coord(1, 1);
  origins[5] = new Coord(2, 1);
  origins[6] = new Coord(0, 2);
  origins[7] = new Coord(1, 2);
  origins[8] = new Coord(2, 2);
  
  // Create and make an asynchronous request
  // set up request types
  findAllGamesRequest = new HTMLRequest(this,"http://api.alacenski.ny4dev.etsy.com/v2/makerfaire/games?status=ready&limit=1");
  timer = new Timer(2000); // display image in millis
  fontTimer = new Timer(30);
  textFont(font);
}

void draw() {
  // Fill background
  background(255);
  // draw image target board
  stroke(0);
  textFont(font);
  for (int i = 0; i < 9; i++) {
    Coord coord = origins[i];
    int offsetX = (coord.x * 5 * offset) + offset;
    int offsetY = (coord.y * 5 * offset) + offset;
    fill(40);
    rect(offsetX, offsetY, 75, 75);
    fill(180, 180, 255);
    text(i+1, offsetX + 10, offsetY + 36);
  }
  
  // if game state ID is set
  if (gameID > 0) {    
    if (gameID != lastGameID) {
      // if game is new
      // should this run during the endgame state or at init?
      lastGameID = gameID; // get this out of the way
      g = new Game(gameID); // start that game up
       
      
      // initialize new game
    } else { // still playing the same game
      // run the game
      
      getGameRequest = new HTMLRequest(this,"http://api.alacenski.ny4dev.etsy.com/v2/makerfaire/games/" + g.gameID + "/?status=ready&includes=GameListings");
      if (g.listingRequestSent) {
        if (g.isReady() == true) {
          // start showing images
          if (!timer.isFinished()) {
            renderImage(curPos);
          } else {
            if (g.listings.size() > 0) {
              updatePos();
              g.setNextListing();
              println("Currently displaying " + g.curListing.getListingID() + " at " + (curPosKey+1));
              // todo: figure out how to end correctly
              timer.start();
            } else {
              // No more listings!
              // endgame state lives here
              // endgame: make API requests to start a game
              println("GAME IS OUT OF LISTINGS");
              println("START NEW GAME?");
              delay(10000);
            }
          } // end timer loop
        }
      } else {
        getGameRequest.makeRequest();
        g.listingRequestSent = true;
      }
    }
  } // if game id is set
}

void mousePressed() {
    findAllGamesRequest.makeRequest();
    println("requested");
}

void keyPressed() {
  fontTimer.start();
  textFont(mcHugeLarge);
  fill(255, 0, 0);
  Integer k = (Integer)Character.digit(key, 10);
  if (k.equals((Integer)curPosKey+1)) {
    println("win");
    for(int j = 0; j < 1000; j++) {
      text("YAY", 10, 300);
    }
  } else {
    while(!fontTimer.isFinished()) {
      text("FUCK", 10, 300);
    }
  }
}

// When a request is finished
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  println(source);
  //Parse response for type, get data out
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = response.getJSONArray("results");
    String method = (String)response.get("api_method");

    // set game state based on method called
    if (method.equals("findAllGames")) { // get a game ID to initialize the new game
      // set game ID
      // required to start game
      JSONObject jsonGame = (JSONObject)results.get(0);
      String id = jsonGame.get("game_id").toString();
      gameID = Integer.parseInt(id);
    } else if (method.equals("getGame")) { // make listing ids available to the current Game
      /* 
        this is not a good way to do this 
        (should be in Game constructor), 
        but listings must be pulled from game environment to be handled with netEvent 
      */
      JSONObject jsonGame = (JSONObject)results.get(0);
      JSONArray gameListings = jsonGame.getJSONArray("GameListings");
      
      g.loadListings(gameListings);
    }
      
  } catch (JSONException e) {
    e.printStackTrace();
  }
}

void renderImage(Coord pos) {  
  int offsetX = (pos.x * 5 * offset) + offset;
  int offsetY = (pos.y * 5 * offset) + offset;
  //println("Running at " + pos.x + ", " + pos.y);
  stroke(0, 100, 255);
  Listing current = g.curListing; 
  image(current.getImage(), offsetX, offsetY);
} 

void updatePos() {
  curPosKey = (int)random(0, 8);
  curPos = origins[curPosKey];
}
