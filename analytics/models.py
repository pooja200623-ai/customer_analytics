from django.db import models


class Category(models.Model):
    category_id = models.AutoField(primary_key=True)
    category_name = models.CharField(max_length=100, unique=True, verbose_name="Category Name")
    description = models.TextField(blank=True, null=True, verbose_name="Description")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        db_table = 'categories'
        verbose_name = "Category"
        verbose_name_plural = "Categories"
        ordering = ['category_id']

    def __str__(self):
        return self.category_name


class Customer(models.Model):
    class GenderChoices(models.TextChoices):
        MALE = 'Male', 'Male'
        FEMALE = 'Female', 'Female'
        OTHER = 'Other', 'Other'
        PREFER_NOT_TO_SAY = 'Prefer not to say', 'Prefer not to say'

    class SegmentChoices(models.TextChoices):
        NEW = 'New', 'New'
        BRONZE = 'Bronze', 'Bronze'
        SILVER = 'Silver', 'Silver'
        GOLD = 'Gold', 'Gold'
        PLATINUM = 'Platinum', 'Platinum'

    customer_id = models.AutoField(primary_key=True)
    first_name = models.CharField(max_length=60, verbose_name="First Name")
    last_name = models.CharField(max_length=60, verbose_name="Last Name")
    email = models.EmailField(max_length=150, unique=True, verbose_name="Email Address")
    phone = models.CharField(max_length=20, blank=True, null=True, verbose_name="Phone Number")
    gender = models.CharField(
        max_length=20,
        choices=GenderChoices.choices,
        default=GenderChoices.PREFER_NOT_TO_SAY,
        verbose_name="Gender"
    )
    date_of_birth = models.DateField(blank=True, null=True, verbose_name="Date of Birth")
    segment = models.CharField(
        max_length=20,
        choices=SegmentChoices.choices,
        default=SegmentChoices.NEW,
        verbose_name="Customer Segment"
    )
    address_line1 = models.CharField(max_length=200, blank=True, null=True, verbose_name="Address Line 1")
    address_line2 = models.CharField(max_length=200, blank=True, null=True, verbose_name="Address Line 2")
    city = models.CharField(max_length=100, blank=True, null=True, verbose_name="City")
    state = models.CharField(max_length=100, blank=True, null=True, verbose_name="State")
    country = models.CharField(max_length=100, default='India', verbose_name="Country")
    postal_code = models.CharField(max_length=20, blank=True, null=True, verbose_name="Postal Code")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    registration_date = models.DateField(verbose_name="Registration Date")
    last_login = models.DateTimeField(blank=True, null=True, verbose_name="Last Login")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        db_table = 'customers'
        verbose_name = "Customer"
        verbose_name_plural = "Customers"
        ordering = ['customer_id']

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    def __str__(self):
        return f"{self.full_name} ({self.email})"


class Product(models.Model):
    product_id = models.AutoField(primary_key=True)
    category = models.ForeignKey(
        Category,
        on_delete=models.RESTRICT,
        related_name='products',
        db_column='category_id',
        verbose_name="Category"
    )
    product_name = models.CharField(max_length=200, verbose_name="Product Name")
    sku = models.CharField(max_length=50, unique=True, verbose_name="SKU")
    description = models.TextField(blank=True, null=True, verbose_name="Description")
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Unit Price (INR)")
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True, verbose_name="Cost Price (INR)")
    stock_quantity = models.IntegerField(default=0, verbose_name="Stock Quantity")
    reorder_level = models.IntegerField(default=10, verbose_name="Reorder Level")
    brand = models.CharField(max_length=100, blank=True, null=True, verbose_name="Brand")
    is_active = models.BooleanField(default=True, verbose_name="Is Active")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        db_table = 'products'
        verbose_name = "Product"
        verbose_name_plural = "Products"
        ordering = ['product_id']

    def __str__(self):
        return f"{self.product_name} ({self.sku})"


