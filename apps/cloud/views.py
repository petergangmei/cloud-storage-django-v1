from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView
from .forms import CloudMediaForm
from .models import CloudMedia
from django.template.loader import render_to_string


class MediaListView(LoginRequiredMixin, ListView):
    model = CloudMedia
    template_name = "cloud/media_list.html"
    context_object_name = "media_items"

    def get_queryset(self):
        return CloudMedia.objects.filter(user=self.request.user)


from django.http import JsonResponse


from django.shortcuts import redirect


class MediaUploadView(LoginRequiredMixin, CreateView):
    model = CloudMedia
    form_class = CloudMediaForm
    success_url = reverse_lazy("cloud:media_list")

    def get(self, request, *args, **kwargs):
        return redirect("cloud:media_list")

    def get_form(self, form_class=None):
        form = super().get_form(form_class)
        if 'media_type' in form.fields:
            form.fields['media_type'].required = False
            # Also ensure it doesn't have the default 'required' attribute in HTML
            form.fields['media_type'].widget.attrs.pop('required', None)
        return form

    def form_valid(self, form):
        form.instance.user = self.request.user
        file = form.cleaned_data.get("file")
        if file:
            content_type = file.content_type
            if content_type.startswith("video/"):
                form.instance.media_type = CloudMedia.MediaType.VIDEO
            else:
                form.instance.media_type = CloudMedia.MediaType.IMAGE
        
        super().form_valid(form)
        
        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            html = render_to_string(
                "cloud/includes/media_card.html", 
                {"item": self.object}, 
                request=self.request
            )
            return JsonResponse({"status": "success", "html": html})
        return redirect(self.success_url)

    def form_invalid(self, form):
        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            import json
            return JsonResponse({
                "status": "error", 
                "errors": json.loads(form.errors.as_json())
            }, status=400)
        return redirect("cloud:media_list")
