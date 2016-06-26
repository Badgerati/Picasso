Picassio
========
Picassio is a PowerShell v3.0+ provisioning/deployment script which uses a single JSON file to determine what commands to execute.

Picassio is named so, as you take a just built empty server/computer and 'paint' it like a canvas using Picassio. The JSON file you pass in is called a 'palette' and this contains a 'paint' (with optional 'erase') object which is an array of 'colours'.

All of Picassio's features (colours) are modularised, allowing for people to have the ability to create extension modules - explained at the end of this document.


Installing
==========
To use Picassio properly, you will need to install the scripts. To do so, once you have cloned the repo, navigate to the "src" folder and run the following command in a PowerShell prompt in administrator mode.

```shell
.\Picassio.ps1 -install
```

This will install all scripts for you, setting up the Path/environment variables. You will be able to use the "picassio" command straight away. Test is out by navigating to a different directory and typing `picassio -version`.

Scripts are installed to "C:\Picassio". Here you will find the main modules and tools for Picassio, you will also see an Extensions directory - covered at the bottom. Running `-install` on `.\Picassio.ps1` again will update the core modules/tools, and will leave the extensions in place. Running `-reinstall` will delete the extensions for a complete fresh install.


Features
========
The following are all supported by Picassio:

* Install/upgrade/uninstall software/packages via Chocolatey, NPM, Bower or NuGet
* Clone/checkout repositories from Git/SVN
* Build projects/solutions using MSBuild
* Run specified commands using either Command Prompt or PowerShell
* Install/uninstall and stop/start Windows services
* Copy files/folders with inclusions/exclusions
* Call Vagrant
* Add/remove entries from the hosts file
* Add/remove website on IIS
* Run node.js applications
* Run tests via NUnit
* Install/uninstall Windows (optional) features such as Web-Server for IIS
* Ability to setup certificates in MMC
* Run cake build scripts
* Run SQL Server scripts or create/restore backups
* Can send emails
* Ability to publish/generate scripts for SSDT
* Support for Network Load Balancer
* Extension modules can be written for third-parties


Dependencies
============
Picassio doesn't depend on any external software to run however, when required it will automatically install the following for you:

* Chocolatey
* git
* svn
* Vagrant
* node.js / npm
* cake
* NuGet
* bower

The above will only be installed when Picassio needs to use them. For example, using a Chocolatey type colour to install node.js will automatically install Chocolatey as well, or cloning a Git branch will auto-install Git if needed.

To view the source code, you can see the ps1 scripts via:

* PowerShell ISE
* Your favourite text editor
* Visual Studio (you will need the "PowerShell Tools" Visual Studio extension)


To Do
=====
There are still quite a few things I wish to add to Picassio, the following is a short list:

* Ability to install Picassio via Chocolatey
* Setup the wiki properly for better docs


Examples
========
To chain them together, just append more colour objects within the paint array. This way you can clone a branch from Git which is a simple WCF Service, build it and then install the service and start it.

As a side note, each colour can have an optional "description" key-value. This value will get written to the console for informational purposes only, and to help you find specific sections in the log outputted.

Note: You can see more examples in the `examples.palette` file bundled with the source code, or view each psm1 module for an example of how to use each one in the header.


Running Picassio
---------------
```bash
picassio -palette example.palette -validate
picassio -palette example.palette -paint
picassio -version
picassio -help
```

Calling just `picassio -paint` in a directory will look for a default 'picassio.palette' file.


Passing Credentials
-------------------
Picassio does have support for username/password credentials should you require them. There are two ways to set these credentials:

* Specify the `-username` and `-password` arguments from the CLI
* Add a colour of singular `{ "type": "credentials" }` somewhere in your paint/erase palette sections. When Picassio gets to this type, assuming you haven't already set the credentials, then the user is prompted to enter them

The credentials are passed to every `Start-Module`, `Test-Module`, `Start-Extension` and `Test-Extension` call, and does have the possibility of being null.


