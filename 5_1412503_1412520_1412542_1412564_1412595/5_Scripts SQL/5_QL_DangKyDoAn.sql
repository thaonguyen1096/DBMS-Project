--drop database QL_DangKyDoAn
--CREATE DATABASE QL_DangKyDoAn

use QL_DangKyDoAn


create table Users(
	MaNguoiDung char(5),
	MatKhau varchar(20) not null,
	HoTen nvarchar(31) not null,
	Email nvarchar(50),
	SDT varchar(11),
	DiaChi nvarchar(50),
	Khoa int,
	LoaiNguoiDung char(1) check (LoaiNguoiDung = '0' or LoaiNguoiDung = '1' or LoaiNguoiDung = '2'),
	TinhTrang bit default 1,   -- 1: active, 0: inactive
	primary key (MaNguoiDung)
)

create table Mon(
	MaMH char(6),
	TenMH nvarchar(50) not null,
	TinhTrang bit default 1,
	primary key (MaMH)
)

create table LoaiDoAn(
	MaLoaiDA char(2),
	TenLoaiDA nvarchar(20) not null, 
	primary key (MaLoaiDA)
)

create table De(
	MaDe char(5),
	Mota nvarchar(300) not null,
	primary key(MaDe)
)

create table Nhom(
	MaNhom char(4),
	TenNhom nvarchar(20),
	Mon char(6) not null,
	TruongNhom char(5),
	SLThanhVien tinyint not null,
	TinhTrang bit default 1,
	primary key (MaNhom)
)

create table SinhVien_Mon(
	MSSV char(5),
	MaMH char(6),
	TinhTrang bit default 1,
	primary key (MSSV, MaMH)
)

CREATE TABLE GiaoVien_Mon
(
	MaGV char(5),
	MaMH char(6),
	TinhTrang bit default 1,
	PRIMARY KEY(MaGV, MaMH)
)

CREATE TABLE PhuTrachDe
(
	MaGV char(5),
	MaDe char(5),
	MaMH char(6),
	TinhTrang bit default 1,
	PRIMARY KEY(MaGV, MaDe, MaMH)
)

CREATE TABLE QuanLiNhom
(
	MaGV char(5),
	MaNhom char(4),
	MaDe char(5),
	MaMH char(6),
	TinhTrang bit default 1,
	PRIMARY KEY(MaGV, MaNhom)
)

CREATE TABLE ThanhVienNhom
(
	MaNhom char(4),
	MSSV char(5),
	TinhTrang bit default 1,
	PRIMARY KEY(MSSV, MaNhom)
)

CREATE TABLE DangKyDeNhom
(
	MaDe char(5),
	MaMH char(6),
	MaNhom char(4),
	TrangThai bit default 1,
	PRIMARY KEY(MaDe, MaMH, MaNhom)
)

CREATE TABLE DangKyDeCaNhan
(
	MaDe char(5),
	MaMH char(6),
	MSSV char(5),
	TrangThai bit default 1,
	PRIMARY KEY(MaDe, MaMH, MSSV)
)

CREATE TABLE De_Mon
(
	MaDe char(5),
	MaMH char(6),
	LoaiDoAn char(2) not null,
	LoaiDe bit,
	SLDangKyToiDa tinyint not null,
	SLSVNhom tinyint not null,
	SLDangKy tinyint,
	NgayBDDangKy datetime not null,
	Deadline datetime,
	TinhTrang bit default 1,
	PRIMARY KEY(MaDe, MaMH)
)

ALTER TABLE GiaoVien_Mon
ADD CONSTRAINT FK_GiaoVien_Mon__User
FOREIGN KEY (MaGV)
REFERENCES Users(MaNguoiDung)

ALTER TABLE GiaoVien_Mon
ADD CONSTRAINT FK_GiaoVien_Mon__Mon
FOREIGN KEY (MaMH)
REFERENCES Mon(MaMH)

ALTER TABLE De_Mon
ADD CONSTRAINT FK_De_Mon__De
FOREIGN KEY (MaDe)
REFERENCES De(MaDe)

ALTER TABLE De_Mon
ADD CONSTRAINT FK_De_Mon__Mon
FOREIGN KEY (MaMH)
REFERENCES Mon(MaMH)

ALTER TABLE De_Mon
ADD CONSTRAINT FK_De_Mon__LoaiDoAn
FOREIGN KEY (LoaiDoAn)
REFERENCES LoaiDoAn(MaLoaiDA)

ALTER TABLE PhuTrachDe
ADD CONSTRAINT FK_PhuTrachDe_GiaoVien
FOREIGN KEY (MaGV)
REFERENCES Users(MaNguoiDung)

ALTER TABLE PhuTrachDe
ADD CONSTRAINT FK_PhuTrachDe__De_Mon
FOREIGN KEY (MaDe, MaMH)
REFERENCES De_Mon(MaDe, MaMH)

ALTER TABLE QuanLiNhom
ADD CONSTRAINT FK_QuanLiNhom_GiaoVien
FOREIGN KEY (MaGV)
REFERENCES Users(MaNguoiDung)

