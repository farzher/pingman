


main :: () {
  enable_ansi_escape_codes();

  destination := cmd_arg(1, default="google.com");
  print("Pinging %\n", destination);

  while 1 {
    push_temp();

    ping := get_ping(destination);

    print( tprint(color=get_ping_color(ping), "% ", ping) );

    sleep_milliseconds(1000);

    tfree();
  }
}


// @windows: linux ping command is probably different and breaks
// @perf: spawns a new process every second ... doesn't let your cpu sleep
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

get_ping_color :: (ping: int) -> ConsoleColor {
  if ping <= -1 return ConsoleColor.RED_BG;
  if ping <= 12 return ConsoleColor.B_CYAN;
  if ping <= 24 return ConsoleColor.CYAN;
  if ping <= 36 return ConsoleColor.B_GREEN;
  if ping <= 48 return ConsoleColor.GREEN;
  if ping <= 60 return ConsoleColor.B_YELLOW;
  if ping <= 72 return ConsoleColor.YELLOW;
  if ping <= 84 return ConsoleColor.B_RED;
                return ConsoleColor.RED;
}

color_to_escapecode :: (color: ConsoleColor) -> string {
  if color == {
    case .RED;      return "\u001b[31m";
    case .B_RED;    return "\u001b[31;1m";
    case .GREEN;    return "\u001b[32m";
    case .B_GREEN;  return "\u001b[32;1m";
    case .YELLOW;   return "\u001b[33m";
    case .B_YELLOW; return "\u001b[33;1m";
    case .CYAN;     return "\u001b[36m";
    case .B_CYAN;   return "\u001b[36;1m";
    case .RED_BG;   return "\u001b[41;1m";
    case;           return "";
  }
}

// tprint with console colors!
ConsoleColor :: enum {NONE; RED; B_RED; GREEN; B_GREEN; YELLOW; B_YELLOW; CYAN; B_CYAN; RED_BG;};
tprint :: (color: ConsoleColor, format_string: string, args: .. Any) -> string {
  str := tprint(format_string, .. args);
  return tprint("%+%\u001b[0m", color_to_escapecode(color), str);
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
