class Listing {
  private int listingID;
  private PImage img; // Prevent image from being overwritten
  
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
