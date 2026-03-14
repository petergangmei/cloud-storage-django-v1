from django import forms
from .models import CloudMedia


class CloudMediaForm(forms.ModelForm):
    class Meta:
        model = CloudMedia
        fields = ["file", "title", "media_type"]
        widgets = {
            "title": forms.TextInput(
                attrs={
                    "class": "form-control",
                    "placeholder": "Enter title (optional)",
                }
            ),
            "media_type": forms.Select(attrs={"class": "form-select"}),
            "file": forms.FileInput(attrs={"class": "form-control"}),
        }
