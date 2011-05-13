class Listing {
  private int listingID = 0;
  private PImage img; // Prevent image from being overwritten
  boolean submitted = false;
  
  Listing (int id) {
    listingID = id;
    img = loadImage(id + ".jpg");
  }
 
  PImage getImage() {
    return img;
  }
 
 int getListingID() {
    return listingID;
 } 
}


