# Snap-to-Flatpak

A BASH script that removes Snap from an Ubuntu system and replaces it with Flatpak

It also asks the user if they would like to install an App Store that can download flatpaks in case there is none installed on the system.

(Currently only GNOME Software and KDE Discover support flatpaks)

# Simple (A.K.A. noob-friendly) Instructions

1. Download the `snap-to-flatpak.sh` file from the Releases section.

2. Go to the folder in which you downloaded the script and make it executable.

3. Open a terminal inside the folder in which you downloaded the script.

4. Run it with `./snap-to-flatpak.sh` and follow the intructions on the terminal.

# Terminal-only instructions

1. Clone the repo:

```bash
git clone https://github.com/MasterGeekMX/snap-to-flatpak.git
```

2. Move into the cloned repo folder:

```bash
cd snap-to-flatpak
```

3. Make the script executable

```bash
chmod +x snap-to-flatpak.sh
```

4. Run the script

```bash
./snap-to-flatpak.sh
```

5. Follow the instructions