// POS (Bán hàng & Thu ngân) State & Handlers
let allProducts = [];
let categories = [];
let cart = [];
let employees = [];
let customers = [];
let selectedCategory = 'ALL';
let currentReceipt = null;

// Khởi tạo POS
async function initPOS() {
  await Promise.all([loadProducts(), loadCategories(), loadPartners()]);
  renderCategories();
  renderProducts();
  renderCart();
}

// Tải danh mục
async function loadCategories() {
  try {
    categories = await API.get('/api/categories');
  } catch (err) {
    showToast('Lỗi tải danh mục: ' + err.message, 'error');
  }
}

// Tải sản phẩm
async function loadProducts() {
  try {
    allProducts = await API.get('/api/products');
  } catch (err) {
    showToast('Lỗi tải sản phẩm: ' + err.message, 'error');
  }
}

// Tải nhân viên và khách hàng
async function loadPartners() {
  try {
    [employees, customers] = await Promise.all([
      API.get('/api/partners/employees'),
      API.get('/api/partners/customers')
    ]);
    populateCashierSelect();
    populateCustomerSelect();
  } catch (err) {
    console.error('Lỗi nạp đối tác:', err);
  }
}

function populateCashierSelect() {
  const select = document.getElementById('pos-cashier-select');
  if (!select) return;
  select.innerHTML = employees
    .map(e => `<option value="${e.MaNV}">${e.HoTen} (${e.ChucVu})</option>`)
    .join('');
}

function populateCustomerSelect() {
  const select = document.getElementById('pos-customer-select');
  if (!select) return;
  let html = `<option value="">Khách vãng lai (Không tích điểm)</option>`;
  html += customers
    .map(c => `<option value="${c.MaKH}">${c.HoTen} - ${c.DienThoai} (${c.DiemTichLuy} điểm)</option>`)
    .join('');
  select.innerHTML = html;
}

// Render các nút danh mục
function renderCategories() {
  const container = document.getElementById('category-pills');
  if (!container) return;

  let html = `
    <button onclick="filterCategory('ALL')" 
            class="px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${selectedCategory === 'ALL' ? 'bg-emerald-600 text-white shadow-sm' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'}">
      Tất cả (${allProducts.length})
    </button>
  `;

  categories.forEach(c => {
    const count = allProducts.filter(p => p.MaDM === c.MaDM).length;
    const isSelected = selectedCategory === c.MaDM;
    html += `
      <button onclick="filterCategory('${c.MaDM}')" 
              class="px-3 py-1.5 rounded-full text-xs font-medium transition-colors whitespace-nowrap ${isSelected ? 'bg-emerald-600 text-white shadow-sm' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'}">
        ${c.TenDM} (${count})
      </button>
    `;
  });

  container.innerHTML = html;
}

function filterCategory(catId) {
  selectedCategory = catId;
  renderCategories();
  renderProducts();
}

// Tìm kiếm sản phẩm
function onSearchProducts() {
  renderProducts();
}

