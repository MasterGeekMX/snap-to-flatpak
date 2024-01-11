#!/bin/bash

# snap-to-flat script Version 1.2
# A BASH script that removes Snap from an Ubuntu system and replaces it with Flatpak
# By MasterGeek.MX

# There is a saying: "Do to others as you would have them do to you" (Matthew 7:12),
# So this code, as my other works, is heavily commented and explained so others
# can learn from it, no matter their level.

# To make my life easier, I will make a bash function to print texts on the screen with some extras.
function print(){
	# First, let's set the text on the teminal with bold text to make emphasis
	tput bold
	# I will print the text in hand using echo, but also enabling
	# special characters like \n(ewline) with the -e parameter.
	# And because I'm #TeamTabs, delete all tabs from the text
	# with the translate (tr) program so text inside indentations looks normal.
	echo -e "$1" | tr --delete "\t"
	#return the terminal to regular text
	tput sgr0
}

# another function, this time is is for checking if the answer to a prompt is yes or no
function answer_affirmative(){
	# we will check if the given answer (as a text string) matches some patterns, so we will use regular expressions.
	# Affirmation can be answered by typing 'Y', 'y', 'Yes' and 'yes'. Any other option fails. First, we check if the text starts
	# with either upper-case Y or lower-case y. Then we check if there is an 'es' followinfg the Y or not,
	# and finally we check if we reached the end of the string (marked in regular expressions by a $)
	[[ "$1" =~ [Yy](es)?$ ]]
}

# Let's start by issuing a warning in text, notification and sound
print "
----------------------------------------------
WARNING: ALL YOUR SNAPS WILL BE DELETED!!!!!!!
 REPEAT: ALL YOUR SNAPS WILL BE DELETED!!!!!!!
----------------------------------------------
"

# send a system notification with high priority and a warning icon
notify-send --app-name="Snap to Flatpak script" --icon=emblem-warning "Hey, pay attention to what the script says!"

# ring 3 times the terminal by sending the bell character
for i in {1..3}
do
	# -e tells echo to read the Escape special characters.
	# -n tells it to not put a Newline after printing.
	echo -e -n "\a"
	# sleep for 0.2 seconds so rings are spaced
	sleep .2
done

# prompt the user if they wish to continue
read -p "Are you sure [y/n]: " confirmation

# if the answer was negative, don't proceed and exit
if ! answer_affirmative $confirmation
then
	print "\nOK, nothing was done.\n"
	unset $confirmation
	exit
fi

# unsetting variables (removing them) ensures no variables are left behind after the script.
# it is only a good practice, but not mandatory.
unset $confirmation

print "\nOK. Proceeding..."
print "\n--------------------------------------------------------------------------------\n"
print "FIRST STEP: Removing all the installed snaps"

# in order to process the snaps we get a list of all the snaps on the system and store it on a bash array.
# Because the command `snap list` puts at the first line a header for each field,
# we will filter out the first line using `tail` by telling it to start at the second line.

snaps=$(snap list | tail --lines +2 | cut --field 1 --delimiter " ")

# now some hoops to put all snaps in a proper bash array because `snaps`
# isn't a proper bash array (for some reason i don't know yet)

# create an empty bash array
declare -a snap_list=()

# go element by element on the snaps
for snap in $snaps
do
	# and add them to the snaps array
	snap_list+=($snap)
done

