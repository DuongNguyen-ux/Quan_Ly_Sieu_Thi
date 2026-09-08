// Quản lý Nhập kho (Inventory)
let importCart = [];

async function initInventory() {
  await Promise.all([loadSuppliers(), loadLowStockItems(), loadImportHistory()]);
  populateImportProductSelect();
  renderImportCart();
}

async function loadSuppliers() {
  try {
    const suppliers = await API.get('/api/partners/suppliers');
    const select = document.getElementById('inv-supplier-select');
    if (select) {
      select.innerHTML = suppliers
        .map(s => `<option value="${s.MaNCC}">${s.TenNCC} (${s.DienThoai})</option>`)
        .join('');
    }

    const empSelect = document.getElementById('inv-employee-select');
    if (empSelect && employees.length) {
      empSelect.innerHTML = employees
        .map(e => `<option value="${e.MaNV}">${e.HoTen} (${e.ChucVu})</option>`)
        .join('');
    }
  } catch (err) {
    console.error('Lỗi tải nhà cung cấp:', err);
  }
}

function populateImportProductSelect() {
  const select = document.getElementById('inv-product-select');
  if (!select || !allProducts.length) return;

  select.innerHTML = allProducts
    .map(p => `<option value="${p.MaSP}" data-price="${p.GiaBan * 0.7}">${p.TenSP} (${p.MaSP}) - Tồn: ${p.SoLuongTon}</option>`)
    .join('');

  onSelectImportProduct();
}

function onSelectImportProduct() {
  const select = document.getElementById('inv-product-select');
  const priceInput = document.getElementById('inv-item-price');
  if (!select || !priceInput) return;

  const selectedOpt = select.options[select.selectedIndex];
  const suggestedPrice = Math.round(parseFloat(selectedOpt?.getAttribute('data-price') || 5000));
  if (!priceInput.value) {
    priceInput.value = suggestedPrice;
  }
}

// Thêm sản phẩm vào danh sách chuẩn bị nhập
function addImportItem() {
  const select = document.getElementById('inv-product-select');
  const qtyInput = document.getElementById('inv-item-qty');
  const priceInput = document.getElementById('inv-item-price');

  const maSP = select.value;
  const soLuong = parseInt(qtyInput.value);
  const donGia = parseFloat(priceInput.value);

  if (!maSP || !soLuong || soLuong <= 0 || !donGia || donGia <= 0) {
    showToast('Vui lòng nhập số lượng và đơn giá nhập hợp lệ (> 0)!', 'error');
    return;
  }

  const product = allProducts.find(p => p.MaSP === maSP);
  const existing = importCart.find(i => i.maSP === maSP);

  if (existing) {
    existing.soLuongNhap += soLuong;
    existing.donGiaNhap = donGia; // cập nhật đơn giá mới nhất
  } else {
    importCart.push({
      maSP,
      tenSP: product?.TenSP || maSP,
      donViTinh: product?.DonViTinh || 'Cái',
      soLuongNhap: soLuong,
      donGiaNhap: donGia
    });
  }

  // Reset inputs
  qtyInput.value = '10';
  renderImportCart();
  showToast(`Đã thêm ${product?.TenSP || maSP} vào danh sách nhập kho.`);
}

function removeImportItem(maSP) {
  importCart = importCart.filter(i => i.maSP !== maSP);
  renderImportCart();
}

function clearImportCart() {
  importCart = [];
  renderImportCart();
}

function renderImportCart() {
  const container = document.getElementById('inv-cart-items');
  const totalEl = document.getElementById('inv-cart-total');
  const submitBtn = document.getElementById('btn-submit-import');

  if (!container) return;

  if (importCart.length === 0) {
    container.innerHTML = `
      <tr>
        <td colspan="5" class="py-8 text-center text-slate-400 text-xs">
          Chưa có sản phẩm nào được chọn để nhập.
        </td>
      </tr>
    `;
    if (totalEl) totalEl.innerText = formatMoney(0);
    if (submitBtn) submitBtn.disabled = true;
    return;
  }

  let total = 0;
  container.innerHTML = importCart.map((item, idx) => {
    const subTotal = item.soLuongNhap * item.donGiaNhap;
    total += subTotal;

    return `
      <tr class="border-b border-slate-100 hover:bg-slate-50/50 text-xs">
        <td class="py-2.5 px-3 font-semibold text-slate-800">${idx + 1}. ${item.tenSP}</td>
        <td class="py-2.5 px-3 text-center font-bold text-slate-700">${item.soLuongNhap} ${item.donViTinh}</td>
        <td class="py-2.5 px-3 text-right font-medium text-slate-600">${formatMoney(item.donGiaNhap)}</td>
        <td class="py-2.5 px-3 text-right font-bold text-emerald-600">${formatMoney(subTotal)}</td>
        <td class="py-2.5 px-3 text-center">
          <button onclick="removeImportItem('${item.maSP}')" class="text-rose-500 hover:text-rose-700">
            <i class="fas fa-trash-alt"></i>
          </button>
        </td>
      </tr>
    `;
  }).join('');

  if (totalEl) totalEl.innerText = formatMoney(total);
  if (submitBtn) submitBtn.disabled = false;
}

