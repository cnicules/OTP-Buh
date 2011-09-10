/** standard shell exit codes (from sysexits.h) **/
public class SysExits {
  public static final int EX_OK        =  0;  /* successful */
  public static final int EX_USAGE     = 64;  /* bad command line */
  public static final int EX_DATAERR   = 65;  /* bad input file syntax */
  public static final int EX_NOINPUT   = 66;  /* unreadable input file */
  public static final int EX_CANTCREAT = 73;  /* unwritable output file */
  public static final int EX_SOFTWARE  = 70;  /* internal error */
}
