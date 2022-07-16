//Metal Gear: Ghost Babel Autosplitter
//Created by NickRPGreen

state("bgb")
{
    byte LvlSec: "bgb.exe", 0x172790, 0x1C0, 0x4F9;
    byte LvlMin: "bgb.exe", 0x172790, 0x928, 0x4FA;
    byte LvlHou: "bgb.exe", 0x172790, 0x4, 0x28, 0x4FB;
    byte Map: "bgb.exe", 0x172790, 0x34, 0xC, 0x4C, 0x928, 0xBC0;
    byte BossHealth: "bgb.exe", 0x172790, 0xB0, 0xC, 0x73C, 0x702;
}

init {
    vars.TotalIGT = 0;
}

gameTime {
    if((current.LvlSec + current.LvlMin + current.LvlHou) > 0)
        return TimeSpan.FromSeconds(vars.TotalIGT + current.LvlHou * 3600 + current.LvlMin *60 + current.LvlSec);
}

isLoading {
    return true;
}

update {
    if((old.LvlSec + old.LvlMin + old.LvlHou) > 0 && (current.LvlSec + current.LvlMin + current.LvlHou) == 0)
        vars.TotalIGT = vars.TotalIGT + (old.LvlHou * 3600 + old.LvlMin *60 + old.LvlSec);
}

start {
    return old.Map == 0 && current.Map == 1;
}

split {
    return (old.LvlSec + old.LvlMin + old.LvlHou) > 0 && (current.LvlSec + current.LvlMin + current.LvlHou) == 0;
    return current.Map == 13 && old.BossHealth == 6 && current.BossHealth == 0;
}

onStart {
    vars.TotalIGT = 0;
}

onReset {
    vars.TotalIGT = 0;
}

reset {
    return old.Map > 0 && current.Map == 0;
}