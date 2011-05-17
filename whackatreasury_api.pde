/**
Whack-A-Treasury
by Ari Lacenski for Etsy / 2011
*/

import processing.serial.*;
import ddf.minim.*;
import simpleML.*;
import org.json.*;

// Audio
Minim minim;
AudioSnippet win;
AudioSnippet fail;

// Game world parameters
Game g;
int gameID = 0;
int lastGameID = 0;
boolean newGameRequested = false;
String source = "";
String apiBase = "http://openapi.etsy.com/v2/makerfaire/";
String apiKey = "39u9vrafahzsw66cvvh4j85x";
PImage defaultImage;
int numSquares = 6;
Coord[] origins = new Coord[numSquares];
// set up target origins
Coord curPos;
int curPosKey = 0;
// Colors
color redFill = color(206, 36, 45);
color redStroke = color(125, 24, 30);
color yellowFill = color(255, 226, 94);
color yellowStroke = color(226, 190, 31);
color greenLine = color(72, 99, 100);
color darkBg = color(245, 233, 192);
color paleBg = color(247, 240, 228);
int offset = 34;
int rectSize = 290;
int imgSize = rectSize - 10;
int boardX = 1280;
int boardY = 720;
int treasurySize = 12;
int deadGameCount = 0;
long gameTimeLimit = 180000; // 3 minutes
long endTime;
long startTime;

Serial myPort;

// Timing
Timer timer;
boolean killGameRequest = false;

// Label board
PFont font = createFont(PFont.list()[1], 32);
PFont bigFont = createFont(PFont.list()[1], 90);

// Request types
HTMLRequest findAllGamesRequest, 
  getGameRequest, 
  updateGameListingsRequest, 
  updateGameFinishedRequest,
  listRequest;

void setup() {
  gameID = 0;
  startTime = millis();
  size(boardX, boardY);
  frameRate(30);
  background(255);
  origins[0] = new Coord(0, 0);
  origins[1] = new Coord(1, 0);
  origins[2] = new Coord(2, 0);
  origins[3] = new Coord(0, 1);
  origins[4] = new Coord(1, 1);
  origins[5] = new Coord(2, 1);
  
  // set up request types
  findAllGamesRequest = new HTMLRequest(this, apiBase + "games?status=ready&limit=1&api_key=" + apiKey);
  
  minim = new Minim(this);
  win = minim.loadSnippet("sounds/beep-10.mp3");
  fail = minim.loadSnippet("sounds/beep-10.mp3");
  timer = new Timer(4000); // display image in millis
  
  myPort = new Serial(this, Serial.list()[0], 9600); // init serial port
  defaultImage = loadImage("extras/default.jpg");
  textFont(font);
}

void draw() {
  drawBoard();
  if (gameID > 0) {
    // Playable game
    if (gameID != lastGameID) {
      g = null;
      g = new Game(gameID);
      lastGameID = gameID;
       // playable loop starts here     
    } else { // Play through game since its ID exists
      gameID = g.gameID;
      getGameRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/?status=ready&includes=GameListings&api_key=" + apiKey);
      if (g.listingRequestSent) {
        if (g.isReady()) {
          if (g.timeInPlay < gameTimeLimit) {
            if (!timer.isFinished()) {
              renderImage(curPos);
              myPort.write(curPosKey);
            } else {
              if (g.listings.size() > 0) {
                if (g.successfulHits < treasurySize) {
                  updatePos();
                  g.setNextListing(); // next curListing is ready
                  timer.start();
                } else {
                  // Game is over
                  updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/?status=played&method=PUT&api_key=" + apiKey);
                  updateGameFinishedRequest.makeRequest(); // Send current game status 
                  newGameRequested = false;
                  gameID = -1; // set to -1 so that next draw loop will trigger new game start
                }
              } else {
                println("No listings");
              }
            } // end else case for timer
            g.updateGameTime();
          } else {
            gameID = -1;
          } // end game-length case
        } 
      } else {
        getGameRequest.makeRequest();
        g.listingRequestSent = true;
      }
    }
  } else {
    if (gameID == -1) {
      if (millis() - endTime < 4000) {
        // Do nothing! Print WINNING
        myPort.write(9);
      } else {
        setup();
      }
    }
    deadGameCount++;    
  }
  deadGameCount =0;
  if (deadGameCount > 1000) {
    println("Out of games to play!");
    exit();
  } 
}

// in response from simpleML, set gameRequested back to false
void netEvent(HTMLRequest ml) {
  source = ml.readRawSource();  // Read the raw data
  try {
    JSONObject response = new JSONObject(source);
    JSONArray results = new JSONArray();
    
    if (!(response.get("results").equals(null))) {
      // response!
      results = response.getJSONArray("results");
      String method = (String)response.get("api_method");
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
        JSONArray gameListings = null;
          
        try {
          gameListings = jsonGame.getJSONArray("GameListings");
          
          g.loadListings(gameListings); // load listings, which will set game state to ready
          println(jsonGame.get("player").toString());
         } catch (Exception e) {
          // Endgame state
          endTime = millis();
          println("The last game loaded had null listings!");
          gameID = -1;
          if (killGameRequest == false) {
            updateGameFinishedRequest = new HTMLRequest(this, apiBase + "games/" + jsonGame.get("game_id") + "/?status=played&method=PUT&api_key=" + apiKey);
            updateGameFinishedRequest.makeRequest(); // Send current game status
            killGameRequest = true;
          }
          deadGameCount++;  
        }
      } else if (method.equals("updateGameListings")) { // send a hit
        // do nothing
        JSONObject jsonGame = (JSONObject)results.get(0);
        String id = jsonGame.get("listing_id").toString();
        println("HUGE SUCCESS on " + id);
      } else if (method.equals("updateGame")) { // callback from killed game request 
        killGameRequest = false; // let us move on
      }
    } else { // no response
      // drawWaitingState("Waiting for a game entry");
      // println("Empty game response! Try again");
      deadGameCount++;
    }
  } catch (JSONException e) {
    e.printStackTrace();
  }
}

