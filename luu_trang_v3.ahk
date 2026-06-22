#Requires AutoHotkey v2.0

; Nhấn Ctrl + Shift + S để BẮT ĐẦU
^+s::
{
    ; Tự tạo thư mục nếu chưa có
    try {
        if !DirExist("E:\data_html")
            DirCreate("E:\data_html")
    } catch as err {
        MsgBox("❌ Không thể tạo thư mục E:\data_html.`nKiểm tra ổ E: có tồn tại không.`nLỗi: " err.Message)
        return
    }

    MsgBox("Robot AHK bắt đầu chạy. Vui lòng KHÔNG động vào chuột và bàn phím!")

    successCount := 0
    failedPages := ""

    Loop 11
    {
        ; 1. Focus Chrome
        if WinExist("ahk_class Chrome_WidgetWin_1") {
            WinActivate("ahk_class Chrome_WidgetWin_1")
            WinMaximize("ahk_class Chrome_WidgetWin_1")
        }
        Sleep(1000)

        ; 2. Mở hộp thoại Save As
        Send("^s")

        ; 3. Chờ hộp thoại xuất hiện (tối đa 8 giây)
        if !WinWaitActive("ahk_class #32770", , 8) {
            failedPages .= A_Index " (không thấy hộp thoại Save As)`n"
            Send("{Esc}")
            Sleep(500)
            ; VẪN thực hiện chuyển trang dù save thất bại
            if (A_Index < 11) {
                NextPageNum := A_Index + 1
                Send("^l")
                Sleep(600)
                SendInput("https://masothue.com/tra-cuu-ma-so-thue-theo-nganh-nghe/san-xuat-vat-lieu-xay-dung-tu-dat-set-2392?page=" NextPageNum)
                Sleep(600)
                Send("{Enter}")
                Sleep(6000)
            }
            continue
        }

        ; 4. ĐẶT TÊN FILE TRỰC TIẾP vào ô filename — FIX LỖI CHÍNH
        ;    KHÔNG dùng Ctrl+A (sẽ chọn files trong browser, không phải text trong ô)
        ;    Dùng ControlSetText để nhét text thẳng vào ô Edit
        filePath := "E:\data_html\trang_" A_Index ".html"
        ControlSetText(filePath, "Edit1", "ahk_class #32770")
        Sleep(400)

        ; 5. Xác nhận lưu
        Send("{Enter}")

        ; 6. Chờ hộp thoại đóng (= lưu xong)
        if !WinWaitClose("ahk_class #32770", , 8) {
            ; Nếu hộp thoại vẫn còn mở — có thể có dialog con (Replace file?)
            ; Thử Enter một lần nữa để xác nhận ghi đè
            Send("{Enter}")
            WinWaitClose("ahk_class #32770", , 4)
        }
        Sleep(800)

        ; 7. Kiểm tra file có thật sự tồn tại không
        if FileExist(filePath) {
            successCount++
            print_msg := "[OK] Trang " A_Index " → " filePath
        } else {
            failedPages .= A_Index " (dialog đóng nhưng file không xuất hiện)`n"
        }

        ; 8. Chuyển sang trang tiếp theo (kể cả khi save thất bại, vẫn phải chuyển trang!)
        if (A_Index < 11) {
            NextPageNum := A_Index + 1
            Send("^l")
            Sleep(600)
            SendInput("https://masothue.com/tra-cuu-ma-so-thue-theo-nganh-nghe/san-xuat-vat-lieu-xay-dung-tu-dat-set-2392?page=" NextPageNum)
            Sleep(600)
            Send("{Enter}")
            Sleep(6000) ; Chờ trang mới tải xong
        }
    }

    resultMsg := "🎉 HOÀN THÀNH! Lưu thành công " successCount " / 11 trang vào E:\data_html"
    if (failedPages != "")
        resultMsg .= "`n`n⚠️ Các trang gặp vấn đề:`n" failedPages
    MsgBox(resultMsg)
    return
}

; Nhấn Esc để dừng khẩn cấp
Esc::ExitApp
