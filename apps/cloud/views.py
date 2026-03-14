from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView
from .forms import CloudMediaForm
from .models import CloudMedia


class MediaListView(LoginRequiredMixin, ListView):
    model = CloudMedia
    template_name = "cloud/media_list.html"
    context_object_name = "media_items"

    def get_queryset(self):
        return CloudMedia.objects.filter(user=self.request.user)


from django.http import JsonResponse


class MediaUploadView(LoginRequiredMixin, CreateView):
    model = CloudMedia
    form_class = CloudMediaForm
    template_name = "cloud/media_form.html"
    success_url = reverse_lazy("cloud:media_list")

    def form_valid(self, form):
        form.instance.user = self.request.user
        file = form.cleaned_data.get("file")
        if file:
            content_type = file.content_type
            if content_type.startswith("video/"):
                form.instance.media_type = CloudMedia.MediaType.VIDEO
            else:
                form.instance.media_type = CloudMedia.MediaType.IMAGE
        
        response = super().form_valid(form)
        
        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            return JsonResponse({"status": "success", "url": self.success_url})
        return response

    def form_invalid(self, form):
        response = super().form_invalid(form)
        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            return JsonResponse({"status": "error", "errors": form.errors.as_json()}, status=400)
        return response
