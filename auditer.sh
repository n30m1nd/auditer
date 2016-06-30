#!/bin/bash

trap "{ print_loc \"\n[-] Ctrl-C pressed. Exiting current program.\" ; kill %1 2>/dev/null || echo \"[-] Please answer y/n first...\"; }" INT

# COLORS
REDCOL="\e[31m"
GREENCOL="\e[32m"
BLUECOL="\e[34m"
YELLCOL="\e[33m"
UNDERCOL="\e[4m"
BOLDCOL="\e[1m"
NOCOL="\e[0m"

host="$1"
ask=false

function print_loc {
 printf "$1\n"
}

function runprog {
 $ask && printf "[?] Run $BOLDCOL$1 $2$NOCOL (y/N)? " && read -p "" -r && echo

 if [[ $ask = false || $REPLY =~ ^[Yy]$ ]]; then
  prog=$(which "$1")
  if  [[ -n "$prog" ]]; then
   print_loc "\n$YELLCOL$BOLDCOL============= $UNDERCOL$1$NOCOL$YELLCOL$BOLDCOL OUTPUT ================$NOCOL"
   print_loc "[i] $YELLCOL""Using "$1" at: $prog$NOCOL"
   print_loc "[+] Running: $GREENCOL$BOLDCOL$1 $2$NOCOL"
   $prog $2
   print_loc "$YELLCOL$BOLDCOL============ END OF OUTPUT ==============$NOCOL"
  else
   print_loc "[-] Not found "$1"."
  fi
 fi
}

print_loc "$BLUECOL$BOLDCOL=========== AUDITER ===========$NOCOL"

if [[ -z "$host" ]]; then
 print_loc "$REDCOL$BOLDCOL[-] No host specified... $NOCOL"
 print_loc "[i] Usage: $0 host"
 exit
fi

hostip="$(host $host | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")"
print_loc "[+] Using host: $REDCOL$BOLDCOL$host$NOCOL"
print_loc "[+] Host's IP:  $REDCOL$BOLDCOL$hostip$NOCOL"


print_loc "[+] Information gathering, clicky clicky..."
if [[ -n "$hostip" ]]; then
 print_loc "[+] Open ports: "
 print_loc "[+]\t $UNDERCOL""https://www.shodan.io/host/$hostip$NOCOL"
 print_loc "[+]\t $UNDERCOL""https://censys.io/ipv4/$hostip$NOCOL"
 print_loc "[+] Vhosts: "
 print_loc "[+]\t $UNDERCOL""https://www.bing.com/search?q=ip:$hostip$NOCOL"
fi

read -p "[?] Ask yes/no before each program runs (y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
 ask=true
fi

# ADD YOUR PROGRAMS TO RUN HERE, FORMAT:
# runprog "program_name" "arguments $host"
runprog "curl" "-vv http://$hostip:443" 
runprog "nmap" "-sT --top-ports 100 $host"
runprog "testssl" "$host"
#runprog "whatweb" "$host"
runprog "nikto" "-host $host"
runprog "dirb" "http://$host" "/usr/share/wordlists/dirb/big.txt"
#runprog "dirb" "https://$host" "/usr/share/wordlists/dirb/big.txt"
# END OF PROGRAMS SECTION


