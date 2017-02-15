#!/bin/bash
## With a Little Help from My Friend (sic)
## A small menu driven script to administrate a computer (for dummys)
## Author: M*** N******* (for privacy purpose)
## Date 22/Jul/2016

## Load Bash Shell Function Library (bsfl)
## by Louwrentius <louwrentius@gmail.com> and Jani Hurskainen
## The Library is release under current version of GPL
. /home/$USER/bin/bsfl
bsfl_URL="https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/bsfl/bsfl-2.00-beta-2.tgz" # to download latest version

## Define variables
## Backup
backup_to=pi@192.168.0.10:/home/pi/Elements/BACKUP_$USER/ # Backup to...
backup_from=/home/$USER/				  # Backup from...
backup_mount=/home/$USER/backup/			  # Backup mount point
#External network HDD
elements=pi@192.168.0.10:/home/pi/Elements/		  # External network HDD
elements_mount=/media/pi/Elements/			  # Externerl network HDD mount point
ssh_id_file=/home/$USER/.ssh/id_rsa			  # Authentication via ssh
# Some directorys to exclude from backup
DOWNLOAD=$(xdg-user-dir DOWNLOAD)
PUBLICSHARE=$(xdg-user-dir PUBLICSHARE)
MUSIC=$(xdg-user-dir MUSIC)
VIDEOS=$(xdg-user-dir VIDEOS)
STEAM=/home/$USER/.steam/
VIRTUALBOX="/home/$USER/VirtualBox VMs"
#PICTURES=$(xdg-user-dir PICTURES)
#DOCUMENTS=$(xdg-user-dir DOCUMENTS)
#
# to exclude paths from rsync we need a relative path
# e.g. source=/home/user/
# exclude path: /home/user/Downloads/
# we just need to exclude 'Downloads/', because this is the relative path...
base_path=$backup_from

function relative_path(){
	for exclude_path in $DOWNLOAD $PUBLICSHARE $MUSIC $VIDEOS $STEAM $VIRTUALBOX #$PICTURES $DOCUMENTS
	do
		full_path=$exclude_path
		rel_path=`echo $full_path | sed 's|'$base_path'/||'`
		eval ${exclude_path}=`echo -ne \""${rel_path}"\"`
		echo $rel_path
	done
	echo $DOWNLOAD
	pause
}

## Purpose: Display pause prompt
## $1-> Message (optional)
function pause(){
	local message="$@"
	[ -z $message ] && message="Drücke [Enter] um fortzufahren..."
	read -p "$message" readEnterKey
}

## Purpose: Display a menu on screen
## Shows the date on top and a Menu with 1. 2. 3. etc.
function show_menu(){
	date
	echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	echo "                     Menü                          "
	echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	echo " "
		echo "1. Update meiner Software"
		echo "2. WLAN Probleme beheben"
		echo "3. Backup meiner Daten erstellen (/home/$USER/)"
		echo "4. Backup meiner Daten ansehen"
		echo "5. Backup aushängen"
		echo "6. Elements einhängen"
		echo "7. Elements aushängen"
		echo "8. Selbstdiagnose"
		echo "   (sollte bei erstmaliger Benutzung ausgeführt werden)"
		echo "9. Beenden"
		echo " "
}

## Purpose: Writing a Header for each function
## to show the user whats going on...
## $1 - message
function write_header(){
	local h="$@"
	echo "--------------------------------------------------------"
	echo "        ${h}"
	echo "--------------------------------------------------------"
}

## Purpose: Updating debian (requires root to update everything)
function update_os(){
	write_header " Installiere Updates..."
	sudo apt-get update && sudo apt-get upgrade --yes
	case "$?" in
	0) msg_ok "Update erfolgreich" ;;
	*) msg_fail "Update fehlgeschlagen"
	esac
	## pause "Presse [Enter] key to continue..."
	pause
}

