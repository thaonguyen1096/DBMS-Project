/* Giá trị Delay: 
	0: không delay
	1: delay / UR
	2: PhanTom
	3: Lost update
	4: Dirty read */


-- SỬA THÔNG TIN CÁ NHÂN
alter PROCEDURE SuaThongTinCaNhan 
	@MaNguoiDung char(5),
	@MatKhau varchar(20), 
	@HoTen nvarchar(31),
	@Email nvarchar(50),
	@SDT varchar(11),
	@DiaChi varchar(50),
	@kq int output
AS
BEGIN
	Begin tran
		begin try
		IF @MaNguoiDung NOT in (SELECT MaNguoiDung FROM Users  WHERE MaNguoiDung = @MaNguoiDung and MatKhau = @MatKhau and TinhTrang = '1')
		BEGIN
			RAISERROR (N'Người dùng không tồn tại', 16, 1)
			rollback tran
		    SET @kq = 0
			RETURN
		END
		if @kq != 0
			waitfor delay '00:00:05'
		Update Users set Email = @Email, SDT = @Sdt, DiaChi = @DiaChi where MaNguoiDung = @MaNguoiDung and TinhTrang = '1'
		IF (@@ROWCOUNT = 0)
			begin
				SET @kq = '0'
				RAISERROR(N'Người dùng không tồn tại!!!', 16, 1)
				rollback tran
				RETURN
			end
		end try
		begin catch
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
 
			SELECT @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
			rollback tran
			set @kq = 0
			return
		end catch
		set @kq = 1
	commit tran
end
go
--------------------------------
-- KHÓA TÀI KHOẢN
CREATE PROCEDURE KhoaTaiKhoan
	@MaNguoiDung char(5),
	@kq int out
AS
BEGIN
	BEGIN TRAN
		BEGIN TRY
		--Kiểm tra người dùng tồn tại:
		if exists (select * from Users where MaNguoiDung = @MaNguoiDung and TinhTrang = '1')
			Update Users set TinhTrang = '0' where MaNguoiDung = @MaNguoiDung and TinhTrang = '1'--Khóa tài khoản người dùng
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
			SET @kq = 0
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		SET @kq = 1;
	COMMIT TRAN
END

go-------------------------------
CREATE PROCEDURE DoiMatKhau @manguoidung varchar(5), @matkhaucu nvarchar(20), @matkhaumoi nvarchar(20), @kq int out
AS
BEGIN
	BEGIN TRANSACTION
		BEGIN TRY  
		IF NOT EXISTS (SELECT*FROM Users  WHERE MaNguoiDung = @manguoidung AND MatKhau = @matkhaucu AND TinhTrang='1')
			BEGIN
				SET @kq = '0'
				RAISERROR(N'Mật khẩu sai!!!', 16, 1)
				RETURN
			END
			WAITFOR DELAY '00:00:05'
			UPDATE Users SET MatKhau = @matkhaumoi WHERE MaNguoiDung = @manguoidung AND MatKhau = @matkhaucu AND TinhTrang='1'
			IF (@@ROWCOUNT = 0)
			begin
				SET @kq = '0'
				RAISERROR(N'Người dùng không tồn tại!!!', 16, 1)
				RETURN
			end
		END TRY  
	BEGIN CATCH 
		DECLARE @ErrorMessage NVARCHAR(4000)  
		DECLARE @ErrorSeverity INT  
		DECLARE @ErrorState INT  
		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE() 
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
		ROLLBACK TRANSACTION
		SET @kq = '0'
		RETURN
	END CATCH 
	SET @kq = '1'
	commit TRANSACTION  
END
go
--------------------------
-- HỦY ĐĂNG KÝ ĐỀ CÁ NHÂN
CREATE proc huyDangKyDeCaNhan
	@mssv char(5), 
	@made char(5), 
	@mamon char(6), 
	@kq int out
as
begin
	begin tran huyDangKyDeCaNhan
	begin try 
	if not exists(select*from DangKyDeCaNhan  where MSSV = @mssv and MaDe = @made and MaMH = @mamon and TrangThai= 1)
	begin
		set @kq = 0;
		raiserror(N'Sinh viên chưa đăng ký đề môn này', 16, 1);
		rollback tran huyDangKyDeCaNhan;  
		return;
	end
	Declare @sldk tinyint;
	set @sldk = (select SLDangKy from De_Mon where MaDe = @made and MaMH = @mamon)
	if @kq != 0
		waitfor delay '00:00:05'
	update DangKyDeCaNhan set TrangThai = 0 where MSSV = @mssv and MaDe = @made and MaMH = @mamon and TrangThai= 1
	if @@ROWCOUNT = 0
	begin
		raiserror (N'Đề môn không tồn tại!!!', 16,1)
		set @kq = 0
		rollback
		return
	end
	update De_Mon set SLDangKy = @sldk - 1 where MaDe = @maDe and MaMH = @mamon
	end try  
	begin catch 
		declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;  
		select   @ErrorMessage = ERROR_MESSAGE(),  @ErrorSeverity = ERROR_SEVERITY(),  @ErrorState = ERROR_STATE(); 
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState );  
		rollback tran huyDangKyDeCaNhan;
		set @kq = 0;
		return;
	end catch; 
	set @kq = 1;
	commit tran huyDangKyDeCaNhan;  
