# PHÂN TÍCH ĐỀ TÀI QUẢN LÝ SIÊU THỊ

## 1. Tổng quan

Tên đề tài: Xây dựng cơ sở dữ liệu quản lý siêu thị  
Môn học: Hệ quản trị cơ sở dữ liệu  
Hệ quản trị: Microsoft SQL Server  
Ngôn ngữ: T-SQL

Hệ thống quản lý danh mục, sản phẩm, nhà cung cấp, nhân viên, khách hàng, nhập hàng, tồn kho, bán hàng, hóa đơn, thanh toán và báo cáo. Tài liệu này là nền tảng để viết tiểu luận; khi nộp bài cần bổ sung tên thành viên, ảnh ERD, ảnh kết quả chạy truy vấn và yêu cầu của giảng viên.

## 2. Lý do chọn đề tài

Siêu thị phát sinh nhiều dữ liệu mỗi ngày. Nếu quản lý thủ công, dữ liệu dễ trùng lặp, tồn kho dễ sai, việc tra cứu hóa đơn và doanh thu mất thời gian. Cơ sở dữ liệu giúp lưu trữ tập trung, chuẩn hóa thông tin, kiểm soát dữ liệu không hợp lệ và tự động hóa các nghiệp vụ chính.

Đề tài phù hợp để minh họa khóa chính, khóa ngoại, UNIQUE, CHECK, DEFAULT, view, function, stored procedure, transaction và trigger.

## 3. Mục tiêu

- Lưu trữ tập trung thông tin hoạt động của siêu thị.
- Quản lý tồn kho khi nhập và bán hàng.
- Lập hóa đơn và ghi nhận thanh toán.
- Tính tổng tiền và điểm tích lũy khách hàng.
- Bảo đảm dữ liệu hợp lệ bằng các ràng buộc.
- Cung cấp view cho tra cứu và báo cáo.
- Kiểm thử cả trường hợp hợp lệ và không hợp lệ.

## 4. Phạm vi hệ thống

### Chức năng trong phạm vi

1. Quản lý danh mục và sản phẩm.
2. Quản lý nhà cung cấp, nhân viên và khách hàng.
3. Lập phiếu nhập và chi tiết phiếu nhập.
4. Tự động tăng tồn kho khi nhập hàng.
5. Lập hóa đơn và chi tiết hóa đơn.
6. Kiểm tra tồn kho khi bán hàng.
7. Thanh toán và tích điểm khách hàng.
8. Hủy hóa đơn chưa thanh toán nhưng vẫn giữ lịch sử.
9. Báo cáo doanh thu, sản phẩm bán chạy và sản phẩm sắp hết.

### Chức năng chưa triển khai

- Đăng nhập và phân quyền.
- Nhiều chi nhánh.
- Chấm công và tính lương chi tiết.
- Khuyến mãi, mã giảm giá và thuế.
- Máy quét mã vạch.
- Tích hợp cổng thanh toán bên ngoài.

Đây là các hướng phát triển, không nên mô tả là chức năng đã hoàn thành.

## 5. Phân tích tác nhân

### Quản trị viên

Quản lý dữ liệu nền: danh mục, sản phẩm, nhà cung cấp, nhân viên và khách hàng; kiểm tra dữ liệu và xem báo cáo.

### Nhân viên kho

Lập phiếu nhập, chọn nhà cung cấp, thêm sản phẩm, số lượng và đơn giá. Khi chi tiết nhập được ghi nhận, tồn kho tăng tự động.

### Nhân viên bán hàng hoặc thu ngân

Tạo hóa đơn, chọn khách hàng, thêm sản phẩm, kiểm tra tồn kho, thanh toán và tra cứu hóa đơn.

### Quản lý

Theo dõi doanh thu, hàng bán chạy, hàng sắp hết và lịch sử nhập để hỗ trợ quyết định kinh doanh.

## 6. Các thực thể

| Thực thể | Ý nghĩa | Khóa chính |
|---|---|---|
| DANH_MUC | Nhóm sản phẩm | MaDM |
| SAN_PHAM | Sản phẩm và tồn kho | MaSP |
| NHA_CUNG_CAP | Đơn vị cung cấp | MaNCC |
| NHAN_VIEN | Người lập giao dịch | MaNV |
| KHACH_HANG | Người mua và điểm tích lũy | MaKH |
| PHIEU_NHAP | Thông tin chung lần nhập | MaPN |
| CT_PHIEU_NHAP | Sản phẩm trong phiếu nhập | MaPN, MaSP |
| HOA_DON | Thông tin chung giao dịch bán | MaHD |
| CT_HOA_DON | Sản phẩm trong hóa đơn | MaHD, MaSP |
| THANH_TOAN | Giao dịch thanh toán | MaTT |

