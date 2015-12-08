#!/usr/bin/env ruby

require 'getoptlong'
require 'time'

options = GetoptLong.new( [ '--help',   '-h',    GetoptLong::NO_ARGUMENT  ],
                          [ '--file', '-f',   GetoptLong::OPTIONAL_ARGUMENT ],
                          [ '--begintime', '-b',  GetoptLong::OPTIONAL_ARGUMENT ],
                          [ '--endtime', '-e',  GetoptLong::OPTIONAL_ARGUMENT ],
                          [ '--verbose', '-v',  GetoptLong::NO_ARGUMENT ],
                          [ '--linenum', '-n',  GetoptLong::NO_ARGUMENT ],
                          [ '--operationid', '-i',  GetoptLong::OPTIONAL_ARGUMENT ]
                        )

# Configuration:
log_file = "looker.log"
time_check = false
id_check = false
verbose = false
operation_id=""
begin_date = Time.parse "1969-12-31 00:00:00.000"
end_date = Time.parse "2099-12-31 00:00:00.000"
print_linenum = false

########
def show_help()
  puts <<-EOF

looker-log-reader.rb [-h] -f logfile [-b begintime] [-e endtime] [-i operationid] [-v]

-h, --help:
    show help

-f, --file:
    looker log file

-b, --begintime:
    earliest time to print from the log

-e, --endtime:
    latest time to print from the log

-i, --operationid:
    filter for just one operation

-n, --linenum:
    print line numbers 

-v, --verbose:
    print all lines matching other arguments

EOF
end


begin
  options.each do |opt, arg|
    case opt
    when '--help'
      show_help()
      exit 1
    when '--file'
      if arg == ''
        puts ""
        puts "Missing --file argument"
        show_help()
        exit 1
      else
        log_file = arg
      end
    when '--begintime'
      if arg == ''
        puts ""
        puts "Missing --begintime argument"
        show_help()
        exit 1
      else
        begin_date = Time.parse arg
        time_check = true
      end
    when '--endtime'
      if arg == ''
        puts ""
        puts "Missing --endtime argument"
        show_help()
        exit 1
      else
        end_date = Time.parse arg
        time_check = true
      end
    when '--operationid'
      if arg == ''
        puts ""
        puts "Missing --operationid argument"
        show_help()
        exit 1
      else
        operation_id = arg
        id_check = true
      end
    when '--previous'
      if arg == ''
        puts ""
        puts "Missing --previous argument"
        show_help()
        exit 1
      else
        previous_lines = arg
      end
    when '--verbose'
      verbose = true
    when '--linenum'
      print_linenum = true
    end
  end
rescue
  show_help()
  exit 1
end

ignores = [ /limit/i, /INSERT INTO "HISTORY"/, /GET \/sql, \{\}/, /db:looker/, "running_queries" ]
ignores_re = Regexp.union(ignores)
matches = [ "csv", "sql", "pdf" ]
matches_re = Regexp.union(matches)
date_re = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}/
op_re = Regexp.new("\\|" + operation_id + "\\|")
continue_line = false

line_num = 0

File.foreach(log_file) do |line|
  line_num = line_num + 1 if print_linenum
  if (time_check and line.match(date_re))
    line_date = Time.parse line[0..22]
    exit if line_date > end_date
    next if line_date < begin_date
  end
  if (id_check) 
    if (line.match(op_re))
      print line
      next
    end
  else
    if (not verbose and line.match(ignores_re))
      continue_line=false
      next
    end
    if (line.match(matches_re) and line.match(date_re))
      continue_line=true
      print line_num,": " if print_linenum
      print line 
    end
    if (continue_line and not line.match(date_re))
      print line_num,": " if print_linenum
      print line 
    end
  end
end
