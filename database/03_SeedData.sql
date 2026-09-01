USE QuanLySieuThi;
GO

INSERT INTO DANH_MUC (MaDM, TenDM) VALUES
('DM01', N'Thực phẩm khô'),
('DM02', N'Hóa mỹ phẩm'),
('DM03', N'Đồ uống giải khát'),
('DM04', N'Sữa và sản phẩm từ sữa'),
('DM05', N'Thực phẩm tươi sống'),
('DM06', N'Đồ gia dụng'),
('DM07', N'Bánh kẹo'),
('DM08', N'Văn phòng phẩm');

INSERT INTO NHA_CUNG_CAP (MaNCC, TenNCC, DiaChi, DienThoai, Email) VALUES
('NCC01', N'Công ty Unilever Việt Nam', N'Quận 7, TP.HCM', '0281234567', 'info@unilever.com'),
('NCC02', N'Công ty CP Acecook Việt Nam', N'Quận Tân Phú, TP.HCM', '0287654321', 'contact@acecook.vn'),
('NCC03', N'Công ty Vinamilk', N'Quận 7, TP.HCM', '02854155555', 'contact@vinamilk.com.vn'),
('NCC04', N'Công ty TNHH PepsiCo Việt Nam', N'Khu công nghiệp Sóng Thần', '02743777777', 'support@pepsico.vn'),
('NCC05', N'Công ty Bibica', N'Quận Bình Thạnh, TP.HCM', '02835555555', 'info@bibica.com.vn'),
('NCC06', N'Công ty P&G Việt Nam', N'Quận 1, TP.HCM', '02838222222', 'contact@pg.com');

INSERT INTO NHAN_VIEN (MaNV, HoTen, ChucVu, DienThoai, Luong) VALUES
('NV01', N'Nguyễn Văn Hùng', N'Quản lý siêu thị', '0912345678', 15000000),
('NV02', N'Lê Thị Mai', N'Nhân viên bán hàng', '0987654321', 7000000),
('NV03', N'Trần Minh Tuấn', N'Nhân viên kho', '0901234567', 7500000),
('NV04', N'Phạm Ngọc Lan', N'Nhân viên thu ngân', '0902345678', 6800000),
('NV05', N'Võ Hoàng Nam', N'Nhân viên bán hàng', '0903456789', 7000000),
('NV06', N'Đặng Thùy Linh', N'Kế toán', '0904567890', 9000000);

INSERT INTO KHACH_HANG (MaKH, HoTen, DienThoai, DiemTichLuy) VALUES
('KH01', N'Phạm Minh Tuấn', '0909112233', 120),
('KH02', N'Hoàng Thu Thủy', '0933445566', 45),
('KH03', N'Nguyễn Thị Hồng', '0911223344', 80),
('KH04', N'Lê Quốc Bảo', '0922334455', 15),
('KH05', N'Trần Gia Hân', '0933556677', 230),
('KH06', N'Đỗ Minh Khang', '0944667788', 0),
('KH07', N'Bùi Thanh Hà', '0955778899', 65),
('KH08', N'Phan Anh Đức', '0966889900', 35);

