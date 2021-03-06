#!/bin/bash

trap "{ kill %1 2>/dev/null && print_loc \"\n[-] Ctrl-C pressed. Exiting current program.\" \
|| echo \" [-] Please answer (y)es/(n)o/(q)uit first...\"; }" INT

# COLORS
REDCOL="\e[31m"
GREENCOL="\e[32m"
BLUECOL="\e[34m"
YELLCOL="\e[33m"
UNDERCOL="\e[4m"
BOLDCOL="\e[1m"
BLUEBG="\e[104m"
NOCOL="\e[0m"

function print_loc {
 printf "$1\n"
}

function runprog {
 prog=$(echo "$1" | cut -d ' ' -f1)
 args=$(echo "$1" | cut -d ' ' -f2-)
 REPLY="n" # Automatically set by the 'read' command

 if [[ ! "$prog" =~ [#] ]]; then
  $ask && printf "[?] Run ${BOLDCOL}$prog $args${NOCOL} (y/N)? "&& read -e < /dev/tty
  if [[ "$REPLY" =~ ^[Qq] ]]; then exit; fi
  if [[ "$ask" = false || "$REPLY" =~ ^[Yy]$ ]]; then
   prog=$(which "$prog")
   if  [[ -n "$prog" ]]; then
    print_loc "[+] Running: ${GREENCOL}${BOLDCOL}$prog $args${NOCOL}"
    print_loc "${YELLCOL}${BOLDCOL}============= ${UNDERCOL}$1${NOCOL}${YELLCOL}${BOLDCOL} ================${NOCOL}"
    sh -c "$prog $args"
    print_loc "${YELLCOL}${BOLDCOL}================== END OF OUTPUT ====================\n${NOCOL}"
   else
    print_loc "[-] Not found $prog."
   fi
  fi
 fi
}

function parse_address {
 hostip=$(echo "$host" |  grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
 if [[ -z "$hostip" ]]; then # $host is not an IP and we can safely run the host command 
  hostip=$(host "$host" 8.8.8.8 | grep "has address" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
  if [[ -z "$hostip" ]]; then echo "${REDCOL}[-] Error parsing host's IP${NOCOL}" && exit; fi
 else
  print_loc "[i] ${YELLCOL}Host variable is an IP address.${NOCOL}"
 fi
 print_loc "[+] Using host: ${REDCOL}${BOLDCOL}$host${NOCOL}"
 print_loc "[+] Host's IP:  ${REDCOL}${BOLDCOL}$hostip${NOCOL}"
}

function gather_info {
 print_loc "[+] Information gathering, clicky clicky..."
 if [[ -n "$hostip" ]]; then
  print_loc "[+] ${YELLCOL}${BOLDCOL}============= OPEN PORTS ============${NOCOL}"
  print_loc "[+] ${BOLDCOL}${GREENCOL}SHODAN${NOCOL} ${UNDERCOL}https://www.shodan.io/host/$hostip${NOCOL}"
  print_loc "[+] ${BOLDCOL}${GREENCOL}CENSYS${NOCOL} ${UNDERCOL}https://censys.io/ipv4/$hostip${NOCOL}"
  print_loc "[+] ${YELLCOL}${BOLDCOL}=============== VHOST ===============${NOCOL}"
  print_loc "[+] ${BOLDCOL}${GREENCOL}BINGIP${NOCOL} ${UNDERCOL}https://www.bing.com/search?q=ip:$hostip${NOCOL}"
  # print_loc "[+] ${YELLCOL}${BOLDCOL}============== DOMAINS ==============${NOCOL}"
  # print_loc "[+] ${BOLDCOL}${GREENCOL}GOOGLE${NOCOL} ${UNDERCOL}https://www.bing.com/search?q=ip:$hostip${NOCOL}"
 fi
}

function main {
 print_loc "\n${BLUECOL}${BOLDCOL}=========== AUDITER ===========>${NOCOL} n30m1nd @ github\n"
 if [[ -z "$host" ]] || [ ! -e "$cmdfile" ]; then
  print_loc "${YELLCOL}[i] Usage: $0 host/IP commands_file.txt [outputfile.txt] ${NOCOL}"
  exit
 fi
 parse_address
 gather_info
 print_loc "${BOLDCOL}${REDCOL}${BLUEBG}[!] You can answer 'q'uit at any given input to exit${NOCOL}"
 read -p "[?] Ask yes/no before each program runs (y/N)? " -r -t 5
 if [[ $REPLY =~ ^[Qq] ]]; then exit; fi
 if [[ $REPLY =~ ^[Yy] ]]; then
  ask=true
 fi
 
 # READ PROGRAMS FROM FILE
 IFS=$(echo -en "\n\b")
 for line in $(cat "$cmdfile");do
  cmd=$(echo $line | sed -e "s#\$hostip#$hostip#" -e "s#\$host#$host#" -e "s#\$proto#$proto#" -e "s#\$path#$path#") 
  runprog "$cmd"
 done
}

# SCRIPT CONFIG
host="$1"
cmdfile="$2"
outputfile="$3"

if [[ $outputfile ]]
then
	echo "[+] Output to: $(pwd)/$outputfile"
	exec > >(tee -i "$outputfile")
	exec 2>&1
fi
ask=false

main