## 7. Quan hệ dữ liệu

- Một danh mục có nhiều sản phẩm; một sản phẩm thuộc một danh mục.
- Một nhà cung cấp có thể xuất hiện trong nhiều phiếu nhập.
- Một nhân viên có thể lập nhiều phiếu nhập và hóa đơn.
- Một phiếu nhập có nhiều chi tiết nhập.
- Một hóa đơn có nhiều chi tiết bán.
- Một khách hàng có thể có nhiều hóa đơn.
- Khách vãng lai được biểu diễn bằng MaKH NULL.
- Một hóa đơn có tối đa một thanh toán nhờ UNIQUE(MaHD).

Hai bảng chi tiết dùng khóa chính ghép để ngăn một sản phẩm lặp lại trong cùng một giao dịch. Khi cần thêm số lượng, hệ thống cập nhật dòng hiện có.

## 8. Thiết kế và toàn vẹn dữ liệu

Khóa chính định danh duy nhất bản ghi. Khóa ngoại bảo đảm tham chiếu hợp lệ, ví dụ sản phẩm phải thuộc danh mục và chi tiết hóa đơn phải thuộc hóa đơn tồn tại.

Các ràng buộc chính:

- GiaBan, DonGiaNhap và DonGia phải lớn hơn 0.
- SoLuongTon không được âm.
- Số lượng nhập và bán phải lớn hơn 0.
- Lương nhân viên phải lớn hơn 0.
- Điểm tích lũy không được âm.
- Trạng thái hóa đơn chỉ gồm chưa thanh toán, đã thanh toán hoặc đã hủy.
- Phương thức thanh toán thuộc tập giá trị được quy định.

Thiết kế tách phần thông tin chung và phần chi tiết giao dịch, hạn chế lặp dữ liệu và phù hợp với mục tiêu chuẩn hóa đến 3NF trong phạm vi bài tập.

## 9. Nghiệp vụ nhập hàng

Quy trình:

~~~text
Chọn nhà cung cấp
  → Tạo phiếu nhập
  → Thêm sản phẩm, số lượng, đơn giá
  → Kiểm tra dữ liệu
  → Tăng tồn kho
  → Tính lại tổng tiền
~~~

Trigger trg_CTPN_CapNhatKho xử lý INSERT, UPDATE và DELETE. Trigger tổng hợp dữ liệu từ inserted và deleted, tính chênh lệch số lượng rồi cập nhật tồn kho. Vì vậy thao tác nhiều dòng trong một câu lệnh vẫn được xử lý đúng.

Ví dụ số lượng nhập tăng từ 10 lên 15 thì tồn kho chỉ tăng thêm 5, không cộng lại toàn bộ 15.

## 10. Nghiệp vụ bán hàng

Quy trình:

~~~text
Tạo hóa đơn
  → Chọn khách hàng
  → Thêm sản phẩm
  → Kiểm tra tồn kho
  → Trừ tồn kho
  → Tính tổng tiền
  → Thanh toán
  → Cập nhật trạng thái và điểm
~~~

Giá bán tại thời điểm thêm vào hóa đơn được lưu trong CT_HOA_DON.DonGia. Vì vậy hóa đơn cũ vẫn giữ đúng giá lịch sử khi giá sản phẩm thay đổi.

## 11. Hủy hóa đơn

Chỉ hóa đơn chưa thanh toán mới được hủy. sp_HuyHoaDon thực hiện trong transaction:

1. Kiểm tra hóa đơn tồn tại và còn mở.
2. Xóa chi tiết chưa thanh toán để trigger hoàn lại tồn kho.
3. Đổi trạng thái hóa đơn thành Đã hủy.
4. Commit khi mọi bước thành công.

Hóa đơn không bị xóa khỏi cơ sở dữ liệu. Trigger trg_KhongXoaHoaDon chặn thao tác xóa trực tiếp để bảo toàn lịch sử.

## 12. Các đối tượng T-SQL

### Function