INSERT INTO SAN_PHAM (MaSP, TenSP, DonViTinh, GiaBan, SoLuongTon, MaDM) VALUES
('SP01', N'Mì Hảo Hảo Tôm Chua Cay', N'Gói', 4500, 500, 'DM01'),
('SP02', N'Dầu gội Clear Bạc Hà 650g', N'Chai', 155000, 50, 'DM02'),
('SP03', N'Nước khoáng Aquafina 500ml', N'Chai', 6000, 200, 'DM03'),
('SP04', N'Sữa tươi Vinamilk không đường 1L', N'Hộp', 36000, 120, 'DM04'),
('SP05', N'Trứng gà hộp 10 quả', N'Hộp', 32000, 80, 'DM05'),
('SP06', N'Nước giặt Ariel 3.6kg', N'Túi', 185000, 40, 'DM02'),
('SP07', N'Coca-Cola lon 330ml', N'Lon', 9000, 300, 'DM03'),
('SP08', N'Bánh quy bơ Danisa 454g', N'Hộp', 145000, 35, 'DM07'),
('SP09', N'Khăn giấy ăn Pulppy 3 lớp', N'Gói', 28000, 100, 'DM06'),
('SP10', N'Nồi inox 24cm', N'Cái', 250000, 20, 'DM06'),
('SP11', N'Bút bi Thiên Long TL-027', N'Cây', 5000, 250, 'DM08'),
('SP12', N'Vở học sinh 200 trang', N'Quyển', 18000, 150, 'DM08'),
('SP13', N'Kẹo dẻo trái cây 80g', N'Gói', 22000, 90, 'DM07'),
('SP14', N'Gạo Jasmine túi 5kg', N'Túi', 125000, 60, 'DM01'),
('SP15', N'Dầu ăn Neptune 1L', N'Chai', 42000, 70, 'DM01'),
('SP16', N'Mì Omachi sườn hầm ngũ quả', N'Gói', 8500, 140, 'DM01'),
('SP17', N'Nước tương Chinsu 500ml', N'Chai', 18000, 95, 'DM01'),
('SP18', N'Nước mắm Nam Ngư 750ml', N'Chai', 32000, 85, 'DM01'),
('SP19', N'Đường trắng Biên Hòa 1kg', N'Túi', 24000, 100, 'DM01'),
('SP20', N'Bột giặt OMO 3kg', N'Túi', 128000, 45, 'DM02'),
('SP21', N'Dầu xả Dove 640g', N'Chai', 132000, 35, 'DM02'),
('SP22', N'Sữa rửa mặt Senka 100g', N'Tuýp', 99000, 30, 'DM02'),
('SP23', N'Kem đánh răng P/S 180g', N'Tuýp', 36000, 75, 'DM02'),
('SP24', N'Xà phòng Lifebuoy 4 bánh', N'Hộp', 42000, 65, 'DM02'),
('SP25', N'Trà xanh C2 455ml', N'Chai', 9000, 220, 'DM03'),
('SP26', N'Nước tăng lực Sting 330ml', N'Lon', 11000, 180, 'DM03'),
('SP27', N'Pepsi lon 330ml', N'Lon', 9000, 250, 'DM03'),
('SP28', N'Nước ép cam Twister 1L', N'Hộp', 28000, 70, 'DM03'),
('SP29', N'Sữa chua Vinamilk có đường', N'Lốc', 32000, 90, 'DM04'),
('SP30', N'Sữa đặc Ông Thọ 380g', N'Lon', 28000, 80, 'DM04'),
('SP31', N'Phô mai Con Bò Cười 120g', N'Hộp', 62000, 55, 'DM04'),
('SP32', N'Sữa đậu nành Fami 200ml', N'Lốc', 36000, 100, 'DM04'),
('SP33', N'Xúc xích CP 200g', N'Gói', 45000, 65, 'DM05'),
('SP34', N'Gà rán tẩm ướp đông lạnh', N'Gói', 89000, 25, 'DM05'),
('SP35', N'Cá viên chiên đông lạnh 500g', N'Gói', 58000, 40, 'DM05'),
('SP36', N'Rau củ hỗn hợp đông lạnh 500g', N'Túi', 52000, 35, 'DM05'),
('SP37', N'Nước lau sàn Sunlight 1L', N'Chai', 55000, 45, 'DM06'),
('SP38', N'Nước rửa chén Sunlight 750ml', N'Chai', 38000, 80, 'DM06'),
('SP39', N'Bọc thực phẩm 30cm', N'Cuộn', 29000, 60, 'DM06'),
('SP40', N'Chảo chống dính 26cm', N'Cái', 185000, 18, 'DM06'),
('SP41', N'Bánh snack khoai tây 60g', N'Gói', 12000, 130, 'DM07'),
('SP42', N'Bánh Oreo socola 133g', N'Gói', 22000, 110, 'DM07'),
('SP43', N'Kẹo bạc hà Alpenliebe 90g', N'Gói', 26000, 85, 'DM07'),
('SP44', N'Bánh mì sandwich 450g', N'Gói', 30000, 50, 'DM07'),
('SP45', N'Bút chì 2B Thiên Long', N'Cây', 4000, 200, 'DM08'),
('SP46', N'Bút gel xanh Thiên Long', N'Cây', 7000, 180, 'DM08'),
('SP47', N'Giấy A4 Double A 70gsm', N'Ream', 78000, 40, 'DM08'),
('SP48', N'Tập giấy note màu 3x3', N'Xấp', 15000, 90, 'DM08'),
('SP49', N'Thùng carton nhỏ', N'Cái', 12000, 100, 'DM06'),
('SP50', N'Bình nước nhựa 1L', N'Cái', 65000, 30, 'DM06');
GO