// Xác nhận nhập hàng -> Gọi Stored Procedures
async function submitImportReceipt() {
  if (importCart.length === 0) return;

  const supplierSelect = document.getElementById('inv-supplier-select');
  const employeeSelect = document.getElementById('inv-employee-select');
  const dateInput = document.getElementById('inv-date-input');

  const maNCC = supplierSelect.value;
  const maNV = employeeSelect.value;
  const ngayNhap = dateInput.value || null;

  const btn = document.getElementById('btn-submit-import');
  btn.disabled = true;
  btn.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i>Đang nhập kho...`;

  try {
    const payload = {
      maNCC,
      maNV,
      ngayNhap,
      items: importCart
    };

    const res = await API.post('/api/inventory/receipt-full', payload);

    if (res.success) {
      showToast(res.message, 'success');
      clearImportCart();
      await Promise.all([loadProducts(), loadLowStockItems(), loadImportHistory()]);
      renderProducts();
      populateImportProductSelect();
    }
  } catch (err) {
    showToast('Lỗi nhập kho: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = `<i class="fas fa-truck-ramp-box mr-2"></i>Xác nhận Nhập Kho & Tăng Tồn`;
  }
}

// Tải danh sách cảnh báo sắp hết hàng
async function loadLowStockItems() {
  try {
    const items = await API.get('/api/inventory/low-stock');
    const container = document.getElementById('inv-low-stock-list');
    const badge = document.getElementById('inv-low-stock-badge');

    if (badge) badge.innerText = items.length.toString();

    if (!container) return;

    if (items.length === 0) {
      container.innerHTML = `
        <div class="p-6 text-center text-emerald-600 bg-emerald-50 rounded-xl">
          <i class="fas fa-circle-check text-2xl mb-2"></i>
          <p class="text-xs font-semibold">Tất cả sản phẩm đều đủ tồn kho an toàn (> 20).</p>
        </div>
      `;
      return;
    }

    container.innerHTML = items.map(i => `
      <div class="p-3 bg-amber-50/70 border border-amber-200 rounded-xl flex items-center justify-between gap-3 text-xs">
        <div>
          <p class="font-bold text-slate-800">${i.TenSP}</p>
          <p class="text-[11px] text-amber-800 font-mono mt-0.5">Mã: ${i.MaSP} • Tồn hiện tại: <span class="font-bold text-rose-600">${i.SoLuongTon}</span></p>
        </div>
        <button onclick="quickSelectImport('${i.MaSP}')" class="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white font-medium rounded-lg text-[11px] shadow-sm transition-colors whitespace-nowrap">
          <i class="fas fa-plus mr-1"></i>Nhập ngay
        </button>
      </div>
    `).join('');
  } catch (err) {
    console.error('Lỗi tải hàng sắp hết:', err);
  }
}

function quickSelectImport(maSP) {
  const select = document.getElementById('inv-product-select');
  if (select) {
    select.value = maSP;
    onSelectImportProduct();
    document.getElementById('inv-item-qty').focus();
    showToast(`Đã chọn sản phẩm ${maSP} vào biểu mẫu nhập.`);
  }
}

// Tải lịch sử nhập hàng
async function loadImportHistory() {
  try {
    const history = await API.get('/api/inventory/history');
    const container = document.getElementById('inv-history-list');
    if (!container) return;

    if (history.length === 0) {
      container.innerHTML = `<tr><td colspan="6" class="py-6 text-center text-slate-400 text-xs">Chưa có dữ liệu lịch sử nhập hàng</td></tr>`;
      return;
    }

    container.innerHTML = history.slice(0, 15).map(h => `
      <tr class="border-b border-slate-100 hover:bg-slate-50/50 text-xs">
        <td class="py-2 px-3 font-mono font-bold text-indigo-600">${h.MaPN}</td>
        <td class="py-2 px-3 text-slate-500">${new Date(h.NgayNhap).toLocaleDateString('vi-VN')}</td>
        <td class="py-2 px-3 font-medium text-slate-800 truncate max-w-[150px]">${h.TenNCC}</td>
        <td class="py-2 px-3 text-slate-700 truncate max-w-[150px]">${h.TenSP}</td>
        <td class="py-2 px-3 text-center font-bold">${h.SoLuongNhap}</td>
        <td class="py-2 px-3 text-right font-bold text-emerald-600">${formatMoney(h.ThanhTien)}</td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Lỗi tải lịch sử nhập hàng:', err);
  }
}