class Order(models.Model):
    class StatusChoices(models.TextChoices):
        PENDING = 'Pending', 'Pending'
        CONFIRMED = 'Confirmed', 'Confirmed'
        PROCESSING = 'Processing', 'Processing'
        SHIPPED = 'Shipped', 'Shipped'
        DELIVERED = 'Delivered', 'Delivered'
        CANCELLED = 'Cancelled', 'Cancelled'
        RETURNED = 'Returned', 'Returned'

    order_id = models.AutoField(primary_key=True)
    customer = models.ForeignKey(
        Customer,
        on_delete=models.RESTRICT,
        related_name='orders',
        db_column='customer_id',
        verbose_name="Customer"
    )
    order_date = models.DateTimeField(verbose_name="Order Date")
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING,
        verbose_name="Order Status"
    )
    shipping_address = models.CharField(max_length=300, blank=True, null=True, verbose_name="Shipping Address")
    shipping_city = models.CharField(max_length=100, blank=True, null=True, verbose_name="Shipping City")
    shipping_state = models.CharField(max_length=100, blank=True, null=True, verbose_name="Shipping State")
    shipping_country = models.CharField(max_length=100, default='India', verbose_name="Shipping Country")
    shipping_postal = models.CharField(max_length=20, blank=True, null=True, verbose_name="Shipping Postal Code")
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name="Subtotal (INR)")
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name="Discount Amount (INR)")
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name="Tax Amount (INR)")
    shipping_charge = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name="Shipping Charge (INR)")
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name="Total Amount (INR)")
    estimated_delivery = models.DateField(blank=True, null=True, verbose_name="Estimated Delivery")
    actual_delivery = models.DateField(blank=True, null=True, verbose_name="Actual Delivery")
    notes = models.TextField(blank=True, null=True, verbose_name="Notes")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        db_table = 'orders'
        verbose_name = "Order"
        verbose_name_plural = "Orders"
        ordering = ['-order_date']

    def __str__(self):
        return f"Order #{self.order_id} - {self.customer.full_name} ({self.status})"


class OrderItem(models.Model):
    order_item_id = models.AutoField(primary_key=True)
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items',
        db_column='order_id',
        verbose_name="Order"
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.RESTRICT,
        related_name='order_items',
        db_column='product_id',
        verbose_name="Product"
    )
    quantity = models.PositiveIntegerField(default=1, verbose_name="Quantity")
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Unit Price (INR)")
    discount_pct = models.DecimalField(max_digits=5, decimal_places=2, default=0.00, verbose_name="Discount %")
    line_total = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Line Total (INR)")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")

    class Meta:
        db_table = 'order_items'
        verbose_name = "Order Item"
        verbose_name_plural = "Order Items"
        unique_together = (('order', 'product'),)
        ordering = ['order_item_id']

    def __str__(self):
        return f"Order #{self.order_id} - {self.product.product_name} (x{self.quantity})"


class Payment(models.Model):
    class MethodChoices(models.TextChoices):
        CREDIT_CARD = 'Credit Card', 'Credit Card'
        DEBIT_CARD = 'Debit Card', 'Debit Card'
        NET_BANKING = 'Net Banking', 'Net Banking'
        UPI = 'UPI', 'UPI'
        WALLET = 'Wallet', 'Wallet'
        CASH_ON_DELIVERY = 'Cash on Delivery', 'Cash on Delivery'
        EMI = 'EMI', 'EMI'

    class StatusChoices(models.TextChoices):
        PENDING = 'Pending', 'Pending'
        AUTHORIZED = 'Authorized', 'Authorized'
        CAPTURED = 'Captured', 'Captured'
        FAILED = 'Failed', 'Failed'
        REFUNDED = 'Refunded', 'Refunded'
        PARTIALLY_REFUNDED = 'Partially Refunded', 'Partially Refunded'

    payment_id = models.AutoField(primary_key=True)
    order = models.ForeignKey(
        Order,
        on_delete=models.RESTRICT,
        related_name='payments',
        db_column='order_id',
        verbose_name="Order"
    )
    payment_date = models.DateTimeField(verbose_name="Payment Date")
    method = models.CharField(
        max_length=20,
        choices=MethodChoices.choices,
        verbose_name="Payment Method"
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Amount (INR)")
    currency = models.CharField(max_length=3, default='INR', verbose_name="Currency")
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING,
        verbose_name="Payment Status"
    )
    transaction_ref = models.CharField(
        max_length=100,
        unique=True,
        blank=True,
        null=True,
        verbose_name="Transaction Reference"
    )
    gateway = models.CharField(max_length=60, blank=True, null=True, verbose_name="Payment Gateway")
    notes = models.CharField(max_length=300, blank=True, null=True, verbose_name="Notes")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Created At")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Updated At")

    class Meta:
        db_table = 'payments'
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ['-payment_date']

    def __str__(self):
        return f"Payment #{self.payment_id} for Order #{self.order_id} - ₹{self.amount} ({self.status})"