void mousePressed() {
  try {
    if (newGameRequested == false) {
      findAllGamesRequest.makeRequest();
      newGameRequested = true;
      println("Requested game");
      updatePos();  
    } else {
      println("Keep waiting for game...");
    }
  } catch (Exception e) { // this doesn't actually get caught here :(
    // if there's a connection error, reset everything
    newGameRequested = false;
  }
}

void renderImage(Coord pos) {
    Listing current = g.curListing; 
  int offsetX = (pos.x * (rectSize + 10)) + 200; //offset from left of board
  int offsetY = (pos.y * (rectSize + 10)) + ((boardY - (2*rectSize)) / 2); //offset from bottom of board
  offsetX += 5;
  offsetY += 5;
  try {
      image(current.getImage(), offsetX, offsetY, imgSize, imgSize);
    } catch(Exception e) {
      image(defaultImage, offsetX, offsetY, imgSize, imgSize);
    }
} 

void updatePos() {
  int lastPosKey = curPosKey;  
  curPosKey = (int)random(0, numSquares-1);
  if (lastPosKey == curPosKey) {
    updatePos(); // Prevent picking the same square twice
  } else {
    curPos = origins[curPosKey];
  }
}

void drawBoard() {
  int stripeWidth = 50;
  // Fill background
  for (int i = 0; i < 26; i++) {
    if (i % 2 == 0) {
      fill(paleBg);
    } else {
      fill(darkBg);
    }
    stroke(0, 0, 0, 0);
    rect((i*stripeWidth), 0, stripeWidth, boardY);
  }
  
  strokeWeight(8);
  stroke(greenLine);
  fill(darkBg);
  rect(30, 30, (boardX - 60), (boardY - 60));
  
  // draw image target board
  if (gameID < 1) {
    fill(255, 143, 0);
    if (gameID == 0) {
      drawMessage("Are you ready?");
    } else {
      drawMessage("WINNING!");
    }
  } else {
    strokeWeight(10);  // Beastly
    for (int i = 0; i < numSquares; i++) {
      Coord coord = origins[i];
      int offsetX = (coord.x * (rectSize + 10)) + 200; //offset from left of board
      int offsetY = (coord.y * (rectSize + 10)) + ((boardY - (2*rectSize)) / 2); //offset from bottom of board
      if (i % 2 == 0) {
        stroke(redStroke);
        fill(redFill); 
      } else {
        stroke(yellowStroke);
        fill(yellowFill); 
      }
      
      rect(offsetX, offsetY, rectSize, rectSize);
      fill(255, 182, 88);
      textFont(bigFont);
      text(i+1, offsetX + 48, offsetY + 106);
      textFont(font);
    }
  }
}

void drawMessage(String message) {
  text(message, (boardX/2 - 120), 220);
}
/*
void drawSelectedPad(int index) {
    Coord coord = origins[index];
    int offsetX = (coord.x * 5 * offset) + offset + (boardX/2 - 280); //offset from left of board
    int offsetY = (coord.y * 5 * offset) + offset + (boardY - 380); //offset from bottom of board
    stroke(208, 211,179);
    fill(0,0,255);
    rect(offsetX, offsetY, rectSize, rectSize);
    fill(255, 255, 255);
    textFont(bigFont);
    text(index+1, offsetX + 48, offsetY + 106);
    
    textFont(font);
}
*/
void keyPressed() { // this will become serialEvent
  // set up whack event
  // prepare hit request, but don't make it until hit
  String thisShit = "whacked"; // yo
  
  Integer k = (Integer)Character.digit(key, 10);
  myPort.write(k);
  if (g != null) {
    println("press " + g.gameID);
    if (k.equals((Integer)curPosKey+1)) {
      if (g.successfulHits < treasurySize) {
        try {
          if (g.curListing.submitted == false) {
            updateGameListingsRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT&api_key=" + apiKey);  
            updateGameListingsRequest.makeRequest(); 
            playWin();
            g.curListing.submitted = true;
            g.successfulHits++;
          }
        } catch(NullPointerException e) {
          // a bad listing was loaded, no big deal
          println("Fail!");
          playFail();
        }
      } 
    } else {
      playFail();
    } 
    g.totalHits++;
  } else {
    println("dead press");
  }
}

void playWin() {
  win.play(0);
} 

void playFail() {
  fail.play(0);
} 

void serialEvent(Serial p) { 
  // Set game status
  String thisShit = "whacked"; // yo 
  while (myPort.available() > 0) {
    int inByte = p.read();
    if (g != null) {
      if (inByte == curPosKey && g.curListing.submitted == false) {
        g.successfulHits++;
        if (g.successfulHits <= treasurySize) {
          g.curListing.submitted = true;   
          updateGameListingsRequest = new HTMLRequest(this, apiBase + "games/" + g.gameID + "/listings/" + g.curListing.getListingID() + "/?status=" + thisShit + "&method=PUT&api_key=" + apiKey );  
          updateGameListingsRequest.makeRequest();    
        }
      }
      g.totalHits++;
    }
  }
}


void stop() {
  // always close Minim audio classes when you are done with them
  win.close();
  fail.close();
  // always stop Minim before exiting
  minim.stop();
  super.stop();
}