- fn_KiemTraTonKho: trả về tồn kho hiện tại.
- fn_TinhThanhTien: tính số lượng nhân đơn giá.
- fn_TinhTongHoaDon: tính tổng tiền các chi tiết.
- fn_TinhDiemKhachHang: mỗi 10.000 đồng được 1 điểm.

### Stored procedure

- sp_ThemPhieuNhap: tạo phiếu và kiểm tra dữ liệu.
- sp_ThemChiTietPhieuNhap: thêm chi tiết nhập trong transaction.
- sp_TaoHoaDon: tạo hóa đơn.
- sp_ThemChiTietHoaDon: thêm sản phẩm và kiểm tra tồn kho.
- sp_ThanhToanHoaDon: ghi thanh toán, đổi trạng thái và tích điểm.
- sp_HuyHoaDon: hủy hóa đơn chưa thanh toán và hoàn kho.

### View

- vw_LichSuNhapHang.
- vw_ChiTietHoaDon.
- vw_DoanhThuTheoNgay.
- vw_SanPhamBanChay.
- vw_SanPhamSapHet.

## 13. Transaction và xử lý lỗi

Các nghiệp vụ cập nhật nhiều bảng dùng transaction. Nếu một bước thất bại, rollback giúp tránh tình trạng đã trừ kho nhưng chưa ghi giao dịch hoặc đã ghi thanh toán nhưng chưa đổi trạng thái.

Các procedure dùng TRY...CATCH, XACT_ABORT ON và THROW để trả lỗi cho chương trình gọi.

## 14. Kiểm thử

### Kiểm thử hợp lệ

- Tạo phiếu nhập với dữ liệu tồn tại.
- Thêm nhiều sản phẩm vào một phiếu nhập.
- Cập nhật số lượng nhập và kiểm tra tồn kho.
- Tạo hóa đơn và bán trong giới hạn tồn.
- Thanh toán bằng phương thức hợp lệ.
- Kiểm tra tổng tiền, điểm và doanh thu.
- Hủy hóa đơn chưa thanh toán và kiểm tra hoàn kho.

### Kiểm thử không hợp lệ

- Trùng mã phiếu hoặc mã hóa đơn.
- Nhà cung cấp, nhân viên hoặc sản phẩm không tồn tại.
- Số lượng hoặc đơn giá không hợp lệ.
- Bán vượt tồn kho.
- Thanh toán hóa đơn rỗng hoặc thanh toán hai lần.
- Hủy hóa đơn đã thanh toán.
- Xóa hóa đơn trực tiếp.
- INSERT nhiều dòng để kiểm tra trigger.

File chạy kiểm thử là tests/07_Tests.sql.

## 15. Cách triển khai

Chạy lần lượt:

~~~text
database/01_CreateDatabase.sql
database/02_CreateTables.sql
database/03_SeedData.sql
database/04_Inventory.sql
database/05_Sales.sql
database/06_Reports.sql
tests/07_Tests.sql
~~~

Không chạy lại 02_CreateTables.sql trên database có dữ liệu cần giữ vì file này tạo lại bảng và xóa dữ liệu cũ.

## 16. Ưu điểm

- Mô hình tách rõ dữ liệu nền, giao dịch và chi tiết.
- Có PK, FK, UNIQUE, CHECK và DEFAULT.
- Tồn kho được cập nhật tự động.
- Hóa đơn hủy vẫn giữ lịch sử.
- Có transaction và xử lý lỗi.
- Có nhiều view phục vụ báo cáo.
- Trigger hỗ trợ thao tác nhiều dòng.

## 17. Hạn chế và hướng phát triển

Hệ thống chưa có giao diện, tài khoản, phân quyền, khuyến mãi, thuế, lịch sử giá, mã vạch, hạn sử dụng và nhiều chi nhánh. Có thể phát triển thêm các bảng tài khoản, vai trò, khuyến mãi, lô hàng, lịch sử giá và xây dựng dashboard web.

## 18. Kết luận mẫu

Đề tài đã xây dựng được cơ sở dữ liệu quản lý các nghiệp vụ cơ bản của siêu thị. Mô hình quan hệ, khóa và ràng buộc giúp duy trì tính toàn vẹn dữ liệu. Procedure và trigger tự động hóa nhập hàng, bán hàng, thanh toán và hủy hóa đơn. Các view cung cấp thông tin tổng hợp phục vụ tra cứu và báo cáo. Đây là nền tảng có thể mở rộng thành hệ thống quản lý siêu thị hoàn chỉnh hơn.

