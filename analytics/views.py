from django.shortcuts import render, get_object_or_404, redirect
from django.db.models import Sum, Avg, Count, Q
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.contrib import messages
from django.http import JsonResponse
from .models import Customer, Order, OrderItem, Payment
from .forms import CustomerForm


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
        'active_page': 'dashboard',
    }
    return render(request, 'dashboard.html', context)


def customer_list_view(request):
    """
    Display all customer details in a professional table with search,
    filters (Gender, Location/State), pagination, and modal triggers.
    """
    search_query = request.GET.get('search', '').strip()
    gender_filter = request.GET.get('gender', '').strip()
    location_filter = request.GET.get('location', '').strip()

    customers_qs = Customer.objects.all().order_by('customer_id')

    if search_query:
        customers_qs = customers_qs.filter(
            Q(first_name__icontains=search_query) |
            Q(last_name__icontains=search_query) |
            Q(email__icontains=search_query) |
            Q(phone__icontains=search_query) |
            Q(city__icontains=search_query) |
            Q(customer_id__icontains=search_query)
        )

    if gender_filter:
        customers_qs = customers_qs.filter(gender=gender_filter)

    if location_filter:
        customers_qs = customers_qs.filter(
            Q(city__iexact=location_filter) | Q(state__iexact=location_filter)
        )

    # Distinct locations for filter dropdown
    distinct_locations = Customer.objects.exclude(state__isnull=True).exclude(state='').values_list('state', flat=True).distinct().order_by('state')

    # Pagination: 10 customers per page
    paginator = Paginator(customers_qs, 10)
    page_number = request.GET.get('page', 1)
    try:
        page_obj = paginator.page(page_number)
    except PageNotAnInteger:
        page_obj = paginator.page(1)
    except EmptyPage:
        page_obj = paginator.page(paginator.num_pages)

    form = CustomerForm()

    context = {
        'customers': page_obj,
        'page_obj': page_obj,
        'total_count': customers_qs.count(),
        'all_customers_count': Customer.objects.count(),
        'search_query': search_query,
        'gender_filter': gender_filter,
        'location_filter': location_filter,
        'distinct_locations': distinct_locations,
        'form': form,
        'active_page': 'customers',
    }
    return render(request, 'customers.html', context)


def customer_add_view(request):
    """
    Add a new customer with server-side validation and feedback messages.
    """
    if request.method == 'POST':
        form = CustomerForm(request.POST)
        if form.is_valid():
            customer = form.save()
            messages.success(request, f"Customer '{customer.full_name}' was successfully added (ID: #{customer.customer_id}).")
            return redirect('customer_list')
        else:
            for field, errors in form.errors.items():
                for error in errors:
                    messages.error(request, f"{field.replace('_', ' ').capitalize()}: {error}")
    return redirect('customer_list')


def customer_edit_view(request, customer_id):
    """
    Edit an existing customer record.
    """
    customer = get_object_or_404(Customer, pk=customer_id)
    if request.method == 'POST':
        form = CustomerForm(request.POST, instance=customer)
        if form.is_valid():
            form.save()
            messages.success(request, f"Customer #{customer_id} ('{customer.full_name}') updated successfully.")
            return redirect('customer_list')
        else:
            for field, errors in form.errors.items():
                for error in errors:
                    messages.error(request, f"{field.replace('_', ' ').capitalize()}: {error}")
    return redirect('customer_list')


def customer_delete_view(request, customer_id):
    """
    Delete a customer record, checking if linked orders exist.
    """
    customer = get_object_or_404(Customer, pk=customer_id)
    if request.method == 'POST':
        # Check if customer has orders
        order_count = customer.orders.count()
        if order_count > 0:
            messages.error(request, f"Cannot delete customer '{customer.full_name}' because they have {order_count} associated order(s). Consider setting them inactive instead.")
            return redirect('customer_list')
        name = customer.full_name
        customer.delete()
        messages.success(request, f"Customer #{customer_id} ('{name}') was successfully deleted.")
        return redirect('customer_list')
    return redirect('customer_list')


def customer_detail_api(request, customer_id):
    """
    JSON API for dynamic View / Edit modal hydration.
    """
    customer = get_object_or_404(Customer, pk=customer_id)
    orders_data = []
    for order in customer.orders.all().order_by('-order_date')[:5]:
        orders_data.append({
            'order_id': order.order_id,
            'order_date': order.order_date.strftime('%b %d, %Y'),
            'status': order.status,
            'total_amount': f"{order.total_amount:,.2f}",
        })

    data = {
        'customer_id': customer.customer_id,
        'first_name': customer.first_name,
        'last_name': customer.last_name,
        'full_name': customer.full_name,
        'email': customer.email,
        'phone': customer.phone or 'N/A',
        'gender': customer.gender,
        'age': customer.age if customer.age is not None else 'N/A',
        'date_of_birth': customer.date_of_birth.strftime('%Y-%m-%d') if customer.date_of_birth else '',
        'formatted_dob': customer.date_of_birth.strftime('%b %d, %Y') if customer.date_of_birth else 'N/A',
        'segment': customer.segment,
        'address_line1': customer.address_line1 or '',
        'address_line2': customer.address_line2 or '',
        'city': customer.city or 'N/A',
        'state': customer.state or 'N/A',
        'country': customer.country or 'India',
        'postal_code': customer.postal_code or 'N/A',
        'full_location': f"{customer.city or ''}, {customer.state or ''}".strip(', ') or 'N/A',
        'is_active': customer.is_active,
        'registration_date': customer.registration_date.strftime('%b %d, %Y') if customer.registration_date else 'N/A',
        'last_login': customer.last_login.strftime('%b %d, %Y %I:%M %p') if customer.last_login else 'Never',
        'order_count': customer.orders.count(),
        'total_spent': f"{customer.orders.aggregate(total=Sum('total_amount'))['total'] or 0:,.2f}",
        'recent_orders': orders_data,
    }
    return JsonResponse(data)
