package com.bolao.copa;

import com.bolao.copa.profile.avatar.AvatarStorageProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(AvatarStorageProperties.class)
public class CopaApplication {

	public static void main(String[] args) {
		SpringApplication.run(CopaApplication.class, args);
	}

}
