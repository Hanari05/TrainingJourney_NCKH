# Luồng hiệu chuẩn camera — 01/11/2026

## Luồng mới

Kết nối BE + ảnh camera mới + tracking mới/hợp lệ → bắt đầu phiên hiệu chuẩn có ID riêng → tích lũy đủ 5 giây mẫu đúng tư thế → kiểm tra chất lượng/kết quả đúng phiên → lưu cục bộ → đồng bộ hồ sơ → chọn map.

- BE sử dụng `time.monotonic()` cho thời lượng. Không cộng thời gian mất nhận diện, tư thế sai, khoảng ngắt callback trên 250ms hoặc kết quả callback trùng timestamp.
- Dùng `form_valid` hiện có của T-pose, không thay công thức nhận diện/góc của 5 map. Lấy đủ 5 giây mẫu hợp lệ và tối thiểu 20 mẫu. Giới hạn chờ 20 giây với cấu hình mặc định; thiếu mẫu trả thất bại và giữ giá trị hiệu chuẩn trước đó. Đây là tiêu chí kỹ thuật của game, chưa phải ngưỡng được xác nhận lâm sàng.
- Main đọc snapshot kết quả MediaPipe cùng timestamp, bỏ kết quả cũ hơn 250ms; không làm mới thời gian của một kết quả cũ bằng thời gian vòng lặp.
- Progress bổ sung `valid_elapsed_ms`, `wall_elapsed_ms`, `form_valid`, `timeout_ms`; completion bổ sung `measurement_kind=normalized_t_pose`, `valid_sample_count`, `valid_elapsed_ms`, `sample_quality`. `sample_quality` là tỷ lệ thời gian lấy mẫu, không phải xác suất chính xác nhận diện.
- Provider bắt buộc đúng `session_id` cho calibration và truyền ID vào payload signal. UI từ chối kết quả ngoài phiên đang đo, sai hồ sơ, thiếu chất lượng, camera/tracking cũ hoặc mất kết nối. Watchdog UI dừng khi camera quá 3 giây không có ảnh hoặc phiên quá 25 giây không kết thúc.
- Nút tiếp tục chỉ bật khi có kết quả hợp lệ, lưu cục bộ thành công và camera/tracking còn sẵn sàng. Kết quả giả lập không ghi vào lịch sử hiệu chuẩn.

## Hiển thị

Khung hướng dẫn dùng VBoxContainer; các cột chuyển thành một cột dưới 900px và cuộn dọc. Ảnh camera giữ tỷ lệ. Chỉ số ghi rõ “chuẩn hóa /90”, không gọi là góc khớp đo thô. Các nhãn kỹ thuật không trình bày giá trị confidence cố định của BE như một phép đo xác suất.

## Kiểm thử và vận hành

- 6 kiểm thử Python: mẫu sai, mất tracking, đủ 5 giây hợp lệ, timestamp lặp, callback ngắt quãng, NaN.
- Godot regression: nút khóa/mở, sai phiên, thiếu chất lượng, lưu đúng kết quả, mất kết nối, chặn envelope đến muộn.
- Ảnh bố cục và kiểm tra không giao nhau ở 1152×760, 800×600.
- Không bật camera/Atlas thật trong kiểm thử. Cần khởi động lại cả backend Python và game; FE mới từ chối completion của BE cũ thiếu dữ liệu chất lượng.
- T-pose vẫn dùng tiêu chí tư thế BE có sẵn. Nếu người tập không đáp ứng tiêu chí này, cần BE/chuyên môn xác định chế độ hiệu chuẩn phù hợp; không tự giảm ngưỡng để vượt kiểm tra.
