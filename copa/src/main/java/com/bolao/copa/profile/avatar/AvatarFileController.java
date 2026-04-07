package com.bolao.copa.profile.avatar;

import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/files/avatars")
public class AvatarFileController {

    private final AvatarStorageService avatarStorageService;

    public AvatarFileController(AvatarStorageService avatarStorageService) {
        this.avatarStorageService = avatarStorageService;
    }

    @GetMapping("/{userId}")
    public ResponseEntity<byte[]> get(@PathVariable Long userId) {
        return avatarStorageService
                .load(userId)
                .map(
                        stored -> ResponseEntity.ok()
                                .cacheControl(CacheControl.maxAge(java.time.Duration.ofHours(1)).cachePublic())
                                .header(HttpHeaders.CONTENT_TYPE, stored.contentType())
                                .body(stored.data()))
                .orElse(ResponseEntity.notFound().build());
    }
}
