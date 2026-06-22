#Requires AutoHotkey v2.0

; ══════════════════════════════════════════════════════
;  PHASE 1 — Thu thập URLs từ listing page
;  Cách dùng:
;    1. Mở Chrome, điều hướng đến listing page ngành 2392
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


; ══════════════════════════════════════════════════════
;  PHASE 2 — Tự động extract data từ từng company page
;  Cách dùng:
;    1. Đảm bảo Phase 1 đã xong (E:\company_urls.txt đã có)
;    2. Nhấn Ctrl+Shift+D để bắt đầu — KHÔNG chạm vào máy
;    3. Sau khi xong, chạy: python jsonl_to_csv.py
; ══════════════════════════════════════════════════════
^+d::
{
    if !FileExist("E:\company_urls.txt")
    {
        MsgBox("Chưa có E:\company_urls.txt!`nChạy Phase 1 (Ctrl+Shift+U) trước.")
        return
    }

    ; Đọc và deduplicate URLs
    rawText := FileRead("E:\company_urls.txt", "UTF-8")
    lines   := StrSplit(Trim(rawText), "`n")
    seen    := Map()
    urls    := []
    for _, line in lines
    {
        u := Trim(line)
        if u && !seen.Has(u)
        {
            seen[u] := true
            urls.Push(u)
        }
    }

    total := urls.Length
    if total = 0
    {
        MsgBox("File company_urls.txt trống.")
        return
    }

    MsgBox("Bắt đầu xử lý " total " công ty.`nNhấn OK và KHÔNG chạm vào máy tính cho đến khi xong!")

    ; JS extract 6 trường (1 dòng, dùng clipboard để paste)
    jsX := '(function(){var d={mst:"",name:"",intl_name:"",address:"",rep:"",phone:""};d.mst=location.pathname.replace(/^\//,"").split("-")[0];var h=document.querySelector("h1,h2");if(h)d.name=h.innerText.replace(/^\d+\s*[-\u2013]\s*/,"").trim();var bs=document.querySelectorAll("b,strong");for(var b of bs){var t=b.innerText.trim();if(t.length>3&&!/^\d/.test(t)&&t!==d.name){d.intl_name=t;break;}}document.querySelectorAll("tr").forEach(function(tr){var c=tr.querySelectorAll("td");if(c.length<2)return;var k=c[0].innerText.toLowerCase();var v=c[1].innerText.trim();if(/address/.test(k)&&!/tax/.test(k)&&!d.address)d.address=v;if(/representative/.test(k)&&!d.rep)d.rep=v;if(/phone|tel/.test(k)&&!d.phone)d.phone=v;});copy(JSON.stringify(d));})();'

    if WinExist("ahk_class Chrome_WidgetWin_1")
        WinActivate("ahk_class Chrome_WidgetWin_1")

    successCount := 0

    for idx, url in urls
    {
        ; Điều hướng đến company page
        Send("^l")
        Sleep(500)
        SendInput(url)
        Sleep(400)
        Send("{Enter}")
        Sleep(7000)  ; Chờ trang load

        ; Mở DevTools Console
        Send("^+j")
        Sleep(2000)

        ; Paste JS extraction
        A_Clipboard := jsX
        Sleep(400)
        Send("^a")
        Sleep(150)
        Send("^v")
        Sleep(300)

        ; Clear clipboard, execute
        A_Clipboard := ""
        Sleep(100)
        Send("{Enter}")

        ; Chờ kết quả (tối đa 8 giây)
        if !ClipWait(8)
        {
            Send("{F12}")
            Sleep(500)
            continue
        }

        jsonLine := A_Clipboard

        ; Đóng DevTools
        Send("{F12}")
        Sleep(500)

        ; Ghi vào file nếu hợp lệ
        if InStr(jsonLine, '"mst"')
        {
            FileAppend(jsonLine . "`n", "E:\company_data.jsonl", "UTF-8")
            successCount++
        }

        Sleep(500)
    }

    MsgBox("HOÀN THÀNH! " successCount "/" total " công ty đã trích xuất.`n`nBây giờ chạy: python jsonl_to_csv.py")
}


Esc::ExitApp
