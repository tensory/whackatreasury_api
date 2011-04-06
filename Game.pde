import org.json.*;

class Game {
  int gameID;
  boolean active = false;
  int totalHits;
  int successfulHits;
  int treasurySize;
  boolean listingRequestSent = false;
  private boolean ready;
  
  Listing curListing;
  Stack listings = new Stack();
  
  int imageSize = 60; // Size of image rectangle
  
  Game(int id) {
    gameID = id;
    active = true;
    totalHits = 0;
    successfulHits = 0;
    treasurySize = 0;
    ready = false;
  }
  
  void loadListings(JSONArray listings) {
    // limit listings to 15 just for the local demo. Remove when using full set of Etsy images
     
    try {
      for (int j = 0; j < listings.length(); j++) {
        JSONObject listing = (JSONObject)listings.get(j); 
        
        String id = listing.get("listing_id").toString();
        this.listings.push(new Listing(Integer.parseInt(id))); // change this to initialize images differently
      } 
      
      this.ready = true; // game is ready!
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  
  /*
  // Look through file system for image cache
  void loadListings() {
    BufferedReader reader = null;
    String absPath = "/Users/alacenski/Documents/Projects/whackatreasury/whackatreasury_gameworld/data/";
    
    String line = "";
    
    // Open the source file
    try {
      // Currently the file reader expects a line pattern like:
      // listingID,localfileID
      
      reader = new BufferedReader(new FileReader(file));
      // As long as there are lines in the file, 
      // load up images from the filenames
      while ((line = reader.readLine()) != null) {
        
        if (line.length() > 0) { // if line is not blank
          String[] vals;
          // Split the string by ','
          vals = line.split(",");
          
          // Initialize Listing here and add it to array of listing images
          int id = Integer.parseInt(vals[0]);
          PImage i = loadImage(absPath + this.gameID + "/" + vals[1] + ".gif");
          
          listings.push(new Listing(id, i));
        } // end if (not blank)
      } // end while
    } catch (FileNotFoundException e) {
      e.printStackTrace(); // Show display error
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  */
  
  void setNextListing() {
    curListing = (Listing)listings.pop();
  }
  
  boolean isReady() {
    return this.ready;
  }
  
  void setRequestSent(boolean wasSent) {
    this.listingRequestSent = wasSent;
  }
}
