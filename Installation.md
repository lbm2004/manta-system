# Overview #

In order to start using MANTA, one needs to install a few things:

  * A recent version of MATLAB (incl. the Signal Processing, Instrument Control and Data Acquisition Toolbox)
  * The NIDAQ drivers for either analog (NI-DAQmx) or digital (HS-DIO) DAQ cards
  * Download the code from this website

# Install MATLAB #

Talk to your sysadmin to obtain a recent copy of Matlab from The Mathworks. Our favorite version (since it appears to be the fastest) is R2010b.

# Install NI Driver(s) #

For both drivers it is necessary to register with NI for free.

**Digital Headstages**
Download and install the latest HS DIO driver located at the [NI Homepage](http://search.ni.com/nisearch/app/main/p/bot/no/ap/tech/lang/en/pg/1/sn/catnav:du,n8:3465.155.4779,ssnav:sup/).

**Analog Headstages**
Download and install the latest NI DAQmx driver located at the [NI Homepage](http://search.ni.com/nisearch/app/main/p/bot/no/ap/tech/lang/en/pg/1/sn/catnav:du,n8:3478.41.181.5495,ssnav:sup/).


# Download the MANTA code #

There are two ways of obtaining the MANTA code.

  * Users : Simply download the featured Download on the webpage and unzip locally.
  * Contributors : Install the version control system git and clone the current repository

## Installing GIT ##

**Windows:**

First, install the basic git binaries from [msysGIT](http://code.google.com/p/msysgit/)

Second, if GUI interaction is preferred, install a graphical GIT client. While there are many possibilities, we suggest using [TortoiseGIT](http://code.google.com/p/tortoisegit/), which integrates well with the Explorer.

**Linux/Mac:**

First, install the command line tools using the package management tool of your favorite distribution.

Second, if GUI interaction is preferred, install a graphical GIT client, e.g. [GitX](http://gitx.frim.nl/) for Mac OS X.

## Using GIT to clone the repository ##

**TortoiseSVN (Windows)**

In your favorite location, right click and select clone and enter the following address in the URL field:

```
https://USERNAME@code.google.com/p/manta-system/
```

The username has to be your Google username.

TortoiseGIT is going to ask for the Username and Password. Enter the required information in the settings menu (Git) which is opened. It is also necessary to edit the following information in the local .git/config file, under the heading ["origin"](remote.md):

```
url = https://USERNAME:PASSWORD@code.google.com/p/manta-system/
```

The username is again the Google username, and the password is the Google Code password (i.e. not your regular login password), which can be found under the Google code Profile page, under Settings.

**Git Bash (Windows) or Terminal (Unix)**

Open a Terminal (Unix) or the Git Bash (Windows) and navigate to the folder where you want to locate the code.

**Initial pull:**

```
git clone https://USERNAME:PASSWORD@code.google.com/p/manta-system/ LOCALDIRECTORY
```


**Commit changes locally:**
```
git commit
```

**Push changes to server:**
```
git push origin master
```

# Add the Path to Matlab #

There is multiple ways of doing this, but the most automatic is to add the following line to the startup file (which should be located in ~{MATLAB\_HOME}\toolbox\local\)

```
addpath('PATHTOMANTA/manta-system/'); MANTA('PathOnly');
```

The startup file is executed automatically when Matlab starts.

# Create a Config file for your computer #

In order to run adapted to your computer, you need to create a Config file for your computer. To get started, just copy the config file in the Configurations/ABCNL directory, with the name M\_Hostname\_genone.m . You need to rename your file to end with the hostname of your computer in lowercase letters.

If you are using it in a Lab-environment, create another directory in the Configurations directory, which bears the name of your lab. You can then store all your computers configuration files in this directory. You will also need to adapt the paths in your configurations file to match your paths.