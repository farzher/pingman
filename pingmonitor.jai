


main :: () {
  enable_ansi_escape_codes();

  destination := cmd_arg(1, default="1.1.1.1");
  mylog("pinging:", destination);

  sleep_ms := cmd_arg("sleepms", 1000);
  if cmd_arg("nosleep", default=0) sleep_ms = 0;

  while 1 {
    context.allocator = temp;

    ping := get_ping(destination);
    ping_with_color := tprint(color=get_ping_color(ping), "%", ping);
    print("% ", ping_with_color);

    sleep_milliseconds(xx sleep_ms);

    tfree();
  }
}


// @windows-only: linux ping command is probably different and doesn't work
// @perf: spawns a new process every second ...
get_ping :: (destination: string) -> int {
  #import "Process";
  #import "String";

  // run the ping command
  output_string := run_cmd(tprint("ping % -n 1", destination));

  // look for time=
  index := find_index_from_left(output_string, "time=");

  // if we can't find it, our ping was either <1ms (very fast) or a timeout (very slow)
  if index == -1 {
    index = find_index_from_left(output_string, "time<1ms");
    if index == -1 return -1;
    return 0;
  }

  // examples of what's at the index: time=3ms, time=1063ms
  // examples of pingstr: 3ms, 1063ms
  pingstr := substr(output_string, index+"time=".count, count=4);
  val, success := parse_int(*pingstr);
  if !success return -1;
  return val;
}

run_cmd :: (cmd: string) -> string {
  successfully_launched, output_string := run_command(..break_command_into_strings(cmd), capture_and_return_output=true);
  return output_string;
}

get_ping_color :: (ping: int) -> ConsoleColor {
  if ping <= -1 return .RED_BG;
  if ping <= 12 return .B_CYAN;
  if ping <= 24 return .CYAN;
  if ping <= 36 return .B_GREEN;
  if ping <= 48 return .GREEN;
  if ping <= 60 return .B_YELLOW;
  if ping <= 72 return .YELLOW;
  if ping <= 84 return .B_RED;
                return .RED;
}

color_to_escapecode :: (color: ConsoleColor) -> string {
  if color == {
    case .RED_BG;   return "\u001b[41;1m";
    case .CYAN;     return "\u001b[36m";
    case .B_CYAN;   return "\u001b[36;1m";
    case .GREEN;    return "\u001b[32m";
    case .B_GREEN;  return "\u001b[32;1m";
    case .YELLOW;   return "\u001b[33m";
    case .B_YELLOW; return "\u001b[33;1m";
    case .RED;      return "\u001b[31m";
    case .B_RED;    return "\u001b[31;1m";
    case;           return "";
  }
}

// tprint with console colors!
ConsoleColor :: enum {NONE; RED; B_RED; GREEN; B_GREEN; YELLOW; B_YELLOW; CYAN; B_CYAN; RED_BG;};
tprint :: (color: ConsoleColor, format_string: string, args: .. Any) -> string {
  str := tprint(format_string, .. args);
  return tprint("%0%0\u001b[0m", color_to_escapecode(color), str);
}











// generic modules:

#import "Basic";
mylog :: (args: ..Any) {for args print("% ", it); print("\n"); }

tfree :: reset_temporary_storage;

substr :: inline (str: string, index: int, count: int = 0) -> string #must {
  if count == 0 count = str.count - index;

  c: string = ---;
  c.data = str.data + index;
  c.count = count;
  return c;
}

// return the positional argument at index
// skips over / ignores non-positional arguments ex: -nosleep
cmd_arg :: (index: int, default: string = "") -> string {
  args_i_care_about: [..]string;
  args_i_care_about.allocator = temp;
  for arg, i: get_command_line_arguments() {
    // the first arg, the exe name, is always allowed, even if it starts with a -
    if i > 0 {
      begins_with_dash := find_index_from_left(arg, "-") == 0;
      if begins_with_dash continue;
    }
    array_add(*args_i_care_about, arg);
  }

  if index >= args_i_care_about.count return default;
  return args_i_care_about[index];
}

// return the value of a named argument ex: -sleepms=0
cmd_arg :: (varname: string, default: int = 0) -> int {
  #import "String";
  for arg: get_command_line_arguments() {
    if arg == tprint("-%", varname) return 1;
    if begins_with(arg, tprint("-%=", varname)) {
      valstr := substr(arg, 1+varname.count+1);
      return parse_int(*valstr);
    }
  }
  return default;
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
