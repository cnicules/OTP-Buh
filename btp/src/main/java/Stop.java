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
  public long getId() { return this.id; }
  public double getLat() { return this.lat; }
  public double getLon() { return this.lon; }
  public String getName() { return this.name; }
  public String getNameSansDiacritics() { return this.nameSansDiacritics; }
  
  public @Override boolean equals(Object other) {
    if (other instanceof Stop) {
      Stop that = (Stop) other;
      return (this.id == that.id &&
              this.lat == that.lat &&
              this.lon == that.lon &&
              this.name.equals(that.name)); // ignore nameSansDiacritics
    } else return false;
  }
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

  public int compareTo(Stop that) {
    return (this.id < that.id ? -1 :
            this.id > that.id ? 1 : 0);
  }

  public @Override String toString() {
    return ("Stop(id="+id+", lat="+lat+", lon="+lon+ ", name="+name+")");
  }
}
