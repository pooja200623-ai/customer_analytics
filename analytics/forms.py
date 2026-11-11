from django import forms
from datetime import date
from .models import Customer


class CustomerForm(forms.ModelForm):
    class Meta:
        model = Customer
        fields = [
            'first_name',
            'last_name',
            'email',
            'phone',
            'gender',
            'date_of_birth',
            'segment',
            'address_line1',
            'address_line2',
            'city',
            'state',
            'country',
            'postal_code',
            'is_active',
        ]
        widgets = {
            'first_name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter first name', 'required': True}),
            'last_name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter last name', 'required': True}),
            'email': forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'customer@example.com', 'required': True}),
            'phone': forms.TextInput(attrs={'class': 'form-control', 'placeholder': '10-digit mobile number'}),
            'gender': forms.Select(attrs={'class': 'form-select'}),
            'date_of_birth': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'segment': forms.Select(attrs={'class': 'form-select'}),
            'address_line1': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'House / Flat / Street'}),
            'address_line2': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Area / Landmark'}),
            'city': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'e.g. Mumbai'}),
            'state': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'e.g. Maharashtra'}),
            'country': forms.TextInput(attrs={'class': 'form-control', 'value': 'India'}),
            'postal_code': forms.TextInput(attrs={'class': 'form-control', 'placeholder': '6-digit PIN'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

    def clean_email(self):
        email = self.cleaned_data.get('email', '').strip().lower()
        if not email:
            raise forms.ValidationError("Email is required.")
        qs = Customer.objects.filter(email__iexact=email)
        if self.instance and self.instance.pk:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise forms.ValidationError(f"A customer with the email '{email}' already exists.")
        return email

    def clean_date_of_birth(self):
        dob = self.cleaned_data.get('date_of_birth')
        if dob and dob > date.today():
            raise forms.ValidationError("Date of birth cannot be in the future.")
        return dob

    def clean_first_name(self):
        first_name = self.cleaned_data.get('first_name', '').strip()
        if not first_name:
            raise forms.ValidationError("First name cannot be empty.")
        return first_name

    def clean_last_name(self):
        last_name = self.cleaned_data.get('last_name', '').strip()
        if not last_name:
            raise forms.ValidationError("Last name cannot be empty.")
        return last_name

    def save(self, commit=True):
        instance = super().save(commit=False)
        if not instance.registration_date:
            instance.registration_date = date.today()
        if commit:
            instance.save()
        return instance
