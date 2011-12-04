import java.util.logging.XMLFormatter;
import java.util.logging.Handler;

/**
 * Like java.util.logging.XMLFormatter, but removes
 * standalone="no" in the log file ?xml header, 
 * and removes the doctype specifying the dtd.  
 * The logger.dtd file does not contain any entities, so it is not needed.
 * Without these changes, parsers unnecessarily require the dtd file.
 */
public class XMLFormatterStandalone extends XMLFormatter {
  public @Override String getHead(Handler h) {
    String result = super.getHead(h);
    return (result
            .replaceFirst("standalone=\"no\"", "")
            .replaceFirst("<!DOCTYPE log SYSTEM \"logger.dtd\">", ""));
  }
}