end
go
-----------------------------------------
-- HỦY ĐĂNG KÝ ĐỀ NHÓM
CREATE proc huyDangKyDeNhom (@manhom char(4), @made char(5), @mamon char(6), @kq int out)
as
begin
	begin tran huyDangKyDeNhom
	begin try 
	--set isolation repeatable read
		if not exists(select*from DangKyDeNhom  where MaNhom = @manhom and MaDe = @made and MaMH = @mamon and TrangThai= 1)
		begin
			set @kq = 0;
			raiserror(N'Sinh viên chưa đăng ký đề môn này', 16, 1);
			rollback tran huyDangKyDeCaNhan;  
			return;
		end
		Declare @sldk tinyint;
		set @sldk = (select SLDangKy from De_Mon where MaDe = @made and MaMH = @mamon)
		if @kq != 0
			waitfor delay '00:00:05'
		update DangKyDeNhom set TrangThai = 0 where MaNhom = @manhom and MaDe = @made and MaMH = @mamon and TrangThai= 1
		if @@ROWCOUNT = 0
		begin
			raiserror (N'Đề không tồn tại trong môn học này!!!', 16,1)
			set @kq = 0
			rollback
			return
		end
		update QuanLiNhom set TinhTrang = 0 where MaNhom = @manhom and MaDe = @made and MaMH = @mamon
		update De_Mon set SLDangKy = @sldk - 1 where MaDe = @maDe and MaMH = @mamon
	end try  
	begin catch 
		declare @ErrorMessage NVARCHAR(4000);  
		declare @ErrorSeverity INT;  
		declare @ErrorState INT;  
		select   @ErrorMessage = ERROR_MESSAGE(),  @ErrorSeverity = ERROR_SEVERITY(),  @ErrorState = ERROR_STATE(); 
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState );  
		rollback tran huyDangKyDeNhom;
		set @kq = 0;
		return;
	end catch; 
	set @kq = 1;
	commit tran huyDangKyDeNhom;  
end
go
--------------------------------------
-- XÓA ĐỀ CỦA MÔN
CREATE PROCEDURE XoaDeMon 
	@maMon char(6), 
	@maDe char(5), 
	@kq int out
AS
	BEGIN TRANSACTION XoaDeMon
		BEGIN TRY
			if @kq != 0
				waitfor delay '00:00:05'
			if 1 = (select LoaiDe from De_Mon WHERE MaMH = @maMon AND MaDe = @maDe and TinhTrang = 1)
				update DangKyDeCaNhan set TrangThai = 0 where MaMH = @maMon AND MaDe = @maDe
			else 
			BEGIN
			    update QuanLiNhom set TinhTrang = 0 where MaMH = @maMon AND MaDe = @maDe
				update DangKyDeNhom set TrangThai = 0 where MaMH = @maMon AND MaDe = @maDe
			END
			update PhuTrachDe set TinhTrang = 0 where MaMH = @maMon AND MaDe = @maDe
			UPDATE De_Mon SET TinhTrang = 0 WHERE MaMH = @maMon AND MaDe = @maDe
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			SET @kq = 0
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN XoaDeMon
			RETURN
	END CATCH
		SET @kq = 1
		COMMIT TRANSACTION XoaDeMon
go
----------------
-- SỬA THÔNG TIN ĐỀ MÔN
CREATE PROCEDURE SuaDeMon
	@maMon char(6), 
	@maDe char(5), 
	@slDKToiDa tinyint, 
	@slsvNhom tinyint, 
	@ngayBD datetime, 
	@deadline datetime,
	@kq int out 
AS
	BEGIN TRANSACTION
		begin try
			IF NOT EXISTS (SELECT * FROM De_Mon   WHERE MaDe = @maDe AND MaMH = @maMon AND TinhTrang = 1)
			BEGIN
				RAISERROR (N'Đề không tồn tại trong môn học này!!!', 16, 1)
				SET @kq = 0
				ROLLBACK TRANSACTION
				RETURN
			END
			
			if @slDKToiDa < (select SLDangKyToiDa from De_Mon where MaDe = @maDe and MaMH = @maMon)
				begin
					raiserror(N'Không thể chỉnh sửa số lượng sinh viên/nhóm vì đã có nhóm đăng kí có số lượng thành viên vượt quá số lượng này', 16, 1)
					rollback tran
					SET @kq = 0
					return
				end
			if @kq = 1
				waitfor delay '00:00:05'
			UPDATE De_Mon 
			SET SLDangKyToiDa = @slDKToiDa, SLSVNhom = @slsvNhom, Deadline = @deadline
			WHERE MaMH = @maMon AND MaDe = @maDe and TinhTrang = 1
			if @@ROWCOUNT = 0
			BEGIN
				raiserror (N'Đề không tồn tại trong môn học này!!!', 16,1)
				set @kq = 0
				rollback
				return
			END 
			if @kq = 4
				waitfor delay '00:00:05'
			if (@slsvNhom < 1 or @slDKToiDa < 1)  
			begin
				raiserror(N'Các thông tin về số lượng phải lớn hơn 0', 16, 1)
				rollback tran
				SET @kq = 0
				return
			end
			if (1 = (select LoaiDe from De_Mon where MaDe = @maDe and MaMH = @maMon) and @slsvNhom != 1)
			begin
			raiserror (N'Số lượng sinh viên/ nhóm đề cá nhân phải là 1', 16, 1)
			rollback
			return
		end
			if @slsvNhom < (select max(n.SLThanhVien) from DangKyDeNhom dk, Nhom n where MaDe = @maDe and MaMH = @maMon and n.MaNhom = dk.MaNhom and dk.TrangThai = 1)
			begin
				raiserror(N'Không thể chỉnh sửa số lượng sinh viên/nhóm vì đã có nhóm đăng kí có số lượng thành viên vượt quá số lượng này', 16, 1)
				rollback tran
				SET @kq = 0
				return
			end
			if @deadline <= (select NgayBDDangKy from De_Mon where MaDe = @maDe and MaMH = @maMon)
			begin
				raiserror(N'Deadline phải sau ngày bắt đấu đăng ký', 16, 1)
				rollback tran
				SET @kq = 0
				return
			end
		end try
		BEGIN CATCH
		DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int;
		SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

		SET @kq = 0
		RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
		ROLLBACK TRAN
		RETURN
	END CATCH
		SET @kq = 1
	COMMIT TRANSACTION
