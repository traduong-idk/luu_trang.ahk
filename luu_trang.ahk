#Requires AutoHotkey v2.0

; Nhấn tổ hợp phím Ctrl + Shift + S để BẮT ĐẦU chạy tự động
^+s::
{
    MsgBox("Robot AHK bắt đầu chạy. Vui lòng KHÔNG động vào chuột và bàn phím cho đến khi hoàn thành!")

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
        Sleep(2500) ; Chờ hộp thoại Save As hiện lên

        ; 3. Nhập đường dẫn ổ E và tên file (ví dụ: E:\data_html\trang_1.html)
        SendInput("E:\data_html\trang_" A_Index ".html")
        Sleep(1000)
        
        ; 4. Ấn Enter để xác nhận lưu file
        Send("{Enter}")
        Sleep(4000) ; Chờ 4 giây cho Chrome tải xong file HTML xuống ổ E

        ; 5. Nếu chưa phải trang cuối cùng, thực hiện chuyển trang bằng cách gõ URL mới
        if (A_Index < 11)
        {
            NextPageNum := A_Index + 1
            Send("^l") ; Bấm Ctrl + L để nhảy lên thanh địa chỉ (Address bar)
            Sleep(600)
            
            ; Gõ trực tiếp URL trang tiếp theo
            SendInput("https://masothue.com/tra-cuu-ma-so-thue-theo-nganh-nghe/san-xuat-vat-lieu-xay-dung-tu-dat-set-2392?page=" NextPageNum)
            Sleep(600)
            Send("{Enter}") ; Ấn Enter để chuyển trang
            
            Sleep(6000) ; Chờ 6 giây cho trang web mới tải xong hoàn toàn
        }
    }

    MsgBox("🎉 HOÀN THÀNH! Đã tải xong 11 trang HTML vào thư mục E:\data_html")
    return
}

; Nếu muốn DỪNG KHẨN CẤP khi robot đang chạy lỗi, hãy nhấn phím Esc trên bàn phím
Esc::ExitApp