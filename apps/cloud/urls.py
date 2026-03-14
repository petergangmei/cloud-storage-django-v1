from django.urls import path
from .views import MediaListView, MediaUploadView

app_name = "cloud"

urlpatterns = [
    path("", MediaListView.as_view(), name="media_list"),
    path("upload/", MediaUploadView.as_view(), name="media_upload"),
]
