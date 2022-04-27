# Snap-to-Flatpak

A BASH script that removes Snap from an Ubuntu system and replaces it with Flatpak

It also asks the user if they would like to install an App Store that can download flatpaks in case there is none installed on the system.

(Currently only GNOME Software and KDE Discover support flatpaks)

# Simple (A.K.A. noob-friendly) Instructions

1. Download the `snap-to-flatpak.sh` file from the Releases section.

![Instructional image 1](/images/1-downloading-script.png "How to donwload the script from the releases")

2. Go to the folder in which you downloaded the script and mark it as an executable file.

![Instructional image 2](/images/2-marking-as-executable.png "How to mark it as executable in different Flavours")

3. Open a terminal inside the folder in which you downloaded the script and run it with `./snap-to-flatpak.sh`

![Instructional image 3](/images/3-run-and-follow.png "How to open a terminal and run the script in different Flavours")

4. Follow the intructions on the terminal.

# Terminal-only instructions

1. Clone the repo:

```
git clone https://github.com/MasterGeekMX/snap-to-flatpak.git
```

2. Move into the cloned repo folder:

```
cd snap-to-flatpak
```

3. Make the script executable

```
chmod +x snap-to-flatpak.sh
```

4. Run the script

```
./snap-to-flatpak.sh
```

5. Follow the instructions
