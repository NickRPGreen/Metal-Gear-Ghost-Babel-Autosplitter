// Metal Gear: Ghost Babel Autosplitter
// Created by NickRPGreen 

// For use with Metal Gear Solid Master Collection Volume 2 Bonus Content
// For use with the GSE Gameboy Emulator

// v4.0:
// - Rewritten all memory capture. Previous version's memory capture was extremely poor, resulting in LiveSplit constantly scanning memory until a new game had been started.
// - Reverted the emulator memory capture back to version 2.0, meaning once again, only GSE is supported and emu-help-v3 is required.
// - MGS:MC2 memory capture has been rewritten from scratch. During initialisation, the launcher header is searched and the memory location advising whether the game has been launched is read.
//   Upon the game being launched, a new ROM header is searched which then provides the required in-game memory locations.
//   When the ASL detects the game has returned to the launcher, the ROM header scan is reset and is searched again when the game is launched again.  

state("GSE") {}
state("MGS MC2 Bonus Content") {}

startup{
    vars.U = new ExpandoObject();
    var u = vars.U;
    u.Log = (Action<string>)(x => print("MG:Ghost Babel ASL - " + x.ToString()));

    var type = Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).GetType("GBC");
    vars.Helper = Activator.CreateInstance(type, args: false);

    u.LauncherTarget = new SigScanTarget(8, "CD CC CC BD 00 00 80 BF ?? 00 00 00 ??");
    u.RomTarget = new SigScanTarget(0, "4D 45 54 41 4C 47 45 41 52 47 42 42 4D ?? ?? 00");
}

init {
    var u = vars.U;
    u.FrameCounter = 0;
    u.TotalIGT = 0;
    refreshRate = 60;

    u.Executable = game.ProcessName.ToLowerInvariant();
    u.isGSE = u.Executable == "gse";
    u.isMC2 = u.Executable == "mgs mc2 bonus content";

    u.initComplete = false;
    u.launcherMark = IntPtr.Zero;
    u.currentMark = IntPtr.Zero;
    u.gameState = null;
}

update {
    var u = vars.U; 
    if(!u.initComplete){
        if(u.isGSE){
            vars.Helper.Update();
            u.Screen = vars.Helper.Make<byte>(0xC0AA);
            u.Result = vars.Helper.Make<byte>(0xC432);
            u.LvlFrames = vars.Helper.Make<int>(0xC4F8);
            u.LvlSecs = vars.Helper.Make<byte>(0xC4F9);
            u.LvlMins = vars.Helper.Make<byte>(0xC4FA);
            u.LvlHours = vars.Helper.Make<byte>(0xC4FB);
            u.Life = vars.Helper.Make<byte>(0xC5E3);
            u.initComplete = true;
            u.Log("Memory Watchers compiled. GSE Autosplitter ready.");
        }
        else if(u.isMC2){
            if(u.launcherMark == IntPtr.Zero) {
                u.Log("Scanning Memory for Launcher Header");
                foreach (var page in game.MemoryPages()) {
                    if ((int)page.State != 0x1000 || (int)page.Protect == 0x01) {
                        continue;
                    }
                    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
                    u.launcherMark = scanner.Scan(u.LauncherTarget);
                    if (u.launcherMark != IntPtr.Zero) {
                        u.Log("Launcher Header found at " + u.launcherMark.ToString("X"));
                        u.gameState = new MemoryWatcher<byte>(u.launcherMark);
                        break;
                    }
                }

                if (u.launcherMark == IntPtr.Zero) {
                    return false;
                }
            }

            u.gameState.Update(game);
            if(u.gameState.Current == 1){
                u.Log("Awating ROM launch. Will scan memory for ROM Header");
                foreach (var page in game.MemoryPages()) {
                    if ((int)page.State != 0x1000 || (int)page.Protect == 0x01) {
                        continue;
                    }
                    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
                    u.currentMark = scanner.Scan(u.RomTarget);
                    if (u.currentMark != IntPtr.Zero) {
                        break;
                    }
                }

                if (u.currentMark == IntPtr.Zero) {
                    return false;
                }
                u.Log("Rom Header found at " + u.currentMark.ToString("X") + ". Compiling Memory Watchers.");
                u.statLst = new MemoryWatcherList() {
                    new MemoryWatcher<byte> (u.currentMark + 0x2417E) { Name="Screen" },
                    new MemoryWatcher<byte> (u.currentMark + 0x24506) { Name="Result" },
                    new MemoryWatcher<int>  (u.currentMark + 0x245CC) { Name="LvlFrames" },
                    new MemoryWatcher<byte> (u.currentMark + 0x245CD) { Name="LvlSecs" },
                    new MemoryWatcher<byte> (u.currentMark + 0x245CE) { Name="LvlMins" },
                    new MemoryWatcher<byte> (u.currentMark + 0x245CF) { Name="LvlHours" },
                    new MemoryWatcher<byte> (u.currentMark + 0x246B7) { Name="Life" },
                };
                u.initComplete = true;
                u.Log("Memory Watchers compiled. MC2 Autosplitter ready.");
            }
        }
    }

    if(!u.initComplete){
        return false;
    }

    if(u.isGSE){
        vars.Helper.Update();
        current.Screen = u.Screen.Current;
        current.Result = u.Result.Current;
        current.LvlFrames = u.LvlFrames.Current;
        current.LvlSecs = u.LvlSecs.Current;
        current.LvlMins = u.LvlMins.Current;
        current.LvlHours = u.LvlHours.Current;
        current.Life = u.Life.Current;

        old.Screen = u.Screen.Old;
        old.LvlFrames = u.LvlFrames.Old;
        old.LvlSecs = u.LvlSecs.Old;
        old.LvlMins = u.LvlMins.Old;
        old.LvlHours = u.LvlHours.Old;
    }
    else if(u.isMC2){
        u.statLst.UpdateAll(game);
        current.Screen = u.statLst["Screen"].Current;
        current.Result = u.statLst["Result"].Current;
        current.LvlFrames = u.statLst["LvlFrames"].Current;
        current.LvlSecs = u.statLst["LvlSecs"].Current;
        current.LvlMins = u.statLst["LvlMins"].Current;
        current.LvlHours = u.statLst["LvlHours"].Current;
        current.Life = u.statLst["Life"].Current;

        old.Screen = u.statLst["Screen"].Old;
        old.LvlFrames = u.statLst["LvlFrames"].Old;
        old.LvlSecs = u.statLst["LvlSecs"].Old;
        old.LvlMins = u.statLst["LvlMins"].Old;
        old.LvlHours = u.statLst["LvlHours"].Old;

        u.gameState.Update(game);
        if(u.gameState.Current == 2){
            u.Log("Returned to Launcher Menu. Memory Watchers will be rewritten.");
            u.initComplete = false;
            u.launcherMark = IntPtr.Zero;
            u.currentMark = IntPtr.Zero;
            return false;
        }
    }

    if(current.LvlFrames > old.LvlFrames) u.FrameCounter = u.FrameCounter + 1;
    if((current.LvlSecs != old.LvlSecs) && ((current.LvlSecs + current.LvlMins + current.LvlHours) > 0)) u.FrameCounter = 0;
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
    if(current.Screen == 0) return false;
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
    var u = vars.U;
    return u.gameState.Current == 2;
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

shutdown {
    vars.Helper.Dispose();
}
