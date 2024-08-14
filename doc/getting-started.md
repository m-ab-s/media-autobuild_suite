# Getting Started

## First Time

### Preliminaries

1. Path is less than 60 characters.
2. Path has no spaces.
3. OS level is Windows 8.1 or above.
    - Although Windows 7 could work, it is not supported.
4. Powershell version 4 and above
    - Do not run this script from Powershell Core prior to version 7 as it will fail to download the wget-pack.exe. See [Pull #1021](https://github.com/m-ab-s/media-autobuild_suite/pull/1021)
5. Make sure to get the latest version of the suite before running anything.
    - If you have cloned the repository using git, look at the `Using update_suite.sh` section or the `Using git` section of [updating.md](./updating.md#using-git)
    - If you have downloaded the suite through the zip, look at the `Using snapshots from Github` section of [updating.md](./updating.md#using-snapshots-from-github#using-snapshots-from-github)

### Running the Suite

Running the suite is simple:

1. Run media-autobuild_suite.bat
2. Answer the questions that appear

### After the Suite is Done

After the suite is done, the binary files will appear in the local[64|32] folder folders under bin-audio, bin-global, and bin-video.

To use these, you can either:

- Copy the files in those folders to a folder that is in your enviroment PATH*.
- Add the bin-* folders to your enviroment PATH*.
- Invoke the programs using their path.
  - For CMD: `C:\Users\Potatoe>C:\media-autobuild_suite\local64\bin-video\ffmpeg.exe -h`
  - For Powershell: `PS C:\Users\Potatoe> C:\media-autobuild_suite\local64\bin-video\ffmpeg.exe -h`
  - Adjust the path to match your situation.

*Note: It is almost always recommeded to copy/move the files in the bin-\* folders to somewhere you can easily remember and use as you cannot use them while the suite is updating or compiling.*

\* If you do not know what your enviroment PATH is, either ignore those options or google what the enviroment PATH is.

## Afterwards

Look at [updating.md](./updating.md) for when you want to update the suite or just rerun the batch script as it will automatically look for updates itself.

If you want to rebuild the programs from scratch at any time due to an error or something else, delete the local[32|64] folder folder and remove any \*-git and \*-svn folders from the build folder. Finally rerun the batch script, it should redownload all of those folders and rebuild into a new local[32|64] folder.

If you want to rebuild the suite from scratch completely, in addition to deleting the folders specified above, also delete the msys64 folder and rerun the script. It should at that point redownload and setup the msys2 system again.
