


main :: () {
  enable_ansi_escape_codes();

  // default destination is our own public ip address
  destination := cmd_arg(1, default="");
  if !destination {
    destination = request("https://farzher.com/myip");
    print("pinging: your own IP address\n");
  } else {
    print("pinging: %\n", destination);
  }

  while 1 {
    push_temp();

    ping := get_ping(destination);

    print( tprint(color=get_ping_color(ping), "% ", ping) );

    sleep_milliseconds(1000);

    tfree();
  }
}


// @windows: linux ping command is probably different and breaks
// @perf: spawns a new process every second ...
get_ping :: (destination: string) -> int {
  #import "Process";
  #import "String";
  successfully_launched, exit_code, output_string := os_run_command(
    ..break_command_into_strings(tprint("ping % -n 1", destination)),
    capture_and_return_output=true
  );
  index := find_index_from_left(output_string, "time=");
  if index == -1 {
    index = find_index_from_left(output_string, "time<1ms");
    if index == -1 return -1;
    return 0;
  }
  pingstr := substr(output_string, index+"time=".count, count=4);
  val, success := parse_int(*pingstr);
  if !success return -1;
  return val;
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

#import "Curl";
// Allocates response_body using context.allocator
request :: (url: string) -> response_body: string {
    curl := curl_easy_init();
    defer curl_easy_cleanup(curl);

    curl_easy_setopt(curl, .URL, temp_c_string(url));

    builder: String_Builder;
    curl_easy_setopt(curl, .WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, .WRITEDATA,     *builder);

    curl_easy_perform(curl);

    return builder_to_string(*builder);

    size_t :: u64;
    write_callback :: (ptr: *u8, size: size_t, nmemb: size_t, userdata: *void) -> size_t #c_call {
        builder := cast(*String_Builder)userdata;
        jai_context: Context;
        push_context jai_context {
            append(builder, ptr, xx nmemb);
        }
        return nmemb;
    }
}
