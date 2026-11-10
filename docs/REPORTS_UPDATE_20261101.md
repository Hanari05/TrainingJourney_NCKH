# Báo cáo và lịch sử tập — 01/11/2026

## Dữ liệu và đồng bộ MongoDB

- Chỉ hiển thị session có `patient_id` khớp hồ sơ; bản ghi cũ thiếu ID được giữ trên máy, không tự gán cho người bệnh.
- Yêu cầu đồng bộ MongoDB đi qua hàng đợi `cloud_outbox` lưu cùng tiến độ. GET → hợp nhất → POST tuần tự; không hủy yêu cầu đang chạy. Lỗi giữ hàng đợi, thử lại khi bấm Đồng bộ hoặc mở lại game. Chưa có bộ hẹn giờ tự retry.
- Backend hợp nhất session theo ID, ROM theo ngày/nguồn, tiến độ mở khóa theo giá trị lớn hơn. Không dùng snapshot cũ để thay toàn bộ lịch sử.
- Reset có xác nhận, chỉ tác động hồ sơ được chọn, dùng `/api/patients/<id>/reset`, `expected_generation` và `reset_token`. Token giúp retry không xóa lần hai. `generation` ngăn client cũ ghi lại dữ liệu đã reset.
- Nếu reset gặp HTTP 409 do hồ sơ đã reset ở thiết bị khác, giữ yêu cầu và báo lỗi; cần đối chiếu hồ sơ với BE trước khi xử lý. Không tự xóa dữ liệu để vượt xung đột.
- Cập nhật cả game và `mongodb_service.py` + `report_store.py`, rồi khởi động lại backend. Các provider Supabase/Firebase là luồng cũ, không nằm trong bộ kiểm thử MongoDB lần này.

## Hợp đồng session mới

`patient_id`, `patient_name` chốt tại lúc bắt đầu. Có `status` (`completed`, `stopped_early`, `interrupted`), `ended_at_utc`, và `completed_at_utc` chỉ khi hoàn thành.

`active_seconds`, `rest_seconds`, `paused_seconds`, `tracking_lost_seconds` là thời gian do game đo; thời gian active gồm lúc chờ vùng thực hiện động tác trong trạng thái tập. `completed_reps`, `target_reps`, `completed_sets`, `target_sets` lấy từ cấu hình và tiến độ session.

`calibration_rom_angle` là ảnh chụp giá trị hiệu chuẩn khi bắt đầu, `rom_source=calibration_snapshot`; không phải phép đo ROM mới trong buổi. Không tạo thêm điểm ROM theo ngày từ session. Chỉ `source=calibration` đi lên biểu đồ. Bản ghi cũ vẫn được giữ, không bịa thêm thời lượng/mục tiêu hoặc nguồn đo.

Thoát cảnh có kiểm soát ghi dừng sớm. Đóng cưỡng bức/crash chưa có checkpoint để phục hồi buổi đang diễn ra. Thời gian, trạng thái mới chỉ áp dụng buổi tập tạo sau bản sửa.

## Báo cáo và UI

- Không có lượt tập: tỷ lệ hợp lệ là “Chưa có dữ liệu”. Phân biệt số buổi ghi nhận/hoàn thành.
- Mức hoàn thành tính từ các cặp map/mức đã hoàn thành; không tính mức mở sẵn. Mở khóa hiển thị riêng.
- So sánh ROM mô tả Tăng/Giảm/Ít thay đổi; không đánh giá phục hồi y khoa. Tổng kết toàn bộ lịch sử, biểu đồ ghi rõ 10 ngày có phép đo gần nhất, trục thời gian dùng khoảng cách ngày thực tế, trục góc tự mở rộng. Mốc 90° chỉ là tham chiếu game.
- Header cố định, nội dung cuộn chung, chữ nội dung từ 18px, thẻ tổng kết chuyển một cột khi hẹp. Giao diện Người tập/Quản lý là tùy chọn trình bày, không phải đăng nhập/phân quyền.

## Kiểm tra không dùng dữ liệu thật

- Python: `python -m unittest discover -s tests -p test_report_store.py -v` (fake database, không kết nối MongoDB).
- Godot: `godot --headless --path . res://tests/core/report_regression.tscn -- --no-save`.
- `--no-save` không khởi chạy backend nhúng hoặc mở WebSocket. Kiểm tra regression dùng fake HTTP.
- Test bố cục `tests/core/report_visual.tscn -- --no-save` chụp dữ liệu giả ở 1152×760 và 800×600. Không kiểm thử camera hay MongoDB Atlas thật trong đợt này.