go
-----------------------------------------------
-- Phân công quản lý nhóm
CREATE PROCEDURE PhanCongQuanLy @nhom char(4), @maDe char(5), @maMon char(6), @kq int out
AS
	BEGIN TRANSACTION
		BEGIN TRY
			DECLARE @gv char(5)
			SET @gv = ( select Top 1 ptd.MaGV
						from PhuTrachDe ptd left join QuanLiNhom qln on ptd.MaDe = qln.MaDe and ptd.MaMH = qln.MaMH and ptd.MaGV = qln.MaGV
					    where ptd.MaDe = @maDe and ptd.MaMH = @maMon
						group by (ptd.MaGV)
						having  count(qln.MaNhom) <= all (select count(qln.MaNhom)
								from PhuTrachDe ptd left join QuanLiNhom qln on ptd.MaDe = qln.MaDe and ptd.MaMH = qln.MaMH and ptd.MaGV = qln.MaGV
								where ptd.MaDe = @maDe and ptd.MaMH = @maMon
								group by (ptd.MaGV)))
			INSERT INTO QuanLiNhom VALUES(@gv, @nhom, @maDe, @maMon, 1)
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			SET @kq = 0
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		SET @kq = 1
		COMMIT TRANSACTION
go
----------------------------------
-- ĐĂNG KÝ ĐỀ CÁ NHÂN
CREATE PROCEDURE usp_DangKyDeCaNhan @mssv char(5), @maDe char(5), @maMon char(6), @kq int out
AS
BEGIN TRANSACTION
	BEGIN TRY
			if not exists (select*from De_Mon  where MaDe = @MaDe and MaMH = @maMon and TinhTrang = 1)
			begin
				raiserror(N'Đề môn không tồn tại', 16 , 1)
				set @kq = 0
				rollback tran
				return
			end
			if not exists (select * from SinhVien_Mon where @mssv = MSSV and MaMH = @maMon and TinhTrang = 1)
			begin
				raiserror(N'Sinh viên môn nào thì chỉ được đăng ký đề môn đó', 16 , 1)
				set @kq = 0
				rollback tran
				return
			end
			declare @sldk tinyint, @sldkToiDa tinyint
			set @sldk = (select SLDangKy from De_Mon where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1)
			set @sldkToiDa = (select SLDangKyToiDa from De_Mon where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1)
			if (@kq = 1 or @kq = 3)
				waitfor delay '00:00:05'
			if (@sldk < @sldkToiDa)
			begin
				update De_Mon set SLDangKy = @sldk + 1 where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1
				if @@ROWCOUNT = 0
				begin
					raiserror(N'Đề môn không tồn tại', 16 , 1)
					set @kq = 0
					rollback tran
					return
				end
				if exists (select * from DangKyDeCaNhan where MaDe = @maDe AND MaMH = @maMon and MSSV = @mssv) -- trường hợp đăng ký lại
					update DangKyDeCaNhan set TrangThai = 1 where MaDe = @maDe AND MaMH = @maMon and MSSV = @mssv
				else
					INSERT INTO DangKyDeCaNhan VALUES(@maDe, @maMon, @mssv, 1)
				if @kq = 4
					waitfor delay '00:00:05'
				DECLARE @loaiDA char(2)
				SET @loaiDA = (SELECT LoaiDoAn FROM De_Mon WHERE MaDe = @maDe AND MaMH = @maMon AND TinhTrang = 1)
				IF @loaiDA IN (SELECT dm.LoaiDoAn FROM De_Mon dm, DangKyDeCaNhan dk WHERE dk.MaDe != @maDe and dm.MaMH = dk.MaMH AND dk.MSSV = @mssv AND dk.TrangThai = 1)
				BEGIN
					SET @kq = 0;
					RAISERROR (N'Một sinh viên chỉ được đăng ký một đề của một loại đồ án của môn', 16, 1);
					ROLLBACK TRAN  
					RETURN
				END
			end
			else 
			begin
				set @kq = 0;
				raiserror(N'Đề đã đủ số lượng đăng ký', 16, 1);
				rollback tran
				return;
			end
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int;
		SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

		SET @kq = 0
		RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
		ROLLBACK TRAN
		RETURN
	END CATCH
	SET @kq = 1
