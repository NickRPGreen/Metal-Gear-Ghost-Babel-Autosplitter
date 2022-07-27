//Metal Gear: Ghost Babel Autosplitter
//Created by NickRPGreen 

state("bgb")
{
//24903F9 -> 24908B9
    byte Map: "bgb.exe",  0x172790, 0x1C0, 0xBC0;
    byte BossHealth: "bgb.exe", 0x172790, 0x1C0, 0x802;
    int LvlFrames: "bgb.exe", 0x172790, 0x1C0, 0x4F8;
    byte LvlSec: "bgb.exe", 0x172790, 0x1C0, 0x4F9;
    byte LvlMin: "bgb.exe", 0x172790, 0x1C0, 0x4FA;
    byte LvlHou: "bgb.exe", 0x172790, 0x1C0, 0x4FB;
}

init {
    vars.FrameCounter = 0;
    vars.TotalIGT = 0;
    refreshRate = 60;
}

startup{
    settings.Add("Test", false, "If this setting has appeared, the ASL has updated. It does nothing.");
}

gameTime {    
    if(vars.FrameCounter > 0) {
        return TimeSpan.FromMilliseconds(vars.TotalIGT + (current.LvlHou * 3600000) + (current.LvlMin *60000) + (current.LvlSec * 1000) + (vars.FrameCounter * 16.94915254237288));
    }
    else if (current.LvlFrames + vars.TotalIGT == 0) {
        return TimeSpan.FromSeconds(0);
    }
}

isLoading {
    return true;
}

update {
    if(current.LvlFrames > old.LvlFrames) vars.FrameCounter = vars.FrameCounter + 1;
    if((current.LvlSec != old.LvlSec) && ((current.LvlSec + current.LvlMin + current.LvlHou) > 0)) vars.FrameCounter = 0;
    if((old.LvlSec + old.LvlMin + old.LvlHou) > 0 && (current.LvlSec + current.LvlMin + current.LvlHou) == 0) vars.TotalIGT = vars.TotalIGT + (old.LvlHou * 3600000) + (old.LvlMin * 60000) + (old.LvlSec * 1000);
}

start {
    return old.Map == 0 && current.Map == 1;
}

split {
    return (old.LvlFrames) > 0 && (current.LvlFrames) == 0;
    return current.Map == 13 && old.BossHealth == 6 && current.BossHealth == 0;
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
    return old.Map > 0 && current.Map == 0;
}
