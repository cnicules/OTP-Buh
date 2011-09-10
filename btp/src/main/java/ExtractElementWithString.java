import java.io.*;

/**
 * For HTML files that cannot be parsed by NekoHTML:
 * find relevant element containing string, and
 * write just that element enclosed in
 * <code>&lt;html&gt;&lt;body&gt;...&lt;body&gt;&lt;html&gt;</code>
 */
public class ExtractElementWithString {
  public static void main(String[] args) {
    if (args.length != 5) {
      System.err.println
        ("parameters: "+
         "inFile outFile startTagString contentString endTagString");
      System.exit(SysExits.EX_USAGE);
    }
    File inFilePath = new File(args[0]), outFilePath = new File(args[1]);
    try {
      main(inFilePath, outFilePath, args[2], args[3], args[4]);
    } catch (FileNotFoundException ex) {
      System.err.println(ex);
      System.exit(SysExits.EX_NOINPUT);
    } catch (StringNotFoundException ex) {
      System.err.println(ex);
      System.exit(SysExits.EX_DATAERR);
    } catch (IOException ex) {
      System.err.println(ex);
      System.exit(SysExits.EX_CANTCREAT);
    }
  }
  /**
   * Extract element containing contentString.
   */
  public static void main(File inFilePath, File outFilePath,
                          String startTagString, String contentString,
                          String endTagString)
  throws IOException {
    main(new InputStreamReader(new FileInputStream(inFilePath), "UTF-8"),
         new OutputStreamWriter(new FileOutputStream(outFilePath), "UTF-8"),
         startTagString, contentString, endTagString);
  }
  /**
   * Find contentString, search backward for startTag and forward for endTag.
   * Quote unquoted attributes in the substring.
   * Write the result substring to writer, wrapped in 
   * <code>&lt;html&gt;&lt;body&gt;...&lt;body&gt;&lt;html&gt;</code>.
   * @param reader reads bad html file
   * @param writer where to write html element
   * @param startTagString beginning of start tag
   * @param contentString string to search for that identifies relevant element
   * @param endTagString end tag matching start tag
   */
  public static void main(Reader reader, Writer writer, String startTagString,
                          String contentString, String endTagString)
  throws IOException {
    String string = readAll(reader);
    int contentIndex = string.indexOf(contentString);
    if (contentIndex == -1) throw new StringNotFoundException(contentString);
    int startIndex = string.lastIndexOf(startTagString, contentIndex);
    if (startIndex == -1) throw new StringNotFoundException(startTagString);
    int endIndex = string.indexOf(endTagString,
                                  contentIndex+contentString.length());
    if (endIndex == -1) throw new StringNotFoundException(endTagString);

    String element = string.substring(startIndex,
                                      endIndex + endTagString.length());
    // put quote around attributes to make more like xml
    // Note: not always valid xml because end tags may be missing in html.
    element = element.replaceAll("(\\w+)=(\\w+)","$1=\"$2\"");
    // remove unmatched quote in attribute
    element = element.replaceAll(": [\"]#", ": #");
    // fix end tags
    element = element.replaceAll("</td>(</td>)+<tr", "</td></tr><tr");
    element = element.replaceAll("</td>(</td>\\s*)+</tr>", "</td></tr>");
    element = element.replaceAll("<b></td>", "</b></td>");
    // replace entities
    element = element.replaceAll("&nbsp;","&#xA0;");
    element = element.replaceAll("&ndash;","&#x2013;");
    //element = element.replaceAll("&mdash;","&#x2014;");

    writer.write("<html>\n<body>\n");
    writer.write(element);
    writer.write("</body>\n</html>\n");
    writer.close();
  }
  public static String readAll(Reader reader) throws IOException {
    BufferedReader bufReader = new BufferedReader(reader);
    StringBuilder sb = new StringBuilder();
    for (String line; (line = bufReader.readLine()) != null; ) {
      sb.append(line).append('\n');
    }
    return sb.toString();
  }
  public static class StringNotFoundException extends IllegalArgumentException{
    StringNotFoundException(String s) { super(s); }
  }
}
