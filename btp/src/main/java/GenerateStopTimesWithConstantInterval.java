import java.io.File;
import java.io.FileReader;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

import java.text.Collator;
import java.text.CollationKey;
import java.text.MessageFormat;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.TreeSet;
import java.util.TreeMap;
import java.util.logging.FileHandler;
import java.util.logging.Formatter;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.LogManager;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.XMLReaderFactory;

import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;

/**
 * Generate stop times using a constant inter-station travel duration
 * between stops and a constant boarding duration at each stop. <p/>
 *
 * For each stop writes 
 * tripId, arrival time, deparature time, stop id, sequence number, headsign.
 * <p/>
 *
 * A stop time is written for each stop in the schedule stop-sequence.
 * (It is more accurate and complete than the stops in the map route.)
 * When the map route contains a stop with the same name, it is used
 * for the stop id (used for location).  Otherwise if another route of
 * the same type contains a stop with the same name, that stop is
 * used.  Otherwise if there is a previous stop, it is substituted.
 * Otherwise the next stop is substituted.  If no map stops are found
 * for the scheduled route, then the trip is omitted.  <p/>
 *
 * In all error cases (cases other than a single stop on the map route
 * is found with the same name as the stop in the schedule), a message
 * explaining the problem is written to System.err. <p/>
 */
public class GenerateStopTimesWithConstantInterval {
  public static void main(String[] args) {
    if (args.length != 11) {
      System.err.println
        ("parameters: lang routeType trafficSide "+
         "tripsXml stopSeqsXml routesStopsXml stopsXml "+
         "boardingDur travelDur outXml errLog\n"+
         " where:\n"+
         "  lang        lowercase 2-letter ISO-639 language code\n"+
         "  trafficSide LEFT or RIGHT\n"+
         "  routeType   OSM route type: "
         +             "railway|subway|tram|trolleybus|bus|ferry\n"+
         "  tripsXml    trips/trip/{@tripId,@route_short_name,@direction}\n"+
         "  stopSeqsXml stop-sequences/route{@short_name}/stop-sequence{@dir}/"+
         "stop/{@number,@name}\n"+
         "  routeStopsXml route-stops/route/"+
         "stop{@stop_id,@stop_lat,@stop_lon,@stop_name}\n"+
         "  stopsXml    stops/stop/{@stop_id,@stop_name}\n"+
         "  boardingDur is hours:minutes:seconds duration like 00:00:20\n"+
         "  travelDur   is hours:minutes:seconds duration like 00:02:40\n"+
         "  outXml      result stop-times.xml file\n"+
         "  errLog      log file for error and warning messages");
      System.exit(SysExits.EX_USAGE);
    }

    // parse parameters
    int p = 0;
    Locale locale = new Locale(args[p++]);
    String trafficSideString = args[p++];
    TrafficSide trafficSide;
    try { trafficSide = TrafficSide.valueOf(trafficSideString.toUpperCase()); }
    catch (IllegalArgumentException ex) {
      System.err.println("trafficSide must be LEFT or RIGHT: "+trafficSideString);
      System.exit(SysExits.EX_USAGE);
      throw new AssertionError(); // satisfy compiler
    }
    String routeType = args[p++];
    File tripsXml = new File(args[p++]);
    File stopSeqsXml = new File(args[p++]);
    File routeStopsXml = new File(args[p++]);
    File stopsXml = new File(args[p++]);
    for (File file : new File[]{tripsXml,stopSeqsXml,routeStopsXml,stopsXml}) {
      if (!file.exists()) {
        System.err.println("file not found: "+file);
        System.exit(SysExits.EX_NOINPUT);
      }
      if (!file.canRead()) {
        System.err.println("file unreadable: "+file);
        System.exit(SysExits.EX_NOINPUT);
      }
      if (file.length() == 0) {
        System.err.println("file empty: "+file);
        System.exit(SysExits.EX_NOINPUT);
      }
    }
    Duration boardingDur, travelDur;
    try { 
      boardingDur = Duration.parseDuration(args[p++]);
      travelDur = Duration.parseDuration(args[p++]);
    } catch (NumberFormatException ex) {
      System.err.println(ex.getMessage());
      System.exit(SysExits.EX_USAGE);
      throw new AssertionError(); // satisfy compiler
    }
    File outXml = new File(args[p++]);
    if (outXml.exists()) {
      System.err.println("Will overwrite "+outXml);
    }
    File errLog = new File(args[p++]);
    try { 
      GenerateStopTimesWithConstantInterval generator =
        new GenerateStopTimesWithConstantInterval
        (locale, trafficSide, routeType, tripsXml, stopSeqsXml, routeStopsXml, stopsXml,
         boardingDur, travelDur, outXml, errLog);
      generator.run();
    } catch (IOException ex) {
      System.err.println(ex);
      System.exit(SysExits.EX_CANTCREAT);
    } catch (Throwable th) {
      th.printStackTrace();
      System.exit(SysExits.EX_SOFTWARE);
    }
  }
  
  private final Duration boardingDur, travelDur;
  private final File tripsXml, stopSeqsXml, routeStopsXml, stopsXml, outXml;
  private final String routeType;
  private final TrafficSide trafficSide;

  private final StopFromId stopFromId = new StopFromId();
  private final StopsFromName stopsFromName;
  private final Map<String, Set<Stop>> stopsFromMapRoute =
    new LinkedHashMap<String, Set<Stop>>();
  private final XPath xpath = XPathFactory.newInstance().newXPath();

  /** {route:{dir:List<stopSeq>}}, where stopSeq is List<stop>.
      dir is "forward" or "backward".
      There may be multiple partial trips or local/express trips on a route. **/
  private Map<String, Map<String, List<List<Stop>>>> stopsFromSched =
    new LinkedHashMap<String, Map<String, List<List<Stop>>>>();

  private final Logger LOG = Logger.getLogger(this.getClass().getName());

  /**
   * Construct generator and initialize log handler.
   * @param locale identifies language used for collator for matching names.
   * @param trafficSide the side of the way on which traffic travels.
   * @param routeType OSM route type, such as 
   * railway, subway, tram, trolleybus, bus, or ferry; used in log messages.
   * @param tripsXml for each trip, the id, the route, direction,
   *   and begin and end stops:
   *   trips/trip{&#64;trip_id, &#64;route_shortName, &#64;direction_id,
   *   &#64;beginStop, &#64;endStop} where beginStop and endStop are schedule names.
   * @param stopSeqsXml for each route,
   *   sequence of stop names parsed from schedule:
   *   stop-sequences/route{&#64;short_name}/stop-sequence{&#64;dir}/stop{&#64;name}
   * @param routeStopsXml for each route,
   *   sequence of stops data parsed from OSM map data:
   *   route-stops/route{&#64;route_short_name}/stop{&#64;stop_id,&#64;stop_lat,&#64;stop_lon,&#64;stop_name}
   * @param stopsXml contains stop names possibly with Romanian diactrics removed:
   *   stops/stop{&#64;stop_id,&#64;stop_lat,&#64;stop_lon,&#64;stop_name[,&#64;stop_name_sans_diacritics]}
   * @param boardingDur constant boarding time to use at each stop.
   * @param travelDur constant travel time to use between stops.
   * @param outXml where to write result stop_times.xml file.
   * @param errLog where to write log messages.
   *
   * @throws IOException if errLog cannot be created.
   * @throws NullPointerException if any parameter is null.
   */
  public GenerateStopTimesWithConstantInterval
    (Locale locale, TrafficSide trafficSide, String routeType,
     File tripsXml, File stopSeqsXml, File routeStopsXml, File stopsXml,
     Duration boardingDur, Duration travelDur,
     File outXml, File errLog) throws IOException
  {
    if (locale == null || trafficSide == null ||
        tripsXml == null || stopSeqsXml == null || stopsXml == null ||
        boardingDur == null || travelDur == null ||
        outXml == null || errLog == null)
      throw new NullPointerException();
    this.tripsXml = tripsXml;
    this.stopSeqsXml = stopSeqsXml;
    this.routeStopsXml = routeStopsXml;
    this.stopsXml = stopsXml;
    this.boardingDur = boardingDur;
    this.travelDur = travelDur;
    this.outXml = outXml;
    this.stopsFromName = new StopsFromName(locale);
    this.routeType = routeType;
    this.trafficSide = trafficSide;
    initLogHandler(errLog);
  }

