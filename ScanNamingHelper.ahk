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
SanitizeForFilename := true   ; true  = replace "/" with "-" in the date (Windows file-name safe)
                              ; false = leave the date exactly as typed (e.g. an EMR field that allows "/")
Suffix := "-BW"               ; trailing tag on every name
BodyParts := ["Knee","Hip","Shoulder","Ankle","Foot","Hand","Wrist","Elbow","Spine","Femur","Tibia","Humerus","Clavicle"]

DrChronoURL  := "https://app.drchrono.com/"   ; DrChrono web login page
ChromeProfile := ""                           ; leave "" for default; or e.g. "Profile 1" for a specific Chrome profile
FocusPageDelay := 1800                        ; ms to wait for the login page to load
; OPTIONAL: click the username field after load so the iCloud popup appears.
; Leave both at "" to rely on the page auto-focusing the field (most reliable).
; To set them: run AutoHotkey's "Window Spy", hover the username box, read the
; "Screen" X,Y, and paste below. NOTE: these break if the window moves or the
; screen resolution changes, so only use on a fixed setup.
UsernameFieldX := ""
UsernameFieldY := ""
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

; ---------------- OPEN DRCHRONO ----------------
;  Opens the DrChrono login page in Chrome.  It does NOT enter your
;  password -- let Chrome's password manager (or your clinic's password
;  manager) autofill that.  See the note at the bottom of this file.
F1::OpenDrChrono()
:*:/dc::
{
    OpenDrChrono()
}

OpenDrChrono() {
    global DrChronoURL, ChromeProfile, FocusPageDelay, UsernameFieldX, UsernameFieldY
    profileArg := (ChromeProfile != "") ? ' --profile-directory="' ChromeProfile '"' : ""
    args := profileArg ' "' DrChronoURL '"'

    launched := false
    for exe in ["chrome.exe"
              , "C:\Program Files\Google\Chrome\Application\chrome.exe"
              , "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"] {
        try {
            Run((InStr(exe, "\") ? '"' exe '"' : exe) args)
            launched := true
            break
        }
    }
    if !launched {
        MsgBox("Couldn't find chrome.exe. Edit the path in OpenDrChrono().", "Scan Naming Helper")
        return
    }

    ; wait for the page, then put the cursor in the username field
    if WinWaitActive("ahk_exe chrome.exe", , 10)
        Sleep(FocusPageDelay)
    if (UsernameFieldX != "" && UsernameFieldY != "")
        Click(UsernameFieldX " " UsernameFieldY)   ; focuses the field -> iCloud popup appears
    ; (If left blank, the login page's own auto-focus puts the cursor in the field.)
}

; ============================================================
;  ABOUT THE LOGIN
;  ------------------------------------------------------------
;  This macro intentionally stops at the login page. Storing a
;  DrChrono password in this file would put PHI-system credentials
;  in plain text on disk -- a real security/HIPAA risk.
;
;  Fast + safe ways to fill the password from the keyboard:
;    * Chrome's built-in password manager: save the login once, then
;      it offers to fill automatically. Press Enter to accept.
;    * A password manager (1Password, Bitwarden, etc.) with a global
;      fill shortcut (e.g. Ctrl+Shift+L in Bitwarden) -- one keystroke,
;      encrypted at rest, and shareable across staff the right way.
; ============================================================
