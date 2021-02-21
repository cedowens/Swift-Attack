# Swift-Attack
Unit tests for blue teams to aid with building detections for some common macOS post exploitation methods. I have included some post exploitation examples using both command line history and on disk binaries (which should be easier for detection) as well as post exploitation examples using API calls only (which will be more difficult for detection). The post exploitation examples included here are not all encompassing. Instead these are just some common examples that I thought would be useful to conduct unit tests around. I plan to continue to add to this project over time with additional unit tests.

## Steps:
> git clone https://github.com/cedowens/Swift-Attack

- Ensure you have installed swift and developer tools (can install from the mac app store)

- open the xcodeproj file in XCode

- Build in XCode

- The compiled app will be dropped to something like: ***Users/<username>/Library/Developer/Xcode/DerivedData/Swift-Attack-[random]/Build/Products/Debug/Swift-Attack.app***

- cd to the build directory above

- cd Swift-Attack.app/Contents/MacOS (you can run the macho from here or copy it elsewhere and run...up to you)

- grant the Swift-Attack macho full disk access to ensure you can run all of the tests without TCC issues

- run the following to remove any quarantine attributes:

> xattr -c Swift-Attack 

- Run Swift-Attack:

> ./Swift-Attack -h 

![Image](swift-attack.png)

## Usage:

You can run Swift-Attack with a single option or multiple options

> ./Swift-Attack [option1] [option2]...

- I also included a simple macro.txt file (unobfuscated) for testing parent-child relationships around office macro executions on macOS. I did not obfuscate it since the focus is on parent-child relationship visibility/detection. If you want to test with an obfuscated macro, I have a repo at github.com/cedowens/MacC2 that contains an obfuscated macro.

- I also did not include any persistence items, since in my opinion it is best to just clone and test persistence using Leo Pitt's persistent JXA repo https://github.com/D00MFist/PersistentJXA. This repo is by far the most comprehensive and current repo that I know of for macOS persistence.
