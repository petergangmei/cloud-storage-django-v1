from django.urls import path
from .views import MediaListView, MediaUploadView, MediaDeleteView

app_name = "cloud"

urlpatterns = [
    path("", MediaListView.as_view(), name="media_list"),
    path("upload/", MediaUploadView.as_view(), name="media_upload"),
    path("delete/<int:pk>/", MediaDeleteView.as_view(), name="media_delete"),
]
