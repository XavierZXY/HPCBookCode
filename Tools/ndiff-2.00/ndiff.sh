#! /usr/bin/sh
### ====================================================================
###  @UNIX-shell-file{
###     author          = "Nelson H. F. Beebe",
###     version         = "1.00",
###     date            = "28 January 2000",
###     time            = "08:38:46 MST",
###     filename        = "ndiff.sin",
###     copyright       = "Copyright (c) 2000 Nelson H. F. Beebe. This
###                        code is licensed under the GNU General Public
###                        License, version 2 or later.",
###     address         = "Center for Scientific Computing
###                        University of Utah
###                        Department of Mathematics, 322 INSCC
###                        155 S 1400 E RM 233
###                        Salt Lake City, UT 84112-0090
###                        USA",
###     telephone       = "+1 801 581 5254",
###     FAX             = "+1 801 585 1640, +1 801 581 4148",
###     URL             = "http://www.math.utah.edu/~beebe",
###     checksum        = "60519 321 1475 10932",
###     email           = "beebe@math.utah.edu, beebe@acm.org,
###                        beebe@ieee.org (Internet)",
###     codetable       = "ISO/ASCII",
###     keywords        = "numerical file differencing",
###     supported       = "yes",
###     docstring       = "This Bourne-shell-compatible script directs
###                        the argument processing for ndiff.
###
###                        See the accompanying UNIX manual pages for
###                        complete documentation of all of the
###                        command-line options.
###
###                        The checksum field above contains a CRC-16
###                        checksum as the first value, followed by the
###                        equivalent of the standard UNIX wc (word
###                        count) utility output of lines, words, and
###                        characters.  This is produced by Robert
###                        Solovay's checksum utility.",
###  }
### ====================================================================

### This value is set at configure time in the output ndiff.sh file:
AWK=/usr/bin/mawk

### Special check for developer: files in local directory override
### installed files.

if test -f ndiff.awk
then
	LIBDIR=.
else
	LIBDIR=/usr/local/share/lib/ndiff/ndiff-2.00
fi

if test -f ndiff.sh
then
	BINDIR=.
else
	BINDIR=@BINDIR@
fi

### Set defaults; these must match those set in ndiff.awk, and
### documented in ndiff.man.
NDIFF="`basename $0`"

### files is the list of non-option arguments, assumed to be input
### files.
files=""

### initfiles is the default list of initialization files read before
### any other command-line arguments are handled.  The order is
### critical, documented, and important: system-specific,
### user-specific, and directory-specific.
initfiles="$LIBDIR/.ndiffrc $HOME/.ndiffrc ./.ndiffrc"

### NB: options holds the list of all options passed to the awk
### program, ndiff.awk.  Those options that are handled entirely in
### this script (-?, -author, -copyright, -help, and -version) are not
### included.
options=""

### run gets set to no for the -?, -author, -copyright, -help, and
### -version options which are handled here, in order to suppress
### invocation of the awk program.
run=yes

author()
{
    ## Handle the -author option.

    cat 1>&2 <<EOF
Author:
	Nelson H. F. Beebe
	Center for Scientific Computing
	University of Utah
	Department of Mathematics, 322 INSCC
	155 S 1400 E RM 233
	Salt Lake City, UT 84112-0090
	USA
	Email: beebe@math.utah.edu, beebe@acm.org, beebe@ieee.org (Internet)
	WWW URL: http://www.math.utah.edu/~beebe
	Telephone: +1 801 581 5254
	FAX: +1 801 585 1640, +1 801 581 4148
EOF
}

copyright()
{
    ## Handle the -copyright option.

    cat 1>&2 <<EOF
########################################################################
########################################################################
########################################################################
###                                                                  ###
### ndiff: compare putatively similar files, ignoring small numeric  ###
###        differences                                               ###
###                                                                  ###
###              Copyright (C) 2000 Nelson H. F. Beebe               ###
###                                                                  ###
### This program is covered by the GNU General Public License (GPL), ###
### version 2 or later, available as the file COPYING in the program ###
### source distribution, and on the Internet at                      ###
###                                                                  ###
###               ftp://ftp.gnu.org/gnu/GPL                          ###
###                                                                  ###
###               http://www.gnu.org/copyleft/gpl.html               ###
###                                                                  ###
### This program is free software; you can redistribute it and/or    ###
### modify it under the terms of the GNU General Public License as   ###
### published by the Free Software Foundation; either version 2 of   ###
### the License, or (at your option) any later version.              ###
###                                                                  ###
### This program is distributed in the hope that it will be useful,  ###
### but WITHOUT ANY WARRANTY; without even the implied warranty of   ###
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    ###
### GNU General Public License for more details.                     ###
###                                                                  ###
### You should have received a copy of the GNU General Public        ###
### License along with this program; if not, write to the Free       ###
### Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,   ###
### MA 02111-1307 USA.                                               ###
########################################################################
########################################################################
########################################################################
EOF
}