Palette Settings
----------------
A palette has two sections: a paint and an erase section. The paint section is designed to deploy and provision the machine, where as the erase section should roll the machine back to a state before it was painted.

When painting the machine it is possible for it to fail, and then you're left in a malformed state. Or what if you wish to roll everything back, and then paint the machine.

Well, Picassio has the following three settings that can be supplied at the top of a palette:

* rollbackOnFail: Runs the opposite section to the one that was just attempted, if the current one fails to run successfully.
* eraseBeforePaint: Runs the erase section first, before painting the current machine.
* eraseAfterPaint: Mostly for testing purposes, but will erase the machine after it has been painted.

```json
{
    "rollbackOnFail": true,
    "eraseBeforePaint": false,
    "eraseAfterPaint": false,
    "paint": [
        "..."
    ],
    "erase": [
        "..."
    ]
}
```

If none of the settings are supplied, then they are all defaulted to false.


Installing Software
-------------------
This example palette will install Git onto the computer that Picassio is run:
```json
{
    "paint": [
        {
            "type": "chocolatey",
            "ensure": "install",
            "software": {
                "git": "latest"
            }
        }
    ]
}
```
The above palette will ensure that Git is installed, and is installed up to the latest version (that is available to Chocolatey). If you wish to install a specific version of Git, then you would supply the version such as `"git": "1.8.3"`.

If the version key is not supplied, then the install will default to the latest version. If you try to install software that is already installed, then Picassio will upgrade the software to what ever version you supply. If the version is less than the one installed then nothing will happen; so first you'll have to uninstall then re-install.

If you instead wish to uninstall some software (so long as it was originally installed by Chocolately), then the following example palette will uninstall, say, Git
```json
{
    "paint": [
        {
            "type": "chocolatey",
            "ensure": "uninstall",
            "software": {
                "git": ""
            }
        }
    ]
}
```
Here you'll notice that the version is not required, as you're uninstalling software.


Cloning a Branch from Git
-------------------------
Picassio has the ability to clone a branch from any Git server. Simply supply the remote path to your branch as well as the branch's name, along with a local path/name to which to clone, and Picassio will pull down the branch for you.
```json
{
    "paint": [
        {
            "type": "git",
            "remote": "https://path/to/some/branch.git",
            "path": "C:\\path\\to\\place\\branch",
            "name": "NewBranch",
            "branch": "master"
        }
    ]
}
```
This will pull down our master branch, an rename the auto-created folder to be "NewBranch" at the specified local path. If Picassio sees that the local folder already exists, the current one is renamed with the current date appended.


Building a Project using MSBuild
--------------------------------
Picassio is able to build a .NET project/solution using MSBuild (so long as the computer has MSBuild available). One of the keys for MSBuild is the path to where the MSBuild.exe can be found, if one is not supplied a default path is used.

To clean the projects before building, you can pass true to the "clean" parameter:
```json
{
    "paint": [
        {
            "type": "msbuild",
            "toolpath": "C:\\path\\to\\your\\msbuild.exe",
            "projects": [ "C:\\path\\to\\your\\project.csproj" ],
            "arguments": "/p:Configuration=Debug",
            "clean": true
        }
    ]
}
```


Running Specific Commands
-------------------------
For the things that Picassio doesn't do, such as renaming folders or if you wish to run an inhouse script, you can use the command type colour to run commands from the prompt. You have the option of either Command Prompt or PowerShell, and you can run any command you wish.
```json
{
    "paint": [
        {
            "type": "command",
            "prompt": "cmd",
            "command": "echo Hello, world!"
        },
        {
            "type": "command",
            "prompt": "powershell",
            "command": "echo 'Hello, world again!'"
        }
    ]
}
```


Installing a Service
--------------------
Something else Picassio can do it install/uninstall and stop/start Windows services. If you are installing a service then the absolute path to the installer in required however, if you are just uninstalling one then the path can be omitted.

