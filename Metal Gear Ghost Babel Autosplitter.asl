// Metal Gear: Ghost Babel Autosplitter
// Created by NickRPGreen 

// For use with Metal Gear Solid Master Collection Volume 2 Bonus Content
// For use with the GSE, BGB (x84 and x64), and Gambatte Gameboy Emulators (does not support the Gambatte core on BizHawk)

// v3.1:
// - Now supports multiple emulators: all emulators can use the same method used for MC2, so support for bgb, bgb64, and Gambatte have been added.
// - emu-help-v3 no longer required: as GSE can use the MC2 method, there's no need to have it use a separate method, so emu-help-v3 is no longer needed.
// v3.0:
// - Now supports MGS:MC2 version.
// - Start adjusted to start upon gaining control of Snake, rather than the opening parachute in. 
//   In MGS:MC2 the memory locations are only assigned to RAM upon the game starting, so this change gives the ASL time to assign the MemoryWatchers before gameplay starts.

state("MGS MC2 Bonus Content") {}
state("GSE") {}
state("bgb64") {}
state("bgb") {}
state("gambatte_speedrun") {}

startup{
    vars.U = new ExpandoObject();
    var u = vars.U;          
    u.Log = (Action<string>)(x => print("MG:Ghost Babel Autosplitter - " + x.ToString()));
}

init {
    refreshRate = 60;
    var u = vars.U;
    u.FrameCounter = 0;
    u.TotalIGT = 0;
    u.Log("Running init");
    u.initComplete = false;
    u.AssemblyLoaded = false;
}

update {
    var u = vars.U;
    if(!u.initComplete){
        u.Log(game.ProcessName + " process found. Scanning for MARK.");
        var target = new SigScanTarget(0, "03 9C 80 8F 8F 8F 03 9C A0 86 86 86 03 9C C0 8E 8E 8E 03 9C E0 8E 8E 8E 03 9D 00 86 86 86 03 9D 20 8E 8E 8E 03 9D 40 8E 8E 8E 03 9D 60 8E 8E 8E 03 9D 80 8F 8F 8F 03 9D A0 8E 8E 8E 03 9D C0 8E 8E 8E 03 9D E0 8E 8E 8E 03 9E 00 8F 8F 8F 03 9E 20 8F 8F 8F");
        IntPtr mark = IntPtr.Zero;

        try {
            foreach (var page in game.MemoryPages()) {
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
                mark = scanner.Scan(target);
                if (mark != IntPtr.Zero) {
                    break;
                }
            }
        }
        catch {
            return false;
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
        u.Log("Memory watchers compiled. Autosplitter ready.");
    }

    if(!u.initComplete){
        return false;
    }

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

    if(current.LvlFrames > old.LvlFrames) {
        u.FrameCounter = u.FrameCounter + 1;
    }
    if((current.LvlSecs != old.LvlSecs) && ((current.LvlSecs + current.LvlMins + current.LvlHours) > 0)) {
        u.FrameCounter = 0;
    }
    if(old.LvlFrames > 0 && current.LvlFrames == 0) {
        u.TotalIGT = u.TotalIGT + (old.LvlHours * 3600000) + (old.LvlMins * 60000) + (old.LvlSecs * 1000);
        u.FrameCounter = 0;
    }
}

gameTime {
    var u = vars.U;
    if(current.Result == 4) {
        return TimeSpan.FromMilliseconds(u.TotalIGT + (current.LvlHours * 3600000) + (current.LvlMins *60000) + (current.LvlSecs * 1000));
    }
    else if(u.FrameCounter > 0) {
        return TimeSpan.FromMilliseconds(u.TotalIGT + (current.LvlHours * 3600000) + (current.LvlMins *60000) + (current.LvlSecs * 1000) + (u.FrameCounter * 16.7427));
    }
    else if (current.LvlFrames + u.TotalIGT == 0) {
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
    if(current.Screen == 0) {
        return false;
    }
    return old.LvlFrames > 0 && current.LvlFrames == 0;
}

onStart {
    var u = vars.U; 
    u.FrameCounter = 0;
    u.TotalIGT = 0;
}

onReset {
    var u = vars.U;
    u.FrameCounter = 0;
    u.TotalIGT = 0;
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
