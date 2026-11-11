/**
 * Customer Management Interactive Logic
 * Handles View Modal (AJAX fetch), Edit Modal (hydration), and Delete Confirmation.
 */

document.addEventListener('DOMContentLoaded', function () {
  // 1. Generic Modal Helpers
  window.openModal = function (modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('active');
      document.body.style.overflow = 'hidden';
    }
  };

  window.closeModal = function (modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('active');
      document.body.style.overflow = 'auto';
    }
  };

  // Close modals when clicking the backdrop
  document.querySelectorAll('.modal-backdrop-custom').forEach(backdrop => {
    backdrop.addEventListener('click', function (e) {
      if (e.target === this) {
        this.classList.remove('active');
        document.body.style.overflow = 'auto';
      }
    });
  });

  // 2. View Customer Details via AJAX API
  window.viewCustomer = function (customerId) {
    openModal('viewCustomerModal');
    const loadingElem = document.getElementById('viewModalLoading');
    const contentElem = document.getElementById('viewModalContent');
    
    if (loadingElem) loadingElem.style.display = 'block';
    if (contentElem) contentElem.style.display = 'none';

    fetch(`/customers/${customerId}/detail/`)
      .then(res => {
        if (!res.ok) throw new Error('Customer record not found');
        return res.json();
      })
      .then(data => {
        if (loadingElem) loadingElem.style.display = 'none';
        if (contentElem) contentElem.style.display = 'block';

        // Populate details
        document.getElementById('viewCustomerTitle').innerText = `${data.full_name} (ID: #${data.customer_id})`;
        document.getElementById('viewFullName').innerText = data.full_name;
        document.getElementById('viewEmail').innerText = data.email;
        document.getElementById('viewPhone').innerText = data.phone;
        document.getElementById('viewGender').innerText = data.gender;
        document.getElementById('viewAge').innerText = data.age !== 'N/A' ? `${data.age} yrs (${data.formatted_dob})` : 'N/A';
        document.getElementById('viewLocation').innerText = data.full_location;
        document.getElementById('viewAddress1').innerText = data.address_line1 || 'N/A';
        document.getElementById('viewAddress2').innerText = data.address_line2 || 'N/A';
        document.getElementById('viewPostal').innerText = data.postal_code;
        document.getElementById('viewRegDate').innerText = data.registration_date;
        document.getElementById('viewLastLogin').innerText = data.last_login;
        document.getElementById('viewOrdersCount').innerText = `${data.order_count} orders`;
        document.getElementById('viewTotalSpent').innerText = `₹${data.total_spent}`;

        // Status badge
        const statusSpan = document.getElementById('viewStatus');
        if (data.is_active) {
          statusSpan.innerHTML = '<span class="badge delivered"><span class="badge-dot"></span>Active Customer</span>';
        } else {
          statusSpan.innerHTML = '<span class="badge returned"><span class="badge-dot"></span>Inactive</span>';
        }

        // Segment badge
        const segmentSpan = document.getElementById('viewSegment');
        const segLower = (data.segment || 'new').toLowerCase();
        segmentSpan.innerHTML = `<span class="segment-tag ${segLower}">${data.segment}</span>`;

        // Populate recent order lines
        const ordersList = document.getElementById('viewRecentOrders');
        if (ordersList) {
          if (data.recent_orders && data.recent_orders.length > 0) {
            ordersList.innerHTML = data.recent_orders.map(o => `
              <li style="display:flex; justify-content:space-between; padding:8px 0; border-bottom:1px solid #f1f5f9; font-size:12.5px;">
                <span><strong>#ORD-${o.order_id}</strong> &bull; ${o.order_date}</span>
                <span>₹${o.total_amount} <strong style="color:#2563eb;">(${o.status})</strong></span>
              </li>
            `).join('');
          } else {
            ordersList.innerHTML = '<li style="color:#94a3b8; font-size:12.5px; padding:6px 0;">No order transactions placed yet.</li>';
          }
        }
      })
      .catch(err => {
        if (loadingElem) {
          loadingElem.innerHTML = `<p style="color:#ef4444; font-weight:600;">Error fetching customer data: ${err.message}</p>`;
        }
      });
  };

  // 3. Edit Customer Record
  window.editCustomer = function (customerId) {
    fetch(`/customers/${customerId}/detail/`)
      .then(res => res.json())
      .then(data => {
        const form = document.getElementById('editCustomerForm');
        form.action = `/customers/${customerId}/edit/`;

        document.getElementById('edit_first_name').value = data.first_name;
        document.getElementById('edit_last_name').value = data.last_name;
        document.getElementById('edit_email').value = data.email;
        document.getElementById('edit_phone').value = data.phone !== 'N/A' ? data.phone : '';
        document.getElementById('edit_gender').value = data.gender;
        document.getElementById('edit_date_of_birth').value = data.date_of_birth;
        document.getElementById('edit_segment').value = data.segment;
        document.getElementById('edit_address_line1').value = data.address_line1;
        document.getElementById('edit_address_line2').value = data.address_line2;
        document.getElementById('edit_city').value = data.city !== 'N/A' ? data.city : '';
        document.getElementById('edit_state').value = data.state !== 'N/A' ? data.state : '';
        document.getElementById('edit_country').value = data.country;
        document.getElementById('edit_postal_code').value = data.postal_code !== 'N/A' ? data.postal_code : '';
        document.getElementById('edit_is_active').checked = data.is_active;

        document.getElementById('editModalHeaderId').innerText = `#${customerId}`;
        openModal('editCustomerModal');
      })
      .catch(err => {
        alert('Failed to load customer for editing: ' + err.message);
      });
  };

  // 4. Delete Customer Confirmation
  window.confirmDeleteCustomer = function (customerId, customerName) {
    const deleteForm = document.getElementById('deleteCustomerForm');
    deleteForm.action = `/customers/${customerId}/delete/`;
    document.getElementById('deleteCustomerName').innerText = customerName;
    document.getElementById('deleteCustomerId').innerText = customerId;
    openModal('deleteCustomerModal');
  };
});