ALTER TABLE QuanLiNhom
ADD CONSTRAINT FK_QuanLiNhom_Nhom
FOREIGN KEY (MaNhom)
REFERENCES Nhom(MaNhom)

ALTER TABLE QuanLiNhom
ADD CONSTRAINT FK_QuanLiNhom__De_Mon
FOREIGN KEY (MaDe, MaMH)
REFERENCES De_Mon(MaDe, MaMH)

ALTER TABLE ThanhVienNhom
ADD CONSTRAINT FK_ThanhVienNhom_Users
FOREIGN KEY (MSSV)
REFERENCES Users(MaNguoiDung)

ALTER TABLE ThanhVienNhom
ADD CONSTRAINT FK_ThanhVienNhom_Nhom
FOREIGN KEY (MaNhom)
REFERENCES Nhom(MaNhom)

ALTER TABLE DangKyDeNhom
ADD CONSTRAINT FK_DangKyDeNhom_Nhom
FOREIGN KEY (MaNhom)
REFERENCES Nhom(MaNhom)

ALTER TABLE DangKyDeNhom
ADD CONSTRAINT FK_DangKyDeNhom__De_Mon
FOREIGN KEY (MaDe, MaMH)
REFERENCES De_Mon(MaDe, MaMH)

ALTER TABLE DangKyDeCaNhan
ADD CONSTRAINT FK_DangKyDeCaNhan_Users
FOREIGN KEY (MSSV)
REFERENCES Users(MaNguoiDung)

ALTER TABLE DangKyDeCaNhan
ADD CONSTRAINT FK_DangKyDeCaNhan__De_Mon
FOREIGN KEY (MaDe, MaMH)
REFERENCES De_Mon(MaDe, MaMH)

alter table Nhom
add constraint FK_Nhom_Mon
foreign key (Mon)
references Mon(MaMH)

alter table Nhom
add constraint FK_Nhom_Users
foreign key (TruongNhom)
references Users(MaNguoiDung)

alter table SinhVien_Mon
add constraint FK_SinhVien_Mon__Users
foreign key (MSSV)
references Users(MaNguoiDung)

alter table SinhVien_Mon
add constraint FK_SinhVien_Mon__Mon
foreign key (MaMH)
references Mon(MaMH)

go
--Nếu là sinh viên thì khóa không được null, nếu là admin hoặc giáo viên thì khóa phải bằng null
create trigger KiemTraKhoa
on Users
for insert, update
as
begin
	if update(Khoa)
	begin
		declare @khoa int,  @ma_user tinyint
		set @khoa = (ISNULL((select Khoa from inserted), 0))
		set @ma_user = (select LoaiNguoiDung from inserted)
		if ((@khoa!=0) and (@ma_user = 0 or @ma_user = 1))
		begin
			raiserror (N'Giá trị khóa phải null', 16, 1)
			rollback tran
			return
		end

		if(@khoa = 0 and @ma_user = 2)
		begin
			raiserror (N'Giá trị khóa không được null', 16, 1)
			rollback tran
			return
		end
	end
end

go
create trigger KiemTraThemThanhVienNhom
on ThanhVienNhom
for insert, update
as
begin
	if update (TinhTrang)
	begin
		if exists (select*from Nhom, inserted where inserted.MaNhom = Nhom.MaNhom and inserted.MSSV = Nhom.TruongNhom and inserted.TinhTrang = '0')
		begin
			raiserror(N'Trưởng nhóm không được phép rút nhóm', 16 , 1)
			rollback tran
			return
		end
	end
end

--insert into ThanhVienNhom values ('N001', '11020', 1)
--update ThanhVienNhom set TinhTrang='0' where MSSV = '14011'
--select*from ThanhVienNhom
--select*from Users where MaNguoiDung='12006'
go
create trigger KiemTraCapNhatTruongNhom
on Nhom
for update 
as
begin 
	if not exists (select* from inserted, ThanhVienNhom where inserted.TruongNhom = ThanhVienNhom.MSSV and ThanhVienNhom.TinhTrang='1')
	begin
		raiserror(N'Trưởng nhóm phải là thành viên của nhóm', 16 , 1)
		rollback tran
		return
	end
end

go
---	Đề cá nhân của môn chỉ do 1 giáo viên phụ trách
create trigger KiemTraQLDe
on PhuTrachDe
for insert, update
as
begin
	if((select count(*)from PhuTrachDe, inserted, De_Mon where inserted.MaDe=PhuTrachDe.MaDe and De_Mon.MaDe = inserted.MaDe and De_Mon.LoaiDe='1') > 1)
	begin
		raiserror(N'Đề cá nhân chỉ được quản lý bởi một giáo viên', 16, 1)
		rollback tran
		return
	end
end

