// Metal Gear: Ghost Babel Autosplitter
// Created by NickRPGreen 

// For use with Metal Gear Solid Master Collection Volume 2 Bonus Content
// For use with the GSE Gameboy Emulator: https://github.com/CasualPokePlayer/GSE
// Requires emu-help-v3 in Components folder to run: https://github.com/Jujstme/emu-help-v3/blob/main/lib%2FLivesplit%2Femu-help-v3

// v3.0:
// - Now supports MGS:MC2 version.
// - Start adjusted to start upon gaining control of Snake, rather than the opening parachute in. 
//   In MGS:MC2 the memory locations are only assigned to RAM upon the game starting, so this change gives the ASL time to assign the MemoryWatchers before gameplay starts.

state("MGS MC2 Bonus Content") {}
state("GSE") {}

startup{
    Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("GBC");
    vars.U = new ExpandoObject();
    var u = vars.U;          
    u.Log = (Action<string>)(x => print("MGS:Ghost Babel Autosplitter - " + x.ToString()));
}

init {
    vars.FrameCounter = 0;
    vars.TotalIGT = 0;
    refreshRate = 60;

    var u = vars.U;
    u.Log("Running init");
    u.initComplete = false;
}

update {
    var u = vars.U; 
    if(!u.initComplete){
        switch(game.ProcessName.ToLowerInvariant()){
            case "mgs mc2 bonus content":
                u.Log("MGS MC2 Bonus Content process found. Scanning for MARK.");
                var target = new SigScanTarget(0, "03 9C 80 8F 8F 8F 03 9C A0 86 86 86 03 9C C0 8E 8E 8E 03 9C E0 8E 8E 8E 03 9D 00 86 86 86 03 9D 20 8E 8E 8E 03 9D 40 8E 8E 8E 03 9D 60 8E 8E 8E 03 9D 80 8F 8F 8F 03 9D A0 8E 8E 8E 03 9D C0 8E 8E 8E 03 9D E0 8E 8E 8E 03 9E 00 8F 8F 8F 03 9E 20 8F 8F 8F");
                IntPtr mark = IntPtr.Zero;

                foreach (var page in game.MemoryPages()) {
                    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
                    mark = scanner.Scan(target);
                    if (mark != IntPtr.Zero) {
                        break;
                    }
                }

                if (mark == IntPtr.Zero) {
                    return false;
                }

                u.Log("Mark found at " + mark.ToString("X"));
                u.statLst = new MemoryWatcherList() {
                    new MemoryWatcher<byte>    (mark - 0x26E) { Name = "Screen" },
                    new MemoryWatcher<byte>    (mark + 0x11A) { Name = "Result" },
                    new MemoryWatcher<int>     (mark + 0x1E0) { Name = "LvlFrames" },
                    new MemoryWatcher<byte>    (mark + 0x1E1) { Name = "LvlSecs" },
                    new MemoryWatcher<byte>    (mark + 0x1E2) { Name = "LvlMins" },
                    new MemoryWatcher<byte>    (mark + 0x1E3) { Name = "LvlHours" },
                    new MemoryWatcher<byte>    (mark + 0x2CB) { Name = "Life" }
                };

                u.initComplete = true;
                u.Log("Memory Watchers compiled. MC2 Autosplitter ready.");
                break;

            case "gse":
                u.Log("GSE process found. Scanning for values.");
                u.Screen = vars.Helper.Make<byte>(0xC0AA);
                u.LvlFrames = vars.Helper.Make<int>(0xC4F8);
                u.LvlSecs = vars.Helper.Make<byte>(0xC4F9);
                u.LvlMins = vars.Helper.Make<byte>(0xC4FA);
                u.LvlHours = vars.Helper.Make<byte>(0xC4FB);
                u.Result = vars.Helper.Make<byte>(0xC432);
                u.Life = vars.Helper.Make<byte>(0xC5E3);
                u.initComplete = true;
                u.Log("Variable readers compiled. GSE Autosplitter ready.");
                break;

            default:
                break;
        }
    }

    if(!u.initComplete){
        return false;
    }

    switch(game.ProcessName.ToLowerInvariant()){
        case "mgs mc2 bonus content":
            u.statLst.UpdateAll(game);
            current.Screen = u.statLst["Screen"].Current;
            current.Result = u.statLst["Result"].Current;
            current.LvlFrames = u.statLst["LvlFrames"].Current;
            current.LvlSecs = u.statLst["LvlSecs"].Current;
            current.LvlMins = u.statLst["LvlMins"].Current;
            current.LvlHours = u.statLst["LvlHours"].Current;
            current.Life = u.statLst["Life"].Current;

            old.Screen = u.statLst["Screen"].Old;
            old.Result = u.statLst["Result"].Old;
            old.LvlFrames = u.statLst["LvlFrames"].Old;
            old.LvlSecs = u.statLst["LvlSecs"].Old;
            old.LvlMins = u.statLst["LvlMins"].Old;
            old.LvlHours = u.statLst["LvlHours"].Old;
            old.Life = u.statLst["Life"].Old;
            break;

        case "gse":
            current.Screen = u.Screen.Current;
            current.Result = u.Result.Current;
            current.LvlFrames = u.LvlFrames.Current;
            current.LvlSecs = u.LvlSecs.Current;
            current.LvlMins = u.LvlMins.Current;
            current.LvlHours = u.LvlHours.Current;
            current.Life = u.Life.Current;

            old.Screen = u.Screen.Old;
            old.Result = u.Result.Old;
            old.LvlFrames = u.LvlFrames.Old;
            old.LvlSecs = u.LvlSecs.Old;
            old.LvlMins = u.LvlMins.Old;
            old.LvlHours = u.LvlHours.Old;
            old.Life = u.Life.Old;
            break;

        default:
            break;
    }

    if(current.LvlFrames > old.LvlFrames) vars.FrameCounter = vars.FrameCounter + 1;
    if((current.LvlSecs != old.LvlSecs) && ((current.LvlSecs + current.LvlMins + current.LvlHours) > 0)) vars.FrameCounter = 0;
    if(old.LvlFrames > 0 && current.LvlFrames == 0) {
        vars.TotalIGT = vars.TotalIGT + (old.LvlHours * 3600000) + (old.LvlMins * 60000) + (old.LvlSecs * 1000);
        vars.FrameCounter = 0;
    }
}

gameTime {    
    if(current.Result == 4) {
        return TimeSpan.FromMilliseconds(vars.TotalIGT + (current.LvlHours * 3600000) + (current.LvlMins *60000) + (current.LvlSecs * 1000));
    }
    else if(vars.FrameCounter > 0) {
        return TimeSpan.FromMilliseconds(vars.TotalIGT + (current.LvlHours * 3600000) + (current.LvlMins *60000) + (current.LvlSecs * 1000) + (vars.FrameCounter * 16.7427));
    }
    else if (current.LvlFrames + vars.TotalIGT == 0) {
        return TimeSpan.FromSeconds(0);
    }
}

isLoading {
    return true;
}

start {
    return current.Screen == 227 && current.Result == 0 && current.LvlFrames == 1;
}

split {
    if(current.Screen == 0) return false;
    return old.LvlFrames > 0 && current.LvlFrames == 0;
}

onStart {
    vars.FrameCounter = 0;
    vars.TotalIGT = 0;
}

onReset {
    vars.FrameCounter = 0;
    vars.TotalIGT = 0;
}

reset {
    if(old.Screen == 67) {
        if(current.Screen == 67 || current.Screen == 227){
            return false;
        }
        else {
            return true;
        }
    }
    return current.Life == 255 && current.Result == 255;
}