## Purpose: Wifi troubleshooting
function wifi_troubleshooting(){
	write_header " WLAN Problembehebung..."
	echo "Der Vorgang kann einen Moment dauern"
	echo "..."
	nm-online --quiet --timeout 5 # ask NetworkManager whether the network is connected
	cond_1="$?"
	case "$cond_1" in			# check return-value
		0)
		  nc -z 8.8.8.8 53
		  online="$?"
		  if [ $online -eq 0 ]; then
		  	msg_ok "Alles in Ordnung" 
		  else
		  	wifi off &>/dev/null && wifi on &>/dev/null
			echo "Der Fehler sollte behoben sein, möglicherweise besteht aber auch ein Problem"
                  	msg_warning "mit der Internetverbindung und nicht mit dem WLAN"
		  fi ;;
		1)
		  echo "Fehler wird behoben..." 
		  wifi off &>/dev/null && wifi on &>/dev/null 
		  sleep 10s
		  nc -z 8.8.8.8 53
		  online="$?"
		  if [ $online -eq 0 ]; then
			msg_ok "Alles in Ordnung"
                  else
                        wifi off &>/dev/null && wifi on &>/dev/null
                        msg_warning "Der Fehler sollte behoben sein, möglicherweise besteht aber auch ein Problem"
                        echo "mit der Internetverbindung und nicht mit dem WLAN"
                  fi ;;
		2)					# strange return-value
		  echo "Fehler wird behoben..."
		  wifi off &>/dev/null && wifi on &>/dev/null
		  nm-online -quiet --timeout 5		# don't know if this script can fix this error, so double test
		  cond2="$?"
		  if [ "$cond2" = "0" ]; then
		  	msg_ok "Fehler konnte behoben werden..." # yay
		  else
			msg_fail "Fehler konnte nicht behoben werden," # nay
			echo "möglicherweise liegt die Ursache anderswo."
		  fi ;;
		*)
		  msg_fail "Fehler konnte nicht behoben werden,"
                  echo "möglicherweise liegt die Ursache anderswo."
		  sleep 3s ;;
	esac
	echo " "
	pause
}

## Purpose: Backing Up Data to our local Raspberry Pi
function backup_my_data(){
	write_header " Backup der Daten Anlegen (Homeverzeichnis)..."
	echo "Bitte beachte, dass einige Ordner hiervon ausgenommen sind:"   # sum up excluded directorys
	echo "$DOWNLOAD"
	echo "$PUBLICSHARE"
	echo "$MUSIC"
	echo "$VIDEOS"
	echo "$STEAM (sofern steam installiert)"
	echo "$VIRTUALBOX (sofern virtualbox installiert)"
	sleep 2s
	echo " "
	echo "Backup wird nun angelegt"
	rsync -a --exclude={"$DOWNLOAD/","$PUBLICSHARE/","$MUSIC/","$VIDEOS/","$STEAM/","$VIRTUALBOX",".cache",".gvfs","$backup_mount"} --info=progress2 -e "ssh -i $ssh_id_file" $backup_from $backup_to 
	case "$?" in
	0) 
		clear
		write_header " Backup der Daten Anlegen (Homeverzeichnis)..."
		msg_ok "...Erfolgreich" ;;
	*)
		clear
		write_header " Backup der Daten Anlegen (Homeverzeichnis)..."
		msg_warning "Ein Fehler ist aufgetreten. Das Backup konnte nicht angelegt werden oder ist unvollständig"
	esac
	echo " "
	pause
}

## Purpose: mount my Backup from our local Raspberry Pi
function mount_my_backup(){
	write_header " Backup deiner Daten wird eingehängt..."
	if [ ! -d "$backup_mount" ]; then			# local mounting point exists?
		mkdir $backup_mount
	fi
	sshfs $backup_to $backup_mount -p 22 -o IdentityFile=$ssh_id_file &>/dev/null
	case "$?" in
		0) msg_ok "Das Backup steht in deinem Homeverzeichnis unter $backup_mount zur Verfügung."  # yay
		   msg_info "Vergiss bitte nicht das Backup später wieder auszuhängen." ;;
		*) msg_warning "Da ist etwas schief gegangen." 
		   echo "Möglicherweise ist das Backup bereits eingehängt unter $backup_mount"
		   echo "Andernfalls besteht ein Problem mit dem Netzwerk und du solltest deinen Administrator fragen" 
	esac
	echo " "
	pause
}

## Purpose: unmounting backup 
function unmount_my_backup(){
	write_header " Backup deiner Daten wird ausgehängt..."
	if mount | grep /home/$USER/backup &>/dev/null; then				# check wether the backup is mounted
		fusermount -u $backup_mount					# it's mounted...
		msg_ok "$backup_mount wurde ausgehängt."
	else
		msg_info "Backup ist nicht eingehängt."				# no need to unmount
	fi
	echo " "
	pause
}

## Purpose: mount Elements (ext. HDD via SSHFS)
function mount_elements(){
	write_header " Elements einhängen..."
	if [ ! -d "$elements_mount" ]; then                       # local mounting point exists?
                mkdir $elements_mount
        fi
        sshfs $elements $elements_mount -p 22 -o IdentityFile=$ssh_id_file &>/dev/null
        case "$?" in
                0) msg_ok "Elements steht in $elements_mount zur Verfügung."  # yay
                   msg_info "Vergiss bitte nicht das Laufwerk später wieder auszuhängen." ;;
                *) msg_warning "Da ist etwas schief gegangen."
                   echo "Möglicherweise ist Elements bereits eingehängt unter $elements_mount"
                   echo "Andernfalls besteht ein Problem mit dem Netzwerk und du solltest deinen Administrator fragen" 
        esac
        echo " "
 
	pause
}

