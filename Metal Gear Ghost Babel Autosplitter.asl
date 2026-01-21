// Metal Gear: Ghost Babel Autosplitter
// Created by NickRPGreen
// Version 2.0
// For use exclusively with the GSE Gameboy Emulator: https://github.com/CasualPokePlayer/GSE
// Requires emu-help-v3 in Components folder to run: https://github.com/Jujstme/emu-help-v3/blob/main/lib%2FLivesplit%2Femu-help-v3

state("LiveSplit") {}

init {
    vars.FrameCounter = 0;
    vars.TotalIGT = 0;
    refreshRate = 60;
}

startup{
    //Creates a persistent instance of the Gameboy class (for Gameboy emulators)
	Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("GBC");

    vars.Screen = vars.Helper.Make<byte>(0xC0AA);
    vars.LvlFrames = vars.Helper.Make<int>(0xC4F8);
    vars.LvlSec = vars.Helper.Make<byte>(0xC4F9);
    vars.LvlMin = vars.Helper.Make<byte>(0xC4FA);
    vars.LvlHou = vars.Helper.Make<byte>(0xC4FB);
    vars.Result = vars.Helper.Make<byte>(0xC432);
    vars.Life = vars.Helper.Make<byte>(0xC5E3);
}

gameTime {    
    if(vars.Result.Current == 4){
        return TimeSpan.FromMilliseconds(vars.TotalIGT + (vars.LvlHou.Current * 3600000) + (vars.LvlMin.Current *60000) + (vars.LvlSec.Current * 1000));
    }
    else if(vars.FrameCounter > 0) {
        return TimeSpan.FromMilliseconds(vars.TotalIGT + (vars.LvlHou.Current * 3600000) + (vars.LvlMin.Current *60000) + (vars.LvlSec.Current * 1000) + (vars.FrameCounter * 16.94915254237288));
    }
    else if (vars.LvlFrames.Current + vars.TotalIGT == 0) {
        return TimeSpan.FromSeconds(0);
    }
}

isLoading {
    return true;
}

update {    
    current.Screen = vars.Screen.Current;
    current.Result = vars.Result.Current;
    current.LvlFrames = vars.LvlFrames.Current;
    current.Life = vars.Life.Current;

    if(vars.LvlFrames.Current > vars.LvlFrames.Old) vars.FrameCounter = vars.FrameCounter + 1;
    if((vars.LvlSec.Current != vars.LvlSec.Old) && ((vars.LvlSec.Current + vars.LvlMin.Current + vars.LvlHou.Current) > 0)) vars.FrameCounter = 0;
    if(vars.LvlFrames.Old > 0 && vars.LvlFrames.Current == 0) {
        vars.TotalIGT = vars.TotalIGT + (vars.LvlHou.Old * 3600000) + (vars.LvlMin.Old * 60000) + (vars.LvlSec.Old * 1000);
        vars.FrameCounter = 0;
    }
}

start {
    return vars.Screen.Old == 67 && vars.Screen.Current == 227; 
}

split {
    if(vars.Screen.Current == 0) return false;
    return (vars.LvlFrames.Old) > 0 && (vars.LvlFrames.Current) == 0;
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
    if(vars.Screen.Old == 67) {
        if(vars.Screen.Current == 67 || vars.Screen.Current == 227){
            return false;
        }
        else {
            return true;
        }
    }
    return vars.Life.Current == 255 && vars.Result.Current == 255;
}
