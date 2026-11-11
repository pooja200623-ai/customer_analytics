from django.shortcuts import render
from django.db.models import Sum, Avg, Count
from .models import Customer, Order, OrderItem, Payment


def dashboard_view(request):
    """
    Renders the executive dashboard with real-time statistics from the database.
    """
    total_customers = Customer.objects.count()
    active_customers = Customer.objects.filter(is_active=True).count()
    total_orders = Order.objects.count()
    total_revenue = Order.objects.aggregate(total=Sum('total_amount'))['total'] or 0
    avg_order_value = Order.objects.aggregate(avg=Avg('total_amount'))['avg'] or 0

    recent_orders = Order.objects.select_related('customer').order_by('-order_date')[:6]

    context = {
        'total_customers': total_customers,
        'active_customers': active_customers,
        'total_orders': total_orders,
        'total_revenue': total_revenue,
        'avg_order_value': avg_order_value,
        'recent_orders': recent_orders,
    }
    return render(request, 'dashboard.html', context)
