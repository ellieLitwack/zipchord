/*

This file is part of ZipChord.

Copyright (c) 2023 Pavel Soukenik

Refer to the LICENSE file in the root folder for the BSD-3-Clause license. 

*/

Class clsAppShortcuts {
    MD_SHORT := 1
    MD_LONG := 2
    
    _shortcuts := Array()
    _UI_controls := Array()

    Class clsShortcut {
        function := ""
        displayname := ""
        HK := ""
        mode := 0
    }
    Class clsHandles {
        HK_hwnd := ""
        optLong_hwnd := ""
        optShorthwnd := ""
    }
    Init() {
        this.Add("UI_Main_Show", "Open main ZipChord window", "^+z", this.MD_LONG)
        this.Add( "AddShortcut", "Open Add Shortcut window", "^c", this.MD_LONG)
        this.Add("TogglePause", "Pause / Unpause ZipChord", "", this.MD_LONG)
        this.Add("QuitApp", "Quit ZipChord", "", this.MD_SHORT)
        this.LoadSettings()
        this._WireHotkeys("On")
        this._BuildUI()
    }
    ShowUI() {
        Gui, UI_AppShortcuts:Show, w440
    }
    SaveSettings() {
        For i, shortcut in this._shortcuts
            SaveVarToRegistry(shortcut.HK . "|" shortcut.mode, "hk_" . shortcut.function)
    }
    LoadSettings() {
        For i, shortcut in this._shortcuts
        {
            setting := ""
            UpdateVarFromRegistry(setting, "hk_" . shortcut.function)
            if (setting) {
                setting := StrSplit(setting, "|")
                shortcut.HK := setting[1]
                shortcut.mode := setting[2]
            }
        }
    }
    Add(function, name, HK, mode) {
        i := this._shortcuts.Count() + 1
        app_shortcut := New this.clsShortcut
        app_shortcut.function := function
        app_shortcut.displayname := name
        app_shortcut.HK := HK
        app_shortcut.mode := mode
        this._shortcuts[i] := app_shortcut
    }
    _WireHotkeys(status) {
        For i, shortcut in this._shortcuts
            if (shortcut.HK) {
                call := ObjBindMethod(this, "_ProcessHotkey", i)
                if (shortcut.mode == this.MD_SHORT)
                    Hotkey, % shortcut.HK, % call, %status%
                else
                    Hotkey, % "~" . shortcut.HK, % call, %status%
            }
    }
    _ProcessHotkey(shortcut_ID) {
        shortcut := this[shortcut_ID]
        function := shortcut.function
        HK := RegExReplace(shortcut.HK, "[\+\^\!]")
        if (shortcut.mode == this.MD_LONG) {
            Sleep 300
            if GetKeyState(HK,"P")
                %function%()
        } else %function%()
    }
    _BuildUI() {
        Gui, UI_AppShortcuts:New, , % "ZipChord Keyboard Shortcuts"
        Gui, Margin, 20, 20
        Gui, Font, s10, Segoe UI
        Gui, Add, Text, x+20 y-35, % ""
        For i, shortcut in this._shortcuts
        {
            handles := New this.clsHandles
            Gui, Add, GroupBox, xs-20 y+35 w400 h90, % shortcut.displayname
            Gui, Add, Hotkey, xp+20 yp+37 Section Hwndtemp Limit3, % shortcut.HK
            handles.HK_hwnd := temp
            fn := ObjBindMethod(this, "_UpdateUI", i)
            GuiControl +g, % temp, % fn
            checked := shortcut.mode==this.MD_LONG ? 1 : 0
            Gui, Add, Radio, xs+180 ys-9 Hwndtemp Checked%checked%, % "Long press (non-exclusive)"
            handles.optLong_hwnd := temp
            checked := checked ? 0 : 1
            Gui, Add, Radio, y+10 Hwndtemp Checked%checked%, % "Short press (exclusive)"
            handles.optShort_hwnd := temp
            this._UI_controls[i] := handles
        }
        Gui, Add, Button, w80 xm+220 yp+60 Hwndtemp, % "Cancel"
        fn := ObjBindMethod(this, "_CloseUI")
        GuiControl +g, % temp, % fn
        Gui, Add, Button, Default w80 xm+320 yp Default Hwndtemp, % "OK"
        fn := ObjBindMethod(this, "_btnOK")
        GuiControl +g, % temp, % fn
    }
    _UpdateUI(shortcut_ID) {
        GuiControlGet, val, , % this._UI_controls[shortcut_ID].HK_hwnd
        state := val ? 1 : 0
        GuiControl, Enable%state%, % this._UI_controls[shortcut_ID].optLong_hwnd
        GuiControl, Enable%state%, % this._UI_controls[shortcut_ID].optShort_hwnd
    }
    _btnOK() {
        if (this._CheckDuplicates()) {
            this._UpdateHotkeys()
            this.SaveSettings()
            Gui, UI_AppShortcuts:Hide
        }
    }
    _CheckDuplicates() {
        For i, shortcut in this._shortcuts
        {
            GuiControlGet, val, , % this._UI_controls[i].HK_hwnd
            if (val && InStr(list, "^" . val . "^")) {
                MsgBox ,, % "ZipChord", % Format("The keyboard shortcut for '{}' cannot be the same as another shortcut. (Even if the long or short press settings are different.)", shortcut.displayname)
                return false
            }
            list .= "^" . val . "^"
        }
        return true
    }
    _UpdateHotkeys() {
        this._WireHotkeys("Off")
        For i, shortcut in this._shortcuts
        {
            GuiControlGet, val, , % this._UI_controls[i].HK_hwnd
            shortcut.HK := val
            GuiControlGet, val, , % this._UI_controls[i].optLong_hwnd
            mode := val ? this.MD_LONG : this.MD_SHORT
            shortcut.mode := mode
        }
        this._WireHotkeys("On")
    }
    _CloseUI() {
        UI_AppShortcuts_Close()
    }
    shortcut[which] {
        get {
            return this._shortcuts[which]
        }
    }
    __Get(what) {
        if ( ! clsAppShortcuts.HasKey(what)) {
            return this.shortcut[what]
        }
    }
}

t := New clsAppShortcuts
t.Init()
t.ShowUI()
Return

UI_Main_Show() {
    MsgBox, % "Opening Menu..." . m
}

AddShortcut() {
    MsgBox, % "Add..." 
}
TogglePause() {
    MsgBox, % "Toggling"
}
OpenMenu:
    MsgBox, % "3..."
Return
QuitApp:
    ExitApp
Return


UI_AppShortcutsGuiClose() {
    UI_AppShortcuts_Close()
}
UI_AppShortcutsGuiEscape() {
    UI_AppShortcuts_Close()
}
UI_AppShortcuts_Close() {
    Gui, UI_AppShortcuts:Destroy
}

; Shared functions

UpdateVarFromRegistry(ByRef var, key) {
    RegRead new_value, % "HKEY_CURRENT_USER\Software\ZipChord", % key
    if (! ErrorLevel)
        var := new_value
}

SaveVarToRegistry(var, key) {
    RegWrite % "REG_SZ", % "HKEY_CURRENT_USER\Software\ZipChord", % key, % var
}