COMMIT TRANSACTION
go
------------------------------
-- ĐĂNG KÝ ĐỀ NHÓM
CREATE PROCEDURE usp_DangKyDeNhom @maNhom char(4), @maDe char(5), @maMon char(6), @kq int out
AS
BEGIN TRANSACTION
	BEGIN TRY
		begin
			if not exists (select*from De_Mon  where MaDe = @MaDe and MaMH = @maMon and TinhTrang = 1)
			begin
				raiserror(N'Đề môn không tôn tại', 16 , 1)
				set @kq = 0
				rollback tran
				return
			end
			if not exists (select * from Nhom where @maNhom = MaNhom and Mon = @maMon and TinhTrang = 1)
			begin
				raiserror(N'Nhóm môn nào thì chỉ được đăng ký đề môn đó', 16 , 1)
				set @kq = 0
				rollback tran
				return
			end
			declare @sldk tinyint, @sldkToiDa tinyint, @slsvNhom tinyint
			set @slsvNhom = (select SLSVNhom from De_Mon where MaDe = @maDe and MaMH = @maMon)
			if @slsvNhom < (select slThanhVien from Nhom where MaNhom = @maNhom)
			begin
				raiserror (N'Số lượng thành viên nhóm quá số lượng quy định của đề', 16, 1)
				set @kq = 0
				rollback
				return
			end
			set @sldkToiDa = (select SLDangKyToiDa from De_Mon where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1)
			set @sldk = (select SLDangKy from De_Mon where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1)
			if (@kq = 1 or @kq = 3)
				waitfor delay '00:00:05'
			if (@sldk < @sldkToiDa)
			begin
				update De_Mon set SLDangKy = @sldk + 1 where MaDe = @maDe AND MaMH = @maMon and TinhTrang = 1
				if @@ROWCOUNT = 0
				begin
					raiserror(N'Đề môn không tồn tại', 16 , 1)
					set @kq = 0
					rollback tran
					return
				end
				if exists (select * from DangKyDeNhom where MaDe = @maDe AND MaMH = @maMon and MaNhom = @maNhom) -- trường hợp đăng ký lại
					update DangKyDeNhom set TrangThai = 1 where MaDe = @maDe AND MaMH = @maMon and MaNhom = @maNhom
				else
					INSERT INTO DangKyDeNhom VALUES(@maDe, @maMon, @maNhom, 1)
				if @kq = 4
					waitfor delay '00:00:05'
				DECLARE @loaiDA char(2)
				SET @loaiDA = (SELECT LoaiDoAn FROM De_Mon WHERE MaDe = @maDe AND MaMH = @maMon AND TinhTrang = 1)
				IF @loaiDA IN (SELECT dm.LoaiDoAn FROM De_Mon dm, DangKyDeNhom dk WHERE dk.MaDe != @maDe and dm.MaDe = dk.MaDe AND dm.MaMH = dk.MaMH AND dk.MaNhom = @maNhom AND dk.TrangThai = 1)
					BEGIN
						SET @kq = 0;
						RAISERROR (N'Một nhóm chỉ được đăng ký một đề của một loại đồ án của môn', 16, 1);
						ROLLBACK TRAN  
						RETURN
					END
				declare @kqua int
				exec PhanCongQuanLy @maNhom, @maDe, @maMon, @kqua out
			end
			else 
			begin
				set @kq = 0;
				raiserror(N'Đề đã đủ số lượng đăng ký', 16, 1);
				rollback tran DangKyDe;  
				return;
			end
		end
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int;
		SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

		SET @kq = 0
		RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
		ROLLBACK TRAN
		RETURN
	END CATCH
	SET @kq = 1
COMMIT TRANSACTION
go
----------------------------------
CREATE PROCEDURE themMon @tenMon nvarchar(50), @kq int out
AS
BEGIN
	BEGIN TRAN
		BEGIN TRY
			declare @ma char(6), @tam int
			set @tam = (select count(*) from Mon )
			set @tam = @tam + 1;
			if (@tam < 10)
				set @ma = CONCAT('CTT00',@tam)
			else if (@tam < 100)
				set @ma = CONCAT('CTT0', @tam)
			else 
				set @ma = CONCAT('CTT',@tam)
		if @kq != 0
			waitfor delay '00:00:05'
		insert into Mon values (@ma, @tenMon, '1')
		END TRY
		BEGIN CATCH
			set @kq = 0;
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;
			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		set @kq = 1
	COMMIT TRAN
END
go
-------------------------------------
-- XEM VÀ ĐẾM DANH SÁCH NHÓM ĐƯỢC QUẢN LÍ BỞI GIÁO VIÊN THEO ĐỀ MÔN
alter PROC	DSQuanLyCuaGV 
	@maGV char(5),
	@maMon char(6),
	@maDe char(5),
	@kq int out
AS
BEGIN TRAN
	BEGIN TRY
		set tran isolation level serializable
		if not exists (select * from PhuTrachDe where MaGV = @maGV and MaDe = @maDe and MaMH = @maMon and TinhTrang = 1)
		begin
			raiserror (N'Giáo viên không phụ trách đề này',16, 1)
			rollback
			return
		end
		select MaNhom, TenNhom, TruongNhom, SLThanhVien from Nhom where MaNhom in (select MaNhom from QuanLiNhom where MaGV = @maGV and MaDe = @maDe and MaMH = @maMon and TinhTrang = 1)
		if @kq != 0
			waitfor delay '00:00:20'
		set @kq = (select count(MaNhom) from Nhom where MaNhom in (select MaNhom from QuanLiNhom where MaGV = @maGV and MaDe = @maDe and MaMH = @maMon and TinhTrang = 1))
	END TRY
	BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
COMMIT TRAN
go
-------------------------------------
-- XEM VÀ ĐẾM DANH SÁCH SINH VIÊN ĐƯỢC QUẢN LÍ BỞI GIÁO VIÊN THEO ĐỀ MÔN ( DANH SÁCH ĐĂNG KÝ ĐỀ CÁ NHÂN)
CREATE PROC	DSDKDeCaNhan 
	@MaGV char(5),
	@maMon char(6),
	@maDe char(5),
	@kq int out
AS
BEGIN TRAN
	BEGIN TRY
		set tran isolation level serializable
		if not exists (select * from PhuTrachDe where MaGV = @maGV and MaDe = @maDe and MaMH = @maMon and TinhTrang = 1)
		begin
			raiserror (N'Giáo viên không phụ trách đề này',16, 1)
			rollback
			return
		end
		select MaNguoiDung, HoTen from Users where MaNguoiDung in (select MSSV from DangKyDeCaNhan where MaDe = @maDe and @maMon = @maMon and TinhTrang = 1)
		if @kq != 0
			waitfor delay '00:00:05'
		set @kq = (select count(MSSV) from DangKyDeCaNhan where MaDe = @maDe and @maMon = @maMon and TrangThai = 1)
	END TRY
	BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
COMMIT TRAN
go
----------------------------------
-- THÊM ĐỀ
CREATE procedure ThemDe
	@moTa nvarchar(300),
	@kq int,
	@MaDe char(5) out

