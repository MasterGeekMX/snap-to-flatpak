# Snap-to-Flatpak

A [BASH](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) script that removes [**Snap**](https://ubuntu.com/blog/whats-in-a-snap) from an [Ubuntu](https://ubuntu.com)/Ubuntu-based system and replaces it with [**Flatpak**](https://flatpak.org).

It also asks the user if they would like to install an App Store that can download Flatpaks in case there is none installed on the system.

(*Currently only [GNOME Software](https://wiki.gnome.org/Apps/Software) and [KDE Discover](https://apps.kde.org/discover/) support Flatpaks*)

#

<details><!--Clickable dropdown for simple instructions-->
 <summary>
  <h1>Simple (noob friendly) Instructions | <-Click to expand</h1><!--Use <h1> tag because Markdown does not work in summaries.-->
 </summary>

 1. Download the `snap-to-flatpak.sh` file from the Releases section.

 ![Instructional image 1](/images/1-downloading-script.png "How to donwload the script from the releases")

 2. Go to the folder in which you downloaded the script and mark it as an executable file.

 ![Instructional image 2](/images/2-marking-as-executable.png "How to mark it as executable in different Flavours")

 3. Open a terminal inside the folder in which you downloaded the script and run it with `./snap-to-flatpak.sh`

 ![Instructional image 3](/images/3-run-and-follow.png "How to open a terminal and run the script in different Flavours")

 4. Follow the instructions in the terminal.

</details>


<details>
 <summary>
  <h1>Terminal-only Instructions | <-Click to expand</h1>
 </summary>

 1. Clone the repo:

 ```
 git clone https://github.com/MasterGeekMX/snap-to-flatpak.git
 ```
 
 + NOTE: if you don't have git installed, do it by running `sudo apt install git`
  
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

 5. Follow the instructions in the terminal.

</details>
