"""
URL configuration for customer_analytics project.
"""
from django.contrib import admin
from django.urls import path
from analytics.views import (
    dashboard_view,
    customer_list_view,
    customer_add_view,
    customer_edit_view,
    customer_delete_view,
    customer_detail_api,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', dashboard_view, name='dashboard'),
    path('customers/', customer_list_view, name='customer_list'),
    path('customers/add/', customer_add_view, name='customer_add'),
    path('customers/<int:customer_id>/edit/', customer_edit_view, name='customer_edit'),
    path('customers/<int:customer_id>/delete/', customer_delete_view, name='customer_delete'),
    path('customers/<int:customer_id>/detail/', customer_detail_api, name='customer_detail_api'),
]