as
begin
	begin transaction ThemDe
		begin try
			declare @dem int
			set @dem = (select count(*) from De )
			if @kq != 0
				waitfor delay '00:00:05'
			set @dem = @dem + 1;
			if (@dem < 10)
				set @maDe = CONCAT('De00',@dem)
			else if (@dem < 100)
				set @maDe = CONCAT('De0', @dem)
			else 
				set @maDe = CONCAT('De',@dem)
			insert into De values (@maDe, @moTa)
		end try
		begin catch
			declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;  
			select   @ErrorMessage = ERROR_MESSAGE(),  @ErrorSeverity = ERROR_SEVERITY(),  @ErrorState = ERROR_STATE(); 
			raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState );  
			rollback tran ThemDe;
			set @kq = 0;
			return;
		end catch
	set @kq = 1
	commit tran ThemDe
end
go
-------------------------------
-- THÊM THÀNH VIÊN NHÓM
CREATE PROCEDURE ThemThanhVienNhom
	@MaMon char(6),
	@MaNhom char(4),
	@MSSV char(5),
	@kq int output
AS
	BEGIN TRANSACTION
		BEGIN TRY
			IF NOT EXISTS (SELECT* FROM Nhom WHERE TinhTrang = 1 AND MaNhom = @MaNhom)
			BEGIN
				RAISERROR (N'Nhóm không tồn tại', 16, 1)
				ROLLBACK TRAN
				RETURN
			END
			IF NOT EXISTS (SELECT* FROM Users WHERE TinhTrang = 1 AND MaNguoiDung = @MSSV) 
			BEGIN
				RAISERROR (N'Mã số sinh viên nhóm trưởng không tồn tại', 16, 1)
				ROLLBACK TRAN
				SET @kq = 0
				RETURN
			END
			DECLARE @slTV int
			SET @slTV = (SELECT SLThanhVien FROM Nhom WHERE MaNhom = @MaNhom AND TinhTrang = 1)
			INSERT INTO ThanhVienNhom VALUES (@MaNhom,@MSSV, 1)
			UPDATE Nhom SET SLThanhVien = @slTV + 1 WHERE MaNhom = @MaNhom AND TinhTrang = 1
			if @kq != 0
				waitfor delay '00:00:05'
			if not exists (select * from SinhVien_Mon where @MaMon = MaMH and @MSSV = MSSV )
			begin
				set @kq = 0
				raiserror(N'Sinh viên môn nào thì chỉ được đăng ký nhóm môn đó', 16 , 1)
				rollback tran
				return
			end
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
 
			SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
			
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
			ROLLBACK TRAN
			SET @kq = 0
				RETURN
		END CATCH
		SET @kq = 1
	COMMIT TRANSACTION

go
--------------------------------
-- ĐĂNG KÝ NHÓM
CREATE procedure DangKyNhom
	@TenNhom nvarchar(20),
	@MaMon char(6),
	@NhomTruong char(5),
	@kq int output
as
begin tran
	begin try
		if not exists (select MaNguoiDung from Users where @NhomTruong = MaNguoiDung and TinhTrang = 1)
		begin
			raiserror (N'Mã số sinh viên nhóm trưởng không tồn tại', 16, 1)
			rollback tran
			set @kq = 0
			return
		end

		if not exists (select MaMH from Mon where @MaMon=MaMH and TinhTrang = 1)
		begin
			raiserror (N'Mã môn không tồn tại', 16, 1)
			rollback tran
			set @kq = 0
			return
		end

		-- Phát sinh mã nhóm
		declare @Count int
		declare @MaNhom char(4) 
		set @Count = (select count(*) from Nhom ) 
		if @kq != 0
			waitfor delay '00:00:05'
		set @Count = @Count + 1
		if (@Count < 10) 
			set @MaNhom = concat('N00', @Count)
		else 
			if (@Count < 100)
				set @MaNhom = concat('N0', @Count)
			else
				set @MaNhom = concat('N', @Count)
		
		-- Thêm nhóm
		insert into Nhom(MaNhom, TenNhom, Mon, TruongNhom, SLThanhVien) values (@MaNhom, @TenNhom, @MaMon, @NhomTruong, 0)

		-- Thêm nhóm trưởng vào thành viên nhóm
		declare @kqua int
		exec ThemThanhVienNhom @MaMon, @MaNhom, @NhomTruong, @kqua out

		-- Update nhóm trưởng cho nhóm
		update Nhom set TruongNhom = @NhomTruong where MaNhom = @MaNhom
	end try
	begin catch
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		rollback transaction
		set @kq = 0
		return 
	end catch
	set @kq = 1
commit tran
go
--------------------------------
-- TẠO TÀI KHOẢN NGƯỜI DÙNG
CREATE procedure TaoTaiKhoan
	@MatKhau varchar(20),
	@HoTen nvarchar(31),
	@Email nvarchar(50),
	@SDT varchar(11),
	@DiaChi varchar(50),
	@Khoa int,
	@LoaiNguoiDung char(1),
	@kq int out
as
begin transaction
	begin try
		declare @MaNguoiDung char(5), @tam int
		declare @str char(2)
		if (@LoaiNguoiDung = '0')
		begin
			set @tam = (select count(*) from Users  where LoaiNguoiDung = '0')
			set @str = 'AD'
		end
		else 
			if (@LoaiNguoiDung = '1')
			begin
				set @tam = (select count(*) from Users  where LoaiNguoiDung = '1')
				set @str = 'GV'
			end
			else
			begin
				set @tam = (select count(*) from Users  where LoaiNguoiDung = @LoaiNguoiDung and Khoa = @Khoa)
				set @str = CONVERT(char(2), @Khoa)
			end
		if @kq = 2
			waitfor delay '00:00:05'
		set @tam = @tam + 1;
		if (@tam < 10)
			set @MaNguoiDung = concat(@str + '00', @tam)
		else 
			if (@tam <100)
				set @MaNguoiDung = concat(@str + '0', @tam)
		else 
			set @MaNguoiDung = concat(@str, @tam)
		insert into Users values (@MaNguoiDung, @MatKhau, @HoTen, @Email, @SDT, @DiaChi, @Khoa, @LoaiNguoiDung, 1)
		if @kq = 4
			waitfor delay '00:00:05'
		if exists (select * from Users where Email = @Email and MaNguoiDung != @MaNguoiDung)
		begin
			set @kq = 0;
			RAISERROR (N'Email không được trùng!!!', 16, 1)
			ROLLBACK TRANSACTION taoTK
			RETURN
		end
		select MaNguoiDung from Users where @MaNguoiDung = MaNguoiDung
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000);
		declare @ErrorSeverity int;
		declare @ErrorState int;
			
		select
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
		set @kq = 0
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		rollback transaction
		return
	end catch
	set @kq = 1
