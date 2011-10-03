import java.io.File;
import java.io.FileReader;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

import java.text.Collator;
import java.text.CollationKey;

import java.util.ArrayList;
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
    pw.println("<stop-times>");

    NodeList tripNodeList = selectElements(this.tripsXml, "/trips/trip");
    tripLoop:
    for (int i = 0; i < tripNodeList.getLength(); i++) {
      Element tripElement = (Element) tripNodeList.item(i);
      String tripId = tripElement.getAttribute("trip_id");
      String tripRteName = tripElement.getAttribute("route_short_name");
      String tripDirAttr = tripElement.getAttribute("direction_id");
      String tripDir = ("0".equals(tripDirAttr) ? "forward" :
                        "1".equals(tripDirAttr) ? "backward" : null);
      String tripBeginStopName = tripElement.getAttribute("beginStop");
      String tripEndStopName   = tripElement.getAttribute("endStop");
      if (tripDir == null) {
        LOG.severe("trip "+tripId+" direction "+ tripDirAttr+
                   " is not 0 or 1.");
        continue tripLoop;
      }
      Map<String, List<List<Stop>>> routeSequences =
        this.stopsFromSched.get(tripRteName);
      if (routeSequences == null) {
        LOG.warning("skipping trip "+tripId+
                    " because no located stops found for route "+
                    tripRteName);
        continue tripLoop;
      }
      Duration tripDur = new Duration();
      List<List<Stop>> tripsStopSeqs = routeSequences.get(tripDir);
      if (tripsStopSeqs == null) {
        LOG.warning("skipping trip "+tripId+
                    " because no located stops found for route "+
                    tripRteName+ " and direction "+tripDir+".");
        continue tripLoop;
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
        LOG.severe("skipping trip "+tripId+
                   " because no trips found that run "+tripDir+ " between "+
                   tripBeginStopName+ " and "+tripEndStopName+": "+sb);
        continue tripLoop;
      }

      String headSign = tripStops.get(tripStops.size() - 1).getName();
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
    NodeList schedRouteNodeList =
      selectElements(this.stopSeqsXml, "/stop-sequences/route");
    for (int i = 0; i < schedRouteNodeList.getLength(); i++) {
      Element schedRouteElement = (Element) schedRouteNodeList.item(i);
      String routeName = schedRouteElement.getAttribute("short_name");
      Set<Stop> routeStops = this.stopsFromMapRoute.get(routeName);
      if (routeStops == null) {
        LOG.severe("Route "+this.routeType+" "+routeName+
                   " not found in OSM map.");
        routeStops = Collections.emptySet();
      }

      // may be multiple partial or local/express trips on a route
      Map<String, List<List<Stop>>> seqStopsMap =
        this.stopsFromSched.get(routeName);
      if (seqStopsMap == null) {
        seqStopsMap = new TreeMap<String, List<List<Stop>>>();
        this.stopsFromSched.put(routeName, seqStopsMap);
      }

      locateSchedRouteStops(schedRouteElement, routeName, routeStops,
                            seqStopsMap, counts);

      if (seqStopsMap.isEmpty()) {
        LOG.severe("Route "+this.routeType+" "+routeName+" has no located stops.");
        // do not add to stopsFromSched.
        counts.routeSkipCount++;
      } else {
        this.stopsFromSched.put(routeName, seqStopsMap);
      }
    }
    // log summary counts
    if (counts.routeSkipCount > 0)
      LOG.info(counts.routeSkipCount+" "+this.routeType+" routes skipped.");
    if (counts.seqSkipCount > 0)
      LOG.info(counts.seqSkipCount+ " "+this.routeType+
               " route direction sequences skipped.");
    if (counts.missingStopCount > 0)
      LOG.info(counts.missingStopCount+" scheduled stop names missing "+
               "(or spelled differently) from all map "+
               this.routeType+" routes.");
    if (counts.sameNameStopSubstCount > 0)
      LOG.info
        (counts.sameNameStopSubstCount+
         " scheduled stops substituted with stop with same name"+
         " from another "+this.routeType+" route.");
    if (counts.stopDupCount > 0)
      LOG.info(counts.stopDupCount+" ambiguous/duplicate stops from all "+
               this.routeType+" routes.");
    if (counts.notBetweenNeighborsCount > 0)
      LOG.info(counts.notBetweenNeighborsCount +
               " stops are further from neighbors than distance between them: "+
               "min(a-b, b-c) > a-c");
  }
  private void locateSchedRouteStops(Element schedRouteElement, 
                                     String routeName, Set<Stop> routeStops,
                                     Map<String, List<List<Stop>>> seqStopsMap,
                                     LoggedStopCounts counts){
    // stop-sequences/route/stop-sequence
    NodeList sequenceNodeList =
      selectElements(schedRouteElement, "stop-sequence");
    for (int j = 0; j < sequenceNodeList.getLength(); j++) {
      Element sequenceElement = (Element) sequenceNodeList.item(j);
      String dir = sequenceElement.getAttribute("dir");

      List<Stop> seqStops = new ArrayList<Stop>();
      List<String> schedStopNamesUnmatched = new ArrayList<String>();
      List<Stop> schedStopsSubstFromOtherRoute = new ArrayList<Stop>();

      locateSchedRouteSeqStops(sequenceElement, routeName, routeStops,
                               seqStops,
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
          if (ab > ac || bc > bc) {
            LOG.warning
              ("Route "+this.routeType+ " "+routeName+" "+dir+
               " stop "+p+" \""+b.getName()+"\""+
               " is further from neighbors than distance between them: "+ b);
            counts.notBetweenNeighborsCount++;
          }
        }
      }
      Set<Stop> mapRouteStopsUnmatched = removeMatchedStops(routeStops, seqStops);
      String summary = makeTripSummary(routeName, dir,
                                       schedStopNamesUnmatched,
                                       schedStopsSubstFromOtherRoute,
                                       mapRouteStopsUnmatched);
      if (seqStops.isEmpty() || seqStops.get(0) == null) { 
        // null would be replaced with later stop if there is one.
        LOG.severe("Route "+this.routeType+" "+routeName+ " "+dir+
                   " has no located stops.");
        // do not add to seqStopsMap.
        counts.seqSkipCount++;
      } else {
        assert !seqStops.contains(null);
        if (new TreeSet<Stop>(seqStops).size() < 2) {
          LOG.severe("Route "+this.routeType+" "+routeName+" "+dir+
                     " has less than 2 located stops.");
          // do not add to seqStopsMap.
          counts.seqSkipCount++;
        } else /* has at least two located stops */ {
          if (!schedStopNamesUnmatched.isEmpty()) {
            LOG.severe(summary);
          } else if (summary.length() > 0) {
            LOG.warning(summary);
          }
          List<List<Stop>> tripsStopSeqs = seqStopsMap.get(dir);
          if (tripsStopSeqs == null) {
            tripsStopSeqs = new ArrayList<List<Stop>>(1);
            seqStopsMap.put(dir, tripsStopSeqs);
          }
          tripsStopSeqs.add(seqStops);
        }
      }
    }
  }
  private void locateSchedRouteSeqStops(Element sequenceElement,
                                        String routeName, Set<Stop> routeStops,
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
      String name = schedStopElement.getAttribute("name");
      Set<Stop> namedStops = stopsFromName.get(name);
      if (namedStops == null || namedStops.isEmpty()) { // no stops have name
        categorizeMissingStop(routeName, name, latestNonNullStop,
                              seqStops, schedStopNamesUnmatched, counts);
      } else {
        Set<Stop> intersection = new TreeSet<Stop>(namedStops);
        intersection.retainAll(routeStops);
        if (intersection.size() == 1) {        // found unique match, so use it
          latestNonNullStop = intersection.iterator().next();
          seqStops.add(latestNonNullStop);
        } else if (intersection.size() > 1) {  // > 1 stops in route have name
          latestNonNullStop = chooseRouteDupStop(routeName, name, intersection,
                                                 latestNonNullStop, seqStops,
                                                 counts);
        } else {
          assert intersection.size() == 0;     // no ROUTE stops have name
          latestNonNullStop = chooseOffRouteStop(routeName, name, namedStops,
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
  private void categorizeMissingStop(String routeName, String name,
                                     Stop latestNonNullStop,
                                     List<Stop> seqStops,
                                     List<String> schedStopNamesUnmatched,
                                     LoggedStopCounts counts) {
    counts.missingStopCount++;
    schedStopNamesUnmatched.add(name);
    if (latestNonNullStop != null) { 
      LOG.fine("scheduled "+this.routeType+ " "+routeName+
               " stop \""+name+"\" not in map "+this.routeType+" routes;"+
               " substituting latest stop "+latestNonNullStop);
      seqStops.add(latestNonNullStop);
    } else {
      LOG.fine("scheduled "+this.routeType+ " "+routeName+
               " stop \""+name+"\" not in map "+this.routeType+" routes;"+
               " will substitute next non-null stop.");
      seqStops.add(null);
    }
  }
  private Stop chooseRouteDupStop(String routeName, String name,
                                  Set<Stop> intersection,
                                  Stop latestNonNullStop, List<Stop> seqStops,
                                  LoggedStopCounts counts){
    // Two stops are common, one located on each side of street; warn if more.
    Level logLevel = intersection.size() == 2 ? Level.FINE : Level.WARNING;
    String logReason = (!LOG.isLoggable(logLevel)? null :
                        "Map route "+this.routeType+" "+routeName+
                        " has "+intersection.size()+ " \""+name+"\" stops");
    assert intersection.size() > 1;
    if (latestNonNullStop == null) { 
      if (LOG.isLoggable(logLevel))
        LOG.log(logLevel, logReason + "; taking first for now: "+intersection);
      latestNonNullStop = intersection.iterator().next(); //take first
    } else {
      latestNonNullStop =
        selectCloseStopOnTrafficSide(latestNonNullStop, intersection,
                                     logLevel, logReason);
    }
    seqStops.add(latestNonNullStop); 
    counts.stopDupCount++;
    return latestNonNullStop;
  }
                                            
  private Stop chooseOffRouteStop(String routeName, String name,
                                  Set<Stop> namedStops,
                                  Stop latestNonNullStop, List<Stop> seqStops,
                                  List<Stop> schedStopsSubstFromOtherRoute,
                                  LoggedStopCounts counts){
    assert namedStops.size() >= 1;
    Level logLevel = Level.WARNING; // always warn of missing stops
    if (namedStops.size() == 1) {
      latestNonNullStop = namedStops.iterator().next();
      if (LOG.isLoggable(logLevel))
        LOG.log(logLevel, "Map route "+this.routeType+" "+routeName+
                " has no stop \""+name+"\"; substituting stop with same name "+
                "from another "+this.routeType+" route: "+
                latestNonNullStop.getId());
      seqStops.add(latestNonNullStop);
      counts.sameNameStopSubstCount++;
      schedStopsSubstFromOtherRoute.add(latestNonNullStop);
    } else {
      String logReason = (!LOG.isLoggable(logLevel) ? null :
                          "map "+this.routeType+" "+routeName+
                          " has no stop \""+name+"\" and "+
                          namedStops.size()+" stops have that name"+
                          " on other "+this.routeType+" route(s)");
      if (latestNonNullStop == null) { 
        latestNonNullStop = namedStops.iterator().next();
        if (LOG.isLoggable(logLevel)) {
          LOG.log(logLevel, logReason +
                  "; substituting first for now: "+ latestNonNullStop.getId());
        }
      } else {
        latestNonNullStop =
          selectCloseStopOnTrafficSide(latestNonNullStop, namedStops,
                                       logLevel, logReason);
      }
      seqStops.add(latestNonNullStop);
      counts.sameNameStopSubstCount++;
      schedStopsSubstFromOtherRoute.add(latestNonNullStop);
    }
    return latestNonNullStop;
  }

  /**
   * Remove stops that have been matched from routeStops.  Also remove
   * stops that have the same name as a matched stop and are within
   * MAX_STOP_PAIR_DISTANCE_m meters (stop on opposite side of street).
   */
  private Set<Stop> removeMatchedStops(Set<Stop> routeStops,
                                       List<Stop> matchedStops) {
    Set<Stop> routeStopsUnmatched = new LinkedHashSet<Stop>(routeStops);
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
    return routeStopsUnmatched;
  }

  private String makeTripSummary(String routeName, String dir, 
                                 List<String> schedStopNamesUnmatched,
                                 List<Stop> schedStopsSubstFromOtherRoute,
                                 Set<Stop> mapRouteStopsUnmatched) {
    StringBuilder summary =
      new StringBuilder("Route "+this.routeType+" "+routeName+ " "+dir+ ":\n"); 
    int emptyLength = summary.length();

    if (!schedStopNamesUnmatched.isEmpty()) {
      summary.append("  unmatched schedule stops (not in other map "+
                     this.routeType+" routes):\n");
      for (String stopName : schedStopNamesUnmatched) {
        summary.append("    ").append(stopName).append('\n');
      }
    }

    if (!schedStopsSubstFromOtherRoute.isEmpty()) { 
      summary.append
        ("  unmatched schedule stops (substituted stop"+
         " with same name found in another map "+ this.routeType+" route):\n");
      for (Stop stop : schedStopsSubstFromOtherRoute) {
        summary.append("    ").append(stop).append('\n');
      }
    }

    if (!mapRouteStopsUnmatched.isEmpty() &&
        // only list unmatched map route stops if there are unmatched
        // sched stops, because some trips do not use all route stops.
        // For example, trips that do not go to end of line, or express trips.
        (!schedStopNamesUnmatched.isEmpty() ||
         !schedStopsSubstFromOtherRoute.isEmpty())) {
      summary.append("  unmatched map route stops:\n");
      for (Stop stop : mapRouteStopsUnmatched) {
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
   */
  private Stop selectCloseStopOnTrafficSide(Stop latestStop,
                                            Set<Stop> candidates,
                                            Level logLevel, String logReason) {
    assert candidates.size() >= 2;
    Stop[] twoClosestStops = selectClosest2Stops(latestStop, candidates);
    Stop stop0 = twoClosestStops[0], stop1 = twoClosestStops[1];
    double distBetween = stop0.distance_m(stop1);
    if (distBetween > MAX_STOP_PAIR_DISTANCE_m) {
      if (LOG.isLoggable(logLevel)) 
        LOG.log(logLevel, logReason+"; subsituting closest for now: "+
                stop0.getId()+
                " (next is "+Math.round(distBetween)+"m further).");
      return stop0;
    }
    if (distBetween == 0.0) {
      LOG.warning("Found two stops at same position, choosing first: "+
                  stop0.getId()+", "+stop1.getId());
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
        LOG.log(logLevel, logReason+ "; substituting closest for now: "+
                stop0.getId()+ " (next is at same angle from previous stop)");
      return stop0; // rare: aligned, just pick closest for now.
    } 

    Stop result;
    switch(this.trafficSide) {
      case LEFT:  result = (dirDiff > 0 ? stop1 : stop0); break;
      case RIGHT: result = (dirDiff < 0 ? stop1 : stop0); break;
      default: throw new AssertionError(this.trafficSide);
    }
    if (LOG.isLoggable(logLevel)) 
      LOG.log(logLevel, logReason+ "; substituting closest on "+
              this.trafficSide.name().toLowerCase()+
              " from previous stop for now: "+ result.getId());
    return result;
  }
  /**
   * Left or right: traffic travels on this side of a bidirectional way.
   */
  public enum TrafficSide { LEFT, RIGHT }

  private Element selectElement(File xmlFile, String xpathExpression) {
    try { 
      return (Element)
        xpath.evaluate(xpathExpression,
                       new InputSource(xmlFile.toString()),
                       XPathConstants.NODE);
    } catch (XPathExpressionException ex) { throw new Error(ex); }
  }
  private NodeList selectElements(File xmlFile, String xpathExpression) {
    try { 
      return (NodeList)
        xpath.evaluate(xpathExpression,
                       new InputSource(xmlFile.toString()),
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
  private class LoggedStopCounts {
    int routeSkipCount = 0, seqSkipCount = 0;
    int missingStopCount = 0;
    int sameNameStopSubstCount = 0;
    int stopDupCount = 0;
    int notBetweenNeighborsCount = 0;
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
          new Error("Error while creating "+handlerClassName+": "+th);
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

}
