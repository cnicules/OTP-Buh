/**
 * Stop represents a transit stop or station, and contains an OSM unique
 * {@link #getId id},
 * {@link #getLat latitude} and
 * {@link #getLon longitude}, a
 * {@link #getName name}, and a
 * {@link #getNameSansDiacritics nameSansDiacritics} for matching. <p/>
 * 
 * {@link #compareTo} compares stops by id. <p/>
 *
 * {@link #distance_m} estimates distance to another stop in meters from
 * the latitudes and longitudes.
 */
class Stop implements Comparable<Stop> {
  final long id;
  final double lat, lon;
  final String name, nameSansDiacritics;
  Stop(long id, double lat, double lon, String name) {
    this(id, lat, lon, name, null);
  }
  Stop(long id, double lat, double lon, String name, String nameSansDiacritics){
    if (name == null)
      throw new NullPointerException("name");
    this.id = id;
    this.lat = lat; this.lon = lon;
    this.name = name;
    this.nameSansDiacritics =
      (nameSansDiacritics != null && nameSansDiacritics.length() > 0
       ? nameSansDiacritics : null);
    if (this.nameSansDiacritics != null) { 
      for (char c : this.nameSansDiacritics.toCharArray()) {
        if (c < 20 || c > 127) {
          System.err.println
            ("Warning: stop "+id+" nameSansDiacritics"+
             " contains char '"+c+"' (&#x"+ Integer.toHexString((int)c)+";)"+
             " that is not ASCII: \""+ this.nameSansDiacritics+"\"");
          break;
        }
      }
    }
  }
  /**
   * OSM id of this stop
   */
  public long getId() { return this.id; }
  /**
   * Latitude of this stop.
   */
  public double getLat() { return this.lat; }
  /**
   * Longitude of this stop.
   */
  public double getLon() { return this.lon; }
  /**
   * Name of this stop.
   */
  public String getName() { return this.name; }
  /**
   * Name of this stop in ASCII.
   */
  public String getNameSansDiacritics() { return this.nameSansDiacritics; }
  
  /**
   * Return distance in meters calculated from latitude and longitude.
   */
  public double distance_m(Stop that) {
    final double r = 6371e3; // 6371km earth radius
    final double radiansPerDegree = Math.PI/180;
    double dLat_rad = radiansPerDegree * (that.lat - this.lat);
    double dNorth_m = r * dLat_rad;
    double smallLat_rad = radiansPerDegree * Math.min(Math.abs(that.lat),
                                                      Math.abs(this.lat));
    double dLon_rad = radiansPerDegree * (that.lon - this.lon);
    double dEast_m = r * Math.cos(smallLat_rad) * dLon_rad;
    return Math.sqrt(dNorth_m * dNorth_m + dEast_m * dEast_m);
  }

  /**
   * Equals if id, latitude, longitude, and name are all equal.
   */
  public @Override boolean equals(Object other) {
    if (other instanceof Stop) {
      Stop that = (Stop) other;
      return (this.id == that.id &&
              this.lat == that.lat &&
              this.lon == that.lon &&
              this.name.equals(that.name)); // ignore nameSansDiacritics
    } else return false;
  }
  /**
   * Hashcode calculated from id, latitude, longitude, and name.
   */
  public @Override int hashCode() {
    return (hashLong(this.id) + hashDouble(this.lat) + hashDouble(this.lon) +
            this.name.hashCode());
  }
  private int hashDouble(double d) {
    // from Double.hashCode
    return hashLong(Double.doubleToLongBits(d));
  }
  private int hashLong(long v) {
    // from Double.hashCode
    return (int)(v^(v>>>32));
  }

  /**
   * Compare by id.  Required by the Comparable interface, used in
   * small space-efficient TreeSet<Stop>.
   */
  public @Override int compareTo(Stop that) {
    return (this.id < that.id ? -1 :
            this.id > that.id ? 1 : 0);
  }

  /**
   * <code>Stop(id=<em>N</em>, lat=<em>N.N</em>, lon=<em>N.N</em>, name=<em>S</em>)</code>
   */
  public @Override String toString() {
    return ("Stop(id="+id+", lat="+lat+", lon="+lon+ ", name="+name+")");
  }
}