commit transaction
go
------------------------------------------------------
CREATE procedure RutNhom  @MaMH char(6), @MaNhom char(4), @MaSV char(5), @kq int out
as
begin
	begin transaction
		begin try
			Declare @sl tinyint;
			if not exists (select * from ThanhVienNhom where MaNhom = @MaNhom and MSSV = @MaSv)
			begin
				set @kq = 0
				raiserror (N'Sinh viên không thuộc nhóm này',16,1);
				rollback transaction
				return
			end 
			SET @sl = (Select SLThanhVien from Nhom where Mon = @MaMH and MaNhom = @MaNhom)
			if @kq != 0
				waitfor delay '00:00:05'
			Update ThanhVienNhom set TinhTrang ='0' where  MaNhom = @MaNhom and MSSV = @MaSv
			Update Nhom set SLThanhVien = @sl -1 where MaNhom = @MaNhom
		end try
		begin catch
			declare @ErrorMessage nvarchar(4000);
			declare @ErrorSeverity int;
			declare @ErrorState int;
			
			select @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE();
			set @kq = 0
			raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
			rollback transaction
			return
		end catch
		set @kq = 1
	commit transaction
end
go
-------------------------------------------
-- SỬA THÔNG TIN ĐỀ
CREATE PROCEDURE suaThongTinDe @made char(5), @mota nvarchar(200), @kq int out
AS
BEGIN
	BEGIN TRANSACTION
		BEGIN TRY
			IF NOT EXISTS (SELECT*FROM De WHERE MaDe = @made)
				BEGIN
					RAISERROR(N'Mã đề không tồn tại!!', 16, 1)
					SET @kq = '0'
					ROLLBACK TRANSACTION
					RETURN
				END
			IF EXISTS (SELECT*FROM De_Mon WHERE MaDe = @made)
				BEGIN
					RAISERROR(N'Không thể sửa đề vì đã có lớp đăng ký đề này!!', 16, 1)
					SET @kq = '0'
					ROLLBACK TRANSACTION
					RETURN
				END
				if @kq != 0
					waitfor delay '00:00:05'
				UPDATE De SET Mota = @mota WHERE MaDe = @made
				
		END TRY
		BEGIN CATCH 
			DECLARE @ErrorMessage NVARCHAR(4000)  
			DECLARE @ErrorSeverity INT  
			DECLARE @ErrorState INT  
			SELECT   
				@ErrorMessage = ERROR_MESSAGE(),  
				@ErrorSeverity = ERROR_SEVERITY(),  
				@ErrorState = ERROR_STATE() 
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
			ROLLBACK TRANSACTION
			SET @kq = '0'
			RETURN
		END CATCH 
		SET @kq = '1'
	commit TRANSACTION  
END
go
----------------------------------------------------
-- SỬA THÔNG TIN MÔN
CREATE PROCEDURE SuaTT_Mon @MaMH char(6), @TenMH nvarchar(50), @kq int out
AS
	BEGIN TRANSACTION
		BEGIN TRY
			IF NOT EXISTS (SELECT MaMH FROM Mon WHERE MaMH = @MaMH AND TinhTrang = 1)
				BEGIN
					RAISERROR (N'Môn học không tồn tại', 16, 1)
					SET @kq = 0
					ROLLBACK TRANSACTION
					RETURN
				END
			if @kq != 0
				waitfor delay '00:00:05'
			UPDATE Mon SET TenMH = @TenMH WHERE MaMH = @MaMH
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage nvarchar(4000);
			DECLARE @ErrorSeverity int;
			DECLARE @ErrorState int;
			
			SELECT
				@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
			ROLLBACK TRANSACTION
			SET @kq = 0
			RETURN
		END CATCH
		SET @kq = 1
	COMMIT TRANSACTION
go
----------------------------------------
-- XEM DANH SÁCH NGƯỜI DÙNG
 --Tạo fulltext index index
 CREATE UNIQUE INDEX PK_UsersSearch ON Users(MaNguoiDung)  
CREATE FULLTEXT CATALOG users_catalog  
GO  
CREATE FULLTEXT INDEX ON users  
 (   
  MaNguoiDung  
     Language 1033,  
  HoTen 
     Language 1033,  
  Email 
     Language 1033,
  DiaChi
	 Language 1033 ,
  LoaiNguoiDung
	 Language 1033  
 )   
  KEY INDEX PK_UsersSearch  
      ON users_catalog   
GO  

-----------------------------------------
-- ĐỌC THÔNG TIN ĐỀ MÔN của giáo viên
CREATE proc DS_DeMon_GV
	@maGV char(5), @maMon char(6)
as
begin
	begin tran
		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
		begin try
			select dm.MaDe, dm.MaMH, d.MoTa, dm.LoaiDe, l.TenLoaiDA, dm.NgayBDDangKy,dm.SLDangKyToiDa, dm.SLDangKy, dm.SLSVNhom, dm.Deadline
			from De_Mon dm, PhuTrachDe pt, De d, LoaiDoAn l
			where d.MaDe = dm.MaDe and dm.MaDe = pt.MaDe and dm.MaMH = pt.MaMH and l.MaLoaiDA = dm.LoaiDoAn and pt.MaGV = @maGV and pt.TinhTrang = 1
		end try
		begin catch
			DECLARE @ErrorMes nvarchar(4000), @ErrorSev int, @ErrorState int;
			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		end catch
	commit tran