// Render danh sách thẻ sản phẩm
function renderProducts() {
  const container = document.getElementById('pos-products-grid');
  if (!container) return;

  const keyword = (document.getElementById('pos-search-input')?.value || '').trim().toLowerCase();

  const filtered = allProducts.filter(p => {
    const matchCat = selectedCategory === 'ALL' || p.MaDM === selectedCategory;
    const matchKey = !keyword || p.TenSP.toLowerCase().includes(keyword) || p.MaSP.toLowerCase().includes(keyword);
    return matchCat && matchKey;
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="col-span-full py-12 text-center text-slate-400">
        <i class="fas fa-box-open text-4xl mb-3"></i>
        <p>Không tìm thấy sản phẩm nào phù hợp</p>
      </div>
    `;
    return;
  }

  // Phân loại icon theo danh mục
  const catIcons = {
    'DM01': 'fa-bowl-rice text-amber-600',
    'DM02': 'fa-pump-soap text-sky-600',
    'DM03': 'fa-bottle-water text-blue-600',
    'DM04': 'fa-cow text-purple-600',
    'DM05': 'fa-egg text-emerald-600',
    'DM06': 'fa-kitchen-set text-rose-600',
    'DM07': 'fa-cookie-bite text-orange-600',
    'DM08': 'fa-pen-ruler text-indigo-600'
  };

  container.innerHTML = filtered.map(p => {
    const iconClass = catIcons[p.MaDM] || 'fa-box text-slate-600';
    const isOutOfStock = p.SoLuongTon <= 0;
    const isLowStock = p.SoLuongTon > 0 && p.SoLuongTon <= 20;

    const stockBadge = isOutOfStock
      ? `<span class="bg-rose-100 text-rose-700 text-[10px] font-semibold px-2 py-0.5 rounded-full">Hết hàng</span>`
      : (isLowStock 
          ? `<span class="bg-amber-100 text-amber-700 text-[10px] font-semibold px-2 py-0.5 rounded-full">Còn: ${p.SoLuongTon} ${p.DonViTinh}</span>`
          : `<span class="bg-emerald-100 text-emerald-700 text-[10px] font-semibold px-2 py-0.5 rounded-full">Tồn: ${p.SoLuongTon}</span>`);

    return `
      <div onclick="addToCart('${p.MaSP}')" 
           class="product-card bg-white p-3 rounded-xl border border-slate-200 cursor-pointer flex flex-col justify-between select-none relative ${isOutOfStock ? 'opacity-60 pointer-events-none' : ''}">
        <div>
          <div class="flex items-start justify-between gap-2 mb-2">
            <span class="w-8 h-8 rounded-lg bg-slate-50 flex items-center justify-center text-sm">
              <i class="fas ${iconClass}"></i>
            </span>
            ${stockBadge}
          </div>
          <p class="text-xs font-bold text-slate-800 line-clamp-2 mb-1" title="${p.TenSP}">${p.TenSP}</p>
          <p class="text-[11px] text-slate-400 font-mono">${p.MaSP} • ${p.DonViTinh}</p>
        </div>
        <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between">
          <span class="text-sm font-bold text-emerald-600">${formatMoney(p.GiaBan)}</span>
          <button class="w-6 h-6 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center hover:bg-emerald-600 hover:text-white transition-colors">
            <i class="fas fa-plus text-xs"></i>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// Thêm vào giỏ hàng
function addToCart(maSP) {
  const product = allProducts.find(p => p.MaSP === maSP);
  if (!product) return;

  if (product.SoLuongTon <= 0) {
    showToast(`Sản phẩm "${product.TenSP}" đã hết hàng!`, 'error');
    return;
  }

  const existing = cart.find(item => item.maSP === maSP);
  if (existing) {
    if (existing.soLuong + 1 > product.SoLuongTon) {
      showToast(`Số lượng trong giỏ (${existing.soLuong + 1}) vượt quá tồn kho hiện có (${product.SoLuongTon})!`, 'error');
      return;
    }
    existing.soLuong += 1;
  } else {
    cart.push({
      maSP: product.MaSP,
      tenSP: product.TenSP,
      donViTinh: product.DonViTinh,
      giaBan: product.GiaBan,
      soLuong: 1,
      soLuongTon: product.SoLuongTon
    });
  }

  renderCart();
}

// Tăng / Giảm số lượng
function updateCartQty(maSP, delta) {
  const item = cart.find(i => i.maSP === maSP);
  if (!item) return;

  const newQty = item.soLuong + delta;
  if (newQty <= 0) {
    removeFromCart(maSP);
    return;
  }

  if (newQty > item.soLuongTon) {
    showToast(`Vượt quá số lượng tồn kho (${item.soLuongTon})!`, 'error');
    return;
  }

  item.soLuong = newQty;
  renderCart();
}

// Xóa khỏi giỏ hàng
function removeFromCart(maSP) {
  cart = cart.filter(i => i.maSP !== maSP);
  renderCart();
}

// Xóa toàn bộ giỏ hàng
function clearCart() {
  if (cart.length === 0) return;
  if (confirm('Bạn có chắc muốn làm mới giỏ hàng hiện tại?')) {
    cart = [];
    renderCart();
    showToast('Đã làm mới giỏ hàng');
  }
}

// Render giỏ hàng & tổng tiền
function renderCart() {
  const container = document.getElementById('pos-cart-items');
  const countBadge = document.getElementById('cart-item-count');
  const totalAmountEl = document.getElementById('cart-total-amount');
  const pointsEl = document.getElementById('cart-reward-points');
  const checkoutBtn = document.getElementById('btn-checkout');

  if (!container) return;

  if (cart.length === 0) {
    container.innerHTML = `
      <div class="h-64 flex flex-col items-center justify-center text-slate-300">
        <i class="fas fa-shopping-basket text-5xl mb-3"></i>
        <p class="text-sm font-medium">Giỏ hàng đang trống</p>
        <p class="text-xs text-slate-400 mt-1">Bấm vào sản phẩm bên trái để thêm</p>
      </div>
    `;
    if (countBadge) countBadge.innerText = '0';
    if (totalAmountEl) totalAmountEl.innerText = formatMoney(0);
    if (pointsEl) pointsEl.innerText = '0';
    if (checkoutBtn) checkoutBtn.disabled = true;
    return;
  }

  let totalMoney = 0;
  let totalItems = 0;

  container.innerHTML = cart.map(item => {
    const itemTotal = item.soLuong * item.giaBan;
    totalMoney += itemTotal;
    totalItems += item.soLuong;

    return `
      <div class="p-3 bg-slate-50 rounded-xl border border-slate-200/80 flex items-center justify-between gap-3 text-sm">
        <div class="flex-1 min-w-0">
          <p class="font-semibold text-slate-800 truncate">${item.tenSP}</p>
          <div class="text-xs text-slate-500 mt-0.5 flex items-center gap-2">
            <span>${formatMoney(item.giaBan)}</span>
            <span>•</span>
            <span class="font-mono text-[11px] text-slate-400">Tồn: ${item.soLuongTon}</span>
          </div>
        </div>

        <!-- Controls số lượng -->
        <div class="flex items-center gap-1.5 bg-white px-2 py-1 rounded-lg border border-slate-200">
          <button onclick="updateCartQty('${item.maSP}', -1)" class="w-5 h-5 text-slate-500 hover:text-slate-800 flex items-center justify-center">
            <i class="fas fa-minus text-[10px]"></i>
          </button>
          <span class="w-6 text-center font-bold text-xs text-slate-800">${item.soLuong}</span>
          <button onclick="updateCartQty('${item.maSP}', 1)" class="w-5 h-5 text-slate-500 hover:text-slate-800 flex items-center justify-center">
            <i class="fas fa-plus text-[10px]"></i>
          </button>
        </div>

        <div class="text-right min-w-[70px]">
          <p class="font-bold text-emerald-600">${formatMoney(itemTotal)}</p>
          <button onclick="removeFromCart('${item.maSP}')" class="text-[11px] text-rose-500 hover:underline">Xóa</button>
        </div>
      </div>
    `;
  }).join('');

  const points = Math.floor(totalMoney / 10000);

  if (countBadge) countBadge.innerText = totalItems.toString();
  if (totalAmountEl) totalAmountEl.innerText = formatMoney(totalMoney);
  if (pointsEl) pointsEl.innerText = `+${points} điểm`;
  if (checkoutBtn) checkoutBtn.disabled = false;
}

// Mở Modal Thanh toán
function openCheckoutModal() {
  if (cart.length === 0) {
    showToast('Giỏ hàng đang trống, chưa thể thanh toán!', 'error');
    return;
  }

  const cashierSelect = document.getElementById('pos-cashier-select');
  const customerSelect = document.getElementById('pos-customer-select');

  const total = cart.reduce((sum, i) => sum + i.soLuong * i.giaBan, 0);
  const points = Math.floor(total / 10000);

  document.getElementById('modal-total-amount').innerText = formatMoney(total);
  document.getElementById('modal-points-earn').innerText = `+${points} điểm`;
  
  // Tên khách hàng & thu ngân
  const custName = customerSelect.options[customerSelect.selectedIndex]?.text || 'Khách vãng lai';
  const cashName = cashierSelect.options[cashierSelect.selectedIndex]?.text || 'Thu ngân';

  document.getElementById('modal-cust-name').innerText = custName;
  document.getElementById('modal-cashier-name').innerText = cashName;

  // Tiền khách đưa mặc định
  const cashInput = document.getElementById('modal-cash-received');
  if (cashInput) {
    cashInput.value = total;
    calculateChange();
  }

  document.getElementById('checkout-modal').classList.remove('hidden');
}

function closeCheckoutModal() {
  document.getElementById('checkout-modal').classList.add('hidden');
}

// Tính tiền thối lại cho khách
function calculateChange() {
  const total = cart.reduce((sum, i) => sum + i.soLuong * i.giaBan, 0);
  const cashInput = document.getElementById('modal-cash-received');
  const changeEl = document.getElementById('modal-cash-change');
  
  const given = parseFloat(cashInput?.value || 0);
  const change = given - total;

  if (changeEl) {
    if (change < 0) {
      changeEl.innerHTML = `<span class="text-rose-600 font-bold">Còn thiếu ${formatMoney(Math.abs(change))}</span>`;
    } else {
      changeEl.innerHTML = `<span class="text-emerald-600 font-bold">${formatMoney(change)}</span>`;
    }
  }
}

// Xác nhận thanh toán từ Modal
async function confirmCheckout() {
  const cashierSelect = document.getElementById('pos-cashier-select');
  const customerSelect = document.getElementById('pos-customer-select');
  const methodSelect = document.getElementById('modal-payment-method');

  const maNV = cashierSelect.value;
  const maKH = customerSelect.value || null;
  const phuongThuc = methodSelect.value;

  const btn = document.getElementById('btn-confirm-checkout');
  btn.disabled = true;
  btn.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i>Đang xử lý...`;

  try {
    const payload = {
      maNV,
      maKH,
      phuongThuc,
      items: cart.map(i => ({ maSP: i.maSP, soLuong: i.soLuong }))
    };

    const res = await API.post('/api/pos/checkout-full', payload);

    if (res.success && res.receipt) {
      currentReceipt = res.receipt;
      closeCheckoutModal();
      showToast('Thanh toán thành công! Tồn kho đã được tự động trừ.', 'success');
      
      // Xóa giỏ hàng & tải lại dữ liệu sản phẩm mới nhất
      cart = [];
      renderCart();
      await loadProducts();
      renderProducts();
      await loadPartners();

      // Mở modal hóa đơn nhiệt cho phép in
      openReceiptModal(currentReceipt);
    }
  } catch (err) {
    showToast('Lỗi thanh toán: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = `<i class="fas fa-check-circle mr-2"></i>Hoàn tất thanh toán`;
  }
}

// Mở Modal Hóa đơn in nhiệt
function openReceiptModal(receipt) {
  if (!receipt) return;

  document.getElementById('rec-invoice-id').innerText = receipt.MaHD;
  document.getElementById('rec-datetime').innerText = formatDateTime(receipt.NgayLap);
  document.getElementById('rec-cashier').innerText = receipt.TenNhanVien;
  document.getElementById('rec-customer').innerText = receipt.TenKhachHang;
  document.getElementById('rec-payment-method').innerText = receipt.PhuongThuc;
  document.getElementById('rec-total').innerText = formatMoney(receipt.TongTien);
  document.getElementById('rec-points-earned').innerText = `+${receipt.DiemNhanDuoc || 0} điểm`;
  document.getElementById('rec-total-points').innerText = `${receipt.DiemTichLuy || 0} điểm`;

  const itemsContainer = document.getElementById('rec-items-list');
  if (itemsContainer && receipt.items) {
    itemsContainer.innerHTML = receipt.items.map(i => `
      <div class="flex justify-between py-1 border-b border-dashed border-slate-200">
        <div>
          <p class="font-bold">${i.TenSP}</p>
          <p class="text-[11px] text-slate-500">${i.SoLuong} x ${formatMoney(i.DonGia)}</p>
        </div>
        <p class="font-bold self-end">${formatMoney(i.ThanhTien)}</p>
      </div>
    `).join('');
  }

  document.getElementById('receipt-modal').classList.remove('hidden');
}

function closeReceiptModal() {
  document.getElementById('receipt-modal').classList.add('hidden');
}

// In hóa đơn nhiệt
function printReceipt() {
  window.print();
}

// Mở Modal thêm nhanh khách hàng
function openAddCustomerModal() {
  document.getElementById('new-cust-name').value = '';
  document.getElementById('new-cust-phone').value = '';
  document.getElementById('add-customer-modal').classList.remove('hidden');
}

function closeAddCustomerModal() {
  document.getElementById('add-customer-modal').classList.add('hidden');
}

async function submitNewCustomer() {
  const hoTen = document.getElementById('new-cust-name').value.trim();
  const dienThoai = document.getElementById('new-cust-phone').value.trim();

  if (!hoTen || !dienThoai) {
    showToast('Vui lòng nhập họ tên và số điện thoại!', 'error');
    return;
  }

  try {
    const res = await API.post('/api/partners/customers', { hoTen, dienThoai });
    if (res.success) {
      showToast(`Đã thêm khách hàng ${hoTen} (${res.maKH})!`);
      closeAddCustomerModal();
      await loadPartners();
      // Chọn ngay khách hàng này vào POS
      const custSelect = document.getElementById('pos-customer-select');
      if (custSelect) custSelect.value = res.maKH;
    }
  } catch (err) {
    showToast('Lỗi: ' + err.message, 'error');
  }
}

