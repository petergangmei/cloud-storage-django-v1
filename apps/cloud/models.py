import os
import time
import uuid

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


def get_upload_path(instance, filename):
    """
    Generate a unique filename using timestamp and UUID.
    Format: cloud/YYYY/MM/DD/[timestamp]_[uuid].[ext]
    """
    ext = filename.split(".")[-1]
    # Use short UUID (first 8 chars) for readability while maintaining high uniqueness
    unique_id = uuid.uuid4().hex[:8]
    timestamp = int(time.time())
    new_filename = f"{timestamp}_{unique_id}.{ext}"
    
    # Use standard date-based directory structure
    date_path = time.strftime("%Y/%m/%d")
    return os.path.join("cloud", date_path, new_filename)


class CloudMedia(models.Model):
    class MediaType(models.TextChoices):
        IMAGE = "IMAGE", _("Image")
        VIDEO = "VIDEO", _("Video")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="cloud_media",
    )
    file = models.FileField(upload_to=get_upload_path)
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


from django.db.models.signals import post_delete
from django.dispatch import receiver

@receiver(post_delete, sender=CloudMedia)
def auto_delete_file_on_delete(sender, instance, **kwargs):
    """
    Deletes file from filesystem
    when corresponding CloudMedia object is deleted.
    """
    if instance.file:
        if os.path.isfile(instance.file.path):
            os.remove(instance.file.path)