  /**
   * Create indexes of map stops. 
   * <ul>
   * <li>{@link #parseMapStops} indexes map stops from <code>stopsXml</code>
   *     by id and name,
   * <li>{@link #parseRouteStops} indexes map stops from
   *     <code>routeStopsXml</code> by route.
   * <li>{@link #locateScheduledStops} indexes map stops by route and scheduled
   *     order.
   * </ul>
   * Called by {@link #run}.
   */
  protected void init() {
    parseMapStops(this.stopsXml);
    parseRouteStops(this.routeStopsXml);
    locateScheduledStops();
  }

  /**
   * {@link #init Initialize} indexes to find stop ids stops on for each route,
   * then iterate over trips in <code>tripsXml</code> to 
   * calculate and write stop times to <code>outXml</code>.
   * The heuristic for calculating times is to add <code>boardingDur</code>
   * and <code>travelDur</code> at each stop.
   * A trip will be skipped if no mapped stops were found for its route.
   */
  public void run() throws IOException {
    init();

    FileOutputStream out = new FileOutputStream(this.outXml);
    OutputStreamWriter outWriter;
    try { outWriter = new OutputStreamWriter(out, "UTF-8"); }
    catch (UnsupportedEncodingException never) { throw new Error(never); }
    PrintWriter pw = new PrintWriter(outWriter);
    pw.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    pw.println("<!-- note: unmatched stops re-use prior (or next) stop_id -->");
    pw.println("<stop-times>");

    NodeList tripNodeList = selectElements(this.tripsXml, "/trips/trip");
    Element stopSequences = selectElement(this.stopSeqsXml, "/stop-sequences");
    tripLoop:
    for (int i = 0; i < tripNodeList.getLength(); i++) {
      Element tripElement = (Element) tripNodeList.item(i);
      String tripId = tripElement.getAttribute("trip_id");
      String tripRteIdAttr = tripElement.getAttribute("route_id");
      String tripRteName = tripElement.getAttribute("route_short_name");
      String tripSvc = tripElement.getAttribute("service_id");
      String tripDirAttr = tripElement.getAttribute("direction_id");
      String tripDir = ("0".equals(tripDirAttr) ? "forward" :
                        "1".equals(tripDirAttr) ? "backward" : null);
      String tripBeginStopName = tripElement.getAttribute("beginStop");
      String tripEndStopName   = tripElement.getAttribute("endStop");
      Long tripRteId = null;
      try { tripRteId = Long.valueOf(tripRteIdAttr); }
      catch (NumberFormatException ex) {
        LOG.log(Level.SEVERE,
                "Trip "+tripId+" contains invalid route_id: "+tripRteIdAttr,
                logParams(LogMsg.TRIP_ROUTE_ID_INVALID,
                          new RouteInfo(tripRteName, null, tripDir, null, null),
                          tripSvc, tripId));
      }
      RouteInfo routeInfo =
        makeTripRouteInfo(stopSequences, tripId, tripRteId, tripRteName,
                          tripDir, tripBeginStopName, tripEndStopName);
      if (routeInfo == null) { // could not find routeInfo (logged problem)
        continue tripLoop;
      }
      if (tripDir == null) {
        LOG.log(Level.SEVERE,
                "trip "+tripId+" direction "+ tripDirAttr+" is not 0 or 1.",
                logParams(LogMsg.TRIP_ROUTE_DIR_INVALID,
                          routeInfo, tripSvc, tripId));
        continue tripLoop;
      }
      List<Stop> tripStops = getTripStops(routeInfo, 
                                          tripBeginStopName, tripEndStopName,
                                          tripSvc, tripId);
      if (tripStops == null) {
        continue tripLoop; // could not find stops (and logged problem)
      }

      String headSign = tripStops.get(tripStops.size() - 1).getName();
      Duration tripDur = new Duration();
      for (int j = 0; j < tripStops.size(); j++) {
        Stop stop = tripStops.get(j);
        assert stop != null;

        pw.print("  <stop-time trip_id=\""+tripId+'\"');
        pw.print(  " arrival_time=\""+tripDur+'\"');
        tripDur = tripDur.plus(this.boardingDur);
        pw.print(  " departure_time=\""+tripDur+'\"');
        tripDur = tripDur.plus(this.travelDur);
        pw.print(  " stop_id=\""+stop.getId()+'\"');
        pw.print(  " stop_sequence=\""+ (j < 10 ? "0"+j : j)+'\"');
        pw.print(  " stop_headsign=\""+ headSign+'\"');
        pw.println("/>");
      }
      
    }
    pw.println("</stop-times>");
    pw.close();
  }
  private RouteInfo makeTripRouteInfo(Element stopSequences,
                                      String tripId, Long tripRteId,
                                      String tripRteName, String tripDir,
                                      String tripBeginStopName,
                                      String tripEndStopName) {
    String tripDirBeginStopName =
      "forward".equals(tripDir)? tripBeginStopName : tripEndStopName;
    String tripDirEndStopName = 
      "backward".equals(tripDir)? tripBeginStopName : tripEndStopName;
    Element stopSeqElement =
      selectElement
      (stopSequences,
       ("route[@short_name='"+tripRteName+"']/"+
        "stop-sequence[@dir='"+tripDir+"' and "
        +             "stop[1]/@name='"+tripDirBeginStopName+"' and "
        +             "stop[last()]/@name='"+tripDirEndStopName+"']"));
    boolean logChoseOnlySeqElement = false;
    if (stopSeqElement == null) { 
      NodeList routes =
        selectElements(stopSequences, "route[@short_name='"+tripRteName+"']");
      if (routes.getLength() == 1) {
        // single trip on same line: select it by direction
        // (more robust in case begin/end stops are spelled differently)
        // (may happen when frequencies and stopSeqs are not generated from
        // same source, or there is a spelling disagreement within the page).
        stopSeqElement = 
          selectElement(stopSequences,
                        "route[@short_name='"+tripRteName+"']/"+
                        "stop-sequence[@dir='"+tripDir+"']");
        logChoseOnlySeqElement = true;
      }
    }
    if (stopSeqElement == null) {
      LOG.log(Level.SEVERE,
              ("Trip "+tripId+": No stop sequence found from "+
               "\""+tripDirBeginStopName+"\" to \""+ tripDirEndStopName+"\"."),
              logParams(LogMsg.TRIP_ROUTE_STOP_SEQ_NOT_FOUND,
                        new RouteInfo(tripRteName, tripRteId, tripDir,
                                      null, null)));
      return null;
    }
    Integer[] beginEndSeqNrs;
    try {
      beginEndSeqNrs = getBeginEndSeqNrs(stopSeqElement,
                                         tripRteName, tripDir);
    } catch (NumberFormatException ex) {
      LOG.log(Level.SEVERE, ex.getMessage(),
              logParams(LogMsg.TRIP_ROUTE_STOP_SEQ_NUMBERS_NOT_FOUND,
                        new RouteInfo(tripRteName, tripRteId, tripDir,
                                      null, null)));
      return null;
    }
    RouteInfo routeInfo =
      new RouteInfo(tripRteName, tripRteId, tripDir,
                    beginEndSeqNrs[0], beginEndSeqNrs[1]);
    if (logChoseOnlySeqElement) {
      String seqBeginStopName =
        selectAttribute(stopSeqElement, "stop[1]/@name");
      String seqEndStopName = 
        selectAttribute(stopSeqElement, "stop[last()]/@name");
      if (!tripDirBeginStopName.equals(seqBeginStopName)) {
        LOG.log(Level.FINEST,
                ("Ignored spelling difference between\n"+
                 "\""+tripDirBeginStopName+"\" from trip "+tripId+
                 " frequencies, and\n"+
                 "\""+seqBeginStopName+ "\" that begins the only "+
                 this.routeType+" "+tripRteName+" "+tripDir+" stop-sequence."),
                logParams(LogMsg.SCHED_STOP_MATCHED_TO_ONLY_SEQ_BEGIN,
                          routeInfo, beginEndSeqNrs[0]));
      }
      if (!tripDirEndStopName.equals(seqEndStopName)) {
        LOG.log(Level.FINEST,
                ("Ignored spelling difference between\n"+
                 "\""+tripDirEndStopName+"\" from trip "+tripId+
                 " frequencies, and\n"+
                 "\""+ seqEndStopName+ "\" that ends the only "+
                 this.routeType+" "+tripRteName+" "+tripDir+" stop-sequence."),
                logParams(LogMsg.SCHED_STOP_MATCHED_TO_ONLY_SEQ_END,
                          routeInfo, beginEndSeqNrs[1]));
      }
    }

    return routeInfo;
  }
  private List<Stop> getTripStops(RouteInfo routeInfo,
                                  String tripBeginStopName,
                                  String tripEndStopName,
                                  String tripSvc, String tripId) {
    String tripRteName = routeInfo.name, tripDir = routeInfo.dir;

    Map<String, List<List<Stop>>> routeSequences =
      this.stopsFromSched.get(tripRteName);
    if (routeSequences == null) {
      LOG.log(Level.WARNING,
              ("skipping trip "+tripId+
               " because no located stops found for route "+tripRteName),
              logParams(LogMsg.TRIP_ROUTE_HAS_NO_LOCATED_STOPS,
                        routeInfo, tripSvc, tripId));
      return null;
    }
    List<List<Stop>> tripsStopSeqs = routeSequences.get(tripDir);
    if (tripsStopSeqs == null) {
      LOG.log(Level.WARNING,
              ("skipping trip "+tripId+
               " because no located stops found for route "+
               tripRteName+ " and direction "+tripDir+"."),
              logParams(LogMsg.TRIP_ROUTE_DIR_HAS_NO_LOCATED_STOPS,
                        routeInfo, tripSvc, tripId));
      return null;
    }
    List<Stop> tripStops = null;
    if (tripsStopSeqs.size() == 1) {
      tripStops = tripsStopSeqs.get(0);
    } else { 
      findTripStop:
      for (List<Stop> stopSeq : tripsStopSeqs) {
        int lastIndex = stopSeq.size() - 1;
        String seqBeginStopName = stopSeq.get(0).getName();
        String seqEndStopName = stopSeq.get(lastIndex).getName();
        if ("forward".equals(tripDir)) {
          if (tripBeginStopName.equalsIgnoreCase(seqBeginStopName) &&
              tripEndStopName.equalsIgnoreCase(seqEndStopName)) {
            tripStops = stopSeq;
            break findTripStop;
          }
        } else if ("backward".equals(tripDir)) {
          if (tripBeginStopName.equalsIgnoreCase(seqEndStopName) &&
              tripEndStopName.equalsIgnoreCase(seqBeginStopName)) {
            tripStops = stopSeq;
            break findTripStop;
          }
        }
      }
    }
    if (tripStops == null) {
      StringBuilder sb = new StringBuilder("[");
      int initialLength = sb.length();
      for (List<Stop> tripStopSeq : tripsStopSeqs) {
        if (sb.length() > initialLength)
          sb.append(", ");
        int lastIndex = tripStopSeq.size() - 1;
        String seqBeginStopName = tripStopSeq.get(0).getName();
        String seqEndStopName = tripStopSeq.get(lastIndex).getName();
        if ("forward".equals(tripDir)) {
          sb.append("("+seqBeginStopName+", "+ seqEndStopName+")");
        } else if ("backward".equals(tripDir)) {
          sb.append("("+seqEndStopName+", "+ seqBeginStopName+")");
        }
      }
      sb.append("]");
      LOG.log(Level.SEVERE,
              ("skipping trip "+tripId+
               " because no trips found that run "+tripDir+ " between "+
               tripBeginStopName+ " and "+tripEndStopName+": "+sb),
              logParams(LogMsg.TRIP_ROUTE_STOP_SEQ_NOT_FOUND,
                        routeInfo, tripSvc));
      return null;
    }
    return tripStops;
  }

