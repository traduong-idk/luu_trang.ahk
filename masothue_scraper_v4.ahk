#Requires AutoHotkey v2.0

; ══════════════════════════════════════════════════════
;  PHASE 1 — không thay đổi
; ══════════════════════════════════════════════════════
^+u::
{
    if WinExist("ahk_class Chrome_WidgetWin_1")
        WinActivate("ahk_class Chrome_WidgetWin_1")
    Sleep(800)
    Send("^+j")
    Sleep(2500)
    jsCmd := "copy([...document.links].filter(l=>l.href.match(/masothue\.com\/\d{10,13}-/)).map(l=>l.href).join(String.fromCharCode(10)))"
    A_Clipboard := jsCmd
    Sleep(400)
    Send("^a")
    Sleep(150)
    Send("^v")
    Sleep(300)
    A_Clipboard := ""
    Sleep(100)
    Send("{Enter}")
    if !ClipWait(8)
    {
        Send("{F12}")
        MsgBox("Không lấy được URL — trang chưa load xong. Thử lại.")
        return
    }
    result := A_Clipboard
    Send("{F12}")
    Sleep(500)
    if !InStr(result, "masothue.com")
    {
        MsgBox("Không tìm thấy company URL. Thử lại.")
        return
    }
    urlCount := StrSplit(Trim(result), "`n").Length
    FileAppend(Trim(result) . "`n", "E:\company_urls.txt", "UTF-8")
    MsgBox("[OK] Lưu " urlCount " URLs. Chuyển trang tiếp theo rồi nhấn Ctrl+Shift+U.")
}


; ══════════════════════════════════════════════════════
;  PHASE 2 — v4
;  Fix address:
;    - Match cả tiếng Việt ("địa chỉ") lẫn English ("address")
;    - Loại bỏ "Địa chỉ Thuế" / "Tax Address"
;    - Fallback: lấy occurrence THỨ 2 có "Tỉnh/Huyện"
;      vì "Địa chỉ Thuế" luôn xuất hiện trước "Địa chỉ"
;
;  TRƯỚC KHI CHẠY: xóa E:\company_data.jsonl nếu đã có!
; ══════════════════════════════════════════════════════
^+d::
{
    if !FileExist("E:\company_urls.txt")
    {
        MsgBox("Chưa có E:\company_urls.txt! Chạy Phase 1 trước.")
        return
    }
    if FileExist("E:\company_data.jsonl")
    {
        ans := MsgBox("Đã có company_data.jsonl từ lần trước.`nXÓA và chạy lại từ đầu?", "Xác nhận", "YesNo")
        if ans = "Yes"
            FileDelete("E:\company_data.jsonl")
        else
            return
    }

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

    MsgBox("Bắt đầu xử lý " total " công ty.`nNhấn OK và KHÔNG chạm vào máy tính!")

    ; ── JS v4 ──────────────────────────────────────────────────────
    ; Thay đổi so với v3:
    ;   [1] Label matching: thêm tiếng Việt cho TẤT CẢ các trường
    ;       "địa chỉ" / "địa chỉ thuế" / "tình trạng" / "người đại diện" / "điện thoại"
    ;   [2] Address fallback: lấy occurrence THỨ 2 có "Tỉnh/Huyện..."
    ;       (occurrence đầu tiên là "Địa chỉ Thuế", thứ 2 là "Địa chỉ")
    ;   [3] Nếu chỉ có 1 occurrence (không có Địa chỉ Thuế riêng), lấy cái đó
    jsX := '(function(){var d={mst:"",name:"",intl_name:"",address:"",status:"",rep:"",phone:"",email:""};d.mst=location.pathname.replace(/^\//,"").split("-")[0];var h=document.querySelector("h1");if(h)d.name=h.innerText.replace(/^\d+\s*[-\u2013]\s*/,"").trim();var bs=document.querySelectorAll("b,strong");for(var b of bs){var t=b.innerText.trim();if(t.length>5&&t.length<200&&/^[A-Za-z0-9\s\-&.,()]+$/.test(t)&&t!==d.name){d.intl_name=t;break;}}document.querySelectorAll("tr").forEach(function(tr){var cells=[...tr.children].filter(function(c){return c.tagName==="TD"||c.tagName==="TH";});if(cells.length<2)return;var k=cells[0].innerText.toLowerCase().replace(/\s+/g," ").trim();var v=cells[cells.length-1].innerText.trim();var isAddr=(k.includes("\u0111\u1ecba ch\u1ec9")||k.includes("address"))&&!k.includes("thu\u1ebf")&&!k.includes("tax");if(isAddr&&!d.address)d.address=v;if((k.includes("t\u00ecnh tr\u1ea1ng")||k.includes("status"))&&!d.status)d.status=v;if((k.includes("ng\u01b0\u1eddi \u0111\u1ea1i di\u1ec7n")||k.includes("representative"))&&!d.rep)d.rep=v;if((k.includes("\u0111i\u1ec7n tho\u1ea1i")||k.includes("phone")||k.includes("telephone"))&&!d.phone)d.phone=v;if(k.includes("email")&&!d.email)d.email=v;});if(!d.address){var cnt=0,found="",tds=document.querySelectorAll("td");for(var i=0;i<tds.length;i++){var txt=tds[i].innerText.trim();if(txt.length>15&&(txt.includes("T\u1ec9nh")||txt.includes("Huy\u1ec7n")||txt.includes("Qu\u1eadn")||txt.includes("Ph\u01b0\u1eddng")||txt.includes("Province")||txt.includes("District")||txt.includes("Commune"))){cnt++;if(cnt===1)found=txt;if(cnt===2){d.address=txt;break;}}}if(!d.address&&cnt===1)d.address=found;}copy(JSON.stringify(d));})();'

    if WinExist("ahk_class Chrome_WidgetWin_1")
        WinActivate("ahk_class Chrome_WidgetWin_1")

    successCount := 0

    for idx, url in urls
    {
        Send("^l")
        Sleep(500)
        SendInput(url)
        Sleep(400)
        Send("{Enter}")
        Sleep(7000)

        Send("^+j")
        Sleep(2000)

        A_Clipboard := jsX
        Sleep(400)
        Send("^a")
        Sleep(150)
        Send("^v")
        Sleep(300)
        A_Clipboard := ""
        Sleep(100)
        Send("{Enter}")

        if !ClipWait(8)
        {
            Send("{F12}")
            Sleep(500)
            continue
        }

        jsonLine := A_Clipboard
        Send("{F12}")
        Sleep(500)

        if InStr(jsonLine, '"mst"')
        {
            FileAppend(jsonLine . "`n", "E:\company_data.jsonl", "UTF-8")
            successCount++
        }

        Sleep(500)
    }

    MsgBox("HOÀN THÀNH! " successCount "/" total " công ty.`nBây giờ chạy: python jsonl_to_xlsx.py")
}


Esc::ExitApp