# save in a variable how many snaps we have by the count of elements in the snaps list array
snap_count=${#snap_list[@]}

# print the number and list of snaps installed
echo -e "\nCurrently $snap_count snaps are installed"
echo -e "The installed snaps are:\n${snap_list[@]}\n"

# Now we are going through that array and remove each snap package from it.
# Snap doesn't let you remove a snap that is a dependency, and unfortunately,
# snaps doesn't offer an option (that I know) to list dependencies, so we are
# going to iterate over the array and try to remove each snap. If it was removed successfully,
# then we pop it out of the list and continue to the next, then we start all over again.
# I know this solution isn't efficient, but it is what I have for the moment.

# while the list of snaps isn't empty...
while [[ $snap_count -gt 0 ]]
do
	# move an index in the range of elements on the snap list
	for ((index=0; index<snap_count; index++))
	do
		# keep track of the snap we are working on currently in a variable with a name easier to read
		current_snap=${snap_list[$index]}
		# remove the snap indicated by the index, and discard the error message if it couldn't be removed
		sudo snap remove --purge $current_snap 2> /dev/null
		# if the last command was successful by exiting with status zero (meaning the snap could be removed)...
		if [[ $? -eq 0 ]]
		then # update the list of snaps by removing the one we just uninstalled
			# create a new empty list for the updated snap list
			declare -a new_snap_list=()
			# iterate on each snap on the list
			for snap in ${snap_list[@]}
			do
				# if the snap in the list isn't the one we just removed...
				if [[ $snap != $current_snap ]]
				then
					# add the snap into the new list
					new_snap_list+=($snap)
				fi
			done
			# replace the old list with the updated one
			snap_list=(${new_snap_list[@]})
			# and update the count of snaps
			snap_count=${#snap_list[@]}
		fi
	done
done

print "\n--------------------------------------------------------------------------------\n"
print "SECOND STEP: Removal of snap"

# Now we are going to remove snap by stopping it's services and then uninstalling it. Then we are going
# to tell APT to hold the package snapd, ignoring it from installations.

print "\nStopping snap services...\n"
# systemctl is the program that allows service management.
# stopping a service means halting it on the spot.
# the --show-transaction is only to make it more verbose
sudo systemctl stop snapd.service --show-transaction
sudo systemctl stop snapd.socket --show-transaction
sudo systemctl stop snapd.seeded.service --show-transaction

print "\nRemoving snap completely...\n"
# we use autoremove because it will also remove other related packages.
# the --purge options is for also removing configuration files,
# and the --assume-yes to do the uninstalling automatically instead of asking the user to confirm
sudo apt autoremove --purge snapd --assume-yes

print "\nMarking snap as a hold package so it cannot be reinstalled\n"
sudo apt-mark hold snapd

# now we are going to make some APT configuration files to avoid the installation of snap and
# the infamous firefox apt package that installs the snap version
print "\nGenerating APT configuration files\n"

# we use the tee program that takes some text as input and then prints it on the screen at the same time it writes that
# into a file. We use it because it can be called with elevated permissions (unlike >) and to show the contents of the config file to the user

# the package and pin-priority fielsds are quite self-explainatory, but the pin not so much.
# release means that the package comes from a given release of a distro.
# the a= parameter refers to the name of the archive of that release. '*'' refers to all.
# the o= parameter refers to the origin of a package (who makes it). 'Ubuntu*' referes to things packaged by Ubuntu.
echo -e "generating file '/etc/apt/preferences.d/no-snap-please' with the following contents:\n"
echo "Package: snapd
Pin: release a=*
Pin-Priority: -1" | sudo tee /etc/apt/preferences.d/no-snap-please

echo -e "\nGenerating the file '/etc/apt/preferences/no-firefox-as-a-snap-please' with the following contents:\n"
echo "Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1" | sudo tee /etc/apt/preferences/no-firefox-as-a-snap-please

print "\nSnap removed"

print "\n--------------------------------------------------------------------------------\n"
print "THIRD STEP: Directory cleanup"

# Now we are going to remove files left by snaps.
# It is easier to make a list of possible directories than trying to search them dynamically.
# Contributors: feel free to add others that I missed.

# let's create a list of the directories to be removed
declare -a directories=("$HOME/snap" "/snap" "/var/snap" "/var/lib/snap" "/var/cache/snapd" "/usr/lib/snapd")

# iterate on each directory on the list of directories...
for directory in ${directories[@]}
do
	# if the path we are looking up exist in the filesystem as a directory...
	if [[ -d $directory ]]
	then
		# ...ask the user if they want to remove the directory and it's contents completely
		echo ""
		read -p "Do you want to completely remove the directory $directory? [y/n]: " rm_confirmation

		# check the user's answer and either do nothing or proceed with the removal
		if answer_affirmative $rm_confirmation
		then # answer was affirmative. Remove the directory completely
			print "Removing $directory"
			# --recursive tells rm to get inside each subdirectory and remove everything inside
			# --force tells rm to don't ask about removing a file and Forces it's removal
			# --verbose tells rm to print each thing it deletes.
			sudo rm --recursive --force --verbose "$directory"
		else
			# answer was negative. Don't remove the directory
			print "OK. $directory is left untouched."
		fi

		unset $rm_confirmation
	fi
done

print "\nFiles removed"

print "\n--------------------------------------------------------------------------------\n"
print "FOURTH STEP: installing and setting up Flatpak"

# Here I'm simply following what it says on https://flatpak.org/setup/Ubuntu

print "\nInstalling flatpak and setting up Flathub repository...\n"

sudo apt install flatpak --assume-yes
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# we are going to detect if the user has a GUI app store compatible with Flatpak
# (currently only GNOME Software and KDE's Discover support flatpak).
# If the user does not have neither installed, a prompt suggesting them will appear.

# detect if gnome-software or plasma-discover is already installed:
# the `command` command is for running stuff that is not bash functions, but if
# we pass the -v flag instead it prints the path where the program lives, and nothing if not found.
# then we check with -x if that path is an executable file. If all is correct, we have found our app store.
if [[ -x $(command -v gnome-software) ]]
then
	appstore="GNOME"
elif [[ -x $(command -v plasma-discover) ]]
then
	appstore="KDE"
else
	appstore="none"
fi

# launch the prompt in case we didn't find a suitable app store
if [[ $appstore == "none" ]]
then
	print "\nYou can install flatpaks with the terminal, but there is the option
	of using a graphical App Store to do it more comfortably.\n"

	# ask the user if they want to install an app store
	read -p "Do you want to install an App Store program? [y/n]: " use_appstore

	# check the answer to see if we proceed with the app store selection or not.
	if answer_affirmative $use_appstore
	then
		print "\nThe options are GNOME Software and KDE Discover
		if you don't have an idea of what to choose,
		Discover works best if you use KDE Plasma (Kubuntu/Ubuntu Studio) or LXQt (Lubuntu),
		and GNOME Software for pretty much everything else:
		GNOME (regular Ubuntu), Xfce (Xubuntu), MATE (Ubuntu Mate/Kylin), Budgie (Ubuntu Budgie)..."

		# prompt the user with the choices of app store available as numbers
		print "\nSelect the number of the App Store you would like to have:"
		select appstore_to_install in GNOME-Software KDE-Discover

		# install the app store the user selected based on it's answer
		do
			case $appstore_to_install in
				"GNOME-Software")
					print "\nOK. Installing GNOME Software...\n"
					sudo apt install gnome-software --assume-yes
					appstore="GNOME"
					break
				;;
				"KDE-Discover")
					print "\nOK. Installing KDE Discover...\n"
					sudo apt install plasma-discover --assume-yes
					appstore="KDE"
					break
				;;
				*) # the user didn't select a number that corresponds with a valid choice
					echo "That is not an option!"
				;;
			esac
		done
	else # the user said no to installing an app store
		print "\nOK then. No GUI app will be installed."
	fi
fi

#install the corresponding backend for flatpaks for the installed app store
# check if there is even an app store to work with in the first place
if [[ $appstore != "none" ]]
then
	print "\nInstalling the corresponding flatpak backend for $appstore_to_install...\n"
	if [[ $appstore == "GNOME" ]]
	then
		sudo apt install gnome-software-plugin-flatpak --assume-yes
	elif [[ $appstore == "KDE" ]]
	then
		sudo apt install plasma-discover-backend-flatpak --assume-yes
	fi
fi

unset $appstore

# finally, tell the user we have finished
print "\nWe are done! snap is no more, and flatpak is in.

check the list of the apps that were installed as snap in case
you want them reinstalled in flatpak/apt format, like Firefox.
Now, restart your computer to finish the setup of Flatpak"