The following palette will install and start a service.
```json
{
    "paint": [
        {
            "type": "service",
            "name": "Test Service",
            "path": "C:\\absolute\\path\\to\\your\\service.exe",
            "ensure": "installed",
            "state": "started"
        }
    ]
}
```

The following palette will uninstall a service.
```json
{
    "paint": [
        {
            "type": "service",
            "name": "Test Service",
            "ensure": "uninstalled"
        }
    ]
}
```

If you are ensuring a service is installed and started, and it already is then the service will be restarted.



Copying Files/Directories
-------------------------
Picassio is able to copy files/folders from one location to another. This is useful for copying files from one system to another; for general maintenance of builds; or creating backups of files/folders. If you specify a path to copy to where all folders don't exist, Picassio will create them for you.

You can also specify files/folders to include/exclude using:

* excludeFiles
* excludeFolders
* includeFiles
* includeFolders

The following palette will copy a folder, and then backup a file within it:
```json
{
    "paint": [
        {
            "type": "copy",
            "from": "C:\\path\\to\\some\\folder",
            "to": "C:\\path\\to\\some\\other\\folder"
        },
        {
            "type": "copy",
            "from": "C:\\path\\to\\some\\other\\folder\\test.txt",
            "to": "C:\\path\\to\\some\\other\\folder\\backups\\test.txt"
        }
    ]
}
```

The following palette will copy a folder, excluding html/js files; but including a src folder only:
```json
{
    "paint": [
        {
            "type": "copy",
            "from": "C:\\path\\to\\some\\folder",
            "to": "C:\\path\\to\\some\\other\\folder",
            "excludeFiles": [ "*.html", "*.js" ],
            "includeFolders": [ "src" ]
        }
    ]
}
```


Calling Vagrant
---------------
Picassio now also supports the ability to call "vagrant up" or other commands such as

* halt
* destroy
* suspend
* share
* etc.

from with a Picassio palette. You will need to supply a path to where a Vagrantfile is located in order for the command to work.

The following palette with navigate to a folder, and call "vagrant up":
```json
{
    "paint": [
        {
            "type": "vagrant",
            "path": "C:\\path\\to\\project",
            "command": "up"
        }
    ]
}
```


Updating the hosts File
-----------------------
Picassio will let you update the hosts file, by allowing you to add/remove entries. To add an entry you will need both the IP/Hostname however, to remove an entry on requires one or both.

When removing, if you supply only either the IP or Hostname, all lines with that IP or Hostname will be removed. If you specify both, then only lines that have both the IP/Hostname will be removed.

The following palette will add an entry to the hosts
```json
{
    "paint": [
        {
            "type": "hosts",
            "ensure": "added",
            "ip": "127.0.0.3",
            "hostname": "test.local.com"
        }
    ]
}
```

The following will remove all entries with the passed IP
```json
{
    "paint": [
        {
            "type": "hosts",
            "ensure": "removed",
            "ip": "127.0.0.3"
        }
    ]
}
```


Add/remove a website in IIS
---------------------------
Picassio can add/remove, start/stop websites and application pools in IIS. You can also set-up binding for http/https IP/port setting.

When a website is created, the default "*:80:" endpoint is removed, if this is required just specify the binding within the bindings array.

Picassio will also add IIS and application pool users to the website path in IIS. This is so the ApplicationPoolIdentity and IIS users have permissions to see the website directory.

The following palette will setup an entry into the hosts file, and also create a website/app pool in IIS. The website will be accessible from 127.0.0.2 or test.site.com.
```json
{
    "paint": [
        {
            "type": "hosts",
            "ensure": "added",
            "ip": "127.0.0.2",
            "hostname": "test.site.com"
        },
        {
            "type": "iis",
            "ensure": "added",
            "state": "started",
            "siteName": "Test Website",
            "appPoolName": "Test Website",
            "path": "C:\\Website\\TestWebsite",
            "bindings": [
                {
                    "ip": "127.0.0.2",
                    "port": "80",
                    "protocol": "http"
                }
            ]
        }
    ]
}
```

