from django.contrib import admin
from django.utils.html import format_html
from .models import Category, Customer, Product, Order, OrderItem, Payment


admin.site.site_header = "Customer Segmentation & Analytics Admin"
admin.site.site_title = "Customer Analytics Portal"
admin.site.index_title = "Database & Behavioral Analytics Management"


class ProductInline(admin.TabularInline):
    model = Product
    extra = 0
    fields = ('product_name', 'sku', 'unit_price', 'stock_quantity', 'is_active')
    show_change_link = True


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    fields = ('product', 'quantity', 'unit_price', 'discount_pct', 'line_total')
    readonly_fields = ('line_total',)
    show_change_link = True


class PaymentInline(admin.TabularInline):
    model = Payment
    extra = 0
    fields = ('payment_date', 'method', 'amount', 'currency', 'status', 'transaction_ref')
    show_change_link = True


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('category_id', 'category_name', 'product_count', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('category_name', 'description')
    ordering = ('category_id',)
    inlines = [ProductInline]

    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = "Products"


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = (
        'customer_id',
        'full_name',
        'email',
        'phone',
        'gender',
        'segment_badge',
        'city',
        'state',
        'registration_date',
        'is_active',
    )
    list_filter = ('segment', 'gender', 'is_active', 'state', 'registration_date')
    search_fields = ('first_name', 'last_name', 'email', 'phone', 'city')
    ordering = ('customer_id',)
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ("Personal Information", {
            'fields': ('first_name', 'last_name', 'email', 'phone', 'gender', 'date_of_birth')
        }),
        ("Segmentation & Status", {
            'fields': ('segment', 'is_active', 'registration_date', 'last_login')
        }),
        ("Address Details", {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'country', 'postal_code')
        }),
        ("Audit Metadata", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def segment_badge(self, obj):
        color_map = {
            'Platinum': '#4B0082',
            'Gold': '#B8860B',
            'Silver': '#708090',
            'Bronze': '#CD7F32',
            'New': '#2E8B57',
        }
        color = color_map.get(obj.segment, '#333333')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 4px; font-weight: bold; font-size: 11px;">{}</span>',
            color,
            obj.segment
        )
    segment_badge.short_description = "Segment"


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        'product_id',
        'product_name',
        'sku',
        'category',
        'brand',
        'unit_price',
        'cost_price',
        'stock_quantity',
        'stock_status',
        'is_active',
    )
    list_filter = ('category', 'brand', 'is_active')
    search_fields = ('product_name', 'sku', 'brand')
    ordering = ('product_id',)
    list_select_related = ('category',)

    fieldsets = (
        ("Basic Information", {
            'fields': ('product_name', 'sku', 'category', 'brand', 'description', 'is_active')
        }),
        ("Pricing & Inventory", {
            'fields': ('unit_price', 'cost_price', 'stock_quantity', 'reorder_level')
        }),
    )

    def stock_status(self, obj):
        if obj.stock_quantity <= obj.reorder_level:
            return format_html(
                '<span style="color: red; font-weight: bold;">Low Stock ({})</span>',
                obj.stock_quantity
            )
        return format_html('<span style="color: green;">In Stock</span>')
    stock_status.short_description = "Stock Status"


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_id',
        'customer',
        'order_date',
        'status_badge',
        'subtotal',
        'discount_amount',
        'tax_amount',
        'shipping_charge',
        'total_amount',
        'shipping_city',
    )
    list_filter = ('status', 'order_date', 'shipping_state')
    search_fields = ('order_id', 'customer__first_name', 'customer__last_name', 'customer__email', 'shipping_city')
    ordering = ('-order_date',)
    list_select_related = ('customer',)
    inlines = [OrderItemInline, PaymentInline]

    fieldsets = (
        ("Order Overview", {
            'fields': ('customer', 'order_date', 'status', 'notes')
        }),
        ("Financials", {
            'fields': ('subtotal', 'discount_amount', 'tax_amount', 'shipping_charge', 'total_amount')
        }),
        ("Shipping & Delivery", {
            'fields': (
                'shipping_address', 'shipping_city', 'shipping_state',
                'shipping_country', 'shipping_postal',
                'estimated_delivery', 'actual_delivery'
            )
        }),
    )

    def status_badge(self, obj):
        colors = {
            'Delivered': '#2E8B57',
            'Shipped': '#1E90FF',
            'Processing': '#DAA520',
            'Confirmed': '#6A5ACD',
            'Pending': '#FF8C00',
            'Returned': '#DC143C',
            'Cancelled': '#808080',
        }
        color = colors.get(obj.status, '#333333')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 4px; font-weight: 500; font-size: 11px;">{}</span>',
            color,
            obj.status
        )
    status_badge.short_description = "Status"


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = (
        'order_item_id',
        'order',
        'product',
        'quantity',
        'unit_price',
        'discount_pct',
        'line_total',
    )
    list_filter = ('product__category',)
    search_fields = ('order__order_id', 'product__product_name', 'product__sku')
    list_select_related = ('order', 'product')
    ordering = ('order_item_id',)


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        'payment_id',
        'order',
        'payment_date',
        'method',
        'amount',
        'currency',
        'payment_status_badge',
        'transaction_ref',
        'gateway',
    )
    list_filter = ('method', 'status', 'gateway', 'payment_date')
    search_fields = ('payment_id', 'order__order_id', 'transaction_ref', 'gateway')
    list_select_related = ('order',)
    ordering = ('-payment_date',)

    def payment_status_badge(self, obj):
        colors = {
            'Captured': '#2E8B57',
            'Authorized': '#1E90FF',
            'Pending': '#FF8C00',
            'Refunded': '#DC143C',
            'Partially Refunded': '#BA55D3',
            'Failed': '#B22222',
        }
        color = colors.get(obj.status, '#333333')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 4px; font-weight: 500; font-size: 11px;">{}</span>',
            color,
            obj.status
        )
    payment_status_badge.short_description = "Status"
