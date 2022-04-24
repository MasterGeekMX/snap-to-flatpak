#!/bin/bash

# snap-to-flat script Version 1.0
# A BASH script that removes Snap from an Ubuntu system and replaces it with Flatpak
# By MasterGeek.MX

# There is a saying: "Do to others as you would have them do to you" (Matthew 7:12),
# So this code, as my other works, is heavly commented and explained so others
# can learn from it, no matter their level.

# Before everything, a warning and a prompt for good measure.
# Oh, and all those 'tput' things are for switching between bold and normal text

tput bold
echo ""
echo "----------------------------------------------"
echo "WARNING: ALL YOUR SNAPS WILL BE DELETED!!!!!!!"
echo " REPEAT: ALL YOUR SNAPS WILL BE DELETED!!!!!!!"
echo "----------------------------------------------"
echo ""

#ring 3 times the terminal by sending the bell character
for i in {1..3}
do
	# -e tells echo to read the Escape characters.
	# -n tells it to not put a Newline after printing.
	echo -e -n "\a"
	sleep .2
done

read -p "Are you sure [y/n]: " confirmation

if [[ "$confirmation" =~ [Nn]o? ]]
then
	echo -e "\nOK, nothing was done.\n"
	tput sgr0
	unset $confirmation
	exit
fi

unset $confirmation

echo -e "\nOK. Proceeding..."
echo -e "\nFIRST STEP: Removing all the installed snaps"
tput sgr0

# First we get a list of all the snaps on the system and store it on a bash array.
# Because the command `snap list` puts at the first line a header for each field,
# we will filter out the first line using `tail` by telling it to start at the second line.

snaps=$(snap list | tail --lines +2 | cut --field 1 --delimiter " ")

#now some hoops because `snaps` isn't a proper bash array (for some reason i don't know yet)
declare -a snap_list=()

for snap in $snaps
do
	snap_list+=($snap)
done

tput bold
echo -e "\nThe installed snaps are:"
tput sgr0
echo -e "${snap_list[@]}\n"

# Now we are going through that array and remove each snap package from it.
# Snap doesn't let you remove a snap that is a dependency, and unfortunately,
# snap doesn't offer an option (that I know) to list dependencies, so we are
# going to iterate over the array and try each snap. If it was removed,
# then we pop it out of the list abd continue, then we start all over again.
# I know it is not efficient, but it is what I have for the moment.