go
--Nhóm phải được quản lý bởi giáo viên phụ trách đề môn mà nhóm đó đăng ký
create trigger KiemTraGVQLNhom
on QuanLiNhom
for insert, update
as
begin
	if not exists (select * from De_Mon, DangKyDeNhom, inserted, PhuTrachDe where 
				De_Mon.MaMH = inserted.MaMH and De_Mon.MaDe = inserted.MaDe
				and De_Mon.MaDe = DangKyDeNhom.MaDe and De_Mon.TinhTrang = '1'
				and PhuTrachDe.MaGV = inserted.MaGV and PhuTrachDe.MaDe = DangKyDeNhom.MaDe 
				and inserted.MaNhom = DangKyDeNhom.MaNhom and DangKyDeNhom.TrangThai='1')
	begin
		raiserror(N'Nhóm chỉ được quản lý bởi giáo viên phụ trách đề mà nhóm đã đăng ký', 16, 1)
		rollback
		return
	end
end

----------=========================---------------------=============
-- Ràng buộc SLSV/nhóm
go 
create trigger trgSLSVNhom
on De_Mon
for insert, update
as
begin
	if update(SLSVNhom)
	begin
		declare @sl int,  @loaide bit
		set @sl = (ISNULL((select SLSVNhom from inserted), 1000))
		set @loaide = (select LoaiDe from inserted)
		if (@sl = 1000)
		begin
			raiserror (N'Số lượng sinh viên/ nhóm phải không được null', 16, 1)
			rollback
			return
		end
	end
end

---	Đề của môn nào phải do giáo viên phụ trách môn đó quản lý 
--DROP TRIGGER trgGVPhuTrachDe
GO
CREATE TRIGGER trgGVPhuTrachDe
ON PhuTrachDe
FOR INSERT, UPDATE
AS
	IF UPDATE(MaMH) OR UPDATE(MaGV)
		BEGIN
			IF EXISTS (SELECT * 
					   FROM INSERTED I
					   WHERE MaMH NOT IN (SELECT GM.MaMH
										FROM GiaoVien_Mon GM, INSERTED I1
										WHERE GM.MaGV = I1.MaGV))
				begin
					raiserror (N'Giáo viên không phụ trách môn học này', 16, 1)
					rollback
				end
		END

GO
CREATE TRIGGER trgGVPhuTrachMon
ON GiaoVien_Mon
FOR UPDATE
AS
	IF UPDATE(MaMH)
		BEGIN
			IF EXISTS (SELECT * FROM PhuTrachDe P, INSERTED I WHERE P.MaGV = I.MaGV AND P.MaMH NOT IN (SELECT GM.MaMH
																									   FROM GiaoVien_Mon GM, INSERTED I1
																									   WHERE GM.MaGV = I1.MaGV))
				BEGIN
					raiserror (N'Lỗi: Giáo viên quản lý đề của môn mà giáo viên không phụ trách', 16, 1)
					rollback
				END
		END
	ELSE IF UPDATE(MaGV)
		BEGIN
			IF EXISTS (SELECT * FROM PhuTrachDe P, INSERTED I WHERE P.MaMH = I.MaMH AND P.MaGV NOT IN (SELECT GM.MaGV
																									   FROM GiaoVien_Mon GM, INSERTED I1
																									   WHERE GM.MaMH = I1.MaMH))
				BEGIN
					raiserror (N'Lỗi: Giáo viên quản lý đề của môn mà giáo viên không phụ trách', 16, 1)
					rollback
				END
		END
---------------------------

-- Sinh viên/ nhóm chỉ được đăng ký đề trong khoảng thời gian được phép đăng ký 
GO
create TRIGGER trgThoiGianDKDeNhom		-- Đăng ký đề nhóm
ON DangKyDeNhom
FOR INSERT
AS
	BEGIN
		DECLARE @bd datetime, @dl datetime, @now datetime
		SET @bd = (SELECT NgayBDDangKy
				   FROM De_Mon DM, INSERTED I
				   WHERE DM.MaDe = I.MaDe AND DM.MaMH = I.MaMH)
		SET @now = getdate()
		IF (@now < @bd)
			BEGIN
				raiserror (N'Đề này chưa tới hạn đăng ký', 16, 1)
				rollback
				return
			END
		SET @dl = (SELECT Deadline
				   FROM De_Mon DM, INSERTED I
				   WHERE DM.MaDe = I.MaDe AND DM.MaMH = I.MaMH)
		IF (@now > @dl)
			BEGIN
				raiserror (N'Đề này đã quá hạn đăng ký', 16, 1)
				rollback
			END
	END

go
create TRIGGER trgThoiGianDKDeSV		-- Đăng ký đề cá nhân
ON DangKyDeCaNhan
FOR INSERT
AS
	BEGIN
		DECLARE @bd datetime, @dl datetime, @now datetime
		SET @bd = (SELECT NgayBDDangKy
				   FROM De_Mon DM, INSERTED I
				   WHERE DM.MaDe = I.MaDe AND DM.MaMH = I.MaMH)
		SET @now = getdate()
		IF (@now < @bd)
			BEGIN
				raiserror (N'Đề này chưa tới hạn đăng ký', 16, 1)
				rollback
				return
			END
		SET @dl = (SELECT Deadline
				   FROM De_Mon DM, INSERTED I
				   WHERE DM.MaDe = I.MaDe AND DM.MaMH = I.MaMH)
		IF (@now > @dl)
			BEGIN
				raiserror (N'Đề này đã quá hạn đăng ký', 16, 1)
				rollback
			END
	END
