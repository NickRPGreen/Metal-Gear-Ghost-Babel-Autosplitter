//Metal Gear: Ghost Babel Autosplitter
//Created by NickRPGreen

state("bgb")
{
    int LvlFrames: "bgb.exe", 0x172790, 0x928, 0x4F8;
    byte Map: "bgb.exe", 0x172790, 0x34, 0xC, 0x4C, 0x928, 0xBC0;
    byte BossHealth: "bgb.exe", 0x172790, 0xB0, 0xC, 0x73C, 0x702;
}

init {
    vars.FrameCounter = 0;
}

gameTime {    
    if(vars.FrameCounter > 0) {
        return TimeSpan.FromMilliseconds(vars.FrameCounter * 17.2175);
    }
}

isLoading {
    return true;
}

update {
    if(current.LvlFrames > old.LvlFrames) vars.FrameCounter = vars.FrameCounter + 1;
}

start {
    return old.Map == 0 && current.Map == 1;
    //return vars.FrameCounter > 0; //used for testing IGT vs RTA
}

split {
    return (old.LvlFrames) > 0 && (current.LvlFrames) == 0;
    return current.Map == 13 && old.BossHealth == 6 && current.BossHealth == 0;
}

onStart {
    vars.FrameCounter = 0;
}

onReset {
    vars.FrameCounter = 0;
}

reset {
    return old.Map > 0 && current.Map == 0;
}