  /**
   * Index of stops by map id.
   */
  protected class StopFromId  {
    private final HashMap<Long, Stop> map = new HashMap<Long, Stop>();
    public boolean add(Stop stop) {
      Stop oldStop = this.map.put(stop.getId(), stop);
      if (oldStop != null) {
        if (!stop.equals(oldStop)) {
          throw new IllegalArgumentException("conflicting stops: \n"+
                                             "  "+oldStop+"\n"+
                                             "  "+stop);
        } else return false;
      } else return true;
    }
    public Stop get(Long id) {
      return this.map.get(id);
    }
    public boolean isEmpty() { return this.map.isEmpty(); }
  }

  /**
   * Map name to set of map stops that match the name.
   * Matching is performed with a primary Collator 
   * so case is insignificant and some diacritics may be ignored.
   */
  protected class StopsFromName {
    private final Collator collator;
    private final HashMap<CollationKey, Set<Stop>> map =
      new HashMap<CollationKey, Set<Stop>>();
    StopsFromName(Locale locale) {
      this.collator = Collator.getInstance(locale);
      // recognize diacritics
      this.collator.setDecomposition(Collator.CANONICAL_DECOMPOSITION);
      // letter without and with various diacritics are equivalent
      this.collator.setStrength(Collator.PRIMARY);
    }

    boolean add(Stop stop) {
      String nameForKey = stop.getNameSansDiacritics();
      if (nameForKey == null) {
        nameForKey = stop.getName();
      }
      CollationKey key = this.collator.getCollationKey(nameForKey);
      Set<Stop> stopSet = this.map.get(key);
      if (stopSet == null) {
        stopSet = new TreeSet<Stop>();
        this.map.put(key, stopSet);
      }
      return stopSet.add(stop);
    }
    Set<Stop> get(String name) {
      return this.map.get(this.collator.getCollationKey(name));
    }
    boolean isEmpty() { return this.map.isEmpty(); }
  }

  /**
   * Parse all stops generated from all routes on the OSM map,
   * and index them by id, and index them by name.  Multiple stops
   * may have the same name.
   */
  protected void parseMapStops(File stopsXml) {
    NodeList nodeList = selectElements(stopsXml, "/stops/stop");
    for (int i = 0; i < nodeList.getLength(); i++) {
      Element stopElement = (Element) nodeList.item(i);
      Stop stop =
        new Stop(Long.parseLong(stopElement.getAttribute("stop_id")),
                 Double.parseDouble(stopElement.getAttribute("stop_lat")),
                 Double.parseDouble(stopElement.getAttribute("stop_lon")),
                 stopElement.getAttribute("stop_name"),
                 stopElement.getAttribute("stop_name_sans_diacritics"));
      this.stopFromId.add(stop);
      this.stopsFromName.add(stop);
    }
  }

  /**
   * Parse stops generated for each route from OSM data to
   * create stopsFromMapRoute (routeName to routeStops).
   */
  protected void parseRouteStops(File routeStopsXml) {
    assert !this.stopFromId.isEmpty();
    this.stopsFromMapRoute.clear();
    NodeList routeList = selectElements(routeStopsXml, "/route-stops/route");
    for (int i = 0; i < routeList.getLength(); i++) {
      Element routeElement = (Element) routeList.item(i);
      String routeName = routeElement.getAttribute("route_short_name");
      Set<Stop> routeStopSet = new LinkedHashSet<Stop>();
      NodeList routeStopList = selectElements(routeElement, "stop");
      for (int j = 0; j < routeStopList.getLength(); j++) {
        Element stopElement = (Element) routeStopList.item(j);
        Stop routeStop =
          new Stop(Long.parseLong(stopElement.getAttribute("stop_id")),
                   Double.parseDouble(stopElement.getAttribute("stop_lat")),
                   Double.parseDouble(stopElement.getAttribute("stop_lon")),
                   stopElement.getAttribute("stop_name"));
        // if generated from same osm file, route stop ids should be found
        // in stop ids.
        Stop stop = this.stopFromId.get(routeStop.getId());
        if (stop == null) {
          throw new IllegalArgumentException
            ("Inconsistent files: stop "+stop.getId()+
             " from "+this.routeStopsXml+" was not found in "+
             this.stopsXml);
        } else if (!routeStop.equals(stop)) {
          throw new IllegalArgumentException
            ("Inconsistent files: stop "+stop.getId()+
             " from "+this.routeStopsXml+" was not the same in "+
             this.stopsXml);
        }
        // stops may be traversed twice in osm data where two ways join.
        routeStopSet.add(stop);
      }
      this.stopsFromMapRoute.put(routeName, routeStopSet);
    }
  }

