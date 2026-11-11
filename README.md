# Hành trình vận động — TrainingJourney NCKH

Game Godot 2D kết hợp backend Python nhận diện cử động cánh tay qua camera.

Đề tài: Nghiên cứu phát triển ứng dụng game Pixel 2D tích hợp trí tuệ nhân tạo nhận diện cử động cánh tay hỗ trợ tập luyện phục hồi chức năng.

Thực hiện: Nông Thị Hồng Lan (chủ trì), Nguyễn Ngọc Gia Hân.

## Chạy dự án

- Mở `project.godot` bằng Godot (bản kiểm thử: 4.7.2).
- Dùng Python 3.12 và các thư viện trong `requirements-local-py312.txt`.
- Nếu đã có môi trường cục bộ: chạy `.venv\Scripts\python.exe main.py` từ thư mục gốc. Nếu chưa có, tạo venv rồi cài bằng `python -m pip install -r requirements-local-py312.txt`.
- Giữ `pose_landmarker_full.task` ở thư mục gốc. Backend camera sử dụng WebSocket `127.0.0.1:8765`; MongoDB bridge dùng HTTP `127.0.0.1:8766`.
- Cấu hình DB và dữ liệu người tập là dữ liệu riêng của máy, không đưa lên Git. Chưa có DB không đồng nghĩa mất dữ liệu đã lưu cục bộ.

## Cấu trúc

| Thư mục/file | Vai trò |
|---|---|
| `main.py`, `exercises_logic.py`, `hand_service.py` | Camera, đánh giá động tác và con trỏ bàn tay |
| `mongodb_service.py`, `report_store.py` | API MongoDB và hợp nhất hồ sơ |
| `core/` | Quản lý phiên tập, kết nối BE, lưu tiến độ, âm thanh |
| `maps/` | 5 màn chơi, controller và cảnh trang trí |
| `ui/` | Menu, hiệu chuẩn, báo cáo/lịch sử, hướng dẫn |
| `assets/` | Hình ảnh, âm thanh, font, shader và tài liệu nguồn/giấy phép |
| `tests/` | Kiểm thử hồi quy; không chứa ảnh và dữ liệu sinh ra từ các lượt thử cũ |
| `tools/` | Công cụ tạo assets/âm thanh và đóng gói |
| `docs/integration/` | Hợp đồng lịch sử, hiệu chuẩn và nhịp chuyển động cảnh |
| `docs/licenses/` | Giấy phép nguồn được lưu kèm dự án |

## Phạm vi hiện tại

5 map × 3 mức, camera/hiệu chuẩn, hướng dẫn, tạm dừng khi mất nhận diện, con trỏ bàn tay, lưu lịch sử và đồng bộ MongoDB đã có mã tích hợp. Giữ phân biệt chỉ số hiệu chuẩn và ROM buổi tập; không tự diễn giải chỉ số trong game thành góc khớp thực đo. Luồng CSV/ROM thực tế cần payload và chức năng BE tương ứng; không dùng dữ liệu giả thay thế.

Các lượt kiểm thử tự động gần nhất dùng chế độ không lưu. Camera và Cloud thật cần kiểm tra trên máy có thiết bị/cấu hình phù hợp.

## Kiểm thử và đóng gói

- Python: `python -B -m unittest discover -s tests -p "test_*.py" -v`.
- Godot: `Godot_console.exe --headless --path . res://tests/core/selective_be_merge.tscn -- --no-save`.
- Script đóng gói nằm trong `tools/packaging/`.
- `.godot/` và `__pycache__/` tự sinh lại; `.venv/` là môi trường cục bộ, không đưa vào gói mã nguồn.
- Giữ các file `.gd.uid`, cấu hình `.import` cần thiết và giấy phép assets. Không đổi đường dẫn assets/cảnh tùy ý vì có tham chiếu `res://` và đường dẫn được ghép trong code.
