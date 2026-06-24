#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
;  Scan Naming Helper  (keyboard / slash-command edition)
;  ------------------------------------------------------------
;  STEP 1 - type  /file  to open the dialog and set:
;             Side (R or L), Body Part, Sx Date.   Press Enter to close.
;             (Values stay until you change them, so the next document
;              for the same surgery needs no re-typing.)
;
;  STEP 2 - in the file-name box, type a command. It erases itself
;           and types the full name in its place:
;
;     /cid ........ Common Interest Disclosure-BW
;     /booking .... Booking Slip {S} {BP} Sx {date}-BW
;     /charges .... Sx Charges {S} {BP} {date}-BW
;     /checklist .. Sx Checklist {S} {BP} {date}-BW
;     /oppics ..... OP Pics {S} {BP} Sx {date}-BW
;     /opreport ... OP Report {S} {BP} Sx {date}-BW
;     /consent .... Consent for {S} {BP} Sx {date}-BW
;     /insurance .. Insurance Verification Form-BW
;
;  (Ctrl+Alt+N also opens the dialog, same as /file.)
; ============================================================

; ---------------- SETTINGS ----------------
SanitizeForFilename := false   ; true  = replace "/" with "-" in the date (Windows file-name safe)
                              ; false = leave the date exactly as typed (e.g. an EMR field that allows "/")
Suffix := "-BW"               ; trailing tag on every name
BodyParts := ["Knee","Hip","Shoulder","Ankle","Foot","Hand","Wrist","Elbow","Spine","Femur","Tibia","Humerus","Clavicle"]
; ------------------------------------------

global gGui, gSide, gBP, gDate

BuildGui()
return

; ---------- the /file dialog ----------
BuildGui() {
    global gGui, gSide, gBP, gDate, BodyParts
    gGui := Gui("+AlwaysOnTop", "Surgery Details")
    gGui.SetFont("s10", "Segoe UI")
    gGui.OnEvent("Close",  (*) => gGui.Hide())
    gGui.OnEvent("Escape", (*) => gGui.Hide())

    gGui.Add("Text", "xm", "Side:")
    gSide := gGui.Add("Edit", "x+6 yp-3 w40 Limit1")
    gGui.Add("Text", "x+15 yp+3", "Body Part:")
    gBP := gGui.Add("ComboBox", "x+6 yp-3 w190", BodyParts)
    gGui.Add("Text", "x+15 yp+3", "Sx Date:")
    gDate := gGui.Add("Edit", "x+6 yp-3 w110")
    gGui.Add("Text", "x+8 yp+3 cGray", "mm/dd/yy")

    gGui.Add("Button", "xm y+14 w90 Default", "OK").OnEvent("Click", (*) => gGui.Hide())
    gGui.Add("Button", "x+10 yp w90", "Reset").OnEvent("Click", ResetFields)

    gGui.Add("Text", "xm y+16", "In the file-name box, type any of these (the / erases itself):")
    gGui.Add("Text", "xm y+4 c0066CC", "/cid   /booking   /charges   /checklist   /oppics   /opreport   /consent   /insurance")
}

ShowPanel(*) {
    global gGui, gSide
    gGui.Show()
    gSide.Focus()
}

ResetFields(*) {
    global gSide, gBP, gDate
    gSide.Value := ""
    gBP.Text := ""
    gDate.Text := ""
    gSide.Focus()
}

; ---------- assemble a name from the current fields ----------
BuildName(docKey) {
    global gSide, gBP, gDate, SanitizeForFilename, Suffix

    if (docKey = "cid")
        return "Common Interest Disclosure" Suffix
    if (docKey = "insurance")
        return "Insurance Verification Form" Suffix

    side := StrUpper(Trim(gSide.Value))
    bp   := Trim(gBP.Text)
    d    := Trim(gDate.Text)
    if (side = "" || bp = "" || d = "")
        return ""
    if SanitizeForFilename
        d := StrReplace(d, "/", "-")

    switch docKey {
        case "booking":   return "Booking Slip "  side " " bp " Sx " d Suffix
        case "charges":   return "Sx Charges "    side " " bp " "    d Suffix
        case "checklist": return "Sx Checklist "  side " " bp " "    d Suffix
        case "oppics":    return "OP Pics "       side " " bp " Sx " d Suffix
        case "opreport":  return "OP Report "     side " " bp " Sx " d Suffix
        case "consent":   return "Consent for "   side " " bp " Sx " d Suffix
    }
    return ""
}

; ---------- type the name into the focused field ----------
Emit(docKey) {
    name := BuildName(docKey)
    if (name = "") {
        Flash("Type /file first and set Side, Body Part, and Date")
        return
    }
    SendText(name)
}

Flash(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}

; ---------------- COMMANDS ----------------
^!n::ShowPanel()

:*:/file::
{
    ShowPanel()
}
:*:/cid::
{
    Emit("cid")
}
:*:/booking::
{
    Emit("booking")
}
:*:/charges::
{
    Emit("charges")
}
:*:/checklist::
{
    Emit("checklist")
}
:*:/oppics::
{
    Emit("oppics")
}
:*:/opreport::
{
    Emit("opreport")
}
:*:/consent::
{
    Emit("consent")
}
:*:/insurance::
{
    Emit("insurance")
}