end
go
-----------------------------------------
-- XEM DANH SÁCH ĐỀ ĐÃ ĐĂNG KÝ CỦA SINH VIÊN
CREATE PROCEDURE XemDSDeSV @maSV char(5)
AS
	BEGIN TRANSACTION
		BEGIN TRY
			SET TRAN ISOLATION LEVEL READ UNCOMMITTED
			SELECT dkdcn.MaDe as MaDe, dm.MaMH as Mon, MoTa, l.TenLoaiDA as LoaiDoAn, dm.LoaiDe as LoaiDe, u.HoTen as GVPT, null as Nhom
			from DangKyDeCaNhan dkdcn, De_Mon dm, PhuTrachDe ptd, Users u, De d, LoaiDoAn l
			where dkdcn.MSSV = @maSV and dkdcn.MaDe = dm.MaDe and dkdcn.MaDe = ptd.MaDe and ptd.MaGV = u.MaNguoiDung and d.MaDe = dm.MaDe and l.MaLoaiDA = dm.LoaiDoAn 
			UNION
			select dkdn.MaDe, dm.MaMH, Mota, dm.LoaiDoAn, dm.LoaiDe, u.HoTen, dkdn.MaNhom as Nhom
				from DangKyDeNhom dkdn, De_Mon dm, QuanLiNhom qln, Users u, De d
				where dkdn.MaNhom in (select tvn.MaNhom
						from DangKyDeNhom dkdn, ThanhVienNhom tvn
						where dkdn.MaNhom = tvn.MaNhom
							and tvn.MSSV = @maSV)
						and dkdn.MaDe = dm.MaDe
						and dkdn.MaDe = qln.MaDe
						and qln.MaGV = u.MaNguoiDung
						and dkdn.MaDe = d.MaDe
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
	COMMIT TRANSACTION
go
--------------------------------------------
-- XEM DANH SÁCH THÀNH VIÊN CỦA NHÓM
CREATE procedure XemDSThanhVien_Nhom
	@MaNhom char(4)
as
begin tran
	begin try 
	SET TRAN ISOLATION LEVEL READ UNCOMMITTED
		if not exists (select MaNhom from Nhom where TinhTrang = 1)
		begin
			raiserror (N'Nhóm không tồn tại', 16, 1)
			rollback tran
			return
		end
		select MaNguoiDung, HoTen from ThanhVienNhom tvm, Users u 
			where tvm.TinhTrang = 1 and tvm.MaNhom = @MaNhom and u.MaNguoiDung = tvm.MSSV
	end try
	begin catch
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
 
		SELECT @ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		rollback tran
		return 
	end catch
commit tran
go
---------------------------------------
-- KIỂM TRA ĐĂNG NHẬP
CREATE procedure DangNhap (@user_input varchar(5), @password nvarchar(20))
as
begin
	if not exists (select * from Users where MaNguoiDung = @user_input and TinhTrang = 1)
	begin
		raiserror(N'Mã người dùng không tồn tại!!!', 16, 1);
		return
	end
	else
	begin
		if not exists(select * from Users where MaNguoiDung = @user_input and MatKhau = @password and TinhTrang = 1)
		begin
			raiserror(N'Mật khẩu sai!!!', 16, 1);
			return
		end
		else
		begin
			select MaNguoiDung, HoTen, Email, SDT, Diachi, Khoa, LoaiNguoiDung  from Users where MaNguoiDung = @user_input and TinhTrang = 1
		end
	end
end
go
--------------------------------
-- XEM DANH SÁCH CÁC ĐỀ
CREATE proc xemDSDe
as
begin
	begin tran
	begin try
		select * from De
	end try
	begin catch 
		declare @ErrorMessage NVARCHAR(4000);  
		declare @ErrorSeverity INT;  
		declare @ErrorState INT;  
		select   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE(); 
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState );  
		rollback tran;
		return;
	end catch; 
	commit tran;  
end
go
-----------------------------------
-- XEM THÔNG TIN MỘT ĐỀ
CREATE proc xemThongTinDe (@made char(5))
as
begin
	begin tran
	begin try
		select * from De where MaDe = @made
	end try
	begin catch 
		declare @ErrorMessage NVARCHAR(4000);  
		declare @ErrorSeverity INT;  
		declare @ErrorState INT;  
		select   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE(); 
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState );  
		rollback tran;
		return;
	end catch; 
	commit tran;  
end
go
-------------------------------
--Xem danh sách đề còn hạn đăng ký
GO
--Xem danh sách đề còn hạn đăng ký của môn
CREATE PROCEDURE TkiemDe_MH_SV @maMon char(6)
AS	
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT De_Mon.MaDe, Mota, MaMH, LoaiDe, LoaiDoAn.TenLoaiDA, NgayBDDangKy,  SLDangKyToiDa, SLDangKy, SLSVNhom, Deadline 
			FROM De_Mon, De, LoaiDoAn 
			WHERE De_Mon.MaMH = @maMon AND De_Mon.TinhTrang = '1' and De.MaDe = De_Mon.MaDe and LoaiDoAn.MaLoaiDA = De_Mon.LoaiDoAn
					and Deadline > GETDATE() and NgayBDDangKy < GETDATE()
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRANSACTION
			RETURN
		END CATCH
	COMMIT TRANSACTION
go
----------------------------------------
--Xem danh sách môn Admin
CREATE PROCEDURE XemDSMonAdmin
AS
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT Mon.MaMH, Mon.TenMH FROM Mon where Mon.TinhTrang = 1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		COMMIT TRANSACTION
GO
--Xem danh sách môn Giáo viên
CREATE PROCEDURE XemDSMonGiaovien @magv char(5)
AS
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT Mon.MaMH, Mon.TenMH FROM GiaoVien_Mon, Mon where GiaoVien_Mon.MaMH = Mon.MaMH and GiaoVien_Mon.MaGV = @magv and GiaoVien_Mon.TinhTrang=1 and Mon.TinhTrang=1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		COMMIT TRANSACTION