processcommandline()
{
	## Scan a command line to extract option and file arguments.
	## This function is usually invoked several times, first for
	## the three standard initialization files, and then for the
	## current command-line arguments.  Consequently, it must
	## accumulate options to be passed to the awk program,
	## ndiff.awk, in the shell variable options.

	while test $# -gt 0
	do
		## Reduce GNU/POSIX style --option to -option, and
	        ## fold to a common letter case:
		opt=`echo $1 | tr A-Z a-z | sed -e 's/^--/-/' `

		case $opt in
		-absolute-error | -absolute-erro | -absolute-err | \
		-absolute-er | -absolute-e | -absolute- | -absolute | \
		-absolut | -absolu | -absol | -abso | -abserr | -abser | \
		-abse | -abs | -ab | -a)
			options="$options -v ABSERR=$2"
			shift
			;;
		-author | -autho | -auth | -aut | -au )
			author
			run=no
			;;
		-copyright | -copyrigh | -copyrig | -copyri | -copyr | -copy | -cop | -co | -c )
			copyright
			run=no
			;;
		-copyleft | -copylef | -copyle | -copyl ) # undocumented support for GNU dialect
			copyright
			run=no
			;;
		-fields | -field | -fiel | -fie | -fi | -f )
			options="$options -v FIELDS=$2"
			shift
			;;
		-[?] | -help | -hel | -he | -h )
			usage
			run=no
			;;
		-logfile | -logfil | -logfi | -logf | -log | -lo | -l )
			# NB: this is an uncommon sh idiom to permanently
			# redirect file descriptor 2 (stderr) to a file,
			# including for all child processes.
			exec 2>$2
			shift
			;;
		-minimum-width | -minimum-widt | -minimum-wid | \
                -minimum-wi | -minimum-w | -minimum- | -minimum | \
                -minimu | -minim | -mini | -minwidth | -minwidt | \
                -minwid | -minwi | -minw | -min | -mi | -m )
			options="$options -v MINWIDTH=$2"
			shift
			;;
		-outfile | -outfil | -outfi | -outf | -out | -ou | -o )
			# NB: this is an uncommon sh idiom to permanently
			# redirect file descriptor 1 (stdout) to a file,
			# including for all child processes.
			exec 1>$2
			shift
			;;
		-quick | -quic )
			initfiles=
			;;
		-quiet | -quie | -qui | -qu | -q )
			options="$options -v QUIET=1"
			;;
		-relative-error | -relative-erro | -relative-err | \
                -relative-er | -relative-e | -relative- | -relative | \
                -relativ | -relati | -relat | -rela | -relerr | \
                -reler | -rele | -rel | -re | -r )
			options="$options -v RELERR=$2"
			shift
			;;
		-separators | -separator | -separato | -separat | \
		-separa | -separ | -sepa | -sep | -se )
			options="$options -v FS='"$2"'"
			shift
			;;
		-silent | -silen | -sile | -sil | -si | -s )
			options="$options -v SILENT=1"
			;;
		-version | -versio | -versi | -vers | -ver | -ve | -v )
			version
			run=no
			;;
		-)		# awk's magic synonym for stdin
			files="$files -"
			;;
		-*)
			for f in 1
			do
				echo "Unrecognized option $1"
				usage
			done 1>&2
			exit 1
			;;
		*)		# everything else is assumed to be a filename
			files="$files $1"
			;;
		esac
		shift		# discard this switch
	done
}

usage()
{
    ## Handle the -? and -help options.  This function is also called
    ## in response to an unrecognized option.

    cat 1>&2 <<EOF
Usage:
	ndiff [ -? ] [ -abserr abserr ] [ -author ] [ -copyright ]
	      [ -fields n1a-n1b,n2,n3a-n3b,...  ] [ -help ]
	      [ -logfile filename ] [ -minwidth nnn ] [ -outfile filename ]
	      [ -precision number-of-bits ] [ -quick ] [ -quiet ]
	      [ -relerr relerr ] [ -separators regexp ] [ -silent ]
	      [ -version ]
	      infile1 infile2
EOF
}

version()
{
    ## Handle the -version option

    cat 1>&2 <<EOF
Version 2.00 of [10-Dec-2000]
EOF
}

### Prescan the command line to see if we have a -quick option to
### suppress loading of initialization files.

for f in "$@"
do
	opt=`echo $f | tr A-Z a-z | sed -e 's/^--/-/' `

	case $opt in
	-quick | -quic )
		initfiles=
		;;
	*)
		;;
	esac
done

### If user option files were not suppressed, process them first for
### any command-line options, so that the current command line can
### override option file settings.  We strip comment lines beginning
### with option whitespace followed by a sharp (#).

if test -n "$initfiles"
then
	processcommandline `cat $initfiles /dev/null 2>/dev/null | egrep -v '^[ 	]*#.*$' `
fi

processcommandline "$@"

if test $run = yes
then
	## We need eval here to correctly handle the case where
	## $options includes -v FILTER='command -opt1 -opt2 ... arg1
	## arg2 ...'. Without eval, awk sees -opt1 ... arg2 ... as
	## separate arguments, rather than as part of the single
	## string assigned to FILTER.
	eval $AWK -f $LIBDIR/ndiff.awk $options $files
else
	exit 0
fi
