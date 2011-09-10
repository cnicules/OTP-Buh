import java.util.logging.Formatter;
import java.util.logging.LogRecord;

public class LevelPlusMessageLogFormatter extends Formatter {
  public String format(LogRecord record) {
    return record.getLevel()+": "+record.getMessage()+"\n";
  }
}
