# Review bao cao Word va ke hoach sua chi tiet

Tai lieu duoc review: `Khóa Luận Tốt Nghiệp.docx`

## 1. Nhan xet tong hop

Bao cao hien co nen tang noi dung tot, mo ta duoc kien truc tong the, cong nghe, luong nghiep vu chinh, co so du lieu va cac thanh phan AI. Tuy nhien tai lieu dang gap mot so van de quan trong ve:

- tinh nhat quan giua bao cao va code hien tai
- do day noi dung cho phan giao dien
- do day noi dung cho role admin
- tinh sach se cua he thong danh so muc
- mot so loi dien dat/ten muc

Neu nop bao cao o trang thai hien tai, diem tru lon nhat se nam o viec phan mo ta UI va role admin chua day du, trong khi he thong code da co `admin-service` va role `ADMIN`.

## 2. Danh sach van de theo muc do uu tien

### P1 - Can sua ngay

1. Muc `3.3. Giao dien cho cac nguoi dung tuong ung` gan nhu trong.

- Tu paragraph 523 den 533 chi moi liet ke tieu de:
  - `3.3.1.1. Giao dien Dang nhap`
  - `3.3.1.2. Giao dien Dang ky`
  - `Giao dien danh cho Chu tro`
  - `Giao dien danh cho Nguoi thue`
  - `Giao dien danh cho Quan tri vien`
- Khong co phan mo ta man hinh, luong thao tac, widget/chuc nang chinh, screenshot, va y nghia nghiep vu.
- Day la khoang trong lon nhat cua bao cao.

2. Bao cao mo ta sai so service o phan ket luan.

- Paragraph 538 dang ghi he thong gom `ba service doc lap: auth-service, host-service, tenant-service`.
- Thuc te repo da co:
  - `auth-service`
  - `host-service`
  - `tenant-service`
  - `admin-service`
- Van de nay lam tai lieu mat tinh nhat quan voi code.

3. Bao cao mo ta sai so role o phan bao mat/phan quyen.

- Paragraph 541 dang ghi phan quyen ro rang giua `HOST` va `TENANT`.
- Thuc te he thong co `ADMIN`, `HOST`, `TENANT`.
- Neu giu nguyen, nguoi cham se thay tai lieu chua cap nhat theo thiet ke thuc te.

4. Bao cao mo ta bao mat chua khop hien trang backend.

- Paragraph 515 mo ta tat ca service deu trien khai JWT stateless authentication.
- Tuy nhien o lan review truoc, `admin-service` dang mo toan bo `/api/admin/**`.
- Neu backend da duoc bo sung xong thi phai cap nhat lai phan nay cho khop code cuoi cung.
- Neu khong sua tai lieu, day la mau thuan truc tiep giua mo ta va he thong.

5. Role admin moi xuat hien theo dang “co nhac den”, chua duoc mo ta thanh mot phan hoan chinh.

- Paragraph 423 co nhac `admin-service`.
- Paragraph 533 co tieu de `Giao dien danh cho Quan tri vien`.
- Nhưng khong co:
  - use case admin
  - luong admin
  - danh sach API admin
  - mo ta UI admin
  - acceptance criteria cho admin

### P2 - Nen sua de bao cao sach va thuyet phuc hon

6. Thieu muc rieng cho `admin-service` trong chuong API.

- Hien tai chuong 3 co:
  - `3.2.2 auth-service`
  - `3.2.3 host-service`
  - `3.2.4 tenant-service`
  - `3.2.5 scheduler`
  - `3.2.6 bao mat va phan quyen`
- Chua co `3.2.7 admin-service - API quan tri`.

7. He thong danh so muc chua dep va chua can doi.

- Dang co `3.3.1.1`, `3.3.1.2` nhung khong co noi dung khung ro cho `3.3.1`.
- Dang co `2.4.1.2` can kiem tra lai xem co can `2.4.1.1` ro rang hay khong.
- Nen sap xep lai heading de nguoi doc theo doi de hon.

8. Co mot so loi dien dat/ten muc.

- Paragraph 140: `he thong minh` can sua thanh `he thong thong minh`.
- Can quet lai toan van ban de sua cac cum tu bi thieu chu, lap chu hoac xuong dong chua dep.

9. Phan han che va huong phat trien chua phan biet ro “da lam” va “se lam”.

- Paragraph 549 dang noi ve giao dien web cho chu tro chua xay dung.
- Can bo sung them tinh trang role admin:
  - neu admin UI da co trong Flutter thi ghi ro
  - neu web admin rieng chua co thi de o huong phat trien

### P3 - Co the nang cap de tang chat luong

10. Phan giao dien nen co screenshot va mo ta giai thich gia tri nghiep vu.

- Moi man hinh nen co:
  - anh chup man hinh
  - muc dich
  - thanh phan chinh
  - thao tac nguoi dung
  - lien ket voi API/backend

11. Phan admin nen duoc dua vao ket luan nhu mot khoi quan tri van hanh.

- Hien ket luan nghieng nhieu ve host/tenant va AI.
- Nen bo sung mot doan ngan ve gia tri cua admin:
  - giam sat he thong
  - khoa/mo host
  - ra soat phong thieu hoa don
  - theo doi doanh thu tong hop

## 3. Ke hoach sua theo chuong/muc

### Chuong 1 - Tong quan

Can sua:

- thong nhat cach goi role: `ADMIN`, `HOST`, `TENANT`
- thong nhat cach goi service: `auth-service`, `host-service`, `tenant-service`, `admin-service`
- sua loi `he thong minh` thanh `he thong thong minh`