## Purpose: unmounting Elements
function unmount_elements(){
	write_header " Elements wird ausgehängt..."
        if mount | grep /media/pi/Elements &>/dev/null; then                              # check wether elements is mounted
                fusermount -u $elements_mount                                     # it's mounted...
                msg_ok "$elements_mount wurde ausgehängt."
        else
                msg_info "Elements ist nicht eingehängt."                         # no need to unmount
        fi
        echo " "
        pause
}

## Purpose: Selfcheck routine (requires root to install dependencies)
function self_check(){
	write_header " Selbstdiagnose"
	echo "Dieses Programm ist nur unter Debian GNU/Linux getestet und setzt einige Abhängigkeiten voraus."
	echo " "
	echo -n "Abhängigkeiten prüfen und installieren? [Y/N]  "		# Install dependencies?
	read yesno
	case $yesno in
		[yY]) 								# yes-case
			echo "Abhängigkeiten werden aufgelöst..."
			sudo apt-get update
			clear
			write_header " Selbstdiagnose"
			if [ -e /home/$USER/bin/bsfl ]; then			# Ist bsfl im vorgesehenen Verzeichnis vorhanden?
				msg_ok "bsfl ist bereits installiert."			# yay
			else wget $bsfl_URL --directory-prefix=/home/$USER/bin &>/dev/null	# download bsfl
				if [ "$?" -eq 0 ]; then
					tar -xvzf /home/$USER/bin/bsfl-2.00-beta-2.tgz && rm /home/$USER/bin/bsfl-2.00-beta-2.tgz
					. /home/$USER/bin/bsfl			# extract and start
					msg_ok "bsfl erfolgreich heruntergeladen."
				else
					echo "Ein Fehler ist aufgetreten. Möglicherweise muss bsfl manuell installiert werden."
					echo "Das Programm wird beendet"; exit 0		# strange error, exit
				fi
			fi
			sudo dpkg -s tlp | grep installed &>/dev/null		# check for dependencie tlp (seperately), 
									#cause its not available in debian repositorys (exept for debian Sid)
			case "$?" in
				0) msg_ok "tlp ist bereits installiert." ;;
				1) msg_info "Das Paket tlp muss installiert werden. Die Installation ist möglicherweise nur aus"
				   echo "externen Paketquellen möglich und muss manuell erfolgen." ;;
				*) msg_error "Es ist ein Fehler aufgetreten."
				   pause
			esac
			for dependencie in rsync sshfs cowsay			# check for other dependencies like rsync, sshfs, cowsay
				do
				sudo dpkg -s $dependencie | grep installed &>/dev/null		# is dependencie installed?
				case "$?" in
					0) msg_ok "$dependencie ist bereits installiert" ;;	# yay
					1) msg_info "$dependencie wird installiert..."		# not installed, so
					   sudo apt-get install $dependencie -y &>/dev/null		# ... installing
					   case "$?" in
					   0) msg_ok "$dependencie wurde erfolgreich installiert." ;;	# succes
				           *) msg_fail "$dependencie konnte nicht installiert werden."	# failed
					      ok=1
					   esac ;;
					*) msg_error "Es ist ein Fehler aufgetreten"			#failed to check wether its installed
					   pause
				esac
			done
			case "$ok" in
			1) msg_fail "Es konnten nicht alle Abhängigkeiten aufgelöst werden" ;; 	# failed to install dependencies
			*) msg_ok "Abhängigkeiten aufgelöst." 					# Everything's fine
			esac ;;
		[nN])	
			msg_info "Du hast Nein ausgewählt."
	esac
	echo " "
	pause
}

## Purpose - "Get input via keyboard and make a decision
function read_input(){
	local c
	read -p "Wähle aus [ 1 - 9 ] " c
	case "$c" in
		1)	update_os ;;
		2)	wifi_troubleshooting ;;
		3)	relative_path ;; #backup_my_data ;;
		4)	mount_my_backup ;;
		5)	unmount_my_backup ;;
		6)	mount_elements ;;
		7)	unmount_elements ;;
		8)	self_check ;;
		9)	
			clear
			echo " "
			echo "Besuchen Sie uns bald wieder."; exit 0 ;;
		*)
			msg_debug "Eingabe muss einer Zahl zwischen 1 und 9 entsprechen."
			pause
	esac
}

## ignore CTRL+C, CTRL+Z and quit singles using a trap
trap '' SIGINT SIGQUIT SIGTSTP

# main logic
while true
do
	clear
	show_menu	# display menu
	read_input	# wait for user input
done	
