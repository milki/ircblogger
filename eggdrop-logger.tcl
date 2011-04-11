### Eggdrop Logger
# based on mIRCStats Eggdrop Logger by JuLeS (c)1999
### http://www.xs4all.nl/~sjuul/tcl/index.html
set statsdir "/home/milki/milkibot/scripts/logs/"
set statslogdir "/home/milki/milkibot/scripts/logs/"
set track_nick "milki*"

set logver "0.01"
set vername "\002logger $logver:\002"
set checktimer "00:00"
set statschanfile "channels"

bind pubm - * chatter
bind out - * selfchatter
bind ctcp - "ACTION" caction

proc startlog {} {
	global statschanfile statslogdir statsdir vername botnick
	set currenttime [unixtime]
	set starttime [ctime $currenttime]
	set current [strftime %H:%M]
	if {![file exists ${statsdir}${statschanfile}]} {
		if {![file exists ${statsdir}${statschanfile}.bak]} {
			putlog "$vername ${statsdir}${statschanfile} is missing."
			putlog "$vername Use .mel +chan <channel>."
			return 0
		}
		set copytonew [file copy -force ${statsdir}${statschanfile}.bak ${statsdir}${statschanfile}]
		set removeold [file delete -force ${statsdir}${statschanfile}.bak]
	}
	set read [open ${statsdir}${statschanfile} r]
	while {![eof $read]} {
		set data [gets $read]
		if {[eof $read]} {break}
		if {![file exists ${statslogdir}${data}.log]} {
			set create [open ${statslogdir}${data}.log w]
			puts $create "Session Start: $starttime"
			close $create
			putlog "$vername Created logfile for ${statslogdir}${data}.log"
		}
	}
	close $read
}

proc createlog {channel} {
	global statschanfile statslogdir statsdir vername botnick
	set starttime [ctime [unixtime]]
	set current [strftime %H:%M]
	set chan [string tolower $channel]
	if {![findchan $chan]} {
		putlog "$vername Error! Tried to create new logfile for $chan but couldn't verify with $statschanfile"
		return 0
	}
	if {![file exists ${statslogdir}${chan}.log]} {
		set create [open ${statslogdir}${chan}.log w]
		puts $create "Session Start: $starttime"
		close $create
		putlog "$vername Created logfile for ${statslogdir}${chan}.log"
	}
	return 0
}

proc endlog {channel} {
	global statschanfile statslogdir statsdir vername
	set endtime [ctime [unixtime]]
	set chan [string tolower $channel]
	if {![findchan $chan]} {
		putlog "$vername Error! Tried to close log of channel not being logged according to $statschanfile"
		return 0
	}
	if {![file exists ${statslogdir}${chan}.log]} {
		putlog "$vername Error! Tried to close non-existant logfile!"
		return 0
	}
	set add "Session Close: $endtime"
	set addfile [open ${statslogdir}${chan}.log a]
	puts $addfile $add
	close $addfile
	putlog "$vername Closed logfile for channel $chan"
	return 0
}

proc switchlogs {} {
	global statschanfile statslogdir statsdir vername
	set read [open ${statsdir}${statschanfile} r]
	while {![eof $read]} {
		set data [gets $read]
		if {[eof $read]} {break}
		set closetime [ctime [unixtime]]
		set add "Session Close: $closetime"
		set addfile [open ${statslogdir}${data}.log a]
		puts $addfile $add
		close $addfile
		set secs [clock seconds]
		set cdate [clock format [incr secs -61] -format %Y-%m-%d]
		set copynew [file copy -force ${statslogdir}${data}.log ${statslogdir}${data}.${cdate}.log]
		set removeold [file delete -force ${statslogdir}${data}.log]
		putlog "$vername Created a backup copy of ${statslogdir}${data}.log to ${statslogdir}${data}.${cdate}.log file"
	}
	close $read
	putlog "$vername Rotating logs"
	startlog
}     

proc findchan {channel} {
	global statschanfile statsdir
	set chan [string tolower $channel]
	if {[file exists ${statsdir}${statschanfile}]} {
		set read [open ${statsdir}${statschanfile} r]
		while {![eof $read]} {
			set data [string tolower [gets $read]]
			if {[eof $read]} {break}
			if {$chan == $data && $data != ""} {
				close $read
				return 1
			}
		}
		close $read
	}
	return 0
}

proc checklogrestart {channel} {
	global statslogdir
	set chan [string tolower $channel]
	if {![file exists ${statslogdir}${chan}.log]} {
		createlog $chan
	}
}

proc logcheck {} {
	global checktimer vername
	set current [strftime %H:%M]
    putlog "$vername Current time is $current"
	if {$current == $checktimer} {switchlogs}
}

## strip colour codes from text
proc strip {args} {
    regsub -all \{|\} $args "" args
    regsub -all \002 $args "" args
    regsub -all \037 $args "" args
    regsub -all  $args "" args
    regsub -all  $args "" args
    regsub -all {(([0-9])?([0-9])?(\,([0-9])?([0-9])?)?)?} $args "" args
    regsub -all {([0-9A-F][0-9A-F])?} $args "" args
    ## since all the colour codes have gone, trim any trailing space we may have.
    set arg [string trimleft $args]
    return $args
}

proc chatter {nick host handle channel text} {
	global statslogdir track_nick
	set phrase [strip $text]
	set current [strftime %H:%M]
	set chan [string tolower $channel]
	if {[findchan $chan]} {
        if {[string match $track_nick $nick]} {
            set add "\[$current\] <$nick> $phrase"
            set adding [open ${statslogdir}${chan}.log a]
            puts $adding "$add"
            close $adding
        } else {
            putlog "$nick"
            return 0
        }
	}
}

proc caction {nick host handle dest keyword arg} {
	global statslogdir track_nick
	set current [strftime %H:%M]
	set chan [string tolower $dest]
	if {[findchan $chan]} {
        if {[string match $track_nick $nick]} {
            set doing [strip $arg]
            set add "\[$current\] * $nick $doing"
            set adding [open ${statslogdir}${chan}.log a]
            puts $adding "$add"
            close $adding
        } else {
            putlog "$nick"
			return 0
		}
	}
}

# thommey's selflog
# http://thommey.tclhelp.net/?page=scripts
proc selfchatter {queue text status} {
	global statslogdir
	set current [strftime %H:%M]

    foreach {key chan} [split $text] break
    set text [join [lrange [split $text] 2 end]]
    if {![string equal -nocase $key "PRIVMSG"] || ![validchan $chan] || ![botonchan $chan]} {
        return
    }
    if {[string index $text 0] == ":"} {
        set phrase [string range $text 1 end]
    } else {
        set phrase [lindex [split $text] end]
    }

    set add "\[$current\] <milkibot> $phrase"
    set adding [open ${statslogdir}${chan}.log a]
    puts $adding "$add"
    close $adding
}

startlog
logcheck

putlog "\002Eggdrop Logger loaded!"