  /**
   * For each stop name in each scheduled route, find the stops from
   * the map for that route, filling this.stopsFromSchedule.
   * Names are matched by {@link StopsFromName}.
   * <ul>
   * <li>If a schedule stop name matches one stop on the map route,
   *   use that stop.
   * <li>If a schedule stop name matches more than one stop on the map route,
   *   pick one (the closest to latest stop, or first if no latest stop). 
   * <li>If a name is not found on the given map route but is on another route
   *   with the same route type, substitute one of the other stops
   *   (the closest to latest stop, or first if no latest stop).
   * <li>If a name is not found on any route, substitute the latest stop if
   *   possible, otherwise the next stop.
   * </ul>
   * Missing stops are substituted, not skipped, so that the result will hold
   * the correct number of stops (needed for the fixed duration-per-stop
   * timing heuristic).
   */
  protected void locateScheduledStops() {
    this.stopsFromSched.clear();
    LoggedStopCounts counts = new LoggedStopCounts();
    Element stopSeqsRoot = selectElement(this.stopSeqsXml, "/stop-sequences");
    NodeList schedRouteNodeList = selectElements(stopSeqsRoot, "route");
    Element routeStopsElement =
      selectElement(this.routeStopsXml, "/route-stops");
    for (int i = 0; i < schedRouteNodeList.getLength(); i++) {
      String routeName;
      List<Element> schedRouteElements = new ArrayList<Element>(); {
        Element firstSchedRouteElement = (Element) schedRouteNodeList.item(i);
        routeName = firstSchedRouteElement.getAttribute("short_name");
        schedRouteElements.add(firstSchedRouteElement);
        for (; i+1 < schedRouteNodeList.getLength(); i++) {
          Element nextRouteElement = (Element) schedRouteNodeList.item(i+1);
          String nextName = nextRouteElement.getAttribute("short_name");
          if (routeName.equals(nextName)) {
            schedRouteElements.add(nextRouteElement);
          } else break;
        }
      }

      Set<Stop> routeStops = this.stopsFromMapRoute.get(routeName);
      if (routeStops == null) {
        LOG.log(Level.SEVERE,
                "Route "+this.routeType+" "+routeName+" not found in OSM map.",
                logParams(LogMsg.SCHED_ROUTE_NOT_FOUND_IN_OSM, routeName));
        routeStops = Collections.emptySet();
      }
      Long routeId = null; {
        Element routeElement =
          selectElement(routeStopsElement,
                        "route[@route_short_name='"+routeName+"']");
        if (routeElement != null) { 
          String mapRouteIdAttr = routeElement.getAttribute("route_id");
          try { routeId = Long.valueOf(mapRouteIdAttr); }
          catch (Exception ex) {
            LOG.log(Level.SEVERE,
                    ("Route "+this.routeType+" "+routeName+
                     " has invalid route_id: "+ mapRouteIdAttr),
                    logParams(LogMsg.MAP_ROUTE_ID_INVALID, routeName));
          }
        } // else SCHED_ROUTE_NOT_FOUND_IN_OSM already logged.
      }

      // may be multiple partial or local/express trips on a route
      Map<String, List<List<Stop>>> seqStopsMap =
        this.stopsFromSched.get(routeName);
      if (seqStopsMap == null) {
        seqStopsMap = new TreeMap<String, List<List<Stop>>>();
        this.stopsFromSched.put(routeName, seqStopsMap);
      }

      locateSchedRouteStops(schedRouteElements, routeName, routeId, routeStops,
                            seqStopsMap, counts);

      if (seqStopsMap.isEmpty()) {
        LOG.log(Level.SEVERE,
                "Route "+this.routeType+" "+routeName+" has no located stops.",
                logParams(LogMsg.SCHED_ROUTE_HAS_NO_LOCATED_STOPS,
                          routeName, routeId));
        // do not add to stopsFromSched.
        counts.routeSkipCount++;
      } else {
        this.stopsFromSched.put(routeName, seqStopsMap);
        // does seqStopsMap contains any routeStops, or are all substitutes?
        boolean hasRouteStop = false; {
          findRouteStop:
          for (List<List<Stop>> seqs : seqStopsMap.values()) {
            for (List<Stop> seq : seqs) {
              for (Stop stop : seq) {
                if (routeStops.contains(stop)) {
                  hasRouteStop = true;
                  break findRouteStop;
                }
              }
            }
          }
        }
        if (!hasRouteStop) {
          LOG.log(Level.FINE,
                  ("Route "+this.routeType+" "+routeName+
                   " has only stops substituted from other routes."),
                  logParams(LogMsg.SCHED_ROUTE_HAS_ONLY_SUBST_STOPS,
                            routeName, routeId));
          counts.routeSubstCount++;
        }
      }
    }
    // log summary counts
    int schedRouteCount = countElements(stopSeqsRoot, "route");
    int schedDirSeqCount = countElements(stopSeqsRoot, "route/stop-sequence");
    int schedStopCount = countElements(stopSeqsRoot, "route/stop-sequence/stop");

    LOG.log(counts.routeSkipCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} {0} route{1,choice,0#s|1#|1<s} skipped "+
             "(out of {2} scheduled {0} route{2,choice,1#|1<s}).",
             this.routeType, counts.routeSkipCount, schedRouteCount),
            logParams(LogMsg.COUNT_OF_SKIPPED_ROUTE,
                      counts.routeSkipCount, schedRouteCount));
    LOG.log(counts.routeSubstCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} {0} route{1,choice,0#s|1#|1<s} "+
             "only contain{1,choice,0#|1#s|1<} substitute stops "+
             "(out of {2} scheduled {0} route{2,choice,1#|1<s}).",
             this.routeType, counts.routeSubstCount, schedRouteCount),
            logParams(LogMsg.COUNT_OF_SUBST_ROUTE,
                      counts.routeSubstCount, schedRouteCount));
    LOG.log(counts.seqSkipCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} {0} route stop sequence{1,choice,0#s|1#|1<s} skipped "+
             "(out of {2} {0} route stop sequence{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.seqSkipCount, schedDirSeqCount),
            logParams(LogMsg.COUNT_OF_SKIPPED_ROUTE_DIR,
                      counts.seqSkipCount, schedDirSeqCount));
    LOG.log(counts.missingStopCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} scheduled stop name{1,choice,0#s|1#|1<s} missing "+
             "(or spelled differently) from all map {0} routes "+
             "(out of {2} scheduled stop{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.missingStopCount, schedStopCount),
            logParams(LogMsg.COUNT_OF_SCHED_STOP_NAMES_MISSED_IN_MAP,
                      counts.missingStopCount, schedStopCount));
    LOG.log(counts.sameNameStopSubstCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} scheduled stop{1,choice,0#s|1#|1<s} substituted "+
             "with a stop with same name from another {0} route "+
             "(out of {2} scheduled stop{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.sameNameStopSubstCount, schedStopCount),
            logParams(LogMsg.COUNT_OF_SCHED_STOPS_SUBST_FROM_OTHER_MAP_ROUTE,
                      counts.sameNameStopSubstCount, schedStopCount));
    LOG.log(counts.stopDupCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} ambiguous/duplicate stop{1,choice,0#s|1#|1<s} "+
             " from all {0} routes "+
             " (out of {2} scheduled stop{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.stopDupCount, schedStopCount),
            logParams(LogMsg.COUNT_OF_SCHED_STOPS_AMBIGUOUS_IN_MAP,
                      counts.stopDupCount, schedStopCount));
    LOG.log(counts.notBetweenNeighborsCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} stop{1,choice,0#s|1#|1<s} are further from neighbors "+
             "than the distance between them: max(a-b, b-c) > a-c "+
             "(out of {2} scheduled {0} stop{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.notBetweenNeighborsCount, schedStopCount),
            logParams(
                      LogMsg.COUNT_OF_MAP_ROUTE_STOPS_NOT_BETWEEN_NEIGHBORS,
                      counts.notBetweenNeighborsCount, schedStopCount));
    int matchedMapStopCount = (schedStopCount - counts.missingStopCount
                               - counts.sameNameStopSubstCount);
    int mapStopCount = counts.mapStopsUnmatchedCount + matchedMapStopCount;
    LOG.log(counts.mapStopsUnmatchedCount > 0 ? Level.INFO : Level.FINE,
            MessageFormat.format
            ("{1} map route stop{1,choice,0#s|1#|1<s} are unmatched "+
             " in {0} routes "+
             "(out of about {2} map {0} stop{2,choice,0#s|1#|1<s}).",
             this.routeType, counts.mapStopsUnmatchedCount, mapStopCount),
            logParams(LogMsg.COUNT_OF_MAP_ROUTE_STOPS_NOT_MATCHED,
                      counts.mapStopsUnmatchedCount, mapStopCount));
  }

  private void locateSchedRouteStops(List<Element> schedRouteElements, 
                                     String routeName, Long routeId,
                                     Set<Stop> routeStops,
                                     Map<String, List<List<Stop>>> seqStopsMap,
                                     LoggedStopCounts counts){
    for (Element schedRouteElement : schedRouteElements) {
      locateSchedRouteStops(schedRouteElement, routeName, routeId, routeStops,
                            seqStopsMap, counts);
    }
    // log stops not matched in any seq of route
    LinkedHashSet<Stop> mapRouteStopsUnmatched =
      new LinkedHashSet<Stop>(routeStops);
    for (Map.Entry<String, List<List<Stop>>> entry : seqStopsMap.entrySet()) {
      String dir = entry.getKey();
      List<List<Stop>> stopSeqList = entry.getValue();
      for (List<Stop> stopSeq : stopSeqList) {
        removeMatchedStops(mapRouteStopsUnmatched, stopSeq);
      }
    }
    RouteInfo mapRouteInfo = new RouteInfo(routeName, routeId,
                                           "all", null,null);
    for (Stop stop : mapRouteStopsUnmatched) {
      LOG.log(Level.FINE,
              "Map route "+mapRouteInfo.mapString()+
              " contains unmatched stop: "+stop,
              logParams(LogMsg.MAP_ROUTE_STOP_NOT_MATCHED,
                        mapRouteInfo, stop));
    }
    int mapStopsCount = routeStops.size();
    int mapStopsUnmatchedCount = mapRouteStopsUnmatched.size();
    LOG.log(mapStopsUnmatchedCount > 0 ? Level.WARNING : Level.FINEST,
            MessageFormat.format
            ("Map route {0} contains {1} stop{1,choice,0#s|1#|1<s} "+
             "not matching stops in any scheduled trip on this route "+
             "(out of {2} stop{1,choice,0#s|1#|1<s|} on this map route).",
             mapRouteInfo.mapString(), mapStopsUnmatchedCount, mapStopsCount),
            logParams(LogMsg.MAP_ROUTE_STOPS_NOT_MATCHED_COUNT,
                      routeName, routeId,
                      mapStopsUnmatchedCount, mapStopsCount));
    counts.mapStopsUnmatchedCount += mapStopsUnmatchedCount;
  }
  private void locateSchedRouteStops(Element schedRouteElement, 
                                     String routeName, Long routeId,
                                     Set<Stop> routeStops,
                                     // output containers:
                                     Map<String, List<List<Stop>>> seqStopsMap,
                                     LoggedStopCounts counts){
    // stop-sequences/route/stop-sequence
    NodeList sequenceNodeList =
      selectElements(schedRouteElement, "stop-sequence");
    for (int j = 0; j < sequenceNodeList.getLength(); j++) {
      Element sequenceElement = (Element) sequenceNodeList.item(j);
      String dir = sequenceElement.getAttribute("dir");

      Integer[] beginEndSeqNrs;
      try{ beginEndSeqNrs = getBeginEndSeqNrs(sequenceElement, routeName, dir);}
      catch (NumberFormatException ex) {
        LOG.log(Level.SEVERE, ex.getMessage(),
                logParams(LogMsg.TRIP_ROUTE_STOP_SEQ_NUMBERS_NOT_FOUND,
                          new RouteInfo(routeName, routeId, dir, null, null)));
        continue;
      }
      RouteInfo routeInfo = new RouteInfo(routeName, routeId, dir,
                                          beginEndSeqNrs[0], beginEndSeqNrs[1]);

      List<Stop> seqStops = new ArrayList<Stop>();
      List<String> schedStopNamesUnmatched = new ArrayList<String>();
      List<Stop> schedStopsSubstFromOtherRoute = new ArrayList<Stop>();
      int notBetweenNeighborsCount = 0;

      locateSchedRouteSeqStops(sequenceElement, routeInfo,
                               routeStops, seqStops,
                               schedStopNamesUnmatched,
                               schedStopsSubstFromOtherRoute, counts);
      // analyze result
      //
      // for each triple of adjacent stops,
      // warn if middle is further from its neighbors
      // than distance between its neighbors.
      if (seqStops.size() > 2 && seqStops.get(0) != null) { 
        for (int p = 1; p < seqStops.size() - 1; p++) {
          Stop a = seqStops.get(p - 1);
          Stop b = seqStops.get(p);
          Stop c = seqStops.get(p + 1);
          double ab = a.distance_m(b);
          double bc = b.distance_m(c);
          double ac = a.distance_m(c);
          if (Math.max(ab, bc) > ac) {
            LOG.log(Level.WARNING,
                    ("Route "+routeInfo+ " stop "+p+" \""+b.getName()+"\""+
                     " is further from neighbors than distance between them: "+
                     b),
                    logParams(LogMsg.MAP_ROUTE_STOP_NOT_BETWEEN_NEIGHBORS,
                              routeInfo, p, b));
            counts.notBetweenNeighborsCount++;
            notBetweenNeighborsCount++;
          }
        }
      }
      if (seqStops.isEmpty() || seqStops.get(0) == null) { 
        // null would be replaced with later stop if there is one.
        LOG.log(Level.SEVERE,
                ("Route "+routeInfo+ " has no located stops."),
                logParams(LogMsg.SCHED_ROUTE_DIR_HAS_NO_LOCATED_STOPS,
                          routeInfo));
        // do not add to seqStopsMap.
        counts.seqSkipCount++;
      } else {
        assert !seqStops.contains(null);
        if (new TreeSet<Stop>(seqStops).size() < 2) {
          LOG.log(Level.SEVERE,
                  ("Route "+routeInfo+ " has less than 2 located stops."),
                  logParams(
                    LogMsg.SCHED_ROUTE_DIR_HAS_LESS_THAN_2_LOCATED_STOPS,
                    routeInfo));
          // do not add to seqStopsMap.
          counts.seqSkipCount++;
        } else /* has at least two located stops */ {
          List<List<Stop>> tripsStopSeqs = seqStopsMap.get(dir);
          if (tripsStopSeqs == null) {
            tripsStopSeqs = new ArrayList<List<Stop>>(1);
            seqStopsMap.put(dir, tripsStopSeqs);
          }
          tripsStopSeqs.add(seqStops);
        }
      }

      // log summary for console as well as log
      String summary = makeRouteSummary(routeInfo,
                                        schedStopNamesUnmatched,
                                        schedStopsSubstFromOtherRoute);
      Object[] summaryParams = new Object[]{
        LogMsg.SCHED_ROUTE_SUMMARY,
        this.routeType, routeInfo.name, routeInfo.id, routeInfo.dir,
        schedStopNamesUnmatched.size(),
        schedStopsSubstFromOtherRoute.size(),
        notBetweenNeighborsCount
      };
      if (!schedStopNamesUnmatched.isEmpty()) {
        LOG.log(Level.SEVERE, summary, summaryParams);
      } else if (summary.length() > 0) {
        LOG.log(Level.WARNING, summary, summaryParams);
      } else {
        LOG.log(Level.FINEST, "All stops matched!", summaryParams);
      }
    }
  }
  private void locateSchedRouteSeqStops(Element sequenceElement,
                                        RouteInfo routeInfo,
                                        Set<Stop> routeStops,
                                        List<Stop> seqStops,
                                        List<String> schedStopNamesUnmatched,
                                        List<Stop>
                                        schedStopsSubstFromOtherRoute,
                                        LoggedStopCounts counts) {
    Stop latestNonNullStop = null;
    NodeList schedStopNodeList =
      selectElements(sequenceElement, "stop");
    for (int k = 0; k < schedStopNodeList.getLength(); k++) {
      Element schedStopElement = (Element) schedStopNodeList.item(k);
      // check if same name is on route
      int seqNr = Integer.parseInt(schedStopElement.getAttribute("number"));
      String name = schedStopElement.getAttribute("name");
      Set<Stop> namedStops = stopsFromName.get(name);
      if (namedStops == null || namedStops.isEmpty()) { // no stops have name
        categorizeMissingStop(routeInfo, seqNr, name, latestNonNullStop,
                              seqStops, schedStopNamesUnmatched, counts);
      } else {
        Set<Stop> intersection = new TreeSet<Stop>(namedStops);
        intersection.retainAll(routeStops);
        if (intersection.size() == 1) {        // found unique match, so use it
          latestNonNullStop = intersection.iterator().next();
          seqStops.add(latestNonNullStop);
          if (LOG.isLoggable(Level.FINEST)) { 
            LOG.log(Level.FINEST,
                    "Matched "+latestNonNullStop,
                    logParams(LogMsg.MAP_ROUTE_STOP_MATCHED, routeInfo,
                              seqNr, latestNonNullStop));
          }
        } else if (intersection.size() > 1) {  // > 1 stops in route have name
          latestNonNullStop =
            chooseRouteDupStop(routeInfo, seqNr, name, intersection,
                               latestNonNullStop, seqStops, counts);
        } else {
          assert intersection.size() == 0;     // no ROUTE stops have name
          latestNonNullStop =
            chooseOffRouteStop(routeInfo, seqNr, name, namedStops,
                               latestNonNullStop, seqStops,
                               schedStopsSubstFromOtherRoute,
                               counts);
        }
        assert latestNonNullStop != null;
        assert seqStops.size() == k + 1;
        assert seqStops.get(k) != null;
        // fill in prior nulls with next nonNull
        for (int p = k - 1; p >= 0; p--) {
          if (seqStops.get(p) == null) {
            seqStops.set(p, latestNonNullStop);
          } else break;
        }
      }
    }
  }
  private void categorizeMissingStop(RouteInfo routeInfo, 
                                     int stopSeqNr, String stopName,
                                     Stop latestNonNullStop,
                                     List<Stop> seqStops,
                                     List<String> schedStopNamesUnmatched,
                                     LoggedStopCounts counts) {
    counts.missingStopCount++;
    schedStopNamesUnmatched.add(stopName);
    if (latestNonNullStop != null) { 
      LOG.log(Level.FINE,
              ("Scheduled "+routeInfo+
               " stop \""+stopName+"\" not in map "+this.routeType+" routes;"+
               " substituting latest stop"),
              logParams(LogMsg.SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_PRIOR,
                        routeInfo, stopSeqNr));
      seqStops.add(latestNonNullStop);
    } else {
      LOG.log(Level.FINE,
              ("Scheduled "+routeInfo+
               " stop \""+stopName+"\" not in map "+this.routeType+" routes;"+
               " will substitute next non-null stop."),
              logParams(LogMsg.SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER,
                        routeInfo, stopSeqNr));
      seqStops.add(null);
    }
  }
  private Stop chooseRouteDupStop(RouteInfo routeInfo,
                                  int stopSeqNr, String stopName,
                                  Set<Stop> intersection,
                                  Stop latestNonNullStop, List<Stop> seqStops,
                                  LoggedStopCounts counts){
    // Two stops are common, one located on each side of street; warn if more.
    Level logLevel = intersection.size() == 2 ? Level.FINE : Level.WARNING;
    String logReason = (!LOG.isLoggable(logLevel)? null :
                        "Map route "+routeInfo.mapString()+
                        " has "+intersection.size()+ " \""+stopName+"\" stops");
    assert intersection.size() > 1;
    if (latestNonNullStop == null) { 
      latestNonNullStop = intersection.iterator().next(); //take first
      Set<Stop> rest = new LinkedHashSet<Stop>(intersection);
      rest.remove(latestNonNullStop);
      if (LOG.isLoggable(logLevel)) {
        LOG.log(logLevel,
                (logReason + "; taking first for now:\n"+
                 "  "+latestNonNullStop+"\n"+
                 toLines("  not ", rest)),
                logParams(LogMsg.MAP_ROUTE_STOP_NAME_NOT_UNIQUE, routeInfo,
                          stopSeqNr, latestNonNullStop));
      }
    } else {
      latestNonNullStop =
        selectCloseStopOnTrafficSide(latestNonNullStop, intersection,
                                     logLevel, logReason,
                                     LogMsg.MAP_ROUTE_STOP_NAME_NOT_UNIQUE,
                                     routeInfo, stopSeqNr, stopName);
    }
    seqStops.add(latestNonNullStop); 
    counts.stopDupCount++;
    return latestNonNullStop;
  }
                                            
  private Stop chooseOffRouteStop(RouteInfo routeInfo,
                                  int stopSeqNr, String stopName,
                                  Set<Stop> namedStops,
                                  Stop latestNonNullStop, List<Stop> seqStops,
                                  List<Stop> schedStopsSubstFromOtherRoute,
                                  LoggedStopCounts counts){
    assert namedStops.size() >= 1;
    Level logLevel = Level.WARNING; // always warn of missing stops
    if (namedStops.size() == 1) {
      latestNonNullStop = namedStops.iterator().next();
      if (LOG.isLoggable(logLevel))
        LOG.log(logLevel,
                ("Map route "+routeInfo.mapString()+
                 " has no stop \""+stopName+"\"; "+
                 "substituting stop with same name from another "+
                 this.routeType+" route: "+ latestNonNullStop),
                logParams(LogMsg.SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE,
                          routeInfo, stopSeqNr, latestNonNullStop));
      seqStops.add(latestNonNullStop);
      counts.sameNameStopSubstCount++;
      schedStopsSubstFromOtherRoute.add(latestNonNullStop);
    } else {
      String logReason = (!LOG.isLoggable(logLevel) ? null :
                          "Map route "+routeInfo.mapString()+
                          " has no stop \""+stopName+"\" and "+
                          namedStops.size()+" stops have that name"+
                          " on other "+this.routeType+" route(s)");
      if (latestNonNullStop == null) { 
        latestNonNullStop = namedStops.iterator().next();
        Set<Stop> rest = new LinkedHashSet<Stop>(namedStops);
        rest.remove(latestNonNullStop);
        if (LOG.isLoggable(logLevel)) {
          LOG.log(logLevel,
                  (logReason + "; substituting first for now:\n"+
                   "  "+latestNonNullStop+"\n"+
                   toLines("  not ", rest)),
                  logParams(
                    LogMsg.SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE_NOT_UNIQUE,
                    routeInfo, stopSeqNr, latestNonNullStop));
        }
      } else {
        LogMsg errType = LogMsg.SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE;
        latestNonNullStop =
          selectCloseStopOnTrafficSide(latestNonNullStop, namedStops,
                                       logLevel, logReason, errType,
                                       routeInfo, stopSeqNr, stopName);
      }
      seqStops.add(latestNonNullStop);
      counts.sameNameStopSubstCount++;
      schedStopsSubstFromOtherRoute.add(latestNonNullStop);
    }
    return latestNonNullStop;
  }
  private static <E> String toLines(String indent, Collection<E> collection) {
    StringBuilder sb = new StringBuilder();
    for (E element : collection) {
      sb.append(indent).append(element).append('\n');
    }
    return sb.toString();
  }

  /**
   * Remove stops that have been matched from routeStops.  Also remove
   * stops that have the same name as a matched stop and are within
   * MAX_STOP_PAIR_DISTANCE_m meters (stop on opposite side of street).
   */
  private void removeMatchedStops(Set<Stop> routeStopsUnmatched,
                                  List<Stop> matchedStops) {
    routeStopsUnmatched.removeAll(matchedStops);
    // also remove stops that are near matchedStops (other side of street)
    if (!routeStopsUnmatched.isEmpty()) {
      Iterator<Stop> iter = routeStopsUnmatched.iterator();
      while (iter.hasNext()) {
        Stop unmatchedStop = iter.next(); 
        String unmatchedStopName = unmatchedStop.getName();
        if (unmatchedStopName != null && unmatchedStopName.length() > 0) {
          for (Stop stop : matchedStops) {
            if (stop != null && unmatchedStopName.equals(stop.getName()) &&
                unmatchedStop.distance_m(stop) <= MAX_STOP_PAIR_DISTANCE_m) {
              iter.remove(); // remove other of pair
              break;
            }
          }
        }
      }
    }
  }

  private String makeRouteSummary(RouteInfo routeInfo,
                                  List<String> schedStopNamesUnmatched,
                                  List<Stop> schedStopsSubstFromOtherRoute) {
    StringBuilder summary =
      new StringBuilder("Route "+routeInfo+":\n"); 
    int emptyLength = summary.length();

    if (!schedStopNamesUnmatched.isEmpty()) {
      summary.append("  "+schedStopNamesUnmatched.size()+
                     " unmatched schedule stops (not in other map "+
                     this.routeType+" routes):\n");
      for (String stopName : schedStopNamesUnmatched) {
        summary.append("    ").append(stopName).append('\n');
      }
    }

    if (!schedStopsSubstFromOtherRoute.isEmpty()) { 
      summary.append
        ("  "+schedStopsSubstFromOtherRoute.size()+
         " unmatched schedule stops (substituted stop"+
         " with same name found in another map "+ this.routeType+" route):\n");
      for (Stop stop : schedStopsSubstFromOtherRoute) {
        summary.append("    ").append(stop).append('\n');
      }
    }

    return summary.length() == emptyLength ? "" : summary.toString();
  }


  /**
   * From candidates, select the two stops closest to latestStop.
   * @return result[0] is closest stop, result[1] is next closest stop.
   */
  private Stop[] selectClosest2Stops(Stop latestStop, Set<Stop> candidates) {
    assert !candidates.isEmpty();
    Iterator<Stop> iterator = candidates.iterator();
    Stop closestStopYet = null, secondClosestStopYet = null;
    double closestDistanceYet = Double.POSITIVE_INFINITY;
    double secondClosestDistanceYet = Double.POSITIVE_INFINITY;
    for (Stop candidateStop : candidates) { 
      double candidateDistance = latestStop.distance_m(candidateStop);
      if (candidateDistance < closestDistanceYet) {
        secondClosestStopYet = closestStopYet;
        secondClosestDistanceYet = closestDistanceYet;
        closestStopYet = candidateStop;
        closestDistanceYet = candidateDistance;
      } else if (candidateDistance < secondClosestDistanceYet) {
        secondClosestStopYet = candidateStop;
        secondClosestDistanceYet = candidateDistance;
      }
    }
    return new Stop[]{closestStopYet, secondClosestStopYet};
  }
  /**
   * Max distance in meters between two stops with same name on same route,
   * between stops on opposite sides of street/square/plaza.
   */
  private static final double MAX_STOP_PAIR_DISTANCE_m = 200.0;
  /**
   * From candidates, select a close stop, preferring one
   * that appears to be on trafficSide when looking from latestStop. </p>
   *
   * If the distance between the two closest stops is greater than
   * MAX_STOP_PAIR_DISTANCE, then just choose the closest stop. <p/>
   *
   * If the distance between the two closest stops is 0, then
   * just return one of the stops. <p/>
   *
   * Otherwise choose, from the two closest candidates stops, the one
   * which is on trafficSide when looking from latestStop. <p/>
   *
   * (Rationale: assume terminus is a single stop, and other stops may
   * come in pairs on opposite sides of the street.  Choose the stop
   * in the pair that is on the same side of the street as the traffic
   * when traveling from latestStop to the stop.  This heuristic
   * should work for routes that are mostly straight, but might be
   * incorrect after turning a corner.)
   *
   * @param latestStop the latest matched stop.
   * @param candidates the candidate stops that match the name of the next stop.
   * @param trafficSide left or right (traffic travels on this side of road)
   * @param logLevel level at which to log match messages
   * @param logReason start of log message; explains how candidates were found.
   * @param errType encodes how candidates were found
   */
  private Stop selectCloseStopOnTrafficSide(Stop latestStop,
                                            Set<Stop> candidates,
                                            Level logLevel, String logReason,
                                            LogMsg errType,
                                            RouteInfo routeInfo,
                                            int stopSeqNr, String stopName) {
    assert candidates.size() >= 2;
    Stop[] twoClosestStops = selectClosest2Stops(latestStop, candidates);
    Stop stop0 = twoClosestStops[0], stop1 = twoClosestStops[1];
    double distBetween = stop0.distance_m(stop1);
    if (distBetween > MAX_STOP_PAIR_DISTANCE_m) {
      if (LOG.isLoggable(logLevel)) 
        LOG.log(logLevel,
                (logReason+"; "+
                 (errType.name().contains("SUBST") ? "subsituting" : "picking")+
                 " closest for now: "+stop0+"\n"+ 
                 " (next is "+Math.round(distBetween)+"m further: "+stop1+")"),
                logParams(errType, routeInfo, stopSeqNr, stop0));
      return stop0;
    }
    if (distBetween == 0.0) {
      LOG.log(Level.WARNING,
              ("Found two stops at same position, choosing first:\n  "+
               stop0+",\n  "+stop1),
              logParams(errType, routeInfo, stopSeqNr, stop0));
      return stop0;
    }
      
    double dir0 = latestStop.direction_deg(stop0);
    double dir1 = latestStop.direction_deg(stop1);

    double dirDiff = dir0 - dir1;
    // normalize into interval [-PI, +PI)
    if (dirDiff < -Math.PI)
      dirDiff += 2*Math.PI;
    else if (dirDiff >= Math.PI)
      dirDiff -= 2*Math.PI;

    if (dirDiff == 0) {
      if (LOG.isLoggable(logLevel)) 
        LOG.log(logLevel,
                (logReason+ "; "+
                 (errType.name().contains("SUBST") ? "subsituting" : "picking")+
                 " closest for now: "+
                 stop0+ " (next is at same angle from previous stop)"));
      return stop0; // rare: aligned, just pick closest for now.
    } 

    Stop result, reject;
    switch(this.trafficSide) {
      case LEFT:
        if (dirDiff > 0) { result = stop1; reject = stop0; }
        else             { result = stop0; reject = stop1; }
        break;
      case RIGHT: 
        if (dirDiff < 0) { result = stop1; reject = stop0; }
        else             { result = stop0; reject = stop1; }
        break;
      default: throw new AssertionError(this.trafficSide);
    }
    if (LOG.isLoggable(logLevel)) 
      LOG.log(logLevel,
              (logReason+ "; "+
               (errType.name().contains("SUBST") ? "subsituting" : "picking")+
               " closest on "+ this.trafficSide.name().toLowerCase()+
               " from previous stop for now: "+ result+"\n"+
               "  not the alternative: "+ reject),
              logParams(errType, routeInfo, stopSeqNr, result));
    return result;
  }
  /**
   * Left or right: traffic travels on this side of a bidirectional way.
   */
  public enum TrafficSide { LEFT, RIGHT }

  private int countElements(Node contextNode, String xpathExpression) {
    try {
      Double count = (Double) xpath.evaluate("count("+xpathExpression+")",
                                             contextNode,
                                             XPathConstants.NUMBER);
      return count.intValue();
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private Element selectElement(File xmlFile, String xpathExpression) {
    try { 
      return (Element)
        xpath.evaluate(xpathExpression,
                       makeUTF8InputSource(xmlFile),
                       XPathConstants.NODE);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private Element selectElement(Node contextNode, String xpathExpression) {
    try { 
      return (Element)
        xpath.evaluate(xpathExpression,
                       contextNode,
                       XPathConstants.NODE);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private NodeList selectElements(File xmlFile, String xpathExpression) {
    try { 
      return (NodeList)
        xpath.evaluate(xpathExpression,
                       makeUTF8InputSource(xmlFile),
                       XPathConstants.NODESET);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private NodeList selectElements(Node contextNode, String xpathExpression) {
    try { 
      return (NodeList)
        xpath.evaluate(xpathExpression,
                       contextNode,
                       XPathConstants.NODESET);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private String selectAttribute(Node contextNode, String xpathExpression) {
    try { 
      return (String)
        xpath.evaluate(xpathExpression,
                       contextNode,
                       XPathConstants.STRING);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private static InputSource makeUTF8InputSource(File xmlFile) {
    InputSource inputSource = new InputSource(xmlFile.toString());
    inputSource.setEncoding("UTF-8");
    return inputSource;
  }

  private class LoggedStopCounts {
    int routeSkipCount = 0;
    int routeSubstCount = 0;
    int seqSkipCount = 0;
    int missingStopCount = 0;
    int sameNameStopSubstCount = 0;
    int stopDupCount = 0;
    int notBetweenNeighborsCount = 0;
    int mapStopsUnmatchedCount = 0;
  }
  private class RouteInfo {
    final String name;
    final Long id;
    final String dir;
    final Integer beginStopSeqNr, endStopSeqNr;
    String schedString, mapString;
    /**
     * @param routeName short name of route such as 101 or M3
     * @param routeId unique id of route in map
     * @param routeDir direction, either 'forward' or 'backward'
     * @param beginStopSeqNr stop sequence number of begin stop, typically 0.
     * @param endStopSeqNr stop sequence number of end stop, typically last.
     */
    RouteInfo(String routeName, Long routeId, String routeDir,
              Integer beginStopSeqNr, Integer endStopSeqNr) {
      this.name = routeName;
      this.id = routeId;
      this.dir = routeDir;
      this.beginStopSeqNr = beginStopSeqNr;
      this.endStopSeqNr = endStopSeqNr;
    }
    /**
     * "TYPE NAME" or "TYPE NAME (DIR)" or "TYPE NAME (DIR BEGIN-END)", 
     * where TYPE is route type, NAME is short route name (typically a
     * number such as 101 or M3), BEGIN and END are stop sequence
     * numbers for route in the direction.
     */
    String schedString() {
      if (this.schedString == null) { 
        StringBuilder sb = new StringBuilder();
        sb.append(GenerateStopTimesWithConstantInterval.this.routeType);
        sb.append(' ').append(this.name);
        if (this.dir != null) {
          sb.append(" (");
          sb.append(this.dir);
          if (this.beginStopSeqNr != null || this.endStopSeqNr != null) {
            sb.append(' ');
            sb.append(this.beginStopSeqNr == null ? "?" : this.beginStopSeqNr);
            sb.append('-');
            sb.append(this.endStopSeqNr == null ? "?" : this.endStopSeqNr);
          }
          sb.append(")");
        }
        this.schedString = sb.toString();
      }
      return this.schedString;
    }
    /**
     * "TYPE NAME" or "TYPE NAME (ID)"
     */
    String mapString() {
      if (this.mapString == null) { 
        StringBuilder sb = new StringBuilder();
        sb.append(GenerateStopTimesWithConstantInterval.this.routeType);
        sb.append(' ').append(this.name);
        if (this.id != null) {
          sb.append(" (id=").append(this.id).append(')');
        }
        this.mapString =  sb.toString();
      }
      return this.mapString;
    }
    public String toString() { return schedString(); }
  }
  private Integer[] getBeginEndSeqNrs(Element sequenceElement,
                                      String rteNo, String dir) {
    try { 
      String beginStopNoAttr =
        selectAttribute(sequenceElement, "stop[1]/@number");
      String endStopNoAttr =
        selectAttribute(sequenceElement, "stop[last()]/@number");
      Integer beginStopSeqNr = Integer.valueOf(beginStopNoAttr);
      Integer endStopSeqNr = Integer.valueOf(endStopNoAttr);
      return new Integer[]{beginStopSeqNr, endStopSeqNr};
    } catch (NumberFormatException ex) {
      NumberFormatException ex2 =
        new NumberFormatException
        (this.routeType+" "+rteNo+" "+dir+
         ": error parsing seqStops number attribute: "+ ex.getMessage());
      ex2.initCause(ex);
      throw ex2;
    }
  }
  /**
   * Create a <code>java.util.logging.FileHander</code> that writes to
   * <code>errLog</code>.
   * Initialize the <code>FileHandler</code> with properties from
   * <code>LogManager.getProperty()</code>
   * for <code>java.util.logging.FileHandler.formatter</code>, 
   * <code>java.util.logging.FileHandler.level</code>, 
   * and <code>this.getClass().getName()+".level"</code>.
   *
   * @throws IOException if errLog cannot be created.
   */
  protected void initLogHandler(File errLog) throws IOException {
    LogManager logMgr = LogManager.getLogManager();
    FileHandler handler = new FileHandler(errLog.toString());
    handler.setEncoding("UTF-8");
    String handlerClassName = handler.getClass().getName();
    String formatterClassName =
      logMgr.getProperty(handlerClassName+".formatter");
    if (formatterClassName != null) {
      try { 
        Formatter formatter = (Formatter)
          Class.forName(formatterClassName).newInstance();
        handler.setFormatter(formatter);
      } catch (Throwable th) {
        Error error =
          new Error("Error while creating "+formatterClassName+": "+th);
        error.initCause(th);
        throw error;
      }
    }
    String handlerLevelString = logMgr.getProperty(handlerClassName+".level");
    if (handlerLevelString != null) {
      try {
        Level handlerLevel = Level.parse(handlerLevelString);
        handler.setLevel(handlerLevel);
      } catch (Throwable th) {
        Error error =
          new Error("Error while parsing "+handlerLevelString+": "+th);
        error.initCause(th);
        throw error;
      }
    }
    String classLevelString =
      logMgr.getProperty(this.getClass().getName()+".level");
    if (classLevelString != null) {
      try {
        Level classLevel = Level.parse(classLevelString);
        handler.setLevel(classLevel);
      } catch (Throwable th) {
        Error error =
          new Error("Error while parsing "+classLevelString+": "+th);
        error.initCause(th);
        throw error;
      }
    }
    LOG.addHandler(handler);
    System.err.println("Logging to "+errLog);
  }

  private Object[] logParams(LogMsg errType, int count, int inTotal) {
    return new Object[]{errType, this.routeType, count, inTotal};
  }
  private Object[] logParams(LogMsg errType,
                             String routeName) {
    return new Object[]{errType, this.routeType, routeName};
  }
  private Object[] logParams(LogMsg errType,
                             String routeName, Long routeId) {
    return new Object[]{errType, this.routeType, routeName, routeId};
  }
  private Object[] logParams(LogMsg errType,
                             String routeName, Long routeId,
                             int count, int inTotal) {
    return new Object[]{errType, this.routeType, routeName, routeId,
                        count, inTotal};
  }
  private Object[] logParams(LogMsg errType,
                             RouteInfo routeInfo) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             String routeSvc) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        routeSvc};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             String routeSvc, String tripId) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        routeSvc, tripId};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             String routeSvc, String tripId,
                             String fromStopName, String toStopName) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir, routeSvc,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        fromStopName, toStopName};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             int stopSeqNr) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        stopSeqNr};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             int stopSeqNr, Stop mapStop) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        stopSeqNr, mapStop.getName(), mapStop.getId()};
  }
  private Object[] logParams(LogMsg errType, RouteInfo routeInfo,
                             Stop mapStop) {
    return new Object[]{errType, this.routeType,
                        routeInfo.name, routeInfo.id, routeInfo.dir,
                        routeInfo.beginStopSeqNr, routeInfo.endStopSeqNr,
                        null, mapStop.getName(), mapStop.getId()};
  }
  public enum LogMsg {
    COUNT_OF_SKIPPED_ROUTE,
    COUNT_OF_SKIPPED_ROUTE_DIR,
    COUNT_OF_SUBST_ROUTE,
    COUNT_OF_SCHED_STOP_NAMES_MISSED_IN_MAP,
    COUNT_OF_SCHED_STOPS_SUBST_FROM_OTHER_MAP_ROUTE,
    COUNT_OF_SCHED_STOPS_AMBIGUOUS_IN_MAP,
    COUNT_OF_MAP_ROUTE_STOPS_NOT_BETWEEN_NEIGHBORS,
    COUNT_OF_MAP_ROUTE_STOPS_NOT_MATCHED,

    MAP_ROUTE_ID_INVALID,
    MAP_ROUTE_STOP_MATCHED,
    MAP_ROUTE_STOP_NOT_MATCHED,
    MAP_ROUTE_STOP_NAME_NOT_UNIQUE,
    MAP_ROUTE_STOP_NOT_BETWEEN_NEIGHBORS,
    MAP_ROUTE_STOPS_NOT_MATCHED_COUNT,

    SCHED_ROUTE_NOT_FOUND_IN_OSM,
    SCHED_ROUTE_HAS_NO_LOCATED_STOPS,
    SCHED_ROUTE_HAS_ONLY_SUBST_STOPS,
    SCHED_ROUTE_DIR_HAS_NO_LOCATED_STOPS,
    SCHED_ROUTE_DIR_HAS_LESS_THAN_2_LOCATED_STOPS,
    SCHED_ROUTE_SUMMARY,

    SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_PRIOR,
    SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER,
    SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE,
    SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE_NOT_UNIQUE,
    SCHED_STOP_MATCHED_TO_ONLY_SEQ_BEGIN,
    SCHED_STOP_MATCHED_TO_ONLY_SEQ_END,

    TRIP_ROUTE_ID_INVALID,
    TRIP_ROUTE_DIR_INVALID,
    TRIP_ROUTE_HAS_NO_LOCATED_STOPS,
    TRIP_ROUTE_DIR_HAS_NO_LOCATED_STOPS,
    TRIP_ROUTE_STOP_SEQ_NOT_FOUND,
    TRIP_ROUTE_STOP_SEQ_NUMBERS_NOT_FOUND,
  }
}