snap_count=${#snap_list[@]}

#while the list of snaps isn't empty...
while [[ $snap_count -gt 0 ]]
do
	#move an index in the range of elements on the snap list
	for ((index=0; index<snap_count; index++)) #index in ${!snap_list[@]}
	do
		#keep track of the snap we are working on in a variable with an easier name
		current_snap=${snap_list[$index]}
		#remove the snap indicated by the index, and discard the error message if it couldn't be removed
		sudo snap remove --purge $current_snap 2> /dev/null
		#if the last command was successful (the snap could be removed)...
		if [[ $? -eq 0 ]]
		then
			#create a new empty list for the updated snap list
			declare -a new_snap_list=()
			#go in each snap on the list
			for snap in ${snap_list[@]}
			do
				#if the snap in the list isn't the one we removed...
				if [[ $snap != $current_snap ]]
				then
					#add the snap into the new list
					new_snap_list+=($snap)
				fi
			done
			#replace the old list with the updated one
			snap_list=(${new_snap_list[@]})
			#and update the count of snaps
			snap_count=${#snap_list[@]}
		fi
	done
done

tput bold
echo -e "\nall snaps were removed"
echo -e "\nSECOND STEP: Cleanup"

# Now we are going to remove files left by snaps.
# It is easier to make a list of possible directories.
# Contributors: feel free to add others that I missed.

echo -e "\nRemoving files left behind in:"

declare -a directories=("$HOME/snap" "/snap" "/var/snap" "/var/lib/snap" "/var/cache/snapd" "/usr/lib/snapd")

for directory in ${directories[@]}
do
	if [[ -d $directory ]]
	then
		echo -e "\n$directory:\n"
		tput sgr0
		# -r tells rm to be Recursive; betting inside each directory and removing stuff inside
		# -f tells rm to don't ask about removing a file and Forces it's removal
		# -v tells rm to be Verbose and print each thing it deletes.
		sudo rm -rfv "$directory"
		tput bold
	fi
done

tput bold
echo -e "\nFiles removed"
echo -e "\nTHIRD STEP: Deactivation of snap"

# Now we are going to remove snap, first by stopping and deactivating
# it's services, and then uninstalling it. Finally we are going
# to tell APT to hold the package snapd, ignoring it from installations.

echo -e "\nStopping and deactivating snap services...\n"
tput sgr0

sudo systemctl stop snapd.socket -T
sudo systemctl stop snapd.service -T
sudo systemctl disable snapd.service

tput bold
echo -e "\nRemoving and holding snap...\n"
tput sgr0

#we use autoremove because it will also remove other releated packages.
#purge is for also removing config files.
sudo apt autoremove --purge snapd --assume-yes
#marking a package as held prevents it from being installed/uninstalled
sudo apt-mark hold snapd

tput bold
echo -e "\nSnap removed"
echo -e "\nFOURTH STEP: installing and setting up Flatpak"

# Here I'm simply following what it says on https://flatpak.org/setup/Ubuntu

echo -e "\nInstalling flatpak and setting up Flathub repository...\n"
tput sgr0

sudo apt install flatpak --assume-yes
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# we are going to detect if the user has a GUI app store compatible with Flatpak
# (currently only GNOME software and KDE's Discover support flatpak).
# If the user does not have neither installed, a prompt suggesting them will appear.

#detect if gnome-software or plasma-discover is available
if [[ -x $(command -v plasma-discover) ]]
then
	appstore="discover"
elif [[ -x $(command -v gnome-software) ]]
then
	appstore="software"
else
	appstore="none"
fi

#launch the prompt in case there is no app store
if [[ $appstore == "none" ]]
then
	tput bold
	echo "You can install flatpaks with the terminal, but there is the option"
	echo "of using a graphical App Store to do it more comfortably."

	read -p "Do you want to install an App Store program? [y/n]: " use_appstore

	if [[ $use_appstore =~ [Yy](es)? ]]
	then
		echo -e "\nNeat! the options are GNOME Software and KDE Discover"
		echo "if you don't have an idea of what to choose,"
		echo "Discover works best if you use KDE Plasma (Kubuntu/Ubuntu Studio) or LXQt (Lubuntu),"
		echo "and GNOME Software for pretty much everything else:"
		echo "GNOME (regular Ubuntu), xfce (Xubuntu), Mate (Ubuntu Mate/Kylin), Budgie (Ubuntu Budgie)..."

		echo -e "\nSelect the number of the App Store you would like to have:"
		select appstore_to_install in KDE-Discover GNOME-Software
		do
			case $appstore_to_install in
				"KDE-Discover")
					echo -e "\nOK. Installing KDE Discover...\n"
					tput sgr0
					sudo apt install plasma-discover --assume-yes
					appstore="discover"
					tput bold
					break
				;;
				"GNOME-Software")
					echo -e "\nOK. Installing GNOME Software...\n"
					tput sgr0
					sudo apt install gnome-software --assume-yes
					appstore="software"
					tput bold
					break
				;;
				*)
					echo "That is not an option!"
				;;
			esac
		done
	else
		echo -e "\nOK then. No GUI app will be installed."
	fi
fi

#install the corresponding backend for flatpaks

if [[ $appstore != "none" ]]
then
	tput bold
	echo -e "\nInstalling the corresponding flatpak backend\n"
	tput sgr0
	if [[ $appstore == "discover" ]]
	then
		tput sgr0
		sudo apt install plasma-discover-backend-flatpak --assume-yes
		tput bold
	elif [[ $appstore == "software" ]]
	then
		tput sgr0
		sudo apt install gnome-software-plugin-flatpak --assume-yes
		tput bold
	fi
fi

echo -e "\nWe are done! snap is no more, and flatpak is in.\n"
echo "check the list of the apps that were installed as snap in case"
echo "you want them reinstalled in flatpak/apt format, like Firefox."
echo -e "Now, restart your computer to finish the setup of Flatpak\n"
tput sgr0
