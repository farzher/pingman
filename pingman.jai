


main :: () {
  enable_ansi_escape_codes();

  destination := cmd_arg(1, default="google.com");
  print("Pinging %\n", destination);

  while 1 {
    push_temp();

    ping := get_ping(destination);

    pingcolor := ifx ping <= -1 then ConsoleColor.RED_BG
            else ifx ping <= 12 then ConsoleColor.B_CYAN
            else ifx ping <= 24 then ConsoleColor.CYAN
            else ifx ping <= 36 then ConsoleColor.B_GREEN
            else ifx ping <= 48 then ConsoleColor.GREEN
            else ifx ping <= 60 then ConsoleColor.B_YELLOW
            else ifx ping <= 72 then ConsoleColor.YELLOW
            else ifx ping <= 84 then ConsoleColor.B_RED
            else                     ConsoleColor.RED

    print( tprint(color=pingcolor, "% ", ping) );

    sleep_milliseconds(1000);

    tfree();
  }
}


// @windows - linux ping command is probably different and breaks
get_ping :: (destination: string) -> int {
  #import "Process";
  #import "String";
  successfully_launched, exit_code, output_string := os_run_command(.. break_command_into_strings(tprint("ping % -n 1", destination)), capture_and_return_output=true);
  index := find_index_from_left(output_string, "time=");
  if index == -1 return -1;
  pingstr := substr(output_string, index+"time=".count, count=4);
  val, success := parse_int(*pingstr);
  if !success return -1;
  return val;
}

// with console colors!
ConsoleColor :: enum {NONE; BLACK; GRAY; RED; B_RED; GREEN; B_GREEN; YELLOW; B_YELLOW; CYAN; B_CYAN; RED_BG;};
tprint :: (color: ConsoleColor, format_string: string, args: .. Any) -> string {
  str := tprint(format_string, .. args);
  colorcode := ifx color == .GRAY     then "\u001b[38;5;8m";
          else ifx color == .BLACK    then "\u001b[30m";
          else ifx color == .RED      then "\u001b[31m";
          else ifx color == .B_RED    then "\u001b[31;1m";
          else ifx color == .GREEN    then "\u001b[32m";
          else ifx color == .B_GREEN  then "\u001b[32;1m";
          else ifx color == .YELLOW   then "\u001b[33m";
          else ifx color == .B_YELLOW then "\u001b[33;1m";
          else ifx color == .CYAN     then "\u001b[36m";
          else ifx color == .B_CYAN   then "\u001b[36;1m";
          else ifx color == .RED_BG   then "\u001b[41;1m";
  return tprint("%+%\u001b[0m", colorcode, str);
}











// generic modules:

#import "Math";
#import "Basic";
push_temp :: () #expand {
  old_allocator           := context.allocator;
  `defer context.allocator = old_allocator;
  context.allocator        = temp;
};
tfree :: reset_temporary_storage;
substr :: inline (str: string, index: int, count: int = 0) -> string #must {
  if count == 0 count = str.count - index;

  c: string = ---;
  c.data = str.data + index;
  c.count = count;
  return c;
}
cmd_arg :: (index: int, default: string = "") -> string {
  args := get_command_line_arguments();
  if index >= args.count return default;
  return args[index];
}
enable_ansi_escape_codes :: () {
  #if OS == .WINDOWS {
    Win :: #import "Windows";
    hand := Win.GetStdHandle(Win.STD_OUTPUT_HANDLE);
    mode: Win.DWORD;
    Win.GetConsoleMode(hand, *mode);
    Win.SetConsoleMode(hand, mode | Win.ENABLE_VIRTUAL_TERMINAL_PROCESSING);
  }
}