If you use a binding of 'https' you'll also need to pass a "certificate" key-value in the bindings. So if above we used https, a possible certificate could be "*.site.com".


Add/remove website bindings in IIS
----------------------------------
If you already have a website setup in IIS, then Picassio can add/remove binding to an already existing website.

The following palette will add an http binding to a website. This is rather similar to the binding array for a website:
```json
{
    "paint": [
        {
            "type": "iis-binding",
            "ensure": "added",
            "siteName": "Test Website",
            "ip": "127.0.0.2",
            "port": "80",
            "protocol": "http"
        }
    ]
}
```

Again like above, if you use a binding of 'https' you'll also need to pass a "certificate" key-value in the bindings. So if above we used https, a possible certificate could be "*.site.com".


Testing via NUnit
-----------------
Picassio supports the ability to test your applications via NUnit from a Picassio palette. You will need to supply a path to where your nunit-console.exe is located in order for the command to work.

The following palette with navigate to NUnit, and then run the tests. Picassio by default will just call NUnit for the specified tests. If you wish to pass any further arguments then you may use the "arguments" parameter like below:
```json
{
    "paint": [
        {
            "type": "nunit",
            "toolpath": "C:\\Program Files\\NUnit\\bin\\nunit-2.0\\nunit-console.exe",
            "arguments": "/include:UnitTest,PeformanceTest /nologo",
            "tests": [
                "Example\\Test1.dll",
                "Example\\Test2.dll"
            ]
        }
    ]
}
```
If any of the tests fail (or NUnit fails), then Picassio will be aborted.


Extensions
==========
Due to the way Picassio is designed, you have the ability to create extension psm1 modules. If you wish to create your own module, there are a few things you need to ensure:

* Extension modules must be placed within the "C:\Picassio\Extensions" directory
* The main logic of the extension must be contained within a "Start-Extension($colour, $variables, $credentials)" function
* Before the main logic is executed, the input must be validated in a "Test-Extension($colour, $variables, $credentials)" function
* You may use the Picassio tools via "Import-Module $env:PicassioTools -DisableNameChecking"
* The $colour passed in is of JSON format

Note: when you re-install Picassio, extensions will be kept intact.

So, let's have an example. Say we want to have a simple echo extension which echos whatever we give it. This would look like:

```powershell
# File name: echo.psm1
Import-Module $env:PicassioTools -DisableNameChecking

function Start-Extension($colour, $variables, $credentials)
{
    # Although tested already, variables could have changed since then
    Test-Extension $colour $variables $credentials

    # Main logic
    Write-Message 'Echo text supplied.'
    $text = $colour.text
    Write-Host $test
}

function Test-Extension($colour, $variables, $credentials)
{
    if ([string]::IsNullOrWhiteSpace($colour.text))
    {
        throw 'No text supplied to echo.'
    }
}
```

Here, you'll noticed that we import the Picassio tools module. This module contains some useful tools such as

* Installing software
* Writing messages
* Testing if software is installed
* Backing-up directories
* Running commands via cmd/powershell
* and more

Next, we have the "Start-Extension($colour, $variables, $credentials)" function. This is the main point-of-call for your modules, and any JSON supplied by the user for your extension will be passed through.

We only require that the user supply us with a "text" key in the palette.

Within the function, all we do is retrieve the text via "$colour.text", and then echo the value using Write-Host.

The Test-Extension function will be called during the initial validation of the passed JSON file. Here, we should be ensuring the correct values are passed, and files/folders exist. In the one above, we simply throw an error if no text is supplied to be echoed.

The palette for this will look like the following

```json
{
    "paint": [
        {
            "type": "extension",
            "extension": "echo",
            "text": "Hello, world!"
        }
    ]
}

```

Here you can see that the type will be "extension", informing Picassio that it needs to get the module from the extensions - in case people wish to call extension modules with the same name as the core modules.

Then, we have the extension name of "echo", which is the module to use. Finally there is the text that we wish to echo.
