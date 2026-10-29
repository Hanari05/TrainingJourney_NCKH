# Hành trình vận động — Game Pixel 2D hỗ trợ tập luyện PHCN

Đề tài: Nghiên cứu phát triển ứng dụng game Pixel 2D tích hợp trí tuệ nhân tạo nhận diện cử động cánh tay hỗ trợ tập luyện phục hồi chức năng.

Thực hiện: Nông Thị Hồng Lan (chủ trì), Nguyễn Ngọc Gia Hân.

Cập nhật: **16/10/2026**. Trạng thái: **prototype frontend chơi thử được trên cả 5 map bằng dữ liệu giả lập**. Chưa phải bản tích hợp BE hoàn chỉnh hay sản phẩm đã được thẩm định chuyên môn.

## Chạy dự án

1. Dùng Godot **4.7.2** (phiên bản đã dùng để kiểm thử).
2. Import `project.godot`, đợi Godot tạo cache/import assets rồi nhấn F6 cho scene hoặc F5 để chạy từ menu.
3. Đi qua luồng Bắt đầu → hiệu chỉnh giả lập → chọn map → chọn mức độ → hướng dẫn → tập luyện.
4. Project đang autoload `PoseInput` từ `core/pose/mock_pose_provider.gd`, không kết nối camera/backend thật.

Khi giải nén, nên dùng đường dẫn ngắn như `D:/GamePHCN/` để tránh lỗi đường dẫn Windows quá dài. Giữ các file `.uid` và `.import` đi kèm nguồn; không cần bàn giao cache `.godot/`.

## Mức độ hoàn thiện

| Phần | Hiện trạng |
| --- | --- |
| Luồng màn hình | Menu, hiệu chỉnh giả lập, chọn đủ 5 map theo bố cục 3+2, chọn mức độ, gameplay, Settings, lịch sử buổi tập |
| Menu và xem trước | Demo nền luân phiên 5 map, mỗi map 10 giây; thẻ map tĩnh và chuyển động khi rê chuột; nền chọn mức độ mờ theo map |
| Nhân vật | MK2 mặc trang phục trong game; tư thế/hành động riêng theo map; nhân vật hướng dẫn không trang phục để thấy khớp |
| Hướng dẫn | Góc trực diện và góc ngang dựng bổ sung, hiển thị khớp; xem lại bằng U; có thể bỏ qua 15 giây và đếm ngược 3 giây để chơi tiếp |
| Gameplay | Có tiến độ, hiệp/lần, giữ tư thế, nghỉ, kết quả; frontend nhận sự kiện qua lớp provider |
| UI | Theme vàng kem–viền gỗ, trạng thái nút; hộp xác nhận rời màn nổi trên Settings; nút Xem hướng dẫn rộng |
| Âm thanh | 6 nhạc nền placeholder và SFX đã tích hợp; âm lượng/mute dùng Master; nhạc dừng khi pause |
| Lưu trữ | Tiến độ/cài đặt/lịch sử cục bộ; test có chế độ không ghi dữ liệu người chơi |
| Camera và AI | Chưa tích hợp trong bản này; khung camera đang là placeholder |
| Ổn định/3 tim | Tạm vô hiệu hóa, chưa dùng làm tiêu chí đánh giá phiên tập |
| Chất lượng phát hành | Chưa nghiệm thu nhận diện thật, chưa kiểm thử đầy đủ phần cứng/đóng gói, chưa thẩm định động tác chuyên môn |

Không dùng phần trăm hoàn thiện vì frontend chạy được không đồng nghĩa backend và quy trình tập luyện đã hoàn tất.

## Năm map hiện tại

| Map | Tên màn | Hành động minh họa trong game |
| --- | --- | --- |
| 1 | Phá cản mở đường | Chưởng hai tay, phá đá khi nhận lượt hợp lệ |
| 2 | Nâng đá | Tay từ sát thân nâng lên, giữ/nâng khối đá |
| 3 | Đẩy lùi tường | Đẩy hai tường; chu kỳ trái–phải → trên–dưới → hai khối xiên phía trên đối xứng rồi lặp |
| 4 | Leo vách đá cao | Co tay/chân và nhảy từng bậc, có đích cuối đường |
| 5 | Thiền định | Ngồi thiền, hơi nước và âm thanh nhẹ |

Hành động nhân vật trong gameplay mang tính minh họa, không thay thế động tác trong kịch bản hướng dẫn. Góc ngang MK2 là phần dựng bổ sung, không phải sprite góc ngang có sẵn của pack.

## Cấu trúc thư mục

