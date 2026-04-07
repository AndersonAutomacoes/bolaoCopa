package com.bolao.copa.profile.avatar;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import org.springframework.stereotype.Service;

@Service
public class AvatarStorageService {

    private static final String DATA_SUFFIX = ".avatar";
    private static final String MIME_SUFFIX = ".mime";

    private final AvatarStorageProperties properties;

    public AvatarStorageService(AvatarStorageProperties properties) {
        this.properties = properties;
    }

    public String publicUrlForUser(Long userId) {
        return properties.normalizedPublicBaseUrl() + "/api/v1/files/avatars/" + userId;
    }

    public void save(Long userId, byte[] data, String contentType) {
        Path dir = storageRoot();
        try {
            Files.createDirectories(dir);
            Path dataPath = dir.resolve(userId + DATA_SUFFIX);
            Path mimePath = dir.resolve(userId + MIME_SUFFIX);
            Files.write(dataPath, data);
            Files.writeString(mimePath, contentType != null ? contentType : "application/octet-stream");
        } catch (IOException e) {
            throw new UncheckedIOException("Falha ao gravar avatar", e);
        }
    }

    public void deleteIfExists(Long userId) {
        Path dir = storageRoot();
        try {
            Files.deleteIfExists(dir.resolve(userId + DATA_SUFFIX));
            Files.deleteIfExists(dir.resolve(userId + MIME_SUFFIX));
        } catch (IOException e) {
            throw new UncheckedIOException("Falha ao remover avatar", e);
        }
    }

    public Optional<StoredAvatar> load(Long userId) {
        Path dir = storageRoot();
        Path dataPath = dir.resolve(userId + DATA_SUFFIX);
        Path mimePath = dir.resolve(userId + MIME_SUFFIX);
        if (!Files.isRegularFile(dataPath)) {
            return Optional.empty();
        }
        try {
            byte[] data = Files.readAllBytes(dataPath);
            String mime = Files.isRegularFile(mimePath)
                    ? Files.readString(mimePath).trim()
                    : "application/octet-stream";
            return Optional.of(new StoredAvatar(data, mime));
        } catch (IOException e) {
            throw new UncheckedIOException("Falha ao ler avatar", e);
        }
    }

    private Path storageRoot() {
        String raw = properties.storageDir();
        if (raw == null || raw.isBlank()) {
            return Path.of(System.getProperty("user.dir"), "data", "avatar-uploads");
        }
        return Path.of(raw);
    }

    public record StoredAvatar(byte[] data, String contentType) {}
}