GO
--Xem danh sách môn Sinh viên
CREATE PROCEDURE XemDSMonSinhvien @masv char(5)
AS
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT Mon.MaMH, Mon.TenMH FROM SinhVien_Mon, Mon where SinhVien_Mon.MaMH = Mon.MaMH and SinhVien_Mon.MSSV = @masv and SinhVien_Mon.TinhTrang=1 and Mon.TinhTrang=1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		COMMIT TRANSACTION

---------------------------------------------------------------------------------------------------------

GO
/* Xem thông tin cá nhân
	Input: Mã người dùng
	Output: Thông tin cá nhân của người dùng  */
CREATE procedure XemThongTinCaNhan
	@MaNguoiDung char(6)
as
begin
	begin transaction selectPrivateInf
		begin try 
			if not exists (select * from Users where TinhTrang = 1 and MaNguoiDung = @MaNguoiDung)
			begin
				raiserror (N'Người dùng không tồn tại', 16, 1)
				rollback
				return
			end
				select MaNguoiDung, HoTen, DiaChi, SDT, Email, Khoa from Users where MaNguoiDung = @MaNguoiDung
		end try
		begin catch
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
 
			SELECT @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
			rollback transaction selectPrivateInf
			return 
		end catch
	commit transaction selectPrivateInf
end
go

--------------------------------------------------------------------------------------------------
CREATE PROCEDURE ThemDeMonCu
	@MaDe char(5),
	@MaMH char(6),
	@LoaiDoAn char(2),
	@LoaiDe bit,
	@SLDangKyToiDa tinyint,
	@SLSVNhom tinyint,
	@NgayBDDangKy datetime,
	@Deadline datetime,
	@kq int out
AS
BEGIN
	BEGIN TRAN
		BEGIN TRY	
			insert into De_Mon values(@MaDe,@MaMH,@LoaiDoAn,@LoaiDe,@SLDangKyToiDa,@SLSVNhom,0,@NgayBDDangKy, @Deadline, 1)
		
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			SET @kq = 0
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		SET @kq = 1
	COMMIT TRAN
END
go

CREATE PROCEDURE ThemDeMonMoi
	@MoTa nvarchar(300),
	@MaMH char(6),
	@LoaiDoAn char(2),
	@LoaiDe bit,
	@SLDangKyToiDa tinyint,
	@SLSVNhom tinyint,
	@NgayBDDangKy datetime,
	@Deadline datetime,
	@kq int out
as
BEGIN
	BEGIN TRAN
		BEGIN TRY
			declare @maDe char(5)
			exec ThemDe @MoTa, 0, @maDe out
			exec ThemDeMonCu @maDe, @maMH, @LoaiDoAn, @LoaiDe, @SLDangKyToiDa, @SLSVNhom, @NgayBDDangKy, @Deadline, @kq out
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			SET @kq = 0
			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
		SET @kq = 1
	COMMIT TRAN
END

go
--Lấy các nhóm của sinh viên
CREATE  PROCEDURE layNhomSinhVien @maSV varchar(5), @maMon char(6)
AS
	BEGIN TRANSACTION
		BEGIN TRY
			select Nhom.MaNhom, TenNhom, TruongNhom, SLThanhVien from Nhom, ThanhVienNhom 
			where Nhom.MaNhom = ThanhVienNhom.MaNhom and ThanhVienNhom.MSSV = @maSV and Nhom.Mon = @maMon
			and ThanhVienNhom.TinhTrang = 1 and Nhom.TinhTrang = 1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
	COMMIT TRANSACTION

GO

GO
--Lấy nhóm thuộc môn mà sinh viên làm nhóm trưởng 
CREATE PROCEDURE layNhomSVNhomTruong @maSV varchar(5), @maMon char(6)
AS
	BEGIN TRANSACTION
		BEGIN TRY
			select MaNhom, TenNhom, TruongNhom, SLThanhVien  from Nhom where TruongNhom = @maSV and Mon = @maMon and TinhTrang = 1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMes nvarchar(4000);
			DECLARE @ErrorSev int;
			DECLARE @ErrorState int;

			SELECT @ErrorMes = ERROR_MESSAGE(), @ErrorSev = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()

			RAISERROR(@ErrorMes, @ErrorSev, @ErrorState)
			ROLLBACK TRAN
			RETURN
		END CATCH
	COMMIT TRANSACTION

GO

CREATE PROCEDURE XemDSNguoiDung @tuKhoa nvarchar(100)
AS
BEGIN
	BEGIN TRANSACTION XemNguoiDung
		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			SELECT MaNguoiDung, HoTen, Email, SDT, Diachi, Khoa, LoaiNguoiDung FROM Users WHERE CONTAINS((MaNguoiDung, HoTen, Email, DiaChi, LoaiNguoiDung), @tuKhoa) OR LoaiNguoiDung = @tuKhoa AND TinhTrang = 1
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000)
			DECLARE @ErrorSeverity INT
			DECLARE @ErrorState INT
 
			SELECT @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE()
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
			ROLLBACK TRANSACTION XemNguoiDung
			RETURN
		END CATCH
	COMMIT TRANSACTION XemNguoiDung
END
go

-- Xem danh sách Loại đồ án
CREATE PROCEDURE XemDSLoaiDoAn
AS
BEGIN
	BEGIN TRANSACTION
		BEGIN TRY
			SELECT * FROM LoaiDoAn
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000)
			DECLARE @ErrorSeverity INT
			DECLARE @ErrorState INT
 
			SELECT @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE()
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
			ROLLBACK TRANSACTION XemNguoiDung
			RETURN
		END CATCH
	COMMIT TRANSACTION
END
go