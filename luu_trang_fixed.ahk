#Requires AutoHotkey v2.0

; Nhấn tổ hợp phím Ctrl + Shift + S để BẮT ĐẦU chạy tự động
^+s::
{
    ; --- SỬA LỖI #1: tự tạo thư mục lưu nếu chưa tồn tại ---
    try
    {
        if !DirExist("E:\data_html")
            DirCreate("E:\data_html")
    }
    catch as err
    {
        MsgBox("❌ Không thể tạo thư mục E:\data_html.`nKiểm tra xem ổ E: có tồn tại / có thể ghi được không.`nLỗi: " err.Message)
        return
    }

    MsgBox("Robot AHK bắt đầu chạy. Vui lòng KHÔNG động vào chuột và bàn phím cho đến khi hoàn thành!")

    successCount := 0
    failedPages := ""

    Loop 11 ; Chạy lặp lại đúng 11 trang
    {
        ; 1. Ép Windows tập trung vào cửa sổ Chrome đang mở
        if WinExist("ahk_class Chrome_WidgetWin_1")
        {
            WinActivate("ahk_class Chrome_WidgetWin_1")
            WinMaximize("ahk_class Chrome_WidgetWin_1")
        }
        Sleep(1000)

        ; 2. Bấm Ctrl + S để mở hộp thoại lưu trang web của Chrome
        Send("^s")

        ; --- SỬA LỖI #2: chờ hộp thoại Save As THỰC SỰ xuất hiện ---
        ; "#32770" là class chuẩn của hộp thoại Windows, không phụ thuộc ngôn ngữ tiêu đề
        if !WinWaitActive("ahk_class #32770", , 5)
        {
            failedPages .= A_Index " (không thấy hộp thoại Save As) `n"
            ; Nhỡ có hộp thoại bị kẹt, thử Esc để dọn dẹp trước khi qua trang sau
            Send("{Esc}")
            Sleep(500)
            continue
        }

        ; 3. Nhập đường dẫn ổ E và tên file
        filePath := "E:\data_html\trang_" A_Index ".html"
        SendInput("^a") ; chọn hết nội dung ô filename cũ trước khi gõ đè, tránh bị nối chuỗi lung tung
        Sleep(200)
        SendInput(filePath)
        Sleep(500)

        ; 4. Ấn Enter để xác nhận lưu file
        Send("{Enter}")

        ; --- SỬA LỖI #3: chờ hộp thoại ĐÓNG LẠI = lưu xong, thay vì Sleep cố định ---
        if !WinWaitClose("ahk_class #32770", , 6)
        {
            failedPages .= A_Index " (hộp thoại không đóng sau khi Enter, có thể bị lỗi đường dẫn) `n"
        }
        Sleep(800) ; chờ Chrome ghi file ra đĩa xong

        ; --- SỬA LỖI #4: kiểm tra file có thật sự được tạo ra không ---
        if FileExist(filePath)
            successCount++
        else
            failedPages .= A_Index " (không tìm thấy file sau khi lưu) `n"

        ; 5. Nếu chưa phải trang cuối cùng, chuyển trang
        if (A_Index < 11)
        {
            NextPageNum := A_Index + 1
            Send("^l") ; Bấm Ctrl + L để nhảy lên thanh địa chỉ
            Sleep(600)

            SendInput("https://masothue.com/tra-cuu-ma-so-thue-theo-nganh-nghe/san-xuat-vat-lieu-xay-dung-tu-dat-set-2392?page=" NextPageNum)
            Sleep(600)
            Send("{Enter}")

            Sleep(6000) ; Chờ trang web mới tải xong hoàn toàn
        }
    }

    resultMsg := "🎉 HOÀN THÀNH! Đã lưu thành công " successCount " / 11 trang vào E:\data_html"
    if (failedPages != "")
        resultMsg .= "`n`n⚠️ Các trang gặp vấn đề:`n" failedPages
    MsgBox(resultMsg)
    return
}

; Nếu muốn DỪNG KHẨN CẤP khi robot đang chạy lỗi, hãy nhấn phím Esc trên bàn phím
Esc::ExitApp
