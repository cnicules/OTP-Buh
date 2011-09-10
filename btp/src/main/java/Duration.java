class Duration {
  public final int hours, minutes, seconds;
  Duration() { this(0,0,0); }
  Duration(int hours, int minutes, int seconds) {
    if (!(0 <= hours))
      throw new IllegalArgumentException("h="+hours);
    if (!(0 <= minutes && minutes < 60))
      throw new IllegalArgumentException("m="+minutes);
    if (!(0 <= seconds && seconds < 60))
      throw new IllegalArgumentException("s="+seconds);
    this.hours = hours;
    this.minutes = minutes;
    this.seconds = seconds;
  }
  public static Duration parseDuration(String hh_mm_ss) {
    String[] parts = hh_mm_ss.split(":");
    int hours, minutes, seconds;
    try {
      hours = Integer.parseInt(parts[0]);
      minutes = (parts.length > 1 ? Integer.parseInt(parts[1]) : 0);
      seconds = (parts.length > 2 ? Integer.parseInt(parts[2]) : 0);
    } catch (NumberFormatException ex) {
      throw new NumberFormatException("unparseable duration: "+hh_mm_ss);
    }
    return new Duration(hours, minutes, seconds);
  }
  public @Override String toString() {
    StringBuilder sb = new StringBuilder();
    if (this.hours < 10) sb.append('0');
    sb.append(this.hours);
    sb.append(':');
    if (this.minutes < 10) sb.append('0');
    sb.append(this.minutes);
    sb.append(':');
    if (this.seconds < 10) sb.append('0');
    sb.append(seconds);
    return sb.toString();
  }
  public Duration plus(Duration that) {
    int secondsSum = this.seconds + that.seconds;
    int seconds = secondsSum % 60;
    int minutesCarry = secondsSum / 60;
    int minutesSum = this.minutes + that.minutes + minutesCarry;
    int minutes = minutesSum % 60;
    int hoursCarry = minutesSum / 60;
    int hours = this.hours + that.hours + hoursCarry;
    return new Duration(hours, minutes, seconds);
  }
}
