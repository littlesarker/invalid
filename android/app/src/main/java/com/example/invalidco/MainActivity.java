package com.example.invalidco;

import io.flutter.embedding.android.FlutterActivity;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.provider.MediaStore;

import android.Manifest;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.core.content.ContextCompat;
import androidx.core.app.ActivityCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "gallery_channel";
    private static final int PERMISSION_REQUEST_CODE = 123;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getImages":
                            if (checkStoragePermission()) {
                                result.success(getGalleryImages());
                            } else {
                                result.error("PERMISSION_DENIED", "Storage permission required", null);
                            }
                            break;
                        case "saveImage":
                            byte[] bytes = call.argument("bytes");
                            if (bytes != null) {
                                boolean saved = saveImage(bytes);
                                result.success(saved);
                            } else {
                                result.error("INVALID_ARGUMENT", "Bytes cannot be null", null);
                            }
                            break;
                        case "checkPermission":
                            result.success(checkStoragePermission());
                            break;
                        case "requestPermission":
                            requestStoragePermission(result);
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    private boolean checkStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // For Android 13+ we need READ_MEDIA_IMAGES permission
            return ContextCompat.checkSelfPermission(this,
                    Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED;
        } else {
            // For older versions, use READ_EXTERNAL_STORAGE
            return ContextCompat.checkSelfPermission(this,
                    Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
        }
    }

    private void requestStoragePermission(MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.READ_MEDIA_IMAGES},
                    PERMISSION_REQUEST_CODE);
        } else {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.READ_EXTERNAL_STORAGE},
                    PERMISSION_REQUEST_CODE);
        }
        // Note: You'll need to handle the permission result in onRequestPermissionsResult
        // and communicate back to Flutter via an EventChannel or similar
        result.success(null);
    }

    private List<byte[]> getGalleryImages() {
        List<byte[]> images = new ArrayList<>();
        ContentResolver contentResolver = getContentResolver();

        String[] projection = {MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME};
        String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";

        try (android.database.Cursor cursor = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection, null, null, sortOrder)) {

            if (cursor != null) {
                int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);

                // Limit the number of images to avoid memory issues
                int count = 0;
                final int MAX_IMAGES = 20;

                while (cursor.moveToNext() && count < MAX_IMAGES) {
                    long id = cursor.getLong(idColumn);
                    Uri uri = ContentUris.withAppendedId(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);

                    try {
                        Bitmap bitmap = MediaStore.Images.Media.getBitmap(contentResolver, uri);
                        // Resize to avoid memory issues
                        Bitmap resized = Bitmap.createScaledBitmap(bitmap,
                                bitmap.getWidth() / 4, bitmap.getHeight() / 4, true);

                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        resized.compress(Bitmap.CompressFormat.JPEG, 70, stream);
                        images.add(stream.toByteArray());

                        count++;
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return images;
    }

    private boolean saveImage(byte[] bytes) {
        try {
            Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
            if (bitmap == null) {
                return false;
            }

            String filename = "IMG_" + System.currentTimeMillis() + ".jpg";

            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, filename);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/MyApp");
            }

            Uri uri = getContentResolver().insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

            if (uri != null) {
                try (OutputStream fos = getContentResolver().openOutputStream(uri)) {
                    if (fos != null) {
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
                        fos.flush();
                        return true;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    // Handle permission results if needed
    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CODE) {
            // You might want to communicate this back to Flutter
        }
    }
}
