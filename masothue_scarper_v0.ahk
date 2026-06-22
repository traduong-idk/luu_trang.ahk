#Requires AutoHotkey v2.0

; ══════════════════════════════════════════════════════
;  PHASE 1 — Thu thập URLs từ listing page
;  Cách dùng:
;    1. Mở Chrome, điều hướng đến listing page ngành xxxx
;    2. Chờ đến khi THẤY tên các công ty hiện trên trang
;    3. Nhấn Ctrl+Shift+U
;    4. Lặp lại cho tất cả 11 trang
; ══════════════════════════════════════════════════════
^+u::
{
    if WinExist("ahk_class Chrome_WidgetWin_1")
        WinActivate("ahk_class Chrome_WidgetWin_1")
    Sleep(800)

    ; Mở DevTools Console (Ctrl+Shift+J)
    Send("^+j")
    Sleep(2500)

    ; Lệnh JS: lấy tất cả link có dạng masothue.com/[10-13 số]-...
    jsCmd := "copy([...document.links].filter(l=>l.href.match(/masothue\.com\/\d{10,13}-/)).map(l=>l.href).join(String.fromCharCode(10)))"

    ; Paste vào console
    A_Clipboard := jsCmd
    Sleep(400)
    Send("^a")
    Sleep(150)
    Send("^v")
    Sleep(300)

    ; Clear clipboard trước để detect kết quả
    A_Clipboard := ""
    Sleep(100)
    Send("{Enter}")

    ; Chờ copy() populate clipboard (tối đa 8 giây)
    if !ClipWait(8)
    {
        Send("{F12}")
        MsgBox("Không lấy được URL.`nTrang có thể chưa load xong công ty.`nĐợi thêm rồi nhấn Ctrl+Shift+U lại.")
        return
    }

    result := A_Clipboard

    ; Đóng DevTools
    Send("{F12}")
    Sleep(500)

    ; Kiểm tra có phải company URL không
    if !InStr(result, "masothue.com")
    {
        MsgBox("Không tìm thấy company URL nào.`nThử nhấn Ctrl+Shift+U lại sau khi trang load đủ.")
        return
    }

    urlCount := StrSplit(Trim(result), "`n").Length

    ; Append vào file
    FileAppend(Trim(result) . "`n", "E:\company_urls.txt", "UTF-8")
    MsgBox("[OK] Lưu " urlCount " URLs từ trang này.`nChuyển sang listing page tiếp theo, rồi nhấn Ctrl+Shift+U.")
}