Can bo sung:

- 1 doan ngan o phan tong quan he thong de giai thich role admin co vai tro gi trong he sinh thai van hanh

### Chuong 2 - Phan tich va thiet ke he thong

#### 2.1.1 Yeu cau chuc nang

Bo sung nhom yeu cau chuc nang cho admin:

- xem dashboard tong quan he thong
- xem danh sach host
- xem chi tiet host
- khoa/mo host
- xem danh sach phong toan he thong
- xem phong thieu hoa don ky hien tai
- xem doanh thu theo thang/quy/nam

#### 2.3 Cac so do UML

Bo sung mot muc moi:

- `2.3.9 Luong Quan tri nen tang`

Trong muc nay can co it nhat:

- Use Case cho admin
- Activity cho:
  - xem dashboard
  - khoa/mo host
  - ra soat phong thieu hoa don
  - xem doanh thu
- Sequence cho:
  - login admin -> auth-service -> admin-service
  - admin xem dashboard
  - admin cap nhat trang thai host

### Chuong 3 - Xay dung va trien khai he thong

#### 3.1 Cau truc tong the

Can sua:

- tat ca cho nao ghi `ba service` thanh `bon service`
- tat ca cho nao bo sot `admin-service` phai bo sung lai

#### 3.2 Xay dung cac API nghiep vu

Bo sung muc moi:

- `3.2.7 admin-service - API quan tri`

Noi dung can viet:

- muc dich cua `admin-service`
- co che xac thuc va phan quyen role `ADMIN`
- danh sach endpoint:
  - `GET /api/admin/dashboard`
  - `GET /api/admin/hosts`
  - `GET /api/admin/hosts/{hostId}`
  - `PATCH /api/admin/hosts/{hostId}/status`
  - `GET /api/admin/rooms`
  - `GET /api/admin/rooms/without-invoice`
  - `GET /api/admin/revenue?period=month|quarter|year`
- mo ta du lieu tra ve chinh
- mo ta quy tac nghiep vu:
  - host status
  - room without invoice
  - revenue by period

#### 3.3 Giao dien cho cac nguoi dung tuong ung

Can viet lai phan nay thanh mot khoi day du, khong de title rong.

De xuat cau truc moi:

- `3.3.1 Giao dien Dang nhap va Dang ky`
  - `3.3.1.1 Giao dien Dang nhap`
  - `3.3.1.2 Giao dien Dang ky`
- `3.3.2 Giao dien danh cho Chu tro`
  - dashboard
  - quan ly phong
  - quan ly nguoi thue
  - quan ly hoa don / khieu nai / dich vu
- `3.3.3 Giao dien danh cho Nguoi thue`
  - dashboard
  - hop dong
  - hoa don
  - khieu nai
  - chatbot / thong bao / profile
- `3.3.4 Giao dien danh cho Quan tri vien`
  - dashboard admin
  - host management
  - host detail
  - room audit
  - revenue analytics

Mau noi dung cho moi man hinh:

- muc dich man hinh
- thanh phan UI chinh
- thao tac nguoi dung
- API backend duoc goi
- quy tac dieu huong
- anh chup man hinh

### Ket luan va huong phat trien

Can sua:

- paragraph 538: doi thanh he thong gom `4 service`
- paragraph 541: doi thanh phan quyen giua `3 role`

Can bo sung:

- 1 doan ngan tong ket gia tri cua role admin trong van hanh he thong
- 1 doan ngan neu ro admin UI dang nam trong app Flutter hien tai

### Phan han che

Cap nhat de phan biet ro:

- cai gi da xong
- cai gi chua xong
- cai gi la huong phat trien tiep

De xuat viet lai:

- neu web admin rieng chua co thi de o huong phat trien
- neu admin trong Flutter da co thi dua vao phan “da hoan thanh”
- neu audit log, export bao cao, analytics nang cao chua co thi dua vao phan “han che / future work”

## 4. Thu tu sua de tranh lech tai lieu voi code

1. Chot backend admin
- security
- endpoint
- quy tac nghiep vu

2. Chot frontend admin
- route
- man hinh
- screenshot

3. Sau khi code on dinh moi cap nhat Word
- cap nhat chuong 3.2
- viet lai chuong 3.3
- chen screenshot that
- sua ket luan va han che

Neu sua Word truoc khi code chot, tai lieu se rat de lech voi he thong that.

## 5. Checklist sua bao cao

- [ ] Sua toan bo cho nao ghi 3 service thanh 4 service
- [ ] Sua toan bo cho nao chi nhac 2 role thanh 3 role
- [ ] Them `3.2.7 admin-service - API quan tri`
- [ ] Viet day du `3.3` thay vi de title rong
- [ ] Them noi dung giao dien admin
- [ ] Them use case/activity/sequence cho admin
- [ ] Sua loi `he thong minh`
- [ ] Kiem tra va don lai numbering heading
- [ ] Cap nhat ket luan va han che theo code cuoi cung
- [ ] Chen screenshot giao dien that sau khi frontend admin hoan tat

## 6. Ket luan review

Bao cao hien co bo khung tot nhung dang thieu phan cap nhat cuoi cho role admin va phan giao dien. Neu bo sung dung 3 cum sau, tai lieu se tang chat luong rat ro:

- tinh nhat quan giua code va tai lieu
- mo ta day du giao dien theo tung role
- tach rieng admin thanh mot thanh phan quan tri hoan chinh
