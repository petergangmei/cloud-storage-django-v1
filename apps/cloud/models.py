from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class CloudMedia(models.Model):
    class MediaType(models.TextChoices):
        IMAGE = "IMAGE", _("Image")
        VIDEO = "VIDEO", _("Video")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="cloud_media",
    )
    file = models.FileField(upload_to="cloud/%Y/%m/%d/")
    media_type = models.CharField(
        max_length=10,
        choices=MediaType.choices,
        default=MediaType.IMAGE,
    )
    title = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("Cloud Media")
        verbose_name_plural = _("Cloud Media")
        ordering = ["-created_at"]

    def __str__(self):
        return self.title or self.file.name