- `assets/`: tài nguyên runtime đã chọn lọc; `audio_placeholder/` chứa WAV đang dùng.
- `core/autoload/`: trạng thái/cài đặt/lưu tiến độ.
- `core/pose/`: giao diện provider và bộ giả lập; điểm thay thế khi tích hợp BE.
- `core/exercise/`: máy trạng thái buổi tập, xử lý sự kiện.
- `core/audio/`: quản lý nhạc/UI SFX và âm thanh gameplay.
- `maps/map_1/ ... map_5/`: scene, controller, visuals từng map.
- `maps/shared/`: nhân vật và thành phần thế giới dùng chung.
- `ui/screens/`, `ui/shared/`: màn hình, Settings, hướng dẫn, presentation.
- `docs/design/`: kịch bản gốc.
- `docs/integration/`: tài liệu hợp đồng JSON.
- `docs/licenses/`: giấy phép nguồn; các giấy phép đi kèm assets cũng được giữ lại.
- `tests/core/`, `tests/maps/`: kiểm thử hồi quy, không phải dữ liệu thừa.
- `tools/audio/`: script tạo lại âm thanh placeholder bằng Python standard library.

Một số thư mục tên `placeholders` vẫn được scene/test tham chiếu: không xóa chỉ dựa trên tên.

## Điểm bàn giao backend

- Đọc [JSON Contract](docs/integration/JSON_Contract.docx) và [kịch bản](docs/design/gamescripts_DesignGameplay.docx).
- Xem `core/pose/pose_provider.gd` và `core/pose/mock_pose_provider.gd` để triển khai provider thật, sau đó thay autoload `PoseInput`.
- Giữ giao diện tín hiệu/sự kiện hiện hữu để `ExerciseSession` tiếp tục quản lý tiến độ, thời gian giữ, nghỉ và kết quả.
- Kiểm tra chu trình kết nối/ngắt kết nối, mất/khôi phục tracking, chống đếm trùng và dừng/tiếp tục khi mở UI.
- Gắn hình ảnh camera thật vào vùng bên phải HUD; bản hiện tại chỉ có khung chờ.
- Không bật lại cơ chế tim trước khi thống nhất tiêu chí cùng BE.

## Âm thanh

Xem `assets/audio_placeholder/README.txt`. Thay WAV bằng file thật cùng đường dẫn/tên để không phải sửa code; nếu đổi sang OGG phải cập nhật tham chiếu.

Nhạc/SFX hiện là âm thanh tổng hợp để test, chưa được nghiệm thu chất lượng nghe. Một số file dự phòng (ví dụ UI back/confirm) được giữ có chủ ý dù chưa được gọi riêng; không phải assets rác. Chưa có thanh âm lượng Music/SFX riêng.

## Kiểm thử

Ví dụ (thay `godot` bằng đường dẫn executable nếu chưa có trong PATH):

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . res://tests/core/resource_paths_smoke_test.tscn -- --no-save
godot --headless --path . res://tests/core/navigation_flow_test.tscn -- --no-save
godot --headless --path . res://tests/core/presentation_integration_test.tscn -- --no-save
godot --headless --path . res://tests/core/audio_integration_test.tscn -- --no-save
```

Các kiểm thử audio, chuyển màn và hướng dẫn đã báo PASS trong lần tích hợp gần nhất; vẫn có cảnh báo ObjectDB/AudioStreamPlayback khi kết thúc một số bài test headless. Cần tiếp tục kiểm tra vòng đời audio trước khi phát hành. Test tự động không thay thế kiểm tra nghe, nhìn và tập thực tế.

Ảnh kiểm thử sinh ra ở `tests/visual_output/` được Git bỏ qua và có thể tạo lại. Dùng `--no-save` để không sửa hồ sơ người chơi thật.

## Công việc còn lại

1. Provider BE/AI, camera thật và kiểm thử end-to-end.
2. Xác nhận động tác, giới hạn vận động và nội dung hướng dẫn với người phụ trách chuyên môn.
3. Thay nhạc/SFX chính thức; cân âm lượng và xử lý cảnh báo giải phóng tài nguyên.
4. Hoàn thiện background/assets từng map theo bộ nguồn mới.
5. Kiểm thử nhiều độ phân giải, máy yếu, mất kết nối và bản export trước bàn giao cuối.

## Dọn thư mục ngày 16/10/2026

File cũ không dùng được **dời ra ngoài**, không xóa vĩnh viễn:
`D:/-NCKH-GamePixel2D_PHCN/HANDOFF_ARCHIVE_20261016_UI_AUDIO/`.
Có `manifest.csv` ghi đường dẫn nguồn/đích và SHA-256 để phục hồi.

Bộ nút cũ, script chuẩn bị art phụ thuộc nguồn ngoài và ảnh test cũ được lưu tại đó.
Không thay đổi lịch sử Git, không reset các chỉnh sửa có sẵn; cache editor và giấy phép được giữ.
README thay thế liên kết cũ tới HANDOFF_BE.txt không còn tồn tại